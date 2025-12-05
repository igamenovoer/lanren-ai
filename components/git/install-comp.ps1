<#
.SYNOPSIS
Installs Git for Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, instructs
the user on manual installation options (including China mirrors).

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official Git for Windows sources. This mainly affects
manual guidance when winget is unavailable.

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
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "git" }

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

$lines = @()
$lines += ""
$lines += "=== Installing Git for Windows ==="
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
    if ((Test-ToolOnPath -CommandName "git") -and -not $Force) {
        $lines += "Git is already available on PATH (git command found). Use -Force to reinstall."
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
            $wingetArgs = @("install","-e","--id","Git.Git")
            if ($AcceptDefaults) {
                $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
            }

            $lines += "Running: winget $($wingetArgs -join ' ')"
            & winget @wingetArgs
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0 -and (Test-ToolOnPath -CommandName "git")) {
                $lines += "Git installed successfully via winget."
                $installSucceeded = $true
            } else {
                $lines += "winget install did not complete successfully (exit code $exitCode)."
            }
        } else {
            $lines += "winget is not available; cannot perform automatic Git installation."
        }
    }

    $lines += ""
    $lines += "Manual installation guidance:"
    if (-not $FromOfficial) {
        $lines += "- China mirrors (use these first if accessible):"
        $lines += "    Tsinghua mirror: https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/"
        $lines += "    npmmirror:       https://npmmirror.com/mirrors/git-for-windows/"
    }
    $lines += "- Official Git for Windows site: https://gitforwindows.org/"
    $lines += ""
    $lines += "Download the appropriate installer (.exe) and run it, for example:"
    $lines += "    .\\Git-*-64-bit.exe /VERYSILENT /NORESTART"
} catch {
    $lines += "Error installing Git: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
if ($installSucceeded) {
    Exit-WithWait 0
} else {
    Exit-WithWait 1
}
