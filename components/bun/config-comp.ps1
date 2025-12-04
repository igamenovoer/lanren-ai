<#
.SYNOPSIS
Configures Bun global settings (specifically the package registry mirror).

.DESCRIPTION
Updates or creates the .bunfig.toml file in the user's home directory to set
the default package registry. This is useful for users in regions with slow
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

$bunfigPath = Join-Path $env:USERPROFILE ".bunfig.toml"
$registryUrl = if ($Mirror -eq "cn") { "https://registry.npmmirror.com" } else { "https://registry.npmjs.org" }

Write-Host "=== Configuring Bun Global Mirror ==="
Write-Host "Target file: $bunfigPath"
Write-Host "Selected Mirror: $Mirror ($registryUrl)"

# Read existing content if file exists
if (Test-Path $bunfigPath) {
    $content = Get-Content $bunfigPath -Raw
} else {
    $content = ""
}

# Normalize line endings to `n for processing
$content = $content -replace "`r`n", "`n"

# We need to ensure [install] section exists and registry is set within it.
# Simple parser logic:
# 1. If `registry = "..."` exists, replace it.
# 2. If not, but `[install]` exists, add `registry = ...` after it.
# 3. If `[install]` doesn't exist, append the whole block.

# Note: This simple regex approach assumes `registry` is not used in other sections
# or that we only care about the first occurrence which is typically the global one.
# A more robust way would be to split by sections, but for a simple config script this is usually sufficient.

if ($content -match '(?m)^registry\s*=\s*".*"') {
    # Replace existing registry line
    $content = $content -replace '(?m)^registry\s*=\s*".*"', "registry = `"$registryUrl`""
    Write-Host "Updated existing registry configuration."
} elseif ($content -match '(?m)^\[install\]') {
    # [install] exists but no registry line found (or at least not at top level of it if we assume standard formatting)
    # We'll insert it after [install]
    $content = $content -replace '(?m)^\[install\]', "[install]`nregistry = `"$registryUrl`""
    Write-Host "Added registry configuration to existing [install] section."
} else {
    # No [install] section found
    if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
        $content += "`n"
    }
    $content += "[install]`nregistry = `"$registryUrl`"`n"
    Write-Host "Created [install] section with registry configuration."
}

# Write back with UTF8 encoding
$content | Out-File -FilePath $bunfigPath -Encoding utf8 -Force

Write-Host "Configuration complete."
