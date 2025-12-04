# Context7 MCP Server

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs and configures the Context7 MCP server for use with Claude Code and other MCP-aware clients. For MCP servers, we generally prefer Node.js-based distributions from npm, optionally executed via Bun.

## Installation approach

- Context7 MCP servers are distributed primarily via npm:
  - Community packages such as:
    - `@upstash/context7-mcp`
    - `c7-mcp-server`
  - These are typically run via `npx` or installed globally.
- Our installer will:
  - Ensure Node.js is installed (see `components/nodejs/README.md`).
  - Prefer npm-based installation and execution:
    - Global install:
      ```powershell
      npm install -g @upstash/context7-mcp
      ```
    - Or on-demand via `npx`/`bunx`:
      ```powershell
      npx -y @upstash/context7-mcp
      # or, with Bun available:
      bunx @upstash/context7-mcp
      ```

## China-friendly installation (npm + Bun)

- Use an npm mirror and/or Bun to improve performance:
  ```powershell
  npm config set registry https://registry.npmmirror.com
  npm install -g @upstash/context7-mcp
  ```
- With Bun:
  ```powershell
  bunx --registry https://registry.npmmirror.com @upstash/context7-mcp
  ```
- Our `install-comp` script will:
  - Prefer npm (and `npx`/`bunx`) for installing and launching the Context7 MCP server.
  - Default to `https://registry.npmmirror.com` in China-friendly mode, with `--proxy / -Proxy` used for outbound traffic.
  - Accept `--from-official` to force `https://registry.npmjs.org` and official upstream URLs.

## Official installation

Official installation flows are described in the respective npm package READMEs and documentation, for example:

- Context7 docs: https://context7.com/ (or equivalent docs host)
- `@upstash/context7-mcp`: https://www.npmjs.com/package/@upstash/context7-mcp
- `c7-mcp-server`: https://github.com/quiint/c7-mcp-server

With `--from-official`, the installer will:

- Use `npmjs.org` and official GitHub sources, ignoring China mirrors.
