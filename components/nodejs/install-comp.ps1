<#
.SYNOPSIS
Installs Node.js (LTS preferred) on Windows.

.DESCRIPTION
Prefers installation via winget (`OpenJS.NodeJS.LTS`, then `OpenJS.NodeJS`).
If winget is unavailable or fails, instructs the user on manual installation
options, including China mirrors.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official Node.js download sites in guidance.

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

$lines = @()
$lines += ""
$lines += "=== Installing Node.js (LTS) ==="
$lines += ""

function Write-OutputLine {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        $Content | ForEach-Object { Write-Output $_ }
    }
}

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
        exit 0
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for winget/network: $Proxy"
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $ids = @("OpenJS.NodeJS.LTS","OpenJS.NodeJS")
        foreach ($id in $ids) {
            $wingetArgs = @("install","-e","--id",$id)
            if ($AcceptDefaults) {
                $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
            }

            $lines += "Running: winget $($wingetArgs -join ' ')"
            & winget @wingetArgs
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0 -and (Test-ToolOnPath -CommandName "node")) {
                $lines += "Node.js installed successfully via winget (id=$id)."
                Write-OutputLine -Content $lines -LogFile $CaptureLogFile
                exit 0
            }

            $lines += "winget install (id=$id) did not complete successfully (exit code $exitCode)."
        }
    } else {
        $lines += "winget is not available; cannot perform automatic Node.js installation."
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
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 1
