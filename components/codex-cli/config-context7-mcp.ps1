<#
.SYNOPSIS
Installs the Context7 MCP server and configures it for Codex CLI.

.DESCRIPTION
This script:

- Ensures Node.js, Bun (`bun`), and Codex CLI (`codex`) are available.
- Installs the Context7 MCP server package globally via Bun (`bun add -g @upstash/context7-mcp`).
- Updates `config.toml` under CODEX_HOME (default `%USERPROFILE%\.codex`) to define
  an MCP server entry that uses `bunx` to start the Context7 MCP server:

    [mcp_servers.context7]
    command = "bunx"
    args = ["@upstash/context7-mcp@latest"]

This uses the free/no-API-key mode of Context7 and does not touch JSON configuration.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
Useful when running from a double-clicked .bat file.
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
    Write-Host "[codex-config-context7-mcp] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[codex-config-context7-mcp] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[codex-config-context7-mcp] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Host "=== Configure Context7 MCP for Codex CLI ==="
    Write-Host ""

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
        Exit-WithWait 1
    }

    Write-Info "Checking Bun (bun)..."
    try {
        $bunCmd = Get-Command bun -ErrorAction SilentlyContinue
        if ($bunCmd) {
            $bunVersion = bun --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $bunVersion) {
                Write-Info "Bun found: $bunVersion"
            } else {
                Write-Info "Bun is available on PATH."
            }
        } else {
            throw "bun command not found."
        }
    } catch {
        Write-Err "Bun ('bun') is not available on PATH."
        Write-Host "Install Bun first (for example via components/bun/install-comp), then re-run this script."
        Exit-WithWait 1
    }

    Write-Info "Checking Codex CLI..."
    try {
        $codexCmd = Get-Command codex -ErrorAction SilentlyContinue
        if ($codexCmd) {
            $codexVersion = codex --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $codexVersion) {
                Write-Info "Codex CLI found: $codexVersion"
            } else {
                Write-Info "Codex CLI found."
            }
        } else {
            throw "Codex CLI not found."
        }
    } catch {
        Write-Err "Codex CLI ('codex') is not on PATH."
        Write-Host "Install it first via the codex-cli component installer."
        Exit-WithWait 1
    }

    Write-Host ""
    Write-Info "Installing Context7 MCP server globally via Bun..."

    $packageName = "@upstash/context7-mcp"
    $installArgs = @("add", "-g", $packageName)
    Write-Info "Running: bun $($installArgs -join ' ')"

    & bun @installArgs
    $installExit = $LASTEXITCODE
    if ($installExit -ne 0) {
        Write-Err "bun failed to install $packageName (exit code $installExit)."
        Exit-WithWait 1
    }

    $bunxCmd = Get-Command "bunx" -ErrorAction SilentlyContinue
    if ($bunxCmd) {
        Write-Info "bunx command is available on PATH: $($bunxCmd.Source)"
    } else {
        Write-Warn "bunx command not found on PATH."
        Write-Warn "Codex will attempt to use 'bunx' to start the Context7 MCP server; ensure Bun is installed correctly."
    }

    $context7Cmd = Get-Command "context7-mcp" -ErrorAction SilentlyContinue
    if ($context7Cmd) {
        Write-Info "context7-mcp command is available on PATH: $($context7Cmd.Source)"
    } else {
        Write-Info "context7-mcp command not found on PATH; using 'bunx @upstash/context7-mcp@latest' from config."
    }

    $userHome = $env:USERPROFILE
    if (-not $userHome) {
        Write-Err "Could not determine USERPROFILE."
        Exit-WithWait 1
    }

    $codexHome = $env:CODEX_HOME
    if (-not $codexHome -or $codexHome.Trim().Length -eq 0) {
        $codexHome = Join-Path $userHome ".codex"
    }

    if (-not (Test-Path $codexHome)) {
        New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
    }

    $configPath = Join-Path $codexHome "config.toml"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType File -Path $configPath -Force | Out-Null
        $configContent = ""
    } else {
        $configContent = Get-Content $configPath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $configContent) {
            $configContent = ""
        }
    }

    # Normalize line endings
    $configContent = $configContent -replace "`r`n", "`n"

    # Ensure [mcp_servers] table exists
    if ($configContent -notmatch '(?m)^\[mcp_servers\]') {
        if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
            $configContent += "`n"
        }
        $configContent += "`n[mcp_servers]`n"
    }

    # Remove any existing [mcp_servers.context7] block
    $context7BlockPattern = '(?ms)^\[mcp_servers\.context7\].*?(?=^\[|\z)'
    if ($configContent -match $context7BlockPattern) {
        $configContent = [regex]::Replace($configContent, $context7BlockPattern, "")
        $configContent = $configContent.TrimEnd() + "`n"
    }

    # Append the Context7 MCP server configuration
    $serverLines = @()
    $serverLines += ""
    $serverLines += "[mcp_servers.context7]"
    $serverLines += 'command = "bunx"'
    $serverLines += 'args = ["@upstash/context7-mcp@latest"]'
    $serverLines += ""

    if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += ($serverLines -join "`n") + "`n"

    $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force

    Write-Host ""
    Write-Host "Context7 MCP server has been configured for Codex (mcp_servers.context7)." -ForegroundColor Green
    Write-Host "Config file: $configPath"
    Write-Host ""
    Write-Host "You can list MCP servers from Codex to verify the configuration."

    Exit-WithWait 0
}
catch {
    Write-Err "config-context7-mcp.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}

