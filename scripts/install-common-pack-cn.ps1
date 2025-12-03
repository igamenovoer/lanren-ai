param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function New-LogFile {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $PSCommandPath -ErrorAction SilentlyContinue
    }
    if (-not $scriptDir) {
        $scriptDir = (Get-Location).Path
    }

    $logDir = Join-Path $scriptDir "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Join-Path $logDir "install-common-pack-cn_$timestamp.log"
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

function Ensure-WinGet {
    if (Test-CommandExists -Name "winget") {
        return $true
    }

    if (-not (Ensure-Confirmation -Message "WinGet (App Installer) is not available. Download and install it from Microsoft now?")) {
        Write-Log "User chose not to install winget automatically." "WARN"
        return $false
    }

    Write-Log "Downloading App Installer (winget) from https://aka.ms/getwinget ..." "INFO"

    $tempPath = Join-Path ([IO.Path]::GetTempPath()) "AppInstaller.msixbundle"
    try {
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $tempPath -UseBasicParsing
        Add-AppxPackage -Path $tempPath
    } catch {
        Write-Log "Automatic winget installation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }

    if (Test-CommandExists -Name "winget") {
        Write-Log "winget is now available." "INFO"
        return $true
    }

    Write-Log "winget still not available after attempted installation." "ERROR"
    return $false
}

function Configure-WinGetMirror {
    if (-not (Test-CommandExists -Name "winget")) {
        Write-Log "winget not available; skipping WinGet mirror configuration." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "WinGet is available. Switch WinGet source to USTC mirror (https://mirrors.ustc.edu.cn/winget-source)?")) {
        return
    }

    Write-Log "Switching WinGet source to USTC mirror..." "INFO"
    try {
        winget source remove winget -y 2>$null
    } catch {
        # ignore errors removing existing source
    }

    try {
        winget source add winget https://mirrors.ustc.edu.cn/winget-source --trust-level trusted
        Write-Log "WinGet source configured to USTC mirror." "INFO"
    } catch {
        Write-Log "Failed to configure WinGet mirror: $($_.Exception.Message)" "WARN"
    }
}

function Invoke-WinGetInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [string]$DisplayName
    )

    if (-not (Test-CommandExists -Name "winget")) {
        if (-not (Ensure-WinGet)) {
            Write-Log "winget is not available. Install the Windows App Installer and try again." "ERROR"
            return $false
        }
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

    Write-Log "Installing VSCode extensions from CN common pack..." "INFO"

    foreach ($ext in $extensions) {
        try {
            Write-Log "Installing VSCode extension $ext..." "INFO"
            code --install-extension $ext --force | Out-Null
        } catch {
            Write-Log "Failed to install VSCode extension ${ext}: $($_.Exception.Message)" "WARN"
        }
    }
}

function Install-ClaudeCodeCLI {
    if (-not (Test-CommandExists -Name "npm")) {
        Write-Log "npm is not available. Skipping Claude Code CLI installation. Install Node.js and npm first." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "Install Claude Code CLI via npm (package '@anthropic-ai/claude-code') using the configured China npm mirror?")) {
        return
    }

    Write-Log "Installing Claude Code CLI via npm (package '@anthropic-ai/claude-code')..." "INFO"
    try {
        npm install -g @anthropic-ai/claude-code
        Write-Log "Claude Code CLI installation command completed." "INFO"
    } catch {
        Write-Log "Claude Code CLI installation failed: $($_.Exception.Message)" "WARN"
    }
}

function Install-NodeJS {
    Write-Log "Installing Node.js LTS..." "INFO"
    $result = Invoke-WinGetInstall -Id "OpenJS.NodeJS.LTS" -DisplayName "Node.js LTS"

    if (-not $result) {
        Write-Log "Attempting fallback Node.js package..." "INFO"
        Invoke-WinGetInstall -Id "OpenJS.NodeJS" -DisplayName "Node.js" | Out-Null
    }
}

function Install-Bun {
    Write-Log "Installing Bun JavaScript runtime..." "INFO"
    $result = Invoke-WinGetInstall -Id "Oven-sh.Bun" -DisplayName "Bun"

    if (-not $result) {
        Write-Log "Bun installation via winget failed or was skipped." "WARN"
    }
}

function Install-PowerShell7 {
    if (Test-CommandExists -Name "pwsh") {
        Write-Log "PowerShell 7 (pwsh) already available; skipping installation." "INFO"
        return
    }

    Write-Log "Installing PowerShell 7 (pwsh)..." "INFO"
    $result = Invoke-WinGetInstall -Id "Microsoft.PowerShell" -DisplayName "PowerShell 7"

    if (-not $result) {
        Write-Log "PowerShell 7 installation via winget failed or was skipped." "WARN"
    }
}

