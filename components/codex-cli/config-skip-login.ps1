<#
.SYNOPSIS
Configures Codex CLI to skip the login screen and use OPENAI_API_KEY from the environment.

.DESCRIPTION
Updates the Codex configuration file (`config.toml` under CODEX_HOME, default `%USERPROFILE%\.codex`)
so that the built-in `openai` provider:

- Uses the environment variable `OPENAI_API_KEY` for authentication.
- Has `requires_openai_auth = false`, which disables the login screen.

After running this script and setting `OPENAI_API_KEY` in your environment, Codex CLI should start
without prompting you to sign in.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
Useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit
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
    Write-Host "[codex-config-skip-login] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[codex-config-skip-login] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[codex-config-skip-login] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Info "Configuring Codex CLI to skip login and use OPENAI_API_KEY..."

    $codexCmd = Get-Command codex -ErrorAction SilentlyContinue
    if (-not $codexCmd) {
        Write-Err "'codex' CLI not found in PATH. Install Codex CLI first (see components/codex-cli/install-comp)."
        Exit-WithWait 1
    }

    $userHome = $env:USERPROFILE
    if (-not $userHome) {
        Write-Err "Could not determine USERPROFILE."
        Exit-WithWait 1
    }

    $codexHome = $env:CODEX_HOME
    if (-not $codexHome -or $codexHome.Trim().Length -eq 0) {
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

    $configContent = $configContent -replace "`r`n", "`n"

    if ($configContent -notmatch '(?m)^\[model_providers\]') {
        if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
            $configContent += "`n"
        }
        $configContent += "`n[model_providers]`n"
    }

    $openAiBlockPattern = '(?ms)^\[model_providers\.openai\].*?(?=^\[|\z)'
    if ($configContent -match $openAiBlockPattern) {
        $configContent = [regex]::Replace($configContent, $openAiBlockPattern, "")
        $configContent = $configContent.TrimEnd() + "`n"
    }

    $providerLines = @()
    $providerLines += ""
    $providerLines += "[model_providers.openai]"
    $providerLines += 'name = "OpenAI"'
    $providerLines += 'base_url = "https://api.openai.com/v1"'
    $providerLines += 'env_key = "OPENAI_API_KEY"'
    $providerLines += 'env_key_instructions = "Set OPENAI_API_KEY in your environment before starting Codex."'
    $providerLines += "requires_openai_auth = false"
    $providerLines += ""

    if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += ($providerLines -join "`n") + "`n"

    $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force

    Write-Host ""
    Write-Host "Codex CLI is now configured to skip the login screen for the OpenAI provider." -ForegroundColor Green
    Write-Host "Config file: $configPath"
    Write-Host ""
    Write-Host "Before running 'codex', ensure OPENAI_API_KEY is set in your environment."

    Exit-WithWait 0
}
catch {
    Write-Err "config-skip-login.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}

