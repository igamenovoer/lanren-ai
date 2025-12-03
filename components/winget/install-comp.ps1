<#
.SYNOPSIS
Ensures the Windows Package Manager (winget) is available.

.DESCRIPTION
Checks for the `winget` command and, if missing, downloads and installs the
App Installer package from Microsoft (https://aka.ms/getwinget).

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for downloading App Installer.

.PARAMETER AcceptDefaults
When specified, runs non-interactively and accepts sensible defaults. This
script itself does not prompt.

.PARAMETER FromOfficial
When specified, confirms use of Microsoft's official source. For winget this
is always the case.

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
$lines += "=== Ensuring winget (Windows Package Manager) is available ==="
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

try {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $lines += "winget is already available on this system."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    $lines += "winget is not available; attempting to install App Installer from Microsoft."

    $downloadUrl = "https://aka.ms/getwinget"
    $tempDir = [System.IO.Path]::GetTempPath()
    $fileName = "AppInstaller.msixbundle"
    $outFile = Join-Path $tempDir $fileName

    $lines += "Downloading App Installer from: $downloadUrl"

    $invokeParams = @{
        Uri             = $downloadUrl
        OutFile         = $outFile
        UseBasicParsing = $true
    }
    if ($Proxy) {
        $invokeParams["Proxy"] = $Proxy
        $invokeParams["ProxyUseDefaultCredentials"] = $true
        $lines += "Using proxy: $Proxy"
    }

    Invoke-WebRequest @invokeParams

    $lines += "Download complete. Installing App Installer from: $outFile"
    Add-AppxPackage -Path $outFile

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $lines += "winget is now available."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    $lines += "Installation completed but winget is still not available on PATH."
    $lines += "You may need to log out and log back in, then try again."
} catch {
    $lines += "Error ensuring winget availability: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 1

