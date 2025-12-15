# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lanren AI (懒人 AI)** is a Windows-focused development environment setup toolkit targeting **non-developers** who want to use AI coding assistants (Claude Code, Codex CLI) for daily tasks like document processing, data manipulation, and text automation. The project automates installation of development tools (Python, Node.js, Git, etc.) and AI CLIs with extensive China-friendly mirror support.

## Essential Commands

### Installation & Setup

**One-click install all components** (recommended for new setups):
```batch
install-everything.bat
```

**Enable PowerShell execution** (run first if scripts are blocked):
```batch
enable-ps1-permission.bat
```

**Install individual components** (each component directory):
```batch
cd components\<component-name>
install-comp.bat
```

**Configure components** (optional post-install):
```batch
cd components\<component-name>
config-comp.bat
```

### Common Component Installation Examples

Install Claude Code CLI:
```batch
cd components\claude-code-cli
install-comp.bat
```

Configure Claude Code with custom API endpoint:
```batch
cd components\claude-code-cli
config-custom-api-key.bat
```

Add Tavily MCP to Claude Code:
```batch
cd components\claude-code-cli
config-tavily-mcp.bat
```

Install Codex CLI:
```batch
cd components\codex-cli
install-comp.bat
```

Configure npm registry mirror:
```batch
cd components\nodejs
config-comp.ps1 -Mirror cn
```

### Development & Testing

