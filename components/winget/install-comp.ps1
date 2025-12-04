<#
.SYNOPSIS
Ensures the Windows Package Manager (winget) is available.

.DESCRIPTION
Checks for the `winget` command and, if missing, launches a locally cached
App Installer `.msixbundle` so you can install or repair winget manually.
If no local installer is found, it instructs you to download one.

.PARAMETER AcceptDefaults
When specified, signals a non-interactive run. This script itself does not
prompt, but the parameter is kept for consistency with other installers and
future automation.

.PARAMETER Force
When specified, forces a reinstall/repair attempt even if `winget` is already
available.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using the
console default encoding so a .bat wrapper can print it.
#>

[CmdletBinding()]
param(
    [switch]$AcceptDefaults,
    [switch]$Force,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"
$script:lastPrintedLine = 0

$lines = @()
$lines += ""
$lines += "=== Ensuring winget (Windows Package Manager) is available ==="
$lines += ""

function Write-OutputLine {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        if ($script:lastPrintedLine -lt $Content.Count) {
            for ($i = $script:lastPrintedLine; $i -lt $Content.Count; $i++) {
                Write-Output $Content[$i]
            }
            $script:lastPrintedLine = $Content.Count
        }
    }
}

function Start-AppInstallerAndWait {
    <#
    .SYNOPSIS
    Launches an msixbundle file and waits for the App Installer GUI to close.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$FilePath,
        [switch]$AcceptDefaults
    )

    $null = $AcceptDefaults

    if (-not $PSCmdlet.ShouldProcess($FilePath, "Run App Installer for winget")) {
        return
    }
    
    # Launch the installer - this opens App Installer GUI
    Start-Process -FilePath $FilePath
    
    # Give App Installer time to start
    Start-Sleep -Seconds 2
    
    # Wait for App Installer process to appear and then disappear
    # First, wait for it to start
    $appInstallerProc = $null
    for ($i = 0; $i -lt 60; $i++) {
        $appInstallerProc = Get-Process -Name "AppInstaller" -ErrorAction SilentlyContinue
        if ($appInstallerProc) { break }
        Start-Sleep -Milliseconds 500
    }
    
    # If we found the process, wait for it to exit
    if ($appInstallerProc) {
        $appInstallerProc | Wait-Process
    }
    
    # Give a moment for winget to register in PATH
    Start-Sleep -Seconds 1
}

try {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd -and -not $Force) {
        $lines += "winget is already available on this system. Use -Force to reinstall."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    $lines += "winget is not available (or -Force used); attempting to install App Installer."

    $cacheDir = Join-Path (Get-Location) ".pkgs-cache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $fileName = "AppInstaller.msixbundle"
    $outFile = Join-Path $cacheDir $fileName

    $installed = $false

    # 0. Check if App Installer is already installed on the system
    $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
    if ($appInstaller) {
        $appInstallerPath = Join-Path $appInstaller.InstallLocation "AppInstaller.exe"
        if (Test-Path $appInstallerPath) {
            $lines += "App Installer is already installed at: $($appInstaller.InstallLocation)"
            $lines += "However, the 'winget' command is not found. Proceeding to repair via re-installation..."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        }
    }

    # 1. Try installing from cache if exists
    $foundFile = $null
    if (Test-Path $outFile) {
        $foundFile = $outFile
    } else {
        # Fallback: look for any msixbundle in the cache directory
        $candidates = Get-ChildItem -Path $cacheDir -Filter "*.msixbundle" -ErrorAction SilentlyContinue
        if ($candidates) {
            $foundFile = $candidates[0].FullName
        }
    }

    if (-not $installed -and $foundFile) {
        $lines += "Found cached installer at: $foundFile"
        $lines += "Launching App Installer GUI... Please complete the installation in the popup window."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        
        # Launch the installer GUI and wait for it to complete
        Start-AppInstallerAndWait -FilePath $foundFile -AcceptDefaults:$AcceptDefaults
        
        # Check if installation succeeded
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            $installed = $true
        } else {
            $lines += "Installation process finished, but winget command is not found."
            $lines += "If you cancelled the installation, you can run this script again."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            exit 1
        }
    }

    # 2. If not installed, warn user (Download logic removed to prefer local file)
    if (-not $installed) {
        $lines += "Winget is not installed and no local installer (.msixbundle) was found in:"
        $lines += "  $cacheDir"
        $lines += "Please manually download the App Installer package and place it there."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 1
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
