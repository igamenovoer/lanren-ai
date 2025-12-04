<#
.SYNOPSIS
Installs a Context7 MCP server package from npm.

.DESCRIPTION
Installs `@upstash/context7-mcp` globally via npm, preferring a China npm
mirror by default and falling back to the official registry when needed.

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

$script:LanrenComponentName = Split-Path -Leaf $PSScriptRoot
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "context7-mcp" }

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
$lines += "=== Installing Context7 MCP server ==="
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
    $packageName = "@upstash/context7-mcp"
    $isInstalled = $false
    try {
        $npmList = npm list -g $packageName --depth=0 2>$null
        if ($npmList -match $packageName) {
            $isInstalled = $true
        }
    } catch {
        $lines += "Warning: Failed to query npm for existing Context7 MCP server: $($_.Exception.Message)"
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

    $packageName = "@upstash/context7-mcp"
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

    $lines += "Context7 MCP server installed successfully."
} catch {
    $lines += "Error installing Context7 MCP server: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 0
