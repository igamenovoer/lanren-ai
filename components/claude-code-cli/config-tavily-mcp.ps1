<#
.SYNOPSIS
Installs the Tavily MCP server and configures it for Claude Code CLI (user scope).

.DESCRIPTION
Performs three main steps for the current user:
- Verifies that Node.js, npm, and the Claude Code CLI (`claude`) are available.
- Installs the Tavily MCP server globally via npm (`npm install -g tavily-mcp`).
- Adds/updates a `tavily` MCP server in the Claude Code user scope with the
  provided Tavily API key.

The MCP server is registered using:

  claude mcp add-json -s user tavily '<jsonConfig>'

Where `<jsonConfig>` is a JSON object similar to:

  {
    "type": "stdio",
    "command": "tavily-mcp",
    "args": [],
    "env": { "TAVILY_API_KEY": "..." }
  }

.PARAMETER ApiKey
Optional Tavily API key to use non-interactively. If omitted, the script will
prompt the user. When an environment variable TAVILY_API_KEY is present, the
prompt allows reusing it by pressing Enter.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting. This is
useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [string]$ApiKey
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

function Write-Info {
    param([string]$Message)
    Write-Host "[config-tavily-mcp] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[config-tavily-mcp] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[config-tavily-mcp] ERROR: $Message" -ForegroundColor Red
}

Write-Host "=== Configure Tavily MCP for Claude Code (user scope) ==="
Write-Host ""

try {
    Write-Info "Checking Node.js..."
    try {
        $nodeVersion = node --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $nodeVersion) {
            Write-Info "Node.js found: $nodeVersion"
        } else {
            throw "Node.js command failed."
        }
    } catch {
        Write-Err "Node.js is not available on PATH."
        Write-Host "Install Node.js first, then re-run this script."
        Write-Host "Examples:"
        Write-Host "  - nvm-windows: https://github.com/coreybutler/nvm-windows"
        Write-Host "  - Official:   https://nodejs.org/"
        Exit-WithWait 1
    }

    Write-Info "Checking npm..."
    try {
        $npmVersion = npm --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $npmVersion) {
            Write-Info "npm found: v$npmVersion"
        } else {
            throw "npm command failed."
        }
    } catch {
        Write-Err "npm is not available on PATH."
        Write-Host "npm should be installed together with Node.js."
        Write-Host "Reinstall Node.js and then re-run this script."
        Exit-WithWait 1
    }

    Write-Info "Checking Claude Code CLI..."
    try {
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
        if ($claudeCmd) {
            $claudeVersion = claude --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $claudeVersion) {
                Write-Info "Claude Code CLI found: $claudeVersion"
            } else {
                Write-Info "Claude Code CLI found."
            }
        } else {
            throw "Claude Code CLI not found."
        }
    } catch {
        Write-Err "Claude Code CLI ('claude') is not on PATH."
        Write-Host "Install it first, for example via the claude-code-cli component installer."
        Exit-WithWait 1
    }

    if (-not $ApiKey) {
        $envKey = $env:TAVILY_API_KEY
        Write-Host ""
        Write-Host "A Tavily API key is required to use the Tavily MCP server."
        Write-Host "You can obtain one at: https://app.tavily.com/home"
        Write-Host ""

        if ($envKey) {
            Write-Info "Detected existing TAVILY_API_KEY in environment."
            $inputKey = Read-Host "Enter Tavily API key (press Enter to reuse the existing env value)"
            if ([string]::IsNullOrWhiteSpace($inputKey)) {
                $ApiKey = $envKey
            } else {
                $ApiKey = $inputKey
            }
        } else {
            $ApiKey = Read-Host "Enter Tavily API key"
        }
    }

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-Err "Tavily API key cannot be empty."
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Info "Installing Tavily MCP server globally via npm..."

    $packageName = "tavily-mcp"
    $installArgs = @("install", "-g", $packageName)
    Write-Info "Running: npm $($installArgs -join ' ')"

    & npm @installArgs
    $installExit = $LASTEXITCODE
    if ($installExit -ne 0) {
        Write-Err "npm failed to install $packageName (exit code $installExit)."
        Exit-WithWait 1
    }

    $tavilyCmd = Get-Command "tavily-mcp" -ErrorAction SilentlyContinue
    if ($tavilyCmd) {
        Write-Info "tavily-mcp command is available on PATH: $($tavilyCmd.Source)"
    } else {
        Write-Warn "tavily-mcp command not found on PATH after global install."
        Write-Warn "Claude Code may not be able to start the MCP server unless your global npm bin directory is on PATH."
    }

    $scope = "user"
    $mcpName = "tavily"

    Write-Host ""
    Write-Info "Configuring Tavily MCP server in Claude Code (scope=$scope, name=$mcpName)..."

    # On Windows PowerShell 5.x, avoid claude mcp add-json because JSON
    # arguments are hard to pass correctly. Instead, persist the API key
    # as a user environment variable and use `claude mcp add`.
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Info "Detected Windows PowerShell $($PSVersionTable.PSVersion); using user env var + 'claude mcp add'."

        try {
            [Environment]::SetEnvironmentVariable("TAVILY_API_KEY", $ApiKey, "User")
            $env:TAVILY_API_KEY = $ApiKey
            Write-Info "Set user environment variable TAVILY_API_KEY."
        } catch {
            Write-Err "Failed to set user environment variable TAVILY_API_KEY: $($_.Exception.Message)"
            Exit-WithWait 1
        }

        Write-Info "Removing existing '$mcpName' server in scope 'local' (if any)..."
        try {
            claude mcp remove $mcpName 2>$null
        } catch {
            # ignore errors; server might not exist
        }

        $envArg = "TAVILY_API_KEY=$ApiKey"
        Write-Info "Adding '$mcpName' server in local scope via 'claude mcp add'..."
        & claude mcp add -t stdio -e $envArg $mcpName "tavily-mcp"
        $addExit = $LASTEXITCODE
        if ($addExit -ne 0) {
            Write-Err "Failed to add Tavily MCP server (exit code $addExit)."
            Exit-WithWait 1
        }

        Write-Host ""
        Write-Host "Tavily MCP server has been configured for Claude Code (scope=user, name=$mcpName)." -ForegroundColor Green
        Write-Host "You can verify it with: claude mcp list"
        Write-Host ""

        Exit-WithWait 0
    }

    # PowerShell 7+ path: safe to use JSON-based configuration
    $configObject = @{
        type    = "stdio"
        command = "tavily-mcp"
        args    = @()
        env     = @{ TAVILY_API_KEY = $ApiKey }
    }

    $jsonConfig = $configObject | ConvertTo-Json -Compress

    Write-Info "Removing existing '$mcpName' server in scope '$scope' (if any)..."
    try {
        claude mcp remove -s $scope $mcpName 2>$null
    } catch {
        # ignore errors; server might not exist
    }

    Write-Info "Adding '$mcpName' server in scope '$scope' via 'claude mcp add-json'..."
    & claude mcp add-json -s $scope $mcpName $jsonConfig
    $addExit = $LASTEXITCODE
    if ($addExit -ne 0) {
        Write-Err "Failed to add Tavily MCP server (exit code $addExit)."
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Host "Tavily MCP server has been configured for Claude Code (scope=user, name=$mcpName)." -ForegroundColor Green
    Write-Host "You can verify it with: claude mcp list"
    Write-Host ""

    Exit-WithWait 0
}
catch {
    Write-Err "config-tavily-mcp.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
