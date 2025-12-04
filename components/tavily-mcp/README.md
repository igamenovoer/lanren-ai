# Tavily MCP Server

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs the Tavily MCP server, which exposes Tavily’s search API to MCP-aware tools (e.g., Claude Code). For MCP servers, we generally prefer Node.js-based distributions from npm, optionally executed via Bun.

## Installation approach

- Tavily’s official MCP server is distributed via npm as `tavily-mcp`:
  - npm: https://www.npmjs.com/package/tavily-mcp
  - GitHub: https://github.com/tavily-ai/tavily-mcp
- Our installer will:
  - Ensure Node.js is installed (see `components/nodejs/README.md`).
  - Prefer npm-based installation and execution:
    - Global install:
      ```powershell
      npm install -g tavily-mcp
      ```
    - On-demand via `npx`/`bunx` (as recommended in Tavily docs):
      ```powershell
      npx -y tavily-mcp@latest
      # or, with Bun available:
      bunx tavily-mcp@latest
      ```

## China-friendly installation (npm + Bun)

- Use npm mirrors and/or Bun to improve performance:
  ```powershell
  npm config set registry https://registry.npmmirror.com
  npm install -g tavily-mcp
  ```
- Or on-demand:
  ```powershell
  npx -y tavily-mcp@latest --registry https://registry.npmmirror.com
  # or
  bunx --registry https://registry.npmmirror.com tavily-mcp@latest
  ```
- Our `install-comp` script will:
  - Prefer npm (and `npx`/`bunx`) for installing and launching the Tavily MCP server.
  - Default to `https://registry.npmmirror.com` in China-friendly mode, using `--proxy / -Proxy` for outbound traffic.
  - Accept `--from-official` to force `https://registry.npmjs.org` and official Tavily endpoints.

## Official installation

- Official Tavily docs:
  - MCP server repo: https://github.com/tavily-ai/tavily-mcp
  - Tavily docs (MCP section): https://docs.tavily.com/documentation/mcp
- With `--from-official`, the installer will:
  - Use `npmjs.org` and official Tavily URLs, ignoring China mirrors.
