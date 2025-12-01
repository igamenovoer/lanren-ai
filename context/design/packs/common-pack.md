# Common AI Development Tools Pack

## HEADER
- **Purpose**: Document commonly used AI-assisted development tools and their supporting utilities
- **Status**: Active
- **Date**: 2025-12-01
- **Dependencies**: None
- **Target**: AI assistants and developers setting up development environments

## Overview

This document provides a comprehensive list of commonly used tools for AI-assisted software development, organized by category. These tools form a standard development pack for modern AI-enhanced workflows.

---

## AI Development CLIs

### Claude Code CLI
- **Type**: AI-powered command-line interface
- **Purpose**: Interactive CLI tool for AI-assisted development using Claude
- **Use Cases**: Code generation, debugging, refactoring, documentation
- **Installation**:
  - **Windows**: `winget install Anthropic.ClaudeCode` ([recommended](https://github.com/anthropics/claude-code/issues/11571))
  - **Ubuntu**: `curl -fsSL https://claude.ai/install.sh | sh` ([official installer](https://docs.claude.com/en/docs/claude-code/setup))
  - **Alternative (PowerShell)**: `irm https://claude.ai/install.ps1 | iex`
- **Requirements**: Windows 10+ (requires WSL/Git Bash), Ubuntu 20.04+, 4GB RAM minimum

### Codex CLI
- **Type**: AI-powered command-line interface
- **Purpose**: OpenAI Codex integration for terminal-based AI assistance
- **Use Cases**: Code completion, generation, and assistance via terminal
- **Installation**:
  - **Windows**: Install via WSL, then use npm: `npm i -g @openai/codex` ([WSL required](https://1v0.dev/posts/25-openai-codexcli-wsl/))
  - **Ubuntu**: `npm i -g @openai/codex` (requires Node.js) ([npm package](https://www.npmjs.com/package/@openai/codex))
  - **Alternative**: Use [Homebrew](https://github.com/openai/codex) on macOS/Linux: `brew install --cask codex`
- **Requirements**: Node.js, ChatGPT Plus/Pro/Business/Enterprise account or API key
- **Note**: Windows support is experimental; [WSL recommended](https://apidog.com/blog/codex-on-windows-wsl/)

---

## IDEs and Editors

### Visual Studio Code (VSCode)
- **Type**: Code editor/IDE
- **Purpose**: Primary development environment with extensive extension ecosystem
- **Features**: IntelliSense, debugging, Git integration, terminal, extensions
- **Platform**: Cross-platform (Windows, macOS, Linux)
- **Installation**:
  - **Windows**: `winget install --id Microsoft.VisualStudioCode` ([winget package](https://winget.run/pkg/Microsoft/VisualStudioCode))
  - **Ubuntu**: Download .deb package and install:
    ```bash
    wget -O vscode.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
    sudo apt install ./vscode.deb
    ```
    ([installation guide](https://phoenixnap.com/kb/install-vscode-ubuntu))
  - **Alternative (Ubuntu)**: Add Microsoft repository and use apt ([official method](https://microsoft.github.io/vscode-essentials/en/01-getting-started.html))

---

## VSCode Extensions

### Cline Plugin
- **Type**: AI assistant extension
- **Purpose**: In-editor AI assistance for code generation and explanation
- **Features**: Context-aware suggestions, code explanations, refactoring
- **Extension ID**: `saoudrizwan.claude-dev`
- **Installation**:
  - Via marketplace: Search "Cline"
  - Via CLI: `code --install-extension saoudrizwan.claude-dev`
- **Documentation**: [Cline VSCode Extension](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev)

### Kilo Code Plugin
- **Type**: Code enhancement extension
- **Purpose**: Code quality and productivity improvements
- **Features**: Advanced code analysis and suggestions
- **Extension ID**: `kilocode.Kilo-Code`
- **Installation**:
  - Via marketplace: Search "Kilo Code"
  - Via CLI: `code --install-extension kilocode.Kilo-Code`
- **Documentation**: [Kilo Code](https://marketplace.visualstudio.com/items?itemName=kilocode.Kilo-Code)

### Codex Plugin
- **Type**: AI code completion
- **Purpose**: OpenAI Codex integration for VSCode
- **Features**: AI-powered code completion and generation
- **Extension ID**: `openai.chatgpt`
- **Installation**:
  - Via marketplace: Search "Codex" or "OpenAI"
  - Via CLI: `code --install-extension openai.chatgpt`
- **Documentation**: [OpenAI Codex Extension](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt)

### Claude Code Plugin
- **Type**: AI assistant extension
- **Purpose**: Anthropic Claude integration for VSCode
- **Features**: Advanced reasoning, code analysis, documentation
- **Extension ID**: `anthropic.claude-code`
- **Installation**:
  - Via marketplace: Search "Claude Code"
  - Via CLI: `code --install-extension anthropic.claude-code`
- **Documentation**: [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)
- **Note**: Extension is in beta

### Python Extension
- **Type**: Language support
- **Purpose**: Comprehensive Python development support
- **Features**: IntelliSense, linting, debugging, Jupyter support, testing
- **Publisher**: Microsoft
- **Installation**:
  - Via marketplace: Search "Python" (Microsoft)
  - Via CLI: `code --install-extension ms-python.python`

### Markdown Preview Enhanced
- **Type**: Markdown tooling
- **Purpose**: Enhanced markdown editing and preview
- **Features**: Live preview, export to PDF/HTML, diagrams, math support
- **Use Cases**: Documentation, README files, notes
- **Extension ID**: `shd101wyy.markdown-preview-enhanced`
- **Installation**:
  - Via marketplace: Search "Markdown Preview Enhanced"
  - Via CLI: `code --install-extension shd101wyy.markdown-preview-enhanced`

---

## Batch Installing VSCode Extensions via CLI

All VSCode extensions can be installed via command line, which is useful for automation and setting up new development environments.

### Basic Command

```bash
code --install-extension <extension-id>
```

### Install Multiple Extensions at Once

**Single command** ([multiple --install-extension flags](https://stackoverflow.com/questions/58513266/how-to-install-multiple-extensions-in-vscode-using-command-line)):
```bash
code --install-extension saoudrizwan.claude-dev --install-extension kilocode.Kilo-Code --install-extension openai.chatgpt --install-extension anthropic.claude-code --install-extension ms-python.python --install-extension shd101wyy.markdown-preview-enhanced
```

### Export/Import Extension Lists

**Export current extensions** to a file:
```bash
code --list-extensions > extensions.txt
```

**Install all extensions from list**:

**Windows (PowerShell)** ([PowerShell method](https://gist.github.com/vmandic/ef80f1097521c16063b3b1c3a687d244)):
```powershell
Get-Content extensions.txt | ForEach-Object { code --install-extension $_ --force }
```

**Ubuntu/Linux (Bash)** ([xargs method](https://romanvesely.com/vscode-extensions)):
```bash
cat extensions.txt | xargs -L 1 code --install-extension --force
```

**Alternative (Bash with loop)**:
```bash
cat extensions.txt | while read extension || [[ -n $extension ]]; do
  code --install-extension $extension --force
done
```

**Windows (Batch file)** ([batch script](https://stackoverflow.com/questions/58513266/how-to-install-multiple-extensions-in-vscode-using-command-line)):
```batch
@echo off
for /F "tokens=*" %%a in (extensions.txt) do (
  call code --install-extension %%a --force
)
```

### Complete Installation Script for Common Pack Extensions

**Create `vscode-extensions.txt`**:
```
saoudrizwan.claude-dev
kilocode.Kilo-Code
openai.chatgpt
anthropic.claude-code
ms-python.python
shd101wyy.markdown-preview-enhanced
```

**Windows (PowerShell)**:
```powershell
# Install all extensions from list
Get-Content vscode-extensions.txt | ForEach-Object {
  Write-Host "Installing $_..."
  code --install-extension $_ --force
}
```

**Ubuntu/Linux (Bash)**:
```bash
#!/bin/bash
# Install all extensions from list
cat vscode-extensions.txt | while read extension; do
  echo "Installing $extension..."
  code --install-extension $extension --force
done
```

### Workspace Recommended Extensions

Create `.vscode/extensions.json` in your project ([automatic prompting](https://stackoverflow.com/questions/35929746/automatically-install-extensions-in-vs-code)):
```json
{
  "recommendations": [
    "saoudrizwan.claude-dev",
    "kilocode.Kilo-Code",
    "openai.chatgpt",
    "anthropic.claude-code",
    "ms-python.python",
    "shd101wyy.markdown-preview-enhanced"
  ]
}
```

VSCode will prompt users to install these extensions when they open the workspace.

### Important Flags

- `--force`: Skip update prompts (recommended for [automation scripts](https://ramomujagic.com/blog/bulk-install-vs-code-extensions/))
- `--update-extensions`: Update all installed extensions (added November 2024)

### Verification

Check installed extensions:
```bash
code --list-extensions
```

Check VSCode version:
```bash
code --version
```

---

## Package Managers and Runtime

### Node.js / npm
- **Type**: JavaScript runtime and package manager
- **Purpose**: JavaScript/TypeScript development and package management
- **Components**:
  - Node.js: JavaScript runtime
  - npm: Package manager for JavaScript
- **Use Cases**: Installing tools, running build scripts, dependency management
- **Installation**:
  - **Windows**: `winget install OpenJS.NodeJS` or `winget install OpenJS.NodeJS.LTS` for LTS ([winget package](https://winget.run/pkg/OpenJS/NodeJS))
  - **Ubuntu**: `sudo apt update && sudo apt install nodejs npm` ([basic installation](https://nodejs.org/en/download/package-manager/all))
  - **Alternative (Ubuntu, latest version)**: Use [NodeSource](https://paulgeek.com/blog/nodejs-on-ubuntu):
    ```bash
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    ```
  - **Note**: Consider using nvm for [version management](https://www.geeksforgeeks.org/installation-guide/install-node-js-windows-macos-linux/)

---

## Python Package and Environment Managers

### uv
- **Type**: Ultra-fast Python package installer and resolver
- **Purpose**: Modern, high-performance Python package management
- **Features**: Fast installation, dependency resolution, virtual environments
- **Use Cases**: Quick package installation, script running (`uvx` for tools)
- **Installation**:
  - **Windows**: `irm https://astral.sh/uv/install.ps1 | iex` ([PowerShell installer](https://docs.astral.sh/uv/getting-started/installation/))
  - **Ubuntu**: `curl -LsSf https://astral.sh/uv/install.sh | sh` ([official installer](https://docs.astral.sh/uv/getting-started/installation/))
  - **Alternative**: `wget -qO- https://astral.sh/uv/install.sh | sh`
  - **Via pipx**: `pipx install uv` (requires isolated environment)
- **Documentation**: [docs.astral.sh/uv](https://docs.astral.sh/uv/)
- **Note**: Written in Rust for [maximum performance](https://www.datacamp.com/tutorial/python-uv); significantly faster than pip

### pixi
- **Type**: Cross-platform package manager
- **Purpose**: Conda-compatible package and environment manager
- **Features**: Fast, cross-platform, reproducible environments
- **Use Cases**: Python and non-Python package management, scientific computing
- **Installation**:
  - **Windows**: `winget install --id=prefix-dev.pixi -e` ([winget package](https://winget.run/pkg/prefix-dev/pixi))
  - **Windows (PowerShell)**: `iwr -useb https://pixi.sh/install.ps1 | iex`
  - **Ubuntu**: `curl -fsSL https://pixi.sh/install.sh | sh` ([official installer](https://pixi.sh/latest/))
  - **Alternative**: `brew install pixi` (if Homebrew available)
- **Documentation**: [pixi.sh](https://pixi.sh/)
- **Note**: Single executable with [no external dependencies](https://github.com/prefix-dev/pixi); restart terminal after installation

---

## Data Processing Utilities

### jq
- **Type**: JSON processor
- **Purpose**: Command-line JSON parsing, filtering, and transformation
- **Use Cases**: API response processing, config file manipulation, data extraction
- **Example**: `cat data.json | jq '.items[] | select(.active == true)'`
- **Installation**:
  - **Windows**: `winget install jqlang.jq` ([winget package](https://winget.run/pkg/stedolan/jq))
  - **Ubuntu**: `sudo apt-get install jq` or `sudo apt install -y jq` ([apt package](https://jqlang.org/download/))
  - **Alternative**: Download from [GitHub releases](https://bobbyhadz.com/blog/install-and-use-jq-on-windows)
- **Verification**: Run `jq --version` after installation

### yq
- **Type**: YAML/XML processor
- **Purpose**: Command-line YAML and XML parsing (jq for YAML)
- **Use Cases**: Config file processing, CI/CD pipeline manipulation
- **Example**: `yq eval '.database.host' config.yaml`
- **Installation**:
  - **Windows**: `winget install --id MikeFarah.yq` ([winget package](https://winget.run/pkg/MikeFarah/yq))
  - **Ubuntu**: Download directly from GitHub:
    ```bash
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
    ```
    ([installation guide](https://lindevs.com/install-yq-on-ubuntu/))
  - **Alternative (Ubuntu)**: Install via [Snap](https://snapcraft.io/install/yq/ubuntu): `sudo snap install yq`
- **Documentation**: [github.com/mikefarah/yq](https://github.com/mikefarah/yq/blob/master/README.md)

---

## Document Conversion Tools

### pandoc
- **Type**: Universal document converter
- **Purpose**: Convert between markup formats
- **Supported Formats**: Markdown, HTML, LaTeX, PDF, DOCX, and many more
- **Use Cases**: Documentation generation, format conversion, publishing
- **Installation**:
  - **Windows**: `winget install pandoc` or `winget install JohnMacFarlane.Pandoc` ([winget package](https://winget.run/pkg/JohnMacFarlane/Pandoc))
  - **Ubuntu**: `sudo apt install pandoc` ([apt package](https://pandoc.org/installing.html))
  - **Note**: Ubuntu repositories may have [older versions](https://stackoverflow.com/questions/61100045/how-to-install-stable-and-fresh-pandoc-on-ubuntu); for latest version, download .deb from [GitHub releases](https://gist.github.com/killshot13/5b379355d275e79a5cb1f03c841c7d53):
    ```bash
    wget https://github.com/jgm/pandoc/releases/download/[version]/pandoc-[version]-amd64.deb
    sudo dpkg -i pandoc-[version]-amd64.deb
    ```
- **Documentation**: [pandoc.org](https://pandoc.org/getting-started.html)

### markitdown
- **Type**: Markdown converter
- **Purpose**: Convert various formats to Markdown (Microsoft tool)
- **Installation**:
  - **Both Windows & Ubuntu**: `uv tool run markitdown-mcp` ([uv tool](https://github.com/microsoft/markitdown))
  - **Alternative**: Install via pip: `pip install markitdown` ([PyPI package](https://pypi.org/project/markitdown/))
  - **As MCP server**: Configure with `uv tool run markitdown-mcp` ([MCP setup](https://qiita.com/samplebang/items/7726cb8d5176144dd3e8))
- **Usage**: `uvx markitdown input.pdf -o output.md`
- **Requirements**: Python 3.10+ ([system requirements](https://deepwiki.com/microsoft/markitdown/1.2-installation-and-usage))
- **Note**: `uv` approach recommended for [MCP server deployments](https://github.com/microsoft/markitdown/pull/1213/files)

---

## MCP (Model Context Protocol) Servers

MCP servers provide specialized capabilities to AI assistants through standardized interfaces.

### Tavily MCP
- **Type**: Web search MCP server
- **Purpose**: Real-time web search capabilities for AI assistants
- **Features**: Current information retrieval, fact-checking, research
- **Use Cases**: Looking up current events, documentation, technical references
- **Installation**:
  - **Remote MCP (No installation)**: Connect directly to Tavily's remote server ([easiest method](https://docs.tavily.com/documentation/mcp)):
    ```json
    {
      "mcpServers": {
        "tavily-remote-mcp": {
          "command": "npx -y mcp-remote https://mcp.tavily.com/mcp/?tavilyApiKey=<your-api-key>",
          "env": {}
        }
      }
    }
    ```
  - **NPM/npx**: Configure Claude Desktop ([npm package](https://www.npmjs.com/package/tavily-mcp)):
    ```json
    {
      "mcpServers": {
        "tavily": {
          "command": "npx",
          "args": ["-y", "@mcptools/mcp-tavily"],
          "env": {"TAVILY_API_KEY": "your-api-key"}
        }
      }
    }
    ```
  - **Via Smithery**: `npx -y @smithery/cli install @kshern/mcp-tavily --client claude`
  - **Python/uv**: Clone repo, run `uv sync` and `uv build` ([GitHub](https://github.com/RamXX/mcp-tavily))
- **Requirements**: Tavily API key from [tavily.com](https://tavily.com)

### Context7
- **Type**: Documentation MCP server
- **Purpose**: Access to up-to-date library and framework documentation
- **Features**: API references, code examples, version-specific docs
- **Use Cases**: Library documentation lookup, API reference, code examples
- **Installation**:
  - **Claude Code**: `claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY`
  - **Via Smithery (recommended)**: ([automated installation](https://github.com/upstash/context7))
    ```bash
    npx -y @smithery/cli@latest install @upstash/context7-mcp --client <CLIENT_NAME> --key <YOUR_SMITHERY_KEY>
    ```
  - **Manual (Claude Desktop)**: Add to config ([setup guide](https://apidog.com/blog/context7-mcp-server/)):
    ```json
    {
      "mcpServers": {
        "context7": {
          "command": "npx",
          "args": ["-y", "@upstash/context7-mcp@latest"]
        }
      }
    }
    ```
  - **Cursor**: Settings → Cursor Settings → MCP → Add new global MCP server
  - **Alternative runtimes**: Can use `bunx` or Deno instead of `npx` ([docs](https://deepwiki.com/upstash/context7/3-installation-and-setup))
- **Requirements**: Node.js >= v18.0.0
- **Optional**: Context7 API key for [higher rate limits](https://lobehub.com/mcp/upstash-context7)
- **Usage**: Add "use context7" to your prompts

### Browser MCP
- **Type**: Web browsing MCP server
- **Purpose**: Web page fetching and content extraction
- **Features**: Page scraping, content extraction, screenshot capture
- **Use Cases**: Reading web content, documentation extraction, research
- **Installation**:
  - **Requirements**:
    - Node.js ([Node-based implementations](https://docs.browsermcp.io/setup-server))
    - Chrome/Chromium browser installed
    - Python 3.11+ and uv (for Python-based implementations)
  - **Setup**: Add MCP server config to AI application ([configuration](https://github.com/BrowserMCP/mcp))
  - **Claude Desktop**: Add to config file:
    - **macOS**: `~/Library/Application\ Support/Claude/claude_desktop_config.json`
    - **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`
  - **After configuration**: Restart the application
- **Available implementations**: Multiple options ([guide](https://www.skyvern.com/blog/browser-automation-mcp-servers-guide/)):
  - [mcp-server-browserbase](https://github.com/browserbase/mcp-server-browserbase) (Browserbase + Stagehand)
  - [browser-use MCP](https://medium.com/towards-agi/how-to-setup-and-use-browser-use-mcp-server-8d0725440f31) (Python-based)
  - [Chrome MCP](https://lobehub.com/mcp/lxe-chrome-mcp)
- **Features**: Local automation for [better privacy](https://playbooks.com/mcp/deploya-labs-browser-use), uses existing browser profile

---

## Installation Quick Reference

### Package Managers
```bash
# npm (comes with Node.js)
npm install -g <package>

# uv (Python packages)
pip install uv
uv pip install <package>
uvx <tool>  # Run tool without installing

# pixi
curl -fsSL https://pixi.sh/install.sh | bash
pixi add <package>
```

### Utilities
```bash
# jq (varies by platform)
# Windows: choco install jq
# macOS: brew install jq
# Linux: apt-get install jq

# yq
# Windows: choco install yq
# macOS: brew install yq
# Linux: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

# pandoc
# Windows: choco install pandoc
# macOS: brew install pandoc
# Linux: apt-get install pandoc

# markitdown (via uv)
uvx markitdown input.pdf -o output.md
```

### VSCode Extensions

**Install all common pack extensions** ([batch installation](https://stackoverflow.com/questions/58513266/how-to-install-multiple-extensions-in-vscode-using-command-line)):

**Windows (PowerShell)**:
```powershell
# One-liner for all extensions
"saoudrizwan.claude-dev", "kilocode.Kilo-Code", "openai.chatgpt", "anthropic.claude-code", "ms-python.python", "shd101wyy.markdown-preview-enhanced" | ForEach-Object { code --install-extension $_ --force }
```

**Ubuntu/Linux (Bash)**:
```bash
# Batch install all extensions
for ext in saoudrizwan.claude-dev kilocode.Kilo-Code openai.chatgpt anthropic.claude-code ms-python.python shd101wyy.markdown-preview-enhanced; do
  code --install-extension $ext --force
done
```

**Individual installation**:
```bash
code --install-extension saoudrizwan.claude-dev        # Cline
code --install-extension kilocode.Kilo-Code            # Kilo Code
code --install-extension openai.chatgpt                # Codex
code --install-extension anthropic.claude-code         # Claude Code
code --install-extension ms-python.python              # Python
code --install-extension shd101wyy.markdown-preview-enhanced  # Markdown Preview
```

See **"Batch Installing VSCode Extensions via CLI"** section above for more methods.

---

## Recommended Setup Workflow

1. **Install base tools**:
   - Node.js/npm
   - Python + uv or pixi
   - VSCode

2. **Install VSCode extensions**:
   - Python
   - Markdown Preview Enhanced
   - AI assistant plugins (Cline, Claude Code, etc.)

3. **Install CLI utilities**:
   - jq, yq (data processing)
   - pandoc, markitdown (document conversion)
   - Claude Code CLI, Codex CLI (AI assistance)

4. **Configure MCP servers**:
   - Tavily MCP (web search)
   - Context7 (documentation)
   - Browser MCP (web browsing)

5. **Verify installations**:
   ```bash
   node --version
   npm --version
   uv --version
   jq --version
   yq --version
   pandoc --version
   code --version
   ```

---

## Notes

- **Tool Selection**: Not all tools are required for every project. Select based on project needs.
- **Version Management**: Use version managers (nvm for Node, pyenv/uv for Python) for multiple versions.
- **Updates**: Keep tools updated for latest features and security patches.
- **Platform Differences**: Some installation commands vary by operating system.
- **MCP Configuration**: MCP servers typically require configuration in AI assistant settings.

---

## Related Documentation

- See `context/hints/` for setup guides and troubleshooting
- See `context/tools/` for custom scripts that integrate these tools
- See `context/instructions/` for command templates and workflows
