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
#>

[CmdletBinding()]
param(
    [string]$CaptureLogFile
)

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
$lines += "=== Installing Visual Studio Code extensions ==="
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
    if (-not (Test-ToolOnPath -CommandName "code")) {
        $lines += "VS Code CLI 'code' not found on PATH. Skipping extension installation."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        exit 1
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
            $lines += "Installing VS Code extension: $ext"
            code --install-extension $ext --force | Out-Null
        } catch {
            $lines += "Failed to install VS Code extension ${ext}: $($_.Exception.Message)"
        }
    }
} catch {
    $lines += "Error installing VS Code extensions: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
exit 0
