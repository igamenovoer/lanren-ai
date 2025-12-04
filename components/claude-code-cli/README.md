# Claude Code CLI

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs the Claude Code CLI used by Anthropic’s Claude Code tooling.

## Preferred installation (requires Node.js)

- Ensure Node.js is installed (prefer via winget, see `components/nodejs/README.md`).
- Global installation from npm:
  ```powershell
  npm install -g @anthropic-ai/claude-code
  ```

After installation, Claude Code CLI normally launches an onboarding/login flow the first time you run `claude`. The per-component installer for `claude-code-cli` (its `install-comp.ps1` inside this directory) is responsible for marking onboarding as complete by updating `%USERPROFILE%\.claude.json` (setting `hasCompletedOnboarding = true`), so you can start using the CLI immediately without going through the login wizard on this machine.

## China-friendly installation (npm mirrors)

- For Chinese networks, point npm to a faster mirror before installing:
  ```powershell
  npm config set registry https://registry.npmmirror.com
  npm config get registry
  ```
- Then install:
  ```powershell
  npm install -g @anthropic-ai/claude-code
  ```
- Our `install-comp` script will:
  - Prefer `npm` with `https://registry.npmmirror.com` (or another configured mirror) by default in China.
  - Respect `--proxy / -Proxy` and `--from-official`:
    - `--from-official` forces `https://registry.npmjs.org` as the registry.
   - As a post-install step (implemented inside this component’s own `install-comp.ps1`), it will:
     - Verify `claude` is available on `PATH`.
     - Create or update `%USERPROFILE%\.claude.json` with `hasCompletedOnboarding = true` (UTF-8 without BOM).
     - Ensure subsequent `claude` invocations skip the interactive login/onboarding flow on this host.

## Official installation

- Official docs and package:
  - npm: https://www.npmjs.com/package/@anthropic-ai/claude-code
  - Anthropic docs: https://docs.anthropic.com/
- When `--from-official` is used, the installer will:
  - Set `npm config set registry https://registry.npmjs.org` for the install step.
