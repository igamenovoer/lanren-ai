<#
.SYNOPSIS
Configures Codex CLI to use a custom OpenAI-compatible endpoint and API key without showing the login screen.

.DESCRIPTION
This script does two things for the current user:

- Writes a PowerShell function into your PowerShell profiles (Windows PowerShell 5.1 and PowerShell 7+)
  so you can launch Codex with a custom endpoint and API key via a short alias.
- Updates the Codex configuration file (`config.toml` under CODEX_HOME, default `%USERPROFILE%\.codex`)
  so that:
    - A new model provider is created based on your alias name.
    - `model_provider` is set to that provider.
    - The provider reads its API key from `OPENAI_API_KEY` and has `requires_openai_auth = false`, which disables the login screen.

The PowerShell alias function looks like:

    function <alias> {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$ForwardArgs
        )
        $env:OPENAI_BASE_URL = "<base_url>"
        $env:OPENAI_API_KEY  = "<api_key>"
        codex @ForwardArgs
    }

.PARAMETER AliasName
Name of the PowerShell function/alias to create (for example: codex-openai-proxy).

.PARAMETER BaseUrl
Base URL of the custom OpenAI-compatible endpoint (must start with http:// or https://).

.PARAMETER ApiKey
API key for the endpoint. Stored in your PowerShell profiles as plain text.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
Useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [string]$AliasName,
    [string]$BaseUrl,
    [string]$ApiKey
)

