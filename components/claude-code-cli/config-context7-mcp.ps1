<#
.SYNOPSIS
Installs the Context7 MCP server and configures it for Claude Code CLI (user scope).

.DESCRIPTION
Performs three main steps for the current user:
- Verifies that Node.js, npm, and the Claude Code CLI (`claude`) are available.
- Ensures the Context7 MCP server package (`@upstash/context7-mcp`) is installed via npm.
- Adds/updates a `context7` MCP server in the Claude Code user scope using the free,
  no-API-key mode.

The MCP server is registered purely via the Claude CLI (no direct JSON editing)
with a stdio server named `context7` that runs the `context7-mcp` command:

  claude mcp add -s user context7 context7-mcp

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting. This is
useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit
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
    Write-Host "[config-context7-mcp] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[config-context7-mcp] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[config-context7-mcp] ERROR: $Message" -ForegroundColor Red
}

Write-Host "=== Configure Context7 MCP for Claude Code (user scope) ==="
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

    Write-Host ""
    Write-Info "Ensuring Context7 MCP server is available via npx (@upstash/context7-mcp)..."

    # No separate global install is strictly required for npx, but this helps
    # with performance and reliability.
    $packageName = "@upstash/context7-mcp"
    $installArgs = @("install", "-g", $packageName)
    Write-Info "Running: npm $($installArgs -join ' ')"

    & npm @installArgs
    $installExit = $LASTEXITCODE
    if ($installExit -ne 0) {
        Write-Warn "npm failed to install $packageName globally (exit code $installExit)."
        Write-Warn "npx should still be able to run the server, but startup might be slower."
    }

    $scope = "user"
    $mcpName = "context7"

    Write-Host ""
    Write-Info "Configuring Context7 MCP server in Claude Code (scope=$scope, name=$mcpName)..."

    Write-Info "Removing existing '$mcpName' server in scope '$scope' (if any)..."
    try {
        claude mcp remove -s $scope $mcpName 2>$null
    } catch {
        # ignore errors; server might not exist
    }

    Write-Info "Adding '$mcpName' server in scope '$scope' via 'claude mcp add'..."
    & claude mcp add -s $scope $mcpName "context7-mcp"
    $addExit = $LASTEXITCODE
    if ($addExit -ne 0) {
        Write-Err "Failed to add Context7 MCP server (exit code $addExit)."
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Host "Context7 MCP server has been configured for Claude Code (scope=user, name=$mcpName)." -ForegroundColor Green
    Write-Host "You can verify it with: claude mcp list"
    Write-Host ""

    Exit-WithWait 0
}
catch {
    Write-Err "config-context7-mcp.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
