<#
.SYNOPSIS
Installs MarkItDown via uv.

.DESCRIPTION
Uses `uv tool install markitdown --with "markitdown[all]"`, preferring a China
PyPI mirror by default and falling back to the official index when needed.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for uv network access.

.PARAMETER AcceptDefaults
When specified, runs non-interactively and accepts sensible defaults. This
script itself does not prompt.

.PARAMETER FromOfficial
When specified, forces use of the official PyPI index instead of China mirrors.

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
$lines += "=== Installing MarkItDown (via uv tool) ==="
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
    if (-not (Ensure-ToolOnPath -CommandName "uv")) {
        $lines += "Error: uv is not available on PATH."
        $lines += "Install uv first (see components/uv/install-comp)."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    if ((Ensure-ToolOnPath -CommandName "markitdown") -and -not $Force) {
        $lines += "MarkItDown is already available on PATH. Use -Force to reinstall."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for uv/network: $Proxy"
    }

    $primaryIndex = "https://pypi.tuna.tsinghua.edu.cn/simple"

    if ($FromOfficial) {
        $lines += "Using official PyPI index (uv default)."
        Remove-Item Env:UV_INDEX_URL -ErrorAction SilentlyContinue
    } else {
        $env:UV_INDEX_URL = $primaryIndex
        $lines += "Using China PyPI mirror via UV_INDEX_URL: $primaryIndex"
        $lines += "Will fall back to official index if the mirror fails."
    }

    $installArgs = @("tool","install","markitdown","--with","markitdown[all]")
    $lines += "Running: uv $($installArgs -join ' ')"
    & uv @installArgs
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $FromOfficial) {
        $lines += "uv tool install via mirror failed (exit code $exitCode)."
        $lines += "Retrying against official PyPI (without UV_INDEX_URL)."
        Remove-Item Env:UV_INDEX_URL -ErrorAction SilentlyContinue
        & uv @installArgs
        $exitCode = $LASTEXITCODE
    }

    if ($exitCode -ne 0) {
        $lines += "Error: uv failed to install MarkItDown (exit code $exitCode)."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    $lines += "MarkItDown installed successfully via uv tool."
} catch {
    $lines += "Error installing MarkItDown: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0

