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
    Write-Host "Usage: .\config-comp.ps1 -Mirror <cn|official>"
    Write-Host "  cn       : Use npmmirror.com (China)"
    Write-Host "  official : Use npmjs.org"
    exit 0
}

$ErrorActionPreference = "Stop"

$registryUrl = if ($Mirror -eq "cn") { "https://registry.npmmirror.com" } else { "https://registry.npmjs.org" }

Write-Host "=== Configuring Node.js (npm) Global Mirror ==="
Write-Host "Selected Mirror: $Mirror ($registryUrl)"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm command not found. Please install Node.js first."
    exit 1
}

try {
    Write-Host "Running: npm config set registry $registryUrl"
    npm config set registry $registryUrl
    
    $current = npm config get registry
    Write-Host "Current registry: $current"
    
    if ($current.Trim() -eq $registryUrl) {
        Write-Host "Configuration complete."
    } else {
        Write-Warning "Registry update might have failed. Expected '$registryUrl', got '$current'."
    }
} catch {
    Write-Error "Failed to configure npm registry: $_"
    exit 1
}
