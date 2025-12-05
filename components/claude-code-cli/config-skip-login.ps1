<#
.SYNOPSIS
Marks Claude Code CLI onboarding as completed so it skips the login/onboarding flow.

.DESCRIPTION
Updates the per-user Claude Code configuration file (%USERPROFILE%\.claude.json)
and sets `hasCompletedOnboarding` to `$true`. This lets you use the `claude`
command directly without going through the interactive onboarding UI.

The script:
- Verifies that Node.js, npm, and Claude Code CLI are available.
- Uses PowerShell's built-in JSON cmdlets to read and update the config file.

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
    Write-Host "[config-skip-login] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[config-skip-login] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[config-skip-login] ERROR: $Message" -ForegroundColor Red
}

Write-Host "=== Configure Claude Code to Skip Onboarding ==="
Write-Host ""

try {
    Write-Info "Checking Node.js..."
    try {
        $nodeVersion = node --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $nodeVersion) {
            Write-Info "Node.js found: $nodeVersion"
        } else {
            throw "Node.js command failed."
        }
    } catch {
        Write-Err "Node.js is not available on PATH."
        Write-Host "Install Node.js first, then re-run this script."
        Write-Host "Examples:"
        Write-Host "  - nvm-windows: https://github.com/coreybutler/nvm-windows"
        Write-Host "  - Official:   https://nodejs.org/"
        Exit-WithWait 1
    }

    Write-Info "Checking npm..."
    try {
        $npmVersion = npm --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $npmVersion) {
            Write-Info "npm found: v$npmVersion"
        } else {
            throw "npm command failed."
        }
    } catch {
        Write-Err "npm is not available on PATH."
        Write-Host "npm should be installed together with Node.js."
        Write-Host "Reinstall Node.js and then re-run this script."
        Exit-WithWait 1
    }

    Write-Info "Checking Claude Code CLI..."
    try {
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
        if ($claudeCmd) {
            $claudeVersion = claude --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $claudeVersion) {
                Write-Info "Claude Code CLI found: $claudeVersion"
            } else {
                Write-Info "Claude Code CLI found."
            }
        } else {
            throw "Claude Code CLI not found."
        }
    } catch {
        Write-Err "Claude Code CLI ('claude') is not on PATH."
        Write-Host "Install it first, for example:"
        Write-Host "  npm install -g @anthropic-ai/claude-code"
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Info "Configuring Claude Code to skip onboarding..."

    $configFile = Join-Path $env:USERPROFILE ".claude.json"

    $config = @{}

    if (Test-Path $configFile) {
        try {
            $configContent = Get-Content $configFile -Raw -ErrorAction Stop
            if ($configContent.Trim().Length -gt 0) {
                $config = $configContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                Write-Info "Existing configuration detected; updating hasCompletedOnboarding."
            } else {
                Write-Warn "Existing configuration file is empty; starting fresh."
                $config = @{}
            }
        } catch {
            Write-Warn "Existing configuration is invalid JSON; starting fresh."
            $config = @{}
        }
    } else {
        Write-Info "No existing configuration; creating a new one."
    }

    $config.hasCompletedOnboarding = $true

    try {
        $json = $config | ConvertTo-Json -Depth 10

        # Write JSON as UTF-8 without BOM so Claude's JSON parser
        # sees a clean leading "{" character and not a BOM/extra token.
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($configFile, $json, $utf8NoBom)
    } catch {
        Write-Err "Failed to write configuration: $($_.Exception.Message)"
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Host "Claude Code onboarding has been marked as completed." -ForegroundColor Green
    Write-Host "Config file: $configFile"
    Write-Host ""
    Write-Host "You can now run the 'claude' command without the onboarding flow."

    Exit-WithWait 0
}
catch {
    Write-Err "config-skip-login.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
