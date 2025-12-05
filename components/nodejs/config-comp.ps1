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

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
This is useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [Parameter(Mandatory=$false)
]
    [ValidateSet("cn", "official")]
    [string]$Mirror
)
function Exit-WithWait {
    param([int]$Code = 0)
    if ($NoExit) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit $Code
}



if (-not $Mirror) {
    Write-Output "Usage: .\config-comp.ps1 -Mirror <cn|official>"
    Write-Output "  cn       : Use npmmirror.com (China)"
    Write-Output "  official : Use npmjs.org"
}

$ErrorActionPreference = "Stop"

$registryUrl = if ($Mirror -eq "cn") { "https://registry.npmmirror.com" } else { "https://registry.npmjs.org" }

Write-Output "=== Configuring Node.js (npm) Global Mirror ==="
Write-Output "Selected Mirror: $Mirror ($registryUrl)"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm command not found. Please install Node.js first."
    Exit-WithWait 1
}

try {
    Write-Output "Running: npm config set registry $registryUrl"

    $setArgs = @("config","set","registry",$registryUrl)
    $setProcess = Start-Process -FilePath "npm" -ArgumentList $setArgs -NoNewWindow -Wait -PassThru
    if ($setProcess.ExitCode -ne 0) {
        Write-Error "npm config set registry exited with code $($setProcess.ExitCode)"
        Exit-WithWait 1
    }

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $getArgs = @("config","get","registry")
        $getProcess = Start-Process -FilePath "npm" -ArgumentList $getArgs -NoNewWindow -Wait -RedirectStandardOutput $tempFile -PassThru
        if ($getProcess.ExitCode -ne 0) {
            Write-Error "npm config get registry exited with code $($getProcess.ExitCode)"
            Exit-WithWait 1
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
    Exit-WithWait 1
}


if ($NoExit) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Exit-WithWait 0
