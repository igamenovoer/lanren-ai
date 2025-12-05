<#
.SYNOPSIS
Installs the Tavily MCP server and configures it for Codex CLI.

.DESCRIPTION
This script:

- Ensures Bun (`bun`), Node.js, and Codex CLI (`codex`) are available.
- Installs the Tavily MCP server globally via Bun (`bun add -g tavily-mcp`).
- Prompts for a Tavily API key (or lets you reuse TAVILY_API_KEY from the environment).
- Updates `config.toml` under CODEX_HOME (default `%USERPROFILE%\.codex`) to define
  an MCP server entry that uses `bunx`:

    [mcp_servers.tavily]
    command = "bunx"
    args = ["tavily-mcp@latest"]
    env = { TAVILY_API_KEY = "..." }

.PARAMETER ApiKey
Optional Tavily API key to use non-interactively. If omitted, the script will prompt.
If TAVILY_API_KEY is already set in the environment, you can press Enter to reuse it.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
Useful when running from a double-clicked .bat file.
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
    Write-Host "[codex-config-tavily-mcp] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[codex-config-tavily-mcp] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[codex-config-tavily-mcp] ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Host "=== Configure Tavily MCP for Codex CLI ==="
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
    Write-Info "Installing Tavily MCP server globally via Bun..."

    $packageName = "tavily-mcp"
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
        Write-Warn "Codex will attempt to use 'bunx' to start the Tavily MCP server; ensure Bun is installed correctly."
    }

    $tavilyCmd = Get-Command "tavily-mcp" -ErrorAction SilentlyContinue
    if ($tavilyCmd) {
        Write-Info "tavily-mcp command is available on PATH: $($tavilyCmd.Source)"
    } else {
        Write-Warn "tavily-mcp command not found on PATH after global install."
        Write-Warn "bunx tavily-mcp@latest should still work if Bun is installed correctly."
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

    $configContent = $configContent -replace "`r`n", "`n"

    if ($configContent -notmatch '(?m)^\[mcp_servers\]') {
        if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
            $configContent += "`n"
        }
        $configContent += "`n[mcp_servers]`n"
    }

    # Remove any existing [mcp_servers.tavily] block
    $tavilyBlockPattern = '(?ms)^\[mcp_servers\.tavily\].*?(?=^\[|\z)'
    if ($configContent -match $tavilyBlockPattern) {
        $configContent = [regex]::Replace($configContent, $tavilyBlockPattern, "")
        $configContent = $configContent.TrimEnd() + "`n"
    }

    $serverLines = @()
    $serverLines += ""
    $serverLines += "[mcp_servers.tavily]"
    $serverLines += 'command = "bunx"'
    $serverLines += 'args = ["tavily-mcp@latest"]'
    $serverLines += "env = { TAVILY_API_KEY = `"$ApiKey`" }"
    $serverLines += ""

    if ($configContent.Length -gt 0 -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += ($serverLines -join "`n") + "`n"

    $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force

    Write-Host ""
    Write-Host "Tavily MCP server has been configured for Codex (mcp_servers.tavily)." -ForegroundColor Green
    Write-Host "Config file: $configPath"
    Write-Host ""
    Write-Host "You can list MCP servers from Codex to verify the configuration."

    Exit-WithWait 0
}
catch {
    Write-Err "config-tavily-mcp.ps1 failed: $($_.Exception.Message)"
    Exit-WithWait 1
}
