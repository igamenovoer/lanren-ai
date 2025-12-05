<#
.SYNOPSIS
Installs the Visual Studio Code application on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails,
instructs the user on manual installation from official or China CDN
sources. This script is responsible only for installing the VS Code
application; context menu and extension setup are handled by separate
scripts and orchestrated by `install-comp.ps1`.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers the official VS Code download site
(`code.visualstudio.com`) over China CDNs in guidance.

.PARAMETER Force
When specified, reinstalls VS Code even if the `code` CLI is already
available on PATH.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using
the console default encoding so a .bat wrapper can print it.

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
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "vscode" }

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
$lines += "=== Installing Visual Studio Code (app) ==="
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
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd -and -not $Force) {
        $lines += "Visual Studio Code is already available on PATH (code command found). Use -Force to reinstall."
        $lines += "No installation performed by install-vscode-app.ps1."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for winget/network: $Proxy"
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $wingetArgs = @(
            "install",
            "--id","Microsoft.VisualStudioCode"
        )

        if ($AcceptDefaults) {
            $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
        }

        $override = '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
        $wingetArgs += @("--override",$override)

        $lines += "Running: winget $($wingetArgs -join ' ')"
        & winget @wingetArgs
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            $lines += "VS Code installed successfully via winget."
            $lines += "Installer override requested Explorer context menus and PATH integration."
            Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        }

        $lines += "winget install for VS Code did not complete successfully (exit code $exitCode)."
    } else {
        $lines += "winget is not available; cannot perform automatic VS Code installation."
    }

    $lines += ""
    $lines += "Manual installation guidance:"
    if (-not $FromOfficial) {
        $lines += "- China CDN (preferred when available): https://vscode.cdn.azure.cn/"
    }
    $lines += "- Official download page: https://code.visualstudio.com/Download"
    $lines += ""
    $lines += "Download the User Setup installer (VSCodeUserSetup-*.exe) and run it with, for example:"
    $lines += '  .\VSCodeUserSetup-*.exe /VERYSILENT /NORESTART /MERGETASKS="addcontextmenufiles,addcontextmenufolders,addtopath"'
} catch {
    $lines += "Error installing Visual Studio Code: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
Exit-WithWait 1
if ($NoExit) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Exit-WithWait 0
