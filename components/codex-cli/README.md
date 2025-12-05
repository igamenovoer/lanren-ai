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
