#!/usr/bin/env pwsh

<#
add-custom-api-for-cc.ps1

Windows-only helper to configure Claude Code CLI to use a custom-compatible
Anthropic-style endpoint (e.g., Kimi K2, yunwu.ai, etc.) while skipping the
interactive sign-in and permission prompts.

It writes a PowerShell function into your user PowerShell profile so you can
run your custom endpoint with a simple command like:

    claude-kimi

Behavior:
- Prompts for alias name, base URL, and API key (input NOT hidden)
- Validates values (alias characters; base URL starts with http/https)
- Writes/updates a function in $PROFILE.CurrentUserCurrentHost:

    function <alias> {
        $env:ANTHROPIC_BASE_URL = "<base_url>"
        $env:ANTHROPIC_API_KEY  = "<api_key>"
        claude --dangerously-skip-permissions @ForwardArgs
    }

No administrator privileges are required; the profile is per-user.
#>

[CmdletBinding()]
param(
    [string]$AliasName,
    [string]$BaseUrl,
    [string]$ApiKey
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[add-custom-api] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[add-custom-api] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[add-custom-api] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Info "Configuring Claude Code custom endpoint in your PowerShell profile..."

    # Prompt interactively if parameters not provided
    if (-not $AliasName) {
        $AliasName = Read-Host "Alias name (e.g. claude-kimi)"
    }
    if (-not $BaseUrl) {
        $BaseUrl = Read-Host "Base URL (must include http/https, e.g. https://api.moonshot.cn/anthropic/)"
    }
    if (-not $ApiKey) {
        $ApiKey = Read-Host "API key (will be stored in your PowerShell profile as plain text)"
    }

    # Basic validations
    if (-not $AliasName) {
        Write-Err "Alias name cannot be empty."
        exit 1
    }
    if ($AliasName -notmatch '^[A-Za-z0-9_-]+$') {
        Write-Err "Alias name '$AliasName' has invalid characters. Allowed: A-Z, a-z, 0-9, underscore, hyphen."
        exit 1
    }
    if (-not $BaseUrl) {
        Write-Err "Base URL cannot be empty."
        exit 1
    }
    if ($BaseUrl -notmatch '^https?://') {
        Write-Err "Base URL must start with http:// or https://."
        exit 1
    }
    if (-not $ApiKey) {
        Write-Err "API key cannot be empty."
        exit 1
    }

    # Resolve user PowerShell profile path
    # Prefer the PowerShell 7 profile location, even if this script
    # is launched from Windows PowerShell 5.1 via .bat.
    if ($PSVersionTable.PSVersion.Major -ge 7 -and $PROFILE.CurrentUserCurrentHost) {
        # Running under pwsh: use the current host's profile
        $profilePath = $PROFILE.CurrentUserCurrentHost
    }
    else {
        # Approximate PowerShell 7 profile path for this user
        $userHome = $env:USERPROFILE
        if (-not $userHome) {
            Write-Err "Could not determine USERPROFILE for locating PowerShell 7 profile."
            exit 1
        }
        $profileDir = Join-Path $userHome "Documents\PowerShell"
        $profilePath = Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"
    }

    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    Write-Info "Using PowerShell profile: $profilePath"

    # Remove any existing block for this alias using BEGIN/END markers
    $beginMarker = "# BEGIN: Claude Code custom endpoint ($AliasName)"
    $endMarker   = "# END: Claude Code custom endpoint ($AliasName)"

    $content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        $content = ""
    }

    $pattern = [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker)
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, "", "Singleline")
        $content = $content.TrimEnd() + [Environment]::NewLine
    }

    Set-Content -Path $profilePath -Value $content -Encoding UTF8

    # Build the new function block
    $lines = @()
    $lines += ""
    $lines += $beginMarker
    $lines += "function $AliasName {"
    $lines += "    param("
    $lines += "        [Parameter(ValueFromRemainingArguments = `$true)]"
    $lines += "        [object[]]`$ForwardArgs"
    $lines += "    )"
    $lines += "    `$env:ANTHROPIC_BASE_URL = '$BaseUrl'"
    $lines += "    `$env:ANTHROPIC_API_KEY  = '$ApiKey'"
    $lines += "    claude --dangerously-skip-permissions @ForwardArgs"
    $lines += "}"
    $lines += $endMarker
    $lines += ""

    Add-Content -Path $profilePath -Value $lines -Encoding UTF8

    Write-Host ""
    Write-Host "Custom Claude Code endpoint configured successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Alias/function name: $AliasName"
    Write-Host "Base URL: $BaseUrl"
    Write-Host "API key is stored in your PowerShell profile in plain text." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start using it:"
    Write-Host "  1) Restart PowerShell, or run:"
    Write-Host "       . `"$profilePath`""
    Write-Host "  2) Then run:"
    Write-Host "       $AliasName"
}
catch {
    Write-Err "add-custom-api-for-cc.ps1 failed: $($_.Exception.Message)"
    exit 1
}
