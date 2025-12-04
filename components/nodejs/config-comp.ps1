<#
.SYNOPSIS
Configures Node.js global settings (specifically the npm package registry mirror).

.DESCRIPTION
Sets the global npm registry. This is useful for users in regions with slow
access to the official npm registry (e.g., China).

.PARAMETER Mirror
The mirror to use.
Options:
- 'cn': Uses the npmmirror registry (https://registry.npmmirror.com).
- 'official': Uses the official npm registry (https://registry.npmjs.org).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("cn", "official")]
    [string]$Mirror
)

if (-not $Mirror) {
    Write-Output "Usage: .\config-comp.ps1 -Mirror <cn|official>"
    Write-Output "  cn       : Use npmmirror.com (China)"
    Write-Output "  official : Use npmjs.org"
    exit 0
}

$ErrorActionPreference = "Stop"

$registryUrl = if ($Mirror -eq "cn") { "https://registry.npmmirror.com" } else { "https://registry.npmjs.org" }

Write-Output "=== Configuring Node.js (npm) Global Mirror ==="
Write-Output "Selected Mirror: $Mirror ($registryUrl)"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm command not found. Please install Node.js first."
    exit 1
}

try {
    Write-Output "Running: npm config set registry $registryUrl"

    $setArgs = @("config","set","registry",$registryUrl)
    $setProcess = Start-Process -FilePath "npm" -ArgumentList $setArgs -NoNewWindow -Wait -PassThru
    if ($setProcess.ExitCode -ne 0) {
        Write-Error "npm config set registry exited with code $($setProcess.ExitCode)"
        exit 1
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $getArgs = @("config","get","registry")
        $getProcess = Start-Process -FilePath "npm" -ArgumentList $getArgs -NoNewWindow -Wait -RedirectStandardOutput $tempFile -PassThru
        if ($getProcess.ExitCode -ne 0) {
            Write-Error "npm config get registry exited with code $($getProcess.ExitCode)"
            exit 1
        }

        $current = (Get-Content $tempFile -Raw).Trim()
        Write-Output "Current registry: $current"

        if ($current -eq $registryUrl) {
            Write-Output "Configuration complete."
        } else {
            Write-Warning "Registry update might have failed. Expected '$registryUrl', got '$current'."
        }
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-Error "Failed to configure npm registry: $_"
    exit 1
}
