# OpenAI Codex CLI

This component installs the OpenAI Codex CLI (JavaScript/Node-based).

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

