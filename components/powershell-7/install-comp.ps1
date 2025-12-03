<#
.SYNOPSIS
Installs PowerShell 7 on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, instructs
the user on manual installation from official sources.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, prefers official PowerShell download sites in guidance.

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
$lines += "=== Installing PowerShell 7 ==="
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
    if (Ensure-ToolOnPath -CommandName "pwsh") {
        $lines += "PowerShell 7 (pwsh) is already available on PATH."
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
        $args = @("install","-e","--id","Microsoft.PowerShell")
        if ($AcceptDefaults) {
            $args += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($args -join ' ')"
        & winget @args
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Ensure-ToolOnPath -CommandName "pwsh")) {
            $lines += "PowerShell 7 installed successfully via winget."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            exit 0
        }

        $lines += "winget install for PowerShell 7 did not complete successfully (exit code $exitCode)."
    } else {
        $lines += "winget is not available; cannot perform automatic PowerShell 7 installation."
    }

    $lines += ""
    $lines += "Manual installation guidance (official sources):"
    $lines += "- Microsoft docs: https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows"
    $lines += "- GitHub releases: https://github.com/PowerShell/PowerShell/releases"
    $lines += ""
    $lines += "Download the appropriate MSI or ZIP for your platform and install it."
} catch {
    $lines += "Error installing PowerShell 7: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 1

