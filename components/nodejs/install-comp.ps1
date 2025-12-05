<#
.SYNOPSIS
Installs Node.js LTS on Windows.

.DESCRIPTION
Installs Node.js via winget using the LTS channel
(`OpenJS.NodeJS.LTS`). If winget is unavailable or the LTS package
cannot be installed, instructs the user on manual installation options,
including China mirrors.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official Node.js download sites in guidance.

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
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "nodejs" }

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
$lines += "=== Installing Node.js (LTS) ==="
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
    if ((Test-ToolOnPath -CommandName "node") -and -not $Force) {
        $lines += "Node.js is already available on PATH (node command found). Use -Force to reinstall."
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
            $nodeLtsId = "OpenJS.NodeJS.LTS"
            $wingetArgs = @("install","-e","--id",$nodeLtsId)
            if ($AcceptDefaults) {
                $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
            }

            $lines += "Running: winget $($wingetArgs -join ' ')"
            & winget @wingetArgs
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0 -and (Test-ToolOnPath -CommandName "node")) {
                $lines += "Node.js (LTS) installed successfully via winget (id=$nodeLtsId)."
                $installSucceeded = $true
            } else {
                $lines += "winget install for Node.js (LTS) did not complete successfully (exit code $exitCode)."
            }
        } else {
            $lines += "winget is not available; cannot perform automatic Node.js installation."
        }
    }

    $lines += ""
    $lines += "Manual installation guidance:"
    if (-not $FromOfficial) {
        $lines += "- China mirror for Node.js releases:"
        $lines += "    https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/"
    }
    $lines += "- Official Node.js downloads:"
    $lines += "    https://nodejs.org/en/download"
    $lines += ""
    $lines += "Download an appropriate installer (LTS recommended) and run it."
} catch {
    $lines += "Error installing Node.js: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
if ($installSucceeded) {
    Exit-WithWait 0
} else {
    Exit-WithWait 1
}
