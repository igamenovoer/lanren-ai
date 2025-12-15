# OpenAI Codex CLI

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs the OpenAI Codex CLI (JavaScript/Node-based) and provides helpers to configure custom endpoints and skip the built-in login flow.

## Preferred installation (requires Node.js)

- Ensure Node.js is installed (prefer via winget; see `components/nodejs/README.md`).
- Install from npm:
  ```powershell
  npm install -g @openai/codex
  ```

## China-friendly installation (npm mirrors)

- Use the Taobao/npmmirror registry for faster npm downloads:
  ```powershell
  npm config set registry https://registry.npmmirror.com
  npm config get registry
  npm install -g @openai/codex
  ```
- The `install-comp` script will:
  - Default to `https://registry.npmmirror.com` for China-friendly installs.
  - Respect `--proxy / -Proxy` for network access.
  - Accept `--from-official` to force `https://registry.npmjs.org`.

## Official installation

- Official Codex CLI package:
  - npm: https://www.npmjs.com/package/@openai/codex
- With `--from-official`, the installer will:
  - Use the default npm registry (`npmjs.org`) and official OpenAI endpoints.

## Configure custom endpoint and skip login

Use `config-custom-api-key` to set up a per-alias custom endpoint that uses `OPENAI_API_KEY` from the environment and skips the login screen by configuring a dedicated model provider in `config.toml`:

```powershell
.\components\codex-cli\config-custom-api-key.ps1
```

The script will:

- Prompt you for:
  - A PowerShell alias name (for example: `codex-openai-proxy`).
  - A custom base URL (for example: `https://api.example.com/v1`).
  - An API key.
- Write a PowerShell function into your user profiles that:
  - Sets `OPENAI_BASE_URL` and `OPENAI_API_KEY` for that session.
  - Launches `codex` with any additional arguments you pass.
- Update `~\.codex\config.toml` so that:
  - `model_provider` is set to a provider id derived from your alias.
  - `[model_providers.<alias-id>]`:
    - Uses `base_url` and `env_key = "OPENAI_API_KEY"`.
    - Sets `requires_openai_auth = false`, so Codex will not show the login screen when launched via that alias.

## MCP helpers (Context7 / Tavily)

> Note: For Codex CLI, this repository uses `bunx`（而不是更常见的 `npx`）来启动 MCP 服务器，主要原因是当前「`npx` + Codex CLI」组合在部分环境下并不稳定；推荐先安装 Bun，并按下面的脚本说明使用 `bunx`。

In addition to `config-custom-api-key`, this directory also contains helpers for configuring MCP servers commonly used with Codex:

- `config-context7-mcp.bat` / `.ps1`  
  - Installs the Context7 MCP server via Bun (`bun add -g @upstash/context7-mcp`) and appends an MCP entry such as `[mcp_servers.context7]` to `config.toml` that starts the server with `bunx @upstash/context7-mcp@latest`.  
  - Context7 连接到 Context7 的文档数据库，为 Codex 提供「最新、指定版本」的库 / 框架文档检索能力，减少因为示例过旧或 API 变更导致的报错。  
- `config-tavily-mcp.bat` / `.ps1`  
  - Installs the Tavily MCP server via Bun (`bun add -g tavily-mcp`)、提示输入 Tavily API Key，并在 `config.toml` 中写入 `[mcp_servers.tavily]` 配置，使用 `bunx tavily-mcp@latest` 启动 MCP 服务器，为 Codex 提供联网搜索 / 新闻检索等能力。  

通常流程是：先通过 `install-comp.bat` 安装 Codex CLI，再视需要运行 `config-custom-api-key.bat`、`config-context7-mcp.bat`、`config-tavily-mcp.bat` 做进一步配置。  

## Linux/macOS (POSIX) scripts

- Install:
  ```bash
  cd components/codex-cli
  sh ./install-comp.sh --dry-run
  sh ./install-comp.sh
  ```
- Configure custom endpoint + skip login (creates `~/.local/bin/<alias>` and stores the key in plain text):
  ```bash
  sh ./config-custom-api-key.sh --alias-name codex-openai-proxy --base-url "https://api.example.com/v1"
  ```
- MCP servers (Bun + `bunx`):
  ```bash
  sh ./config-context7-mcp.sh
  sh ./config-tavily-mcp.sh
  ```
