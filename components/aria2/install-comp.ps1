<#
.SYNOPSIS
Installs aria2 (command-line download utility) on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, instructs
the user on manual installation options.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official sources. This mainly affects manual guidance
when winget is unavailable.

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
$lines += "=== Installing aria2 (download utility) ==="
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
    if (Ensure-ToolOnPath -CommandName "aria2c") {
        $lines += "aria2 is already available on PATH (aria2c command found)."
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
        $args = @("install","-e","--id","aria2.aria2")
        if ($AcceptDefaults) {
            $args += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($args -join ' ')"
        & winget @args
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Ensure-ToolOnPath -CommandName "aria2c")) {
            $lines += "aria2 installed successfully via winget."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            exit 0
        }

        $lines += "winget install did not complete successfully (exit code $exitCode)."
    } else {
        $lines += "winget is not available; cannot perform automatic aria2 installation."
    }

    $lines += ""
    $lines += "Manual installation guidance:"
    $lines += "- Official GitHub releases: https://github.com/aria2/aria2/releases"
    $lines += ""
    $lines += "1. Download the latest 'win-64bit' zip file (e.g., aria2-*-win-64bit-build1.zip)."
    $lines += "2. Extract the zip file to a permanent location (e.g., C:\Tools\aria2)."
    $lines += "3. Add that directory to your User or System PATH environment variable."
    $lines += "4. Restart your terminal."
} catch {
    $lines += "Error installing aria2: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 1
