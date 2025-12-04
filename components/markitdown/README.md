# MarkItDown (document → Markdown)

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs [MarkItDown](https://github.com/microsoft/markitdown), a Python tool and CLI for converting documents (PDF, Office, etc.) into Markdown for LLM workflows.

## Preferred installation (uv tool)

- Use `uv` to install MarkItDown as a global tool:
  ```powershell
  uv tool install markitdown --with "markitdown[all]"
  ```
- After installation you can run:
  ```powershell
  markitdown path-to-file.pdf -o output.md
  ```

Our `install-comp` script for this component will:

- Prefer `uv tool install markitdown` (with `markitdown[all]` extras when possible) rather than `pip`/`pipx`.
- Respect `--proxy / -Proxy` by configuring `HTTP_PROXY` / `HTTPS_PROXY` or uv’s proxy options before invoking `uv`.
- Respect `--from-official` to force the official PyPI index even when a China mirror is normally used.

## China-friendly installation

- To prefer a China-based PyPI mirror with `uv`, set:
  ```powershell
  $env:UV_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple"
  uv tool install markitdown --with "markitdown[all]"
  ```
- You can also combine this with an HTTP(S) proxy via `HTTP_PROXY` / `HTTPS_PROXY` if direct access is unreliable.

## Alternative installation (official PyPI)

- If you do not want to use `uv`, you can install from PyPI directly:
  ```powershell
  pip install "markitdown[all]"
  ```
- Our automation still prefers `uv` for isolation and reproducibility, but `pip`/`pipx` remain valid manual alternatives.

