<#
.SYNOPSIS
Installs uv (Astral) on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, falls back
to the official uv install script.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, forces use of official uv URLs. For uv this is already the
default.

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
$lines += "=== Installing uv (Astral) ==="
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
    if (Ensure-ToolOnPath -CommandName "uv") {
        $lines += "uv is already available on PATH."
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
    $installed = $false

    if ($wingetCmd) {
        $args = @("install","-e","--id","astral-sh.uv")
        if ($AcceptDefaults) {
            $args += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($args -join ' ')"
        & winget @args
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Ensure-ToolOnPath -CommandName "uv")) {
            $lines += "uv installed successfully via winget."
            $installed = $true
        } else {
            $lines += "winget install for uv did not complete successfully (exit code $exitCode)."
        }
    } else {
        $lines += "winget is not available; attempting official uv install script."
    }

    if (-not $installed) {
        if ($Proxy) {
            $env:HTTP_PROXY = $Proxy
            $env:HTTPS_PROXY = $Proxy
        }

        $lines += "Running official uv installer script from https://astral.sh/uv/install.ps1 ..."
        $installCommand = 'irm https://astral.sh/uv/install.ps1 | iex'
        powershell -NoProfile -ExecutionPolicy Bypass -Command $installCommand

        if ($LASTEXITCODE -ne 0 -or -not (Ensure-ToolOnPath -CommandName "uv")) {
            $lines += "Error: uv install script did not succeed (exit code $LASTEXITCODE)."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            exit 1
        }

        $lines += "uv installed successfully via official install script."
    }
} catch {
    $lines += "Error installing uv: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0

