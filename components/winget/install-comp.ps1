<#
.SYNOPSIS
Ensures the Windows Package Manager (winget) is available.

.DESCRIPTION
Checks for the `winget` command and, if missing, downloads and installs the
App Installer package. It attempts to download from a China-friendly mirror
(GitHub Proxy) first, and falls back to the official Microsoft source
(https://aka.ms/getwinget) if that fails.

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
    [switch]$Force,
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
    if ($wingetCmd -and -not $Force) {
        $lines += "winget is already available on this system. Use -Force to reinstall."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    $lines += "winget is not available (or -Force used); attempting to install App Installer."

    $tempDir = [System.IO.Path]::GetTempPath()
    $fileName = "AppInstaller.msixbundle"
    $outFile = Join-Path $tempDir $fileName

    # Try to resolve the latest URL for the mirror
    $latestWingetUrl = $null
    try {
        $lines += "Resolving latest winget version from GitHub API..."
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -UseBasicParsing -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1
        if ($asset) {
            $latestWingetUrl = $asset.browser_download_url
            $lines += "Resolved latest version URL: $latestWingetUrl"
        }
    } catch {
        $lines += "Failed to resolve latest version via GitHub API: $($_.Exception.Message)"
        $lines += "Skipping GitHub Proxy mirror."
    }

    # Define sources: Mirror first (if resolved), then Official
    $sources = @()

    if ($latestWingetUrl) {
        $sources += @{
            Name = "GitHub Proxy (China Mirror)"
            Url  = "https://mirror.ghproxy.com/$latestWingetUrl"
        }
    }

    $sources += @{
        Name = "Microsoft Official (aka.ms)"
        Url  = "https://aka.ms/getwinget"
    }

    $installed = $false

    foreach ($source in $sources) {
        try {
            $lines += "Attempting download from $($source.Name): $($source.Url)"
            
            $invokeParams = @{
                Uri             = $source.Url
                OutFile         = $outFile
                UseBasicParsing = $true
                ErrorAction     = "Stop"
            }
            if ($Proxy) {
                $invokeParams["Proxy"] = $Proxy
                $invokeParams["ProxyUseDefaultCredentials"] = $true
                $lines += "Using proxy: $Proxy"
            }

            Invoke-WebRequest @invokeParams
            
            $lines += "Download complete. Installing App Installer from: $outFile"
            Add-AppxPackage -Path $outFile -ErrorAction Stop
            
            $installed = $true
            break # Success, exit loop
        } catch {
            $lines += "Failed to install from $($source.Name): $($_.Exception.Message)"
            $lines += "Trying next source..."
        }
    }

    if (-not $installed) {
        throw "All installation attempts failed."
    }

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

