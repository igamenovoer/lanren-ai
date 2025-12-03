#!/usr/bin/env pwsh

<#
add-custom-api-for-cc.ps1

Windows PowerShell wrapper for the Bash helper:
  add-custom-api-for-cc.sh

This script:
- Locates a usable Bash executable (Git Bash or bash in PATH)
- Locates the sibling add-custom-api-for-cc.sh script
- Forwards all arguments to the Bash script

It does not require administrator privileges; it only modifies files
in your user profile via the underlying Bash script.
#>

$ErrorActionPreference = "Stop"

try {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if (-not $scriptDir) {
        $scriptDir = (Get-Location).Path
    }

    $bashScript = Join-Path $scriptDir "add-custom-api-for-cc.sh"
    if (-not (Test-Path $bashScript)) {
        Write-Error "Cannot find Bash script 'add-custom-api-for-cc.sh' at path: $bashScript"
        exit 1
    }

    $bashExe = $null

    # Prefer Git Bash if installed
    $gitBash64 = Join-Path ${env:ProgramFiles} "Git\bin\bash.exe"
    $gitBash32 = if ($env:ProgramFiles -ne $env:ProgramFilesx86) {
        Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"
    } else {
        $null
    }

    if ($gitBash64 -and (Test-Path $gitBash64)) {
        $bashExe = $gitBash64
    } elseif ($gitBash32 -and (Test-Path $gitBash32)) {
        $bashExe = $gitBash32
    } else {
        $bashCmd = Get-Command bash -ErrorAction SilentlyContinue
        if ($bashCmd) {
            $bashExe = $bashCmd.Path
        }
    }

    if (-not $bashExe) {
        Write-Host "[add-custom-api-for-cc.ps1] ERROR: Could not find a usable 'bash' on this system." -ForegroundColor Red
        Write-Host "Install Git for Windows (which includes Git Bash), or open a Bash shell and run:" -ForegroundColor Yellow
        Write-Host "  bash `"$bashScript`" [args...]" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Running add-custom-api-for-cc.sh via '$bashExe'..." -ForegroundColor Cyan
    Write-Host ""

    & $bashExe $bashScript @args
    $exitCode = $LASTEXITCODE
    exit $exitCode
}
catch {
    Write-Error "add-custom-api-for-cc.ps1 failed: $($_.Exception.Message)"
    exit 1
}

