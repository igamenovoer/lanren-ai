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

$script:LanrenComponentName = Split-Path -Leaf $PSScriptRoot
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "markitdown" }

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

$null = $AcceptDefaults

$lines = @()
$lines += ""
$lines += "=== Installing MarkItDown (via uv tool) ==="
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

function Test-ToolOnPath {
    param(
        [string]$CommandName
    )
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

try {
    if (-not (Test-ToolOnPath -CommandName "uv")) {
        $lines += "Error: uv is not available on PATH."
        $lines += "Install uv first (see components/uv/install-comp)."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    if ((Test-ToolOnPath -CommandName "markitdown") -and -not $Force) {
        $lines += "MarkItDown is already available on PATH. Use -Force to reinstall."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
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
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    $lines += "MarkItDown installed successfully via uv tool."
} catch {
    $lines += "Error installing MarkItDown: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 0
