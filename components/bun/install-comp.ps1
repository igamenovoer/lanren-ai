<#
.SYNOPSIS
Installs the Bun JavaScript runtime on Windows.

.DESCRIPTION
Prefers the official Bun install script so that both `bun` and `bunx` are
available and the PATH is configured correctly. Respects optional proxy
settings and an optional log file for paired .bat wrappers.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for outbound network requests.

.PARAMETER AcceptDefaults
When specified, runs non-interactively and accepts sensible defaults where
possible. This script does not prompt even without this switch, but it is
included for consistency with other installers.

.PARAMETER FromOfficial
When specified, forces use of the official Bun URLs. For Bun this is already
the default.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using the
console default encoding so a .bat wrapper can print it.
#>

[CmdletBinding()]
param(
    [string]$Proxy,
    [switch]$AcceptDefaults,
    [switch]$FromOfficial,
    [switch]$Force,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$script:LanrenComponentName = Split-Path -Leaf $PSScriptRoot
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "bun" }

function Get-LanrenAiRoot {
    [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "lanren-ai")
}

function Get-LanrenComponentLogFile {
    param(
        [string]$ComponentName
    )

    if (-not $ComponentName) {
        $ComponentName = $script:LanrenComponentName
    }

    $root = Get-LanrenAiRoot
    $logDir = Join-Path $root ("logs\" + $ComponentName)
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Join-Path $logDir ("$ComponentName-$timestamp.log")
}

function Get-LanrenComponentPackagePath {
    param(
        [string]$FileName,
        [string]$ComponentName
    )

    if (-not $ComponentName) {
        $ComponentName = $script:LanrenComponentName
    }

    $root = Get-LanrenAiRoot
    $pkgDir = Join-Path $root ("packages\" + $ComponentName)
    if (-not (Test-Path $pkgDir)) {
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
    }

    if ($FileName) {
        return Join-Path $pkgDir $FileName
    }

    return $pkgDir
}

$script:LanrenDefaultLogFile = Get-LanrenComponentLogFile -ComponentName $script:LanrenComponentName
$script:LanrenLogFiles = @($script:LanrenDefaultLogFile)
if ($CaptureLogFile) {
    $script:LanrenLogFiles += $CaptureLogFile
}

$null = $AcceptDefaults
$null = $FromOfficial

$lines = @()
$lines += ""
$lines += "=== Installing Bun (JavaScript runtime) ==="
$lines += ""

function Write-OutputLine {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    $targets = @()
    if ($script:LanrenLogFiles) {
        $targets = $script:LanrenLogFiles
    } elseif ($LogFile) {
        $targets = @($LogFile)
    }

    if ($targets.Count -gt 0) {
        $text = $Content -join "`r`n"
        foreach ($t in $targets) {
            if (-not [string]::IsNullOrWhiteSpace($t)) {
                $dir = Split-Path -Parent $t
                if ($dir -and -not (Test-Path $dir)) {
                    New-Item -ItemType Directory -Path $dir -Force | Out-Null
                }
                $text | Out-File -FilePath $t -Encoding Default -Force
            }
        }
    } else {
        $Content | ForEach-Object { Write-Output $_ }
    }
}

try {
    $existing = Get-Command bun -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        $lines += "Bun is already available on PATH (bun command found). Use -Force to reinstall."
        $lines += "No installation performed."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 0
    }
} catch {
    $lines += "Warning: Failed to detect existing Bun installation: $($_.Exception.Message)"
}

try {
    if ($Proxy) {
        $lines += "Using proxy: $Proxy"
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
    }

    $lines += "Running Bun official installer script from https://bun.sh/install.ps1 ..."
    $installCommand = 'irm https://bun.sh/install.ps1 | iex'

    powershell -NoProfile -ExecutionPolicy Bypass -Command $installCommand
    if ($LASTEXITCODE -ne 0) {
        $lines += "Bun installer returned a non-zero exit code: $LASTEXITCODE"
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    $bunCommand = Get-Command bun -ErrorAction SilentlyContinue
    $bunxCommand = Get-Command bunx -ErrorAction SilentlyContinue

    if (-not $bunCommand -or -not $bunxCommand) {
        $lines += "Bun installation completed but 'bun' or 'bunx' is not on PATH."
        $lines += "You may need to restart your shell or sign out and back in."
    } else {
        $lines += "Bun installation completed successfully."
        $lines += "Detected bun:  $((bun --version) 2>$null)"
        $lines += "Detected bunx: $((bunx --version) 2>$null)"
    }
} catch {
    $lines += "Error installing Bun: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 0
