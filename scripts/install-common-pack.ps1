param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function New-LogFile {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logDir = Join-Path $scriptDir "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Join-Path $logDir "install-common-pack_$timestamp.log"
}

$Global:LogFile = New-LogFile

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $Global:LogFile -Value $line
}

function Test-IsAdmin {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Log "Script is not running with administrative privileges. Some installations may fail." "WARN"
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    $null -ne $cmd
}

function Invoke-WinGetInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [string]$DisplayName
    )

    if (-not (Test-CommandExists -Name "winget")) {
        Write-Log "winget is not available. Install the Windows App Installer and try again." "ERROR"
        return $false
    }

    $name = if ($DisplayName) { $DisplayName } else { $Id }
    Write-Log "Installing $name via winget ($Id)..." "INFO"

    $arguments = @(
        "install",
        "--id", $Id,
        "-e",
        "--accept-source-agreements",
        "--accept-package-agreements"
    )

    $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        Write-Log "winget install for $name exited with code $($process.ExitCode)." "WARN"
        return $false
    }

    Write-Log "$name installation command completed." "INFO"
    return $true
}

function Ensure-Confirmation {
    param(
        [string]$Message
    )

    if ($NonInteractive) {
        return $true
    }

    Write-Host ""
    $answer = Read-Host "$Message (Y/N)"
    if ($answer -match "^[Yy]") {
        return $true
    }

    Write-Log "User chose not to continue: $Message" "WARN"
    return $false
}

function Install-VisualStudioCode {
    Write-Log "Installing Visual Studio Code..." "INFO"
    Invoke-WinGetInstall -Id "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code" | Out-Null
}

function Install-VSCodeExtensions {
    $extensions = @(
        "saoudrizwan.claude-dev",
        "kilocode.Kilo-Code",
        "openai.chatgpt",
        "anthropic.claude-code",
        "ms-python.python",
        "shd101wyy.markdown-preview-enhanced"
    )

    if (-not (Test-CommandExists -Name "code")) {
        Write-Log "VSCode CLI 'code' not found on PATH. Skipping extension installation." "WARN"
        return
    }

    Write-Log "Installing VSCode extensions from common pack..." "INFO"

    foreach ($ext in $extensions) {
        try {
            Write-Log "Installing VSCode extension $ext..." "INFO"
            code --install-extension $ext --force | Out-Null
        } catch {
            Write-Log "Failed to install VSCode extension $ext: $($_.Exception.Message)" "WARN"
        }
    }
}

function Install-ClaudeCodeCLI {
    Write-Log "Installing Claude Code CLI..." "INFO"
    Invoke-WinGetInstall -Id "Anthropic.ClaudeCode" -DisplayName "Claude Code CLI" | Out-Null
}

function Install-NodeJS {
    Write-Log "Installing Node.js LTS..." "INFO"
    $result = Invoke-WinGetInstall -Id "OpenJS.NodeJS.LTS" -DisplayName "Node.js LTS"

    if (-not $result) {
        Write-Log "Attempting fallback Node.js package..." "INFO"
        Invoke-WinGetInstall -Id "OpenJS.NodeJS" -DisplayName "Node.js" | Out-Null
    }
}

function Install-CodexCLI {
    if (-not (Test-CommandExists -Name "npm")) {
        Write-Log "npm is not available. Skipping Codex CLI installation. Install Node.js and npm first." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "Codex CLI is experimental on Windows and works best in WSL. Attempt installation with 'npm i -g @openai/codex'?")) {
        return
    }

    Write-Log "Installing Codex CLI via npm..." "INFO"
    try {
        npm install -g @openai/codex
        Write-Log "Codex CLI installation command completed." "INFO"
    } catch {
        Write-Log "Codex CLI installation failed: $($_.Exception.Message)" "WARN"
    }
}

function Install-Uv {
    if (-not (Ensure-Confirmation -Message "Install uv (Python package and environment manager) using remote script from astral.sh?")) {
        return
    }

    Write-Log "Installing uv via remote PowerShell script..." "INFO"
    try {
        irm https://astral.sh/uv/install.ps1 | iex
        Write-Log "uv installation command completed." "INFO"
    } catch {
        Write-Log "uv installation failed: $($_.Exception.Message)" "WARN"
    }
}

function Install-Pixi {
    Write-Log "Installing pixi..." "INFO"
    Invoke-WinGetInstall -Id "prefix-dev.pixi" -DisplayName "pixi" | Out-Null
}

function Install-Jq {
    Write-Log "Installing jq..." "INFO"
    Invoke-WinGetInstall -Id "jqlang.jq" -DisplayName "jq" | Out-Null
}

function Install-Yq {
    Write-Log "Installing yq..." "INFO"
    Invoke-WinGetInstall -Id "MikeFarah.yq" -DisplayName "yq" | Out-Null
}

function Install-Pandoc {
    Write-Log "Installing pandoc..." "INFO"
    $result = Invoke-WinGetInstall -Id "JohnMacFarlane.Pandoc" -DisplayName "pandoc"

    if (-not $result) {
        Invoke-WinGetInstall -Id "pandoc" -DisplayName "pandoc (generic id)" | Out-Null
    }
}

function Install-Markitdown {
    if (-not (Test-CommandExists -Name "uv")) {
        Write-Log "uv is not available. Skipping markitdown setup. Install uv first." "WARN"
        return
    }

    Write-Log "Preparing markitdown via uv tool run..." "INFO"
    try {
        uv tool run markitdown-mcp -- --help | Out-Null
        Write-Log "markitdown tool invocation completed." "INFO"
    } catch {
        Write-Log "markitdown tool invocation failed: $($_.Exception.Message)" "WARN"
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "This script will attempt to install the following tools from the Common AI Development Tools pack:"
    Write-Host " - Visual Studio Code"
    Write-Host " - VSCode extensions: Cline, Kilo Code, Codex, Claude Code, Python, Markdown Preview Enhanced"
    Write-Host " - Claude Code CLI"
    Write-Host " - Node.js (and npm)"
    Write-Host " - Codex CLI (via npm, experimental on Windows)"
    Write-Host " - uv (Python package and environment manager)"
    Write-Host " - pixi (cross-platform package manager)"
    Write-Host " - jq (JSON processor)"
    Write-Host " - yq (YAML processor)"
    Write-Host " - pandoc (document converter)"
    Write-Host " - markitdown (via uv tool run)"
    Write-Host ""
}

Show-Summary

if (-not (Ensure-Confirmation -Message "Proceed with installation of the Common AI Development Tools pack")) {
    Write-Log "User cancelled pack installation." "WARN"
    exit 0
}

Write-Log "Starting Common AI Development Tools pack installation." "INFO"

try {
    Install-VisualStudioCode
    Install-VSCodeExtensions
    Install-ClaudeCodeCLI
    Install-NodeJS
    Install-CodexCLI
    Install-Uv
    Install-Pixi
    Install-Jq
    Install-Yq
    Install-Pandoc
    Install-Markitdown
} catch {
    Write-Log "Unexpected error during installation: $($_.Exception.Message)" "ERROR"
}

Write-Log "Common AI Development Tools pack installation script completed." "INFO"

