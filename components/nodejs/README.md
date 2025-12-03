# Node.js

This component installs Node.js (preferring the LTS build).

## Preferred installation (winget)

- LTS channel:
  ```powershell
  winget install -e --id OpenJS.NodeJS.LTS
  ```
- Fallback (current):
  ```powershell
  winget install -e --id OpenJS.NodeJS
  ```

## China-friendly installation (mirrors)

If you need to download installers or binaries manually, use a known mirror:

- **Tsinghua nodejs-release mirror**  
  - https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
  - Can be used with tools like `nvm`, `nvs`, or `volta` by setting `NVM_NODEJS_ORG_MIRROR` / `NODE_MIRROR`.
- **npm registry mirror for packages** (after Node is installed):
  ```powershell
  npm config set registry https://registry.npmmirror.com
  npm config get registry
  ```

Our `install-comp` script will:

- Prefer `winget install` as above.
- If direct installers are needed, try `nodejs-release` mirrors first, then fall back to `https://nodejs.org/en/download`.
- Respect `--proxy / -Proxy` and `--from-official` (skipping mirrors and using the official Node.js download site).

## Official installation

- Official downloads:
  - https://nodejs.org/en/download
- Package manager docs:
  - https://nodejs.org/en/download/package-manager

