<#
.SYNOPSIS
Installs the OpenAI Codex CLI.

.DESCRIPTION
Installs `@openai/codex` globally via npm, preferring a China npm mirror by
default and falling back to the official registry when needed.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for npm network access.

.PARAMETER AcceptDefaults
When specified, runs non-interactively and accepts sensible defaults. This
script itself does not prompt.

.PARAMETER FromOfficial
When specified, forces use of the official npm registry instead of mirrors.

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

$null = $AcceptDefaults

$lines = @()
$lines += ""
$lines += "=== Installing OpenAI Codex CLI ==="
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

function Test-ToolOnPath {
    param(
        [string]$CommandName
    )
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

try {
    if (-not (Test-ToolOnPath -CommandName "node")) {
        $lines += "Error: Node.js is not available on PATH."
        $lines += "Install Node.js first (see components/nodejs/install-comp)."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    if (-not (Test-ToolOnPath -CommandName "npm")) {
        $lines += "Error: npm is not available on PATH."
        $lines += "Reinstall Node.js with npm support and try again."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    # Check if package is already installed globally
    $packageName = "@openai/codex"
    $isInstalled = $false
    try {
        $npmList = npm list -g $packageName --depth=0 2>$null
        if ($npmList -match $packageName) {
            $isInstalled = $true
        }
    } catch {
        $lines += "Warning: Failed to query npm for existing Codex CLI: $($_.Exception.Message)"
    }

    if ($isInstalled -and -not $Force) {
        $lines += "Package $packageName is already installed globally. Use -Force to reinstall."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
    }

    $packageName = "@openai/codex"
    $primaryRegistry = "https://registry.npmmirror.com"
    $officialRegistry = "https://registry.npmjs.org"

    if ($FromOfficial) {
        $registryToUse = $officialRegistry
        $lines += "Using official npm registry: $registryToUse"
    } else {
        $registryToUse = $primaryRegistry
        $lines += "Using China npm mirror: $registryToUse"
        $lines += "Will fall back to official registry if the mirror fails."
    }

    $installArgs = @("install","-g",$packageName,"--registry",$registryToUse)
    $lines += "Running: npm $($installArgs -join ' ')"
    & npm @installArgs
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $FromOfficial) {
        $lines += "npm install via mirror failed (exit code $exitCode)."
        $lines += "Retrying against official registry: $officialRegistry"
        $installArgs = @("install","-g",$packageName,"--registry",$officialRegistry)
        & npm @installArgs
        $exitCode = $LASTEXITCODE
    }

    if ($exitCode -ne 0) {
        $lines += "Error: npm failed to install $packageName (exit code $exitCode)."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
    }

    $lines += "Codex CLI installed successfully."
} catch {
    $lines += "Error installing Codex CLI: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 0
