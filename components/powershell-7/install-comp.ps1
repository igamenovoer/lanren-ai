<#
.SYNOPSIS
Installs PowerShell 7 on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, instructs
the user on manual installation from official sources.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official PowerShell download sites in guidance.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using the
console default encoding so a .bat wrapper can print it.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
This is useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [string]$Proxy,
    [switch]$AcceptDefaults,
    [switch]$FromOfficial,
    [switch]$Force,
    [string]$CaptureLogFile
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

$script:LanrenComponentName = Split-Path -Leaf $PSScriptRoot
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "powershell-7" }

function Get-LanrenAiRoot {
    $envRoot = $env:LRAI_MASTER_OUTPUT_DIR
    if (-not [string]::IsNullOrWhiteSpace($envRoot)) {
        return $envRoot
    }

    $cwd = (Get-Location).Path
    return (Join-Path $cwd "lanren-cache")
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

$powershellLtsVersion = "7.4.13.0"

$null = $FromOfficial

$lines = @()
$lines += ""
$lines += "=== Installing PowerShell 7 (LTS) ==="
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

$installSucceeded = $false

function Test-ToolOnPath {
    param(
        [string]$CommandName
    )


    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

try {
    if ((Test-ToolOnPath -CommandName "pwsh") -and -not $Force) {
        $lines += "PowerShell 7 (pwsh) is already available on PATH. Use -Force to reinstall."
        $lines += "No installation performed."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        $installSucceeded = $true
    } else {
        if ($Proxy) {
            $env:HTTP_PROXY = $Proxy
            $env:HTTPS_PROXY = $Proxy
            $lines += "Using proxy for winget/network: $Proxy"
        }

        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            $wingetArgs = @(
                "install",
                "-e",
                "--id","Microsoft.PowerShell",
                "--version",$powershellLtsVersion
            )
            if ($AcceptDefaults) {
                $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
            }

            $lines += "Target LTS version: $powershellLtsVersion"
            $lines += "Running: winget $($wingetArgs -join ' ')"
            & winget @wingetArgs
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                if (Test-ToolOnPath -CommandName "pwsh") {
                    $lines += "PowerShell 7 (LTS) is available on PATH after winget completed."
                } else {
                    $lines += "winget completed; if an installer window opened, wait for it to finish installing PowerShell 7 (LTS)."
                }
                $installSucceeded = $true
            } else {
                $lines += "winget install for PowerShell 7 (LTS) did not complete successfully (exit code $exitCode)."
            }
        } else {
            $lines += "winget is not available; cannot perform automatic PowerShell 7 installation."
        }
    }

    $lines += ""
    $lines += "Manual installation guidance (official sources):"
    $lines += "- Microsoft docs: https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows"
    $lines += "- GitHub releases: https://github.com/PowerShell/PowerShell/releases"
    $lines += ""
    $lines += "Download the appropriate MSI or ZIP for your platform and install it."
} catch {
    $lines += "Error installing PowerShell 7: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
if ($installSucceeded) {
    Exit-WithWait 0
} else {
    Exit-WithWait 1
}
