<#
.SYNOPSIS
Configures Claude Code CLI to use a custom-compatible endpoint and API key.

.DESCRIPTION
Adds a PowerShell function into your user PowerShell profiles so you can run
Claude Code CLI against a custom Anthropic-compatible endpoint (e.g. Kimi K2,
yunwu.ai, etc.) without going through the interactive sign-in and permission
prompts.

This script writes the same function into:
- Windows PowerShell 5.1 profile   (%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1)
- PowerShell 7+ profile            (%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)

The function looks like:

    function <alias> {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$ForwardArgs
        )
        $env:ANTHROPIC_BASE_URL = "<base_url>"
        $env:ANTHROPIC_API_KEY  = "<api_key>"
        # When primary/secondary models are provided, the helper also sets:
        #   - Primary model (big):   ANTHROPIC_MODEL, ANTHROPIC_DEFAULT_OPUS_MODEL, ANTHROPIC_DEFAULT_SONNET_MODEL
        #   - Secondary model (small): ANTHROPIC_DEFAULT_HAIKU_MODEL, CLAUDE_CODE_SUBAGENT_MODEL
        claude --dangerously-skip-permissions @ForwardArgs
    }

.PARAMETER AliasName
Name of the function/alias to create (e.g. claude-kimi).

.PARAMETER BaseUrl
Base URL of the custom endpoint (must start with http:// or https:// when provided). If omitted, the alias will not change ANTHROPIC_BASE_URL and Claude Code will use its default endpoint.

.PARAMETER ApiKey
API key for the custom endpoint. Stored in your PowerShell profiles as plain text.

.PARAMETER PrimaryModelName
Optional primary (big) model name. When provided, the generated alias function sets ANTHROPIC_MODEL and the default OPUS/SONNET models to this value before launching Claude Code.

.PARAMETER SecondaryModelName
Optional secondary (small) model name. When provided, the generated alias function sets the default HAIKU model and CLAUDE_CODE_SUBAGENT_MODEL to this value. If omitted but PrimaryModelName is set, the secondary model defaults to the primary.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
Useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [string]$AliasName,
    [string]$BaseUrl,
    [string]$ApiKey,
    [string]$PrimaryModelName,
    [string]$SecondaryModelName
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
    Write-Host "[config-custom-api-key] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[config-custom-api-key] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[config-custom-api-key] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Info "Configuring Claude Code custom endpoint in your PowerShell profiles..."

    if (-not $AliasName) {
        Write-Host "Alias name is the short PowerShell command you will type later to start Claude Code with this custom endpoint (for example: claude-kimi)."
        $AliasName = Read-Host "Enter alias name"
    }
    if (-not $BaseUrl) {
        $BaseUrl = Read-Host "Base URL (optional; must include http/https when set, e.g. https://api.moonshot.cn/anthropic/; press Enter to use the official endpoint)"
    }
    if (-not $ApiKey) {
        $ApiKey = Read-Host "API key (will be stored in your PowerShell profiles as plain text)"
    }
    if (-not $PrimaryModelName) {
        $PrimaryModelName = Read-Host "Primary model (big; optional, e.g. kimi-k2-thinking-turbo; press Enter to skip)"
    }
    if ($PrimaryModelName -and -not $SecondaryModelName) {
        $SecondaryModelName = Read-Host "Secondary model (small; optional; press Enter to reuse the primary model)"
    }

    if (-not $AliasName) {
        Write-Err "Alias name cannot be empty."
        Exit-WithWait 1
    }
    if ($AliasName -notmatch '^[A-Za-z0-9_-]+$') {
        Write-Err "Alias name '$AliasName' has invalid characters. Allowed: A-Z, a-z, 0-9, underscore, hyphen."
        Exit-WithWait 1
    }
    if ($BaseUrl -and $BaseUrl -notmatch '^https?://') {
        Write-Err "Base URL must start with http:// or https:// when provided."
        Exit-WithWait 1
    }
    if (-not $ApiKey) {
        Write-Err "API key cannot be empty."
        Exit-WithWait 1
    }

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

    $beginMarker = "# BEGIN: Claude Code custom endpoint ($AliasName)"
    $endMarker   = "# END: Claude Code custom endpoint ($AliasName)"

    $functionLines = @()
    $functionLines += ""
    $functionLines += $beginMarker
    $functionLines += "function $AliasName {"
    $functionLines += "    param("
    $functionLines += "        [Parameter(ValueFromRemainingArguments = `$true)]"
    $functionLines += "        [object[]]`$ForwardArgs"
    $functionLines += "    )"
    if ($BaseUrl) {
        $functionLines += "    `$env:ANTHROPIC_BASE_URL = '$BaseUrl'"
    }
    $functionLines += "    `$env:ANTHROPIC_API_KEY    = '$ApiKey'"

    $primaryForEnv = $PrimaryModelName
    $secondaryForEnv = $SecondaryModelName
    if ($primaryForEnv -and -not $secondaryForEnv) {
        $secondaryForEnv = $primaryForEnv
    }

    # Only touch model-related env vars when a primary model is set.
    if ($primaryForEnv) {
        $functionLines += "    `$env:ANTHROPIC_MODEL                = '$primaryForEnv'"
        $functionLines += "    `$env:ANTHROPIC_DEFAULT_OPUS_MODEL   = '$primaryForEnv'"
        $functionLines += "    `$env:ANTHROPIC_DEFAULT_SONNET_MODEL = '$primaryForEnv'"

        if ($secondaryForEnv) {
            $functionLines += "    `$env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = '$secondaryForEnv'"
        }

        $chosenSubagentModel = $primaryForEnv
        if ($chosenSubagentModel) {
            $functionLines += "    `$env:CLAUDE_CODE_SUBAGENT_MODEL     = '$chosenSubagentModel'"
        }
    }
    $functionLines += "    claude --dangerously-skip-permissions @ForwardArgs"
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

    Write-Host ""
    Write-Host "Custom Claude Code endpoint configured successfully." -ForegroundColor Green
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

    $settingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"

    if (Test-Path $settingsFile) {
        $settingsContent = Get-Content $settingsFile -Raw -ErrorAction SilentlyContinue
        if ($settingsContent -and $settingsContent -match '"apiKeyHelper"') {
            Write-Host ""
            $ans = Read-Host "Found existing apiKeyHelper in $settingsFile. Update with new key? [y/N]"
            if ($ans -match '^[Yy]$') {
                $jqAvailable = $false
                try {
                    $jqCmd = Get-Command jq -ErrorAction SilentlyContinue
                    if ($jqCmd) {
                        $jqAvailable = $true
                    }
                } catch {
                    $jqAvailable = $false
                }

                $backupFile = "$settingsFile.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
                Copy-Item -Path $settingsFile -Destination $backupFile -Force
                Write-Warn "Existing settings.json backed up to $backupFile"

                if ($jqAvailable) {
                    Write-Info "Using jq for JSON manipulation"

                    $isValid = $false
                    try {
                        $null = Get-Content $settingsFile -Raw | jq empty 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            $isValid = $true
                        }
                    } catch {
                        $isValid = $false
                    }

                    if ($isValid) {
                        $tempFile = "$settingsFile.tmp"
                        Get-Content $settingsFile -Raw | jq --arg key $ApiKey '.apiKeyHelper = "echo " + $key' | Set-Content $tempFile -Encoding UTF8 -NoNewline
                        Move-Item $tempFile $settingsFile -Force
                        Write-Host "Updated apiKeyHelper in $settingsFile" -ForegroundColor Green
                    } else {
                        Write-Warn "Existing settings.json is invalid JSON. Skipping update."
                    }
                } else {
                    Write-Info "jq not found, using PowerShell for JSON manipulation"

                    try {
                        $config = $settingsContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                        $config.apiKeyHelper = "echo $ApiKey"
                        $config | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
                        Write-Host "Updated apiKeyHelper in $settingsFile" -ForegroundColor Green
                    } catch {
                        Write-Warn "Failed to parse settings.json. Skipping update."
                    }
                }
            } else {
                Write-Warn "Skipped settings.json update."
            }
        }
    }

    Exit-WithWait 0
}
catch {
    Write-Err "config-custom-api-key.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
