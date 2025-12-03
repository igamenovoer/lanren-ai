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
#>

[CmdletBinding()]
param(
    [string]$Proxy,
    [switch]$AcceptDefaults,
    [switch]$FromOfficial,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Installing Git for Windows ==="
$lines += ""

function Write-OutputLines {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        $Content | ForEach-Object { Write-Host $_ }
    }
}

function Ensure-ToolOnPath {
    param(
        [string]$CommandName
    )
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

try {
    if (Ensure-ToolOnPath -CommandName "git") {
        $lines += "Git is already available on PATH (git command found)."
        $lines += "No installation performed."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for winget/network: $Proxy"
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $args = @("install","-e","--id","Git.Git")
        if ($AcceptDefaults) {
            $args += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($args -join ' ')"
        & winget @args
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Ensure-ToolOnPath -CommandName "git")) {
            $lines += "Git installed successfully via winget."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            exit 0
        }

        $lines += "winget install did not complete successfully (exit code $exitCode)."
    } else {
        $lines += "winget is not available; cannot perform automatic Git installation."
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
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 1

