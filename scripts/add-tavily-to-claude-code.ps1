#!/usr/bin/env pwsh

<#
add-tavily-to-claude-code.ps1

Adds the Tavily MCP server to Claude Code CLI using Bun (bunx) in the
current user's configuration (user scope).

Behavior:
- Verifies that `claude` CLI is installed.
- Verifies that Bun is installed (checks for `bunx` / `bun`).
- Always prompts interactively for a Tavily API key.
- Removes any existing `tavily` MCP server config from Claude.
- Adds `tavily` using Bun's runner:
    claude mcp add tavily bunx tavily-mcp@latest -e TAVILY_API_KEY="..."

No administrator privileges are required; Claude Code stores MCP config in
user scope by default.
#>

param()

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[add-tavily] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[add-tavily] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[add-tavily] ERROR: $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    return $null -ne $cmd
}

try {
    Write-Info "Setting up Tavily MCP server for Claude Code (user scope)..."

    if (-not (Test-CommandExists -Name "claude")) {
        Write-Err "Claude Code CLI ('claude') was not found on PATH."
        Write-Host "Please install it first, for example:"
        Write-Host "  npm install -g @anthropic-ai/claude-code"
        exit 1
    }

    $hasBunx = Test-CommandExists -Name "bunx"
    $hasBun  = Test-CommandExists -Name "bun"
    if (-not ($hasBunx -or $hasBun)) {
        Write-Err "Bun is not available (neither 'bunx' nor 'bun' found in PATH)."
        Write-Host "Install Bun first (which includes bunx), for example:"
        Write-Host "  winget install Oven-sh.Bun"
        Write-Host "or see: https://bun.sh/docs/installation"
        exit 1
    }

    $TavilyApiKey = $null
    while (-not $TavilyApiKey) {
        $TavilyApiKey = Read-Host "Enter your Tavily API key (TAVILY_API_KEY, required)"
        if (-not $TavilyApiKey) {
            Write-Err "Tavily API key cannot be empty. Please try again."
        }
    }

    Write-Info "Removing any existing 'tavily' MCP server configuration..."
    try {
        claude mcp remove tavily | Out-Null
    } catch {
        # ignore errors if it doesn't exist
    }

    # Use bunx if available; otherwise assume plain bun also supports bunx-style invocation.
    $runner = if ($hasBunx) { "bunx" } else { "bunx" }

    Write-Info "Adding Tavily MCP server using $runner (package tavily-mcp@latest)..."
    $envArg = "TAVILY_API_KEY=$TavilyApiKey"

    # claude mcp add tavily bunx tavily-mcp@latest -e TAVILY_API_KEY="..."
    claude mcp add tavily $runner tavily-mcp@latest -e $envArg

    Write-Info "Verifying configured MCP servers..."
    claude mcp list

    Write-Host ""
    Write-Host "Tavily MCP has been added to Claude Code with user-scope configuration." -ForegroundColor Green
    Write-Host "You can now use Tavily inside Claude Code (e.g., via 'tavily-search', 'tavily-extract', etc.)."
}
catch {
    Write-Err "Failed to add Tavily MCP server: $($_.Exception.Message)"
    exit 1
}