**Run component installer directly** (PowerShell):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\components\<name>\install-comp.ps1
```

**Non-interactive mode with China mirrors**:
```powershell
.\components\nodejs\install-comp.ps1 -AcceptDefaults
```

**Force official sources** (skip mirrors):
```powershell
.\components\nodejs\install-comp.ps1 -FromOfficial
```

**Test in Windows Sandbox** (for validation):
```batch
# Open .wsb files in scripts\ directory
explorer scripts\
```

## Code Architecture

### Directory Structure

- **`components/`**: Primary installation system with standardized per-tool installers
  - Each subdirectory contains: `install-comp.{bat,ps1,sh}`, optional `config-*.{bat,ps1,sh}`, and `README.md`
  - See `components/INSTALL_ORDER.md` for dependency order

- **`scripts/`**: Legacy installers and Windows-specific helpers
  - `install-common-pack.ps1`: Older all-in-one installer (superseded by `install-everything.bat`)
  - `dev/`: Hyper-V and Windows Sandbox utilities

- **`magic-context/`**: Git submodule with reusable AI prompts and context templates
  - `general/`: Universal prompts (debugging, documentation, architecture)
  - `instructions/`: Task instructions for AI agents
  - `blender-plugin/`: Blender addon development guides

- **`quick-tools/`**: Git submodule with utility scripts
  - `claude/`: Claude Code helpers (skip login, custom API, MCP)
  - `docker-ce/`: Docker installation without Desktop
  - Many functions migrated to `components/` system

- **`context/`**: Project documentation organized by category
  - `design/`: Architectural decisions
  - `hints/`: Troubleshooting tips
  - `issues/`: Known problems and solutions
  - `plans/`: Future roadmap

- **`lanren-cache/`**: Runtime cache directory
  - `logs/<component>/<timestamp>.log`: Installation logs
  - `packages/<component>/`: Downloaded installers

### Component System Design

Each component follows a **three-file pattern**:

1. **`.bat` wrapper**: Thin shell for double-click execution
   ```batch
   @echo off
   powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" -NoExit %*
   ```

2. **`.ps1` installer**: Core PowerShell logic with standard parameters
   - `-Proxy <url>`: HTTP/HTTPS proxy for downloads
   - `-AcceptDefaults`: Non-interactive mode
   - `-FromOfficial`: Skip mirrors, use official sources
   - `-Force`: Force reinstall/repair
   - `-CaptureLogFile <path>`: Write logs to caller-specified file
   - `-NoExit`: Wait for keypress before exiting

3. **`.sh` script**: POSIX equivalent for Linux/macOS (same logic, portable)

### Installation Architecture

The `install-everything.bat` orchestrator follows this **5-stage sequence**:

1. **Base Environment**: PowerShell execution policy → winget → PowerShell 7 → VS Code
2. **CLI Tools**: jq, yq, Git
3. **Development Runtimes**: uv (Python), pixi (Conda), Node.js, Bun, aria2
4. **AI Coding Tools**: Claude Code CLI, Codex CLI, skip-login configs
5. **Extensions**: MarkItDown

Each step uses the `:run_step` helper that logs errors but continues (non-fatal), except Node.js failure aborts remaining steps (critical dependency).

### Configuration Patterns

**Mirror/Registry Strategy** (China-friendly by default):
- **Python (uv)**: Aliyun → Tsinghua → PyPI official
- **npm**: npmmirror.com → registry.npmjs.org
- **Node.js binaries**: Tsinghua mirrors
- Override: Use `-FromOfficial` flag on any `install-comp.ps1`

**PowerShell Profile Integration**:
- Custom CLI aliases written to `$PROFILE` (e.g., `claude-kimi`, `codex-openai-proxy`)
- Aliases set environment variables (`ANTHROPIC_BASE_URL`, `OPENAI_API_KEY`) before launching CLI

**MCP Server Configuration**:
- **Claude Code**: Uses `claude mcp add -s user <name> <command>` to register servers
- **Codex CLI**: Directly edits `~\.codex\config.toml` with `[mcp_servers.<name>]` sections
- **Important**: Codex uses `bunx` (not `npx`) for MCP server startup due to stability issues

**Logging System**:
- All modern installers write to `lanren-cache/logs/<component>/<timestamp>.log`
- Package downloads cached in `lanren-cache/packages/<component>/`
- Override root cache dir with `$env:LRAI_MASTER_OUTPUT_DIR`

### Idempotency & Error Handling

- **Design principle**: All installers can be run multiple times safely
- **Detection first**: Check if tool already exists on PATH before installing
- **Fallback chains**: Try winget → direct download → language-specific tools (npm, uv)
- **Non-fatal errors**: Log warnings but don't stop subsequent steps (except Node.js)
- **Clear messages**: User-friendly error output in Chinese and English

## Important Patterns for Claude Code

### When Working on Components

1. **Check dependency order**: Always consult `components/INSTALL_ORDER.md` before modifying installers
2. **Test Node.js dependency**: Many components (Claude Code CLI, Codex CLI, Bun) require Node.js first
3. **Mirror awareness**: Default behavior prefers China mirrors; test with `-FromOfficial` for official sources
4. **Logging location**: Check `lanren-cache/logs/` to debug failed installations
5. **PowerShell profile**: Custom aliases in `$PROFILE` persist across sessions; document changes

### Coding Standards (from AGENTS.md)

**PowerShell**:
- 4-space indentation
- PascalCase for functions (`Install-Thing`)
- camelCase for locals
- `$Global:` only when necessary
- Log clearly to console and log file

**Batch**:
- Uppercase for environment variables
- Use `setlocal`/`endlocal`
- Keep messages user-friendly and short

### Testing Strategy

No formal test suite exists. Validate changes by:
1. Running modified installers end-to-end on throwaway VM or Windows Sandbox
2. Verifying failure paths produce clear messages and non-zero exit codes
3. Testing both interactive and `-AcceptDefaults` modes
4. Checking with and without `-FromOfficial` flag

### Common Debugging Steps

**Check if a tool is installed**:
```powershell
Get-Command <tool-name> -ErrorAction SilentlyContinue
```

**View recent installation logs**:
```batch
dir /od lanren-cache\logs\<component-name>\
notepad lanren-cache\logs\<component-name>\<latest>.log
```

**Check npm registry configuration**:
```batch
npm config get registry
```

**Check PowerShell profile for custom aliases**:
```powershell
notepad $PROFILE
```

**View Claude Code config**:
```batch
notepad %USERPROFILE%\.claude.json
```

**View Codex CLI config**:
```batch
notepad %USERPROFILE%\.codex\config.toml
```

## Key Architectural Insights

1. **Target audience**: Non-developers on Windows with minimal command-line experience
2. **Design goal**: One-click setup with extensive error recovery and retry capability
3. **Mirror strategy**: China-first by default, with fallback to official sources
4. **Component isolation**: Each `components/<name>/` is self-contained; avoid cross-component dependencies
5. **Batch wrappers**: Enable double-click execution for non-technical users
6. **PowerShell primary**: All logic in `.ps1` files; `.bat` files are thin shells
7. **POSIX variants**: `.sh` scripts use same logic as PowerShell for Linux/macOS portability
8. **Submodules**: `magic-context` and `quick-tools` are reference repos; don't auto-install
9. **MCP integration**: Claude and Codex have different registration methods; understand both
10. **Dependency criticality**: Node.js failure aborts installation; other failures are warnings

## Configuration File Locations

- **Claude Code**: `%USERPROFILE%\.claude.json`
- **Codex CLI**: `%USERPROFILE%\.codex\config.toml`
- **PowerShell Profile**: `$PROFILE` (typically `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`)
- **npm config**: `%USERPROFILE%\.npmrc`
- **Cache root**: `lanren-cache/` (or `%LRAI_MASTER_OUTPUT_DIR%`)

## Related Documentation

- `README.md`: User-facing installation guide (Chinese)
- `AGENTS.md`: Developer guidelines and coding standards
- `components/INSTALL_ORDER.md`: Component dependency order
- `magic-context/general/`: Reusable AI prompts for debugging, architecture, documentation
- `context/design/`: Architectural decision records
