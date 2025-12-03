# Repository Guidelines

## Project Structure & Organization

- Root docs: `README.md` (high-level goal), `AGENTS.md` (this guide).
- `scripts/`: Main Windows helpers and installers (PowerShell + `.bat` launchers).
- `context/`: Design docs, pack specs, and implementation notes (authoritative architecture).
- `magic-context/`, `quick-tools/`: Vendored helper repos; avoid large refactors and keep upstream style.
- `tmp/`: Scratch / generated artifacts; do not commit long‑lived files here.

## Development & Usage Commands

- Run the common tools installer (interactive):  
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-common-pack.ps1`
- Non‑interactive mode:  
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-common-pack.ps1 -NonInteractive`
- Windows Sandbox configs live in `scripts\*.wsb`; open in Explorer to test installers safely.

## Coding Style & Naming

- PowerShell: 4‑space indentation, PascalCase for functions (`Install-Thing`), camelCase for locals, `$Global:` only when necessary.
- Batch: Uppercase for environment variables, use `setlocal`/`endlocal`, keep messages user‑friendly and short.
- Scripts should log clearly to the console and, where appropriate, to a log file (follow patterns in `install-common-pack.ps1`).

## Testing & Validation

- There is no formal test suite yet; validate changes by:
  - Running modified installers end‑to‑end on a throwaway VM or Windows Sandbox.
  - Verifying that failure paths produce clear messages and non‑zero exit codes.
- For new scripts, prefer idempotent behavior and `-WhatIf`/dry‑run switches where feasible.

## Commit & Pull Request Guidelines

- Commit messages: short, imperative/sentence case (e.g., “Polish Claude Code helpers”, “Add Tavily MCP helper”).
- Keep each commit focused (one logical change) and describe user‑visible impact in the body when needed.
- PRs should include:
  - Brief summary of what changed and why.
  - Notes on how you validated the change (commands, environments).
  - Any follow‑up tasks or known limitations.