function Configure-NpmMirror {
    if (-not (Test-CommandExists -Name "npm")) {
        Write-Log "npm not available; skipping npm mirror configuration." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "npm detected. Switch npm registry to China mirror (https://registry.npmmirror.com/) globally?")) {
        return
    }

    Write-Log "Setting npm registry to https://registry.npmmirror.com/ ..." "INFO"
    try {
        npm config set registry https://registry.npmmirror.com/ --global
        Write-Log "npm registry configured to https://registry.npmmirror.com/." "INFO"
    } catch {
        Write-Log "Failed to configure npm mirror: $($_.Exception.Message)" "WARN"
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

function Install-TavilyMcpWithBun {
    if (-not (Test-CommandExists -Name "bunx")) {
        Write-Log "bunx is not available. Skipping Tavily MCP pre-installation. Install Bun first if you plan to use Tavily MCP locally." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "Pre-install Tavily MCP server package via bunx (tavily-mcp@latest)?")) {
        return
    }

    Write-Log "Pre-installing Tavily MCP via 'bunx tavily-mcp@latest --help'..." "INFO"
    try {
        bunx tavily-mcp@latest --help | Out-Null
        Write-Log "Tavily MCP package is available via bun (cached by bunx)." "INFO"
    } catch {
        Write-Log "Tavily MCP bunx warm-up failed: $($_.Exception.Message)" "WARN"
    }
}

function Install-Context7McpWithBun {
    if (-not (Test-CommandExists -Name "bunx")) {
        Write-Log "bunx is not available. Skipping Context7 MCP pre-installation. Install Bun first if you plan to use Context7 MCP locally." "WARN"
        return
    }

    if (-not (Ensure-Confirmation -Message "Pre-install Context7 MCP server package via bunx (@upstash/context7-mcp@latest)?")) {
        return
    }

    Write-Log "Pre-installing Context7 MCP via 'bunx -y @upstash/context7-mcp@latest --help'..." "INFO"
    try {
        bunx -y @upstash/context7-mcp@latest --help | Out-Null
        Write-Log "Context7 MCP package is available via bun (cached by bunx)." "INFO"
    } catch {
        Write-Log "Context7 MCP bunx warm-up failed: $($_.Exception.Message)" "WARN"
    }
}

function Configure-UvMirror {
    $mirror = "https://pypi.tuna.tsinghua.edu.cn/simple"
    Write-Log "Configuring uv to use Python package mirror: $mirror" "INFO"
    $env:UV_DEFAULT_INDEX = $mirror
}

function Install-Uv {
    if (-not (Ensure-Confirmation -Message "Install uv (Python package and environment manager) using remote script from astral.sh, configured to use a China PyPI mirror?")) {
        return
    }

    Configure-UvMirror

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

    Write-Log "Preparing markitdown via uv tool run (may use configured China PyPI mirror)..." "INFO"
    try {
        uv tool run markitdown-mcp -- --help | Out-Null
        Write-Log "markitdown tool invocation completed." "INFO"
    } catch {
        Write-Log "markitdown tool invocation failed: $($_.Exception.Message)" "WARN"
    }
}

function Invoke-ClaudeSkipLoginHelper {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $PSCommandPath -ErrorAction SilentlyContinue
    }
    if (-not $scriptDir) {
        $scriptDir = (Get-Location).Path
    }

    $repoRoot = Split-Path -Parent $scriptDir
    $helperPath = Join-Path $repoRoot "quick-tools\claude\skip-cc-login.ps1"

    if (-not (Test-Path $helperPath)) {
        Write-Log "Claude skip-login helper script not found at $helperPath. Skipping." "WARN"
        return
    }

    Write-Log "Running Claude skip-login helper script: $helperPath ..." "INFO"
    try {
        & $helperPath
        Write-Log "Claude skip-login helper script completed." "INFO"
    } catch {
        Write-Log "Claude skip-login helper script failed: $($_.Exception.Message)" "WARN"
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "This script will attempt to install the following tools from the Common AI Development Tools pack (CN-optimized):"
    Write-Host " - Visual Studio Code"
    Write-Host " - VSCode extensions: Cline, Kilo Code, Codex, Claude Code, Python, Markdown Preview Enhanced"
    Write-Host " - Claude Code CLI"
    Write-Host " - PowerShell 7 (pwsh)"
    Write-Host " - Node.js (and npm), with optional npm China mirror"
    Write-Host " - Bun JavaScript runtime (via winget), with optional Tavily MCP and Context7 MCP pre-install via bunx"
    Write-Host " - Bun JavaScript runtime (via winget)"
    Write-Host " - Codex CLI (via npm, experimental on Windows)"
    Write-Host " - uv (Python package and environment manager) with China PyPI mirror"
    Write-Host " - pixi (cross-platform package manager)"
    Write-Host " - jq (JSON processor)"
    Write-Host " - yq (YAML processor)"
    Write-Host " - pandoc (document converter)"
    Write-Host " - markitdown (via uv tool run)"
    Write-Host ""
}

Show-Summary

if (-not (Ensure-Confirmation -Message "Proceed with installation of the Common AI Development Tools pack (CN-optimized)?")) {
    Write-Log "User cancelled CN common pack installation." "WARN"
    exit 0
}

Write-Log "Starting Common AI Development Tools pack (CN-optimized) installation." "INFO"

try {
    Ensure-WinGet | Out-Null
    Configure-WinGetMirror

    Install-VisualStudioCode
    Install-VSCodeExtensions
    Install-PowerShell7
    Install-NodeJS
    Install-Bun
    Install-TavilyMcpWithBun
    Install-Context7McpWithBun
    Configure-NpmMirror
    Install-ClaudeCodeCLI
    Install-CodexCLI
    Install-Uv
    Install-Pixi
    Install-Jq
    Install-Yq
    Install-Pandoc
    Install-Markitdown
    Invoke-ClaudeSkipLoginHelper
} catch {
    Write-Log "Unexpected error during CN pack installation: $($_.Exception.Message)" "ERROR"
}

Write-Log "Common AI Development Tools pack (CN-optimized) installation script completed." "INFO"
