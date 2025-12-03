#!/usr/bin/env pwsh

<#
skip-cc-login.ps1

Configures Claude Code CLI to skip the onboarding/login process by setting
hasCompletedOnboarding = true in the per-user .claude.json file.

This script:
- Verifies Node.js, npm, and the Claude Code CLI are installed.
- Updates %USERPROFILE%\.claude.json to mark onboarding as complete.

No administrator privileges are required.
#>

$ErrorActionPreference = "Stop"

Write-Host "=== Claude Code Login Skip Script ===" -ForegroundColor Cyan
Write-Host ""

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

function Fail-AndExit {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Red
    exit 1
}

# --- Check Node.js ---
Write-Section "Checking Node.js installation..."
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Node.js found: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js command failed."
    }
} catch {
    Write-Host "Node.js not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js first, for example:" -ForegroundColor Yellow
    Write-Host "  - https://nodejs.org/"
    Write-Host "  - Or nvm-windows: https://github.com/coreybutler/nvm-windows"
    Write-Host ""
    Fail-AndExit "Install Node.js, restart PowerShell, and run this script again."
}

# --- Check npm ---
Write-Section "Checking npm installation..."
try {
    $npmVersion = npm --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "npm found: v$npmVersion" -ForegroundColor Green
    } else {
        throw "npm command failed."
    }
} catch {
    Write-Host "npm not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "npm should be installed together with Node.js." -ForegroundColor Yellow
    Write-Host "Please reinstall Node.js and try again."
    Write-Host ""
    Fail-AndExit "npm is required for Claude Code."
}

# --- Check Claude Code CLI ---
Write-Section "Checking Claude Code CLI installation..."
try {
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        $claudeVersion = claude --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Claude Code found: $claudeVersion" -ForegroundColor Green
        } else {
            Write-Host "Claude Code found (version check failed, but command exists)." -ForegroundColor Green
        }
    } else {
        throw "Claude Code not found."
    }
} catch {
    Write-Host "Claude Code CLI not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Claude Code CLI first, for example:" -ForegroundColor Yellow
    Write-Host "  npm install -g @anthropic-ai/claude-code"
    Write-Host ""
    Fail-AndExit "Install Claude Code CLI and then run this script again."
}

# --- Skip onboarding ---
Write-Section "Configuring Claude Code to skip onboarding..."

$configFile = Join-Path $env:USERPROFILE ".claude.json"

try {
    $config = @{}

    if (Test-Path $configFile) {
        try {
            $configContent = Get-Content $configFile -Raw -ErrorAction Stop
            if ($configContent.Trim().Length -gt 0) {
                $config = $configContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                Write-Host "Existing configuration loaded from $configFile" -ForegroundColor Green
            } else {
                Write-Host "Existing configuration file is empty; starting fresh." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Existing configuration is invalid JSON; starting fresh." -ForegroundColor Yellow
            $config = @{}
        }
    } else {
        Write-Host "No existing configuration found; creating a new one." -ForegroundColor Green
    }

    # Set the onboarding flag
    $config.hasCompletedOnboarding = $true

    # Write back to .claude.json as UTF-8 without BOM
    $json = $config | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configFile, $json, $utf8NoBom)

    Write-Host ""
    Write-Host "Configuration updated successfully." -ForegroundColor Green
    Write-Host "Config file location: $configFile"
    Write-Host ""
    Write-Host "Claude Code onboarding/login will now be skipped." -ForegroundColor Green
    Write-Host "You can start using Claude Code directly with:" 
    Write-Host "  claude" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "Failed to configure Claude Code to skip onboarding." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)"
    Fail-AndExit "Please review the error above and try again."
}
