<#
.SYNOPSIS
Installs the Claude Code CLI and configures it to skip onboarding.

.DESCRIPTION
Installs `@anthropic-ai/claude-code` globally via npm, preferring a China
mirror by default and falling back to the official npm registry when needed.
After installation, updates %USERPROFILE%\.claude.json so that the CLI does
not show the onboarding/login flow on first run.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL used for npm network traffic.

.PARAMETER AcceptDefaults
When specified, runs non-interactively and accepts sensible defaults. This
script itself does not prompt.

.PARAMETER FromOfficial
When specified, forces use of the official npm registry instead of China
mirrors.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using the
console default encoding so a .bat wrapper can print it.

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

$null = $AcceptDefaults

$lines = @()
$lines += ""
$lines += "=== Installing Claude Code CLI ==="
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
        Exit-WithWait 1
    }

    if (-not (Test-ToolOnPath -CommandName "npm")) {
        $lines += "Error: npm is not available on PATH."
        $lines += "Reinstall Node.js with npm support and try again."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        Exit-WithWait 1
    }

    if ((Test-ToolOnPath -CommandName "claude") -and -not $Force) {
        $lines += "Claude Code CLI is already available on PATH. Use -Force to reinstall."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
    }

    $packageName = "@anthropic-ai/claude-code"
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
        Exit-WithWait 1
    }

    if (-not (Test-ToolOnPath -CommandName "claude")) {
        $lines += "Warning: 'claude' command not found on PATH after installation."
        $lines += "Verify your global npm bin directory is on PATH."
    } else {
        $lines += "Claude Code CLI installed successfully."
        $lines += "claude --version output:"
        $lines += (claude --version 2>$null)
    }

    $lines += ""
    $lines += "Configuring Claude Code to skip onboarding..."

    $configFile = Join-Path $env:USERPROFILE ".claude.json"
    $config = @{}

    if (Test-Path $configFile) {
        try {
            $configContent = Get-Content $configFile -Raw -ErrorAction Stop
            if ($configContent.Trim().Length -gt 0) {
                $config = $configContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                $lines += "Existing configuration loaded from $configFile"
            } else {
                $lines += "Existing configuration file is empty; starting fresh."
            }
        } catch {
            $lines += "Existing configuration is invalid JSON; starting fresh."
            $config = @{}
        }
    } else {
        $lines += "No existing configuration found; creating a new one."
    }

    $config.hasCompletedOnboarding = $true

    $json = $config | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configFile, $json, $utf8NoBom)

    $lines += "Updated configuration file: $configFile"
    $lines += "Claude Code onboarding/login should now be skipped on this host."
} catch {
    $lines += "Error installing or configuring Claude Code CLI: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
Exit-WithWait 0
