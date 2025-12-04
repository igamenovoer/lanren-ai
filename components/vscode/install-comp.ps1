<#
.SYNOPSIS
Installs Visual Studio Code on Windows.

.DESCRIPTION
Prefers installation via winget and attempts to enable Explorer context menu
entries by using an installer override when possible. If winget is unavailable
or fails, instructs the user on manual installation from official or China CDN
sources.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers the official VS Code download site (`code.visualstudio.com`)
over China CDNs in guidance.

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
$lines += "=== Installing Visual Studio Code ==="
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

try {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd -and -not $Force) {
        $lines += "Visual Studio Code is already available on PATH (code command found). Use -Force to reinstall."
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
            $lines += "Explorer context menus and PATH should be enabled via installer override."
            Write-OutputLine -Content $lines -LogFile $CaptureLogFile
            exit 0
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
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 1
