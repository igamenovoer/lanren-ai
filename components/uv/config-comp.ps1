<#
.SYNOPSIS
Configures uv global settings (specifically the Python package index mirror).

.DESCRIPTION
Sets the global index-url for uv. This is useful for users in regions with slow
access to the official PyPI registry (e.g., China).
It modifies the user's global configuration file (e.g., %APPDATA%\uv\uv.toml).

.PARAMETER Mirror
The mirror to use.
Options:
- 'cn': Defaults to 'aliyun'.
- 'aliyun': Uses Aliyun mirror (https://mirrors.aliyun.com/pypi/simple/).
- 'tuna': Uses Tsinghua University mirror (https://pypi.tuna.tsinghua.edu.cn/simple).
- 'official': Uses the official PyPI registry (https://pypi.org/simple).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("cn", "aliyun", "tuna", "official")]
    [string]$Mirror
)

if (-not $Mirror) {
    Write-Output "Usage: .\config-comp.ps1 -Mirror <cn|aliyun|tuna|official>"
    Write-Output "  cn       : Use Aliyun mirror (default for China)"
    Write-Output "  aliyun   : Use Aliyun mirror"
    Write-Output "  tuna     : Use Tsinghua University mirror"
    Write-Output "  official : Use official PyPI"
    exit 0
}

$ErrorActionPreference = "Stop"

# Map 'cn' to 'aliyun'
if ($Mirror -eq "cn") { $Mirror = "aliyun" }

$registryUrl = switch ($Mirror) {
    "aliyun"   { "https://mirrors.aliyun.com/pypi/simple/" }
    "tuna"     { "https://pypi.tuna.tsinghua.edu.cn/simple" }
    "official" { "https://pypi.org/simple" }
}

Write-Output "=== Configuring uv Global Mirror ==="
Write-Output "Selected Mirror: $Mirror ($registryUrl)"

# Determine config path
# On Windows, uv looks in %APPDATA%\uv\uv.toml
$configDir = Join-Path $env:APPDATA "uv"
$configPath = Join-Path $configDir "uv.toml"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Read existing content
if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw
} else {
    $content = ""
}

# Normalize line endings
$content = $content -replace "`r`n", "`n"

# We need to set `index-url` in the global scope (top level of toml)
# or under [pip] section if using older conventions, but uv native config uses top-level keys or specific sections.
# According to uv docs, `index-url` is a top-level key in `uv.toml`.

# Simple parser logic:
# 1. If `index-url = "..."` exists, replace it.
# 2. If not, append it.

if ($content -match '(?m)^index-url\s*=\s*".*"') {
    $content = $content -replace '(?m)^index-url\s*=\s*".*"', "index-url = `"$registryUrl`""
    Write-Output "Updated existing index-url configuration."
} else {
    if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
        $content += "`n"
    }
    $content += "index-url = `"$registryUrl`"`n"
    Write-Output "Added index-url configuration."
}

# Write back with UTF8 encoding
$content | Out-File -FilePath $configPath -Encoding utf8 -Force

Write-Output "Configuration complete."
Write-Output "Config file location: $configPath"
