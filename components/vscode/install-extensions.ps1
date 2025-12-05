<#
.SYNOPSIS
Installs common Visual Studio Code extensions.

.DESCRIPTION
Uses the VS Code CLI (`code`) to install a curated set of extensions,
including Python, Git tooling, Markdown preview, CSV/Excel helpers,
and coding agents (OpenAI Codex, Claude Code, and Cline).

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

function Write-OutputLine {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    # Always write to console for visibility
    $Content | ForEach-Object { Write-Host $_ }

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
                # Use Append to support streaming logs
                $text | Out-File -FilePath $t -Encoding Default -Append
            }
        }
    }
}

Write-OutputLine -Content ""
Write-OutputLine -Content "=== Installing Visual Studio Code extensions ==="
Write-OutputLine -Content ""

function Test-ToolOnPath {
    param(
        [string]$CommandName
    )

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

try {
    if (-not (Test-ToolOnPath -CommandName "code")) {
        Write-OutputLine -Content "VS Code CLI 'code' not found on PATH. Skipping extension installation." -LogFile $CaptureLogFile
        Exit-WithWait 0
    }

    $extensions = @(
        # Python extension
        "ms-python.python",
        # Git extension (GitLens)
        "eamodio.gitlens",
        # Markdown Preview Enhanced
        "shd101wyy.markdown-preview-enhanced",
        # Rainbow CSV
        "mechatroner.rainbow-csv",
        # Excel Viewer
        "GrapeCity.gc-excelviewer",
        # OpenAI Codex (Codex - OpenAI's coding agent)
        "openai.chatgpt",
        # Claude Code
        "anthropic.claude-code",
        # Cline
        "saoudrizwan.claude-dev"
    )

    foreach ($ext in $extensions) {
        try {
            Write-OutputLine -Content "Installing VS Code extension: $ext" -LogFile $CaptureLogFile
            # Capture output to show progress
            $output = code --install-extension $ext --force 2>&1
            if ($output) {
                $outStr = $output | Out-String -Stream
                Write-OutputLine -Content $outStr -LogFile $CaptureLogFile
            }
        } catch {
            Write-OutputLine -Content "Failed to install VS Code extension ${ext}: $($_.Exception.Message)" -LogFile $CaptureLogFile
        }
    }
} catch {
    Write-OutputLine -Content "Error installing VS Code extensions: $($_.Exception.Message)" -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Exit-WithWait 0