function Exit-WithWait {
    param([int]$Code = 0)
    if ($NoExit) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit $Code
}

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[codex-config-custom-api-key] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[codex-config-custom-api-key] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[codex-config-custom-api-key] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Info "Configuring Codex CLI custom endpoint and skipping login..."

    if (-not $AliasName) {
        Write-Host "Alias name is the short PowerShell command you will type later to start Codex with this custom endpoint (for example: codex-openai-proxy)."
        $AliasName = Read-Host "Enter alias name"
    }
    if (-not $BaseUrl) {
        $BaseUrl = Read-Host "Base URL (must include http/https, e.g. https://api.example.com/v1)"
    }
    if (-not $ApiKey) {
        $ApiKey = Read-Host "API key (will be stored in your PowerShell profiles as plain text)"
    }

    if (-not $AliasName) {
        Write-Err "Alias name cannot be empty."
        Exit-WithWait 1
    }
    if ($AliasName -notmatch '^[A-Za-z0-9_-]+$') {
        Write-Err "Alias name '$AliasName' has invalid characters. Allowed: A-Z, a-z, 0-9, underscore, hyphen."
        Exit-WithWait 1
    }
    if (-not $BaseUrl) {
        Write-Err "Base URL cannot be empty."
        Exit-WithWait 1
    }
    if ($BaseUrl -notmatch '^https?://') {
        Write-Err "Base URL must start with http:// or https://."
        Exit-WithWait 1
    }
    if (-not $ApiKey) {
        Write-Err "API key cannot be empty."
        Exit-WithWait 1
    }

    # Use the alias as the model provider ID in config.toml. We intentionally do
    # not allow "openai" here because the built-in "openai" provider cannot be
    # overridden in this Codex version due to how providers are merged.
    $providerId = $AliasName
    if ($providerId -ieq "openai") {
        Write-Err "Alias name '$AliasName' cannot be used because 'openai' is a reserved built-in provider id. Please choose a different alias (for example: codex-openai-proxy)."
        Exit-WithWait 1
    }

    # Ensure Codex CLI is available
    $codexCmd = Get-Command codex -ErrorAction SilentlyContinue
    if (-not $codexCmd) {
        Write-Err "'codex' CLI not found in PATH. Install Codex CLI first (see components/codex-cli/install-comp)."
        Exit-WithWait 1
    } else {
        $codexVersion = codex --version 2>$null
        if ($codexVersion) {
            Write-Info "Codex CLI found: $codexVersion"
        } else {
            Write-Info "Codex CLI found."
        }
    }

    # 1) Configure PowerShell alias in both Windows PowerShell 5.1 and PowerShell 7+ profiles
    $userHome = $env:USERPROFILE
    if (-not $userHome) {
        Write-Err "Could not determine USERPROFILE for locating PowerShell profiles."
        Exit-WithWait 1
    }

    $profileTargets = @(
        @{
            Name = "Windows PowerShell 5.1"
            Path = (Join-Path $userHome "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
        },
        @{
            Name = "PowerShell 7+"
            Path = (Join-Path $userHome "Documents\PowerShell\Microsoft.PowerShell_profile.ps1")
        }
    )

    $beginMarker = "# BEGIN: Codex custom endpoint ($AliasName)"
    $endMarker   = "# END: Codex custom endpoint ($AliasName)"

    $functionLines = @()
    $functionLines += ""
    $functionLines += $beginMarker
    $functionLines += "function $AliasName {"
    $functionLines += "    param("
    $functionLines += "        [Parameter(ValueFromRemainingArguments = `$true)]"
    $functionLines += "        [object[]]`$ForwardArgs"
    $functionLines += "    )"
    $functionLines += "    `$env:OPENAI_BASE_URL = '$BaseUrl'"
    $functionLines += "    `$env:OPENAI_API_KEY  = '$ApiKey'"
    $functionLines += "    codex @ForwardArgs"
    $functionLines += "}"
    $functionLines += $endMarker
    $functionLines += ""

    foreach ($target in $profileTargets) {
        $profilePath = $target.Path
        $profileDir = Split-Path -Parent $profilePath

        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }

        Write-Info "Using profile for $($target.Name): $profilePath"

        $content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) {
            $content = ""
        }

        $pattern = [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker)
        if ($content -match $pattern) {
            $content = [regex]::Replace($content, $pattern, "", "Singleline")
            $content = $content.TrimEnd() + [Environment]::NewLine
        }

        # Also remove any existing function definition for this alias, even if it
        # was not created by our markers, to avoid duplicate functions.
        $escapedAlias = [regex]::Escape($AliasName)
        $funcPattern = "(?msi)^\s*function\s+$escapedAlias\s*\{.*?^\}"
        if ($content -match $funcPattern) {
            $content = [regex]::Replace($content, $funcPattern, "", "Singleline")
            $content = $content.TrimEnd() + [Environment]::NewLine
        }

        Set-Content -Path $profilePath -Value $content -Encoding UTF8
        Add-Content -Path $profilePath -Value $functionLines -Encoding UTF8
    }

    # 2) Update CODEX_HOME/config.toml so OpenAI provider uses env key and skips login
    $codexHome = $env:CODEX_HOME
    if (-not $codexHome -or $codexHome.Trim().Length -eq 0) {
        if (-not $userHome) {
            Write-Err "Could not determine CODEX_HOME; CODEX_HOME and USERPROFILE are both unset."
            Exit-WithWait 1
        }
        $codexHome = Join-Path $userHome ".codex"
    }

    if (-not (Test-Path $codexHome)) {
        New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
    }

    $configPath = Join-Path $codexHome "config.toml"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType File -Path $configPath -Force | Out-Null
        $configContent = ""
    } else {
        $configContent = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $configContent) {
            $configContent = ""
        }
    }

    # Normalize line endings
    $configContent = $configContent -replace "`r`n", "`n"

    # Ensure model_provider points to our custom provider id
    if ($configContent -match '(?m)^\s*model_provider\s*=') {
        $configContent = [regex]::Replace(
            $configContent,
            '(?m)^\s*model_provider\s*=.*$',
            "model_provider = `"$providerId`""
        )
    } else {
        # Prepend at the top so root keys stay before tables
        $configContent = "model_provider = `"$providerId`"`n" + $configContent
    }

    if ($configContent -notmatch '(?m)^\[model_providers\]') {
        if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
            $configContent += "`n"
        }
        $configContent += "`n[model_providers]`n"
    }

    # Remove any existing block for this provider id
    $escapedProviderId = [regex]::Escape($providerId)
    $providerBlockPattern = "(?ms)^\[model_providers\.$escapedProviderId\].*?(?=^\[|\z)"
    if ($configContent -match $providerBlockPattern) {
        $configContent = [regex]::Replace($configContent, $providerBlockPattern, "")
        $configContent = $configContent.TrimEnd() + "`n"
    }

    # Append new provider block that uses env key and skips login
    $providerLines = @()
    $providerLines += ""
    $providerLines += "[model_providers.$providerId]"
    $providerLines += 'name = "Custom OpenAI-compatible endpoint"'
    $providerLines += "base_url = `"$BaseUrl`""
    $providerLines += 'env_key = "OPENAI_API_KEY"'
    $providerLines += 'env_key_instructions = "Set OPENAI_API_KEY in your environment or use the PowerShell alias function to launch Codex."'
    $providerLines += "requires_openai_auth = false"
    $providerLines += ""

    if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += ($providerLines -join "`n") + "`n"

    $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force

    Write-Host ""
    Write-Host "Custom Codex endpoint configured successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Alias/function name: $AliasName"
    Write-Host "Base URL: $BaseUrl"
    Write-Host "API key is stored in your PowerShell profiles in plain text." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start using it:"
    Write-Host "  1) Restart PowerShell, or run for each host:"
    Write-Host "       . `"%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`"  (Windows PowerShell 5.1)"
    Write-Host "       . `"%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`"        (PowerShell 7+)"
    Write-Host "  2) Then run:"
    Write-Host "       $AliasName"
    Write-Host ""
    Write-Host "Codex will use OPENAI_API_KEY from the environment and will not show the login screen for this custom provider."

    Exit-WithWait 0
}
catch {
    Write-Err "config-custom-api-key.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
