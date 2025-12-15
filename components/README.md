# Components Directory

The `components/` directory is a home for per-component installers and helpers. Each component (library, tool, or piece of software) gets its own subdirectory under `components/`, and that subdirectory contains the scripts and assets needed to download, install, and configure it.

Example structure (matching this repo):

- `components/winget/` – ensure Windows Package Manager is available.
- `components/powershell-7/` – install PowerShell 7.
- `components/vscode/` – install VS Code and extensions.
- `components/jq/`, `components/yq/`, `components/git/` – common CLI tools.
- `components/uv/`, `components/pixi/`, `components/nodejs/`, `components/bun/`, `components/aria2/` – runtimes, package managers, download helper.
- `components/claude-code-cli/`, `components/codex-cli/`, `components/markitdown/` – AI CLIs and document tools.

The recommended high-level installation order is documented in `components/INSTALL_ORDER.md` and mirrored by the root `install-everything.bat` helper.

## Standard Scripts per Component

Each component subdirectory contains a PowerShell installer script.
- The `.ps1` script is standalone-callable (including from PowerShell/VSCode).
- Most components also provide a thin `.bat` wrapper (for double-click usage) that forwards arguments to the corresponding `.ps1`.
- **Important:** Before running any `.ps1` scripts, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.
- Per-component installers should be **self-contained** within their own directory under `components/` and must not depend on scripts located elsewhere in the repository (for example, do not call helpers under `scripts\` from `components\claude-code-cli\install-comp.ps1`; instead, embed the necessary logic directly in the per-component installer).

Each component also has a POSIX shell counterpart for Linux/macOS:
- Install: `install-comp.sh`
- Configure: `config-comp.sh` (when applicable)
- Notes:
  - Prefer running with `--dry-run` first if you want to verify behavior without modifying the system.
  - Logs go to `./lanren-cache/` by default (or `$LRAI_MASTER_OUTPUT_DIR`).

Where possible, component subdirectories should expose the following standard tools:

### `install-comp.ps1`

- Purpose: Perform the actual installation from a prepared directory.
- Files: `install-comp.ps1` (plus `install-comp.bat` wrapper in most components).
- Key arguments:
  - PowerShell:
    - `-Proxy <url>` (or `-ProxyUrl <url>`) to specify an HTTP/HTTPS proxy for downloads and networked installers.
    - `-AcceptDefaults` (or similar) to run non-interactively (accepting defaults, passing “yes” flags to underlying installers where supported).
    - `-FromOfficial` (or `-UseOfficialSource`) to force use of official URLs even if a local accelerator/proxy is configured.
    - `-Force` to force a reinstall/repair even if the component appears to be already installed.
    - `-CaptureLogFile <path>` to also write logs to a caller-provided path (for paired `.bat` wrappers or external callers to print later).
  - Contract:
    - All `install-comp.ps1` scripts must accept these standard switches (`-Proxy`, `-AcceptDefaults`, `-FromOfficial`, `-Force`, `-CaptureLogFile`), even if some of them are effectively no-ops for a given component.
- Behavior:
  - Does not take an `--input-dir` / `-InputDir` parameter.
  - If the component is available via `winget`, installers should **prefer `winget` as the primary installation method**, using direct downloads or language-specific tools (`npm install`, `uv tool install`, etc.) only as a fallback when `winget` is unavailable or unsuitable.
  - Logging (standard pattern used by newer installers such as `winget`, `powershell-7`, `vscode`, `jq`, `yq`, `git`, `uv`, `pixi`, `nodejs`, `bun`, `aria2`, `markitdown`, `codex-cli`, etc.):
    - Each installer writes log output to a component-scoped file under a shared output directory:
      - Default root: `<pwd>\lanren-cache\`
      - Logs: `<root>\logs\<component-name>\<timestamp>.log`
    - When the environment variable `LRAI_MASTER_OUTPUT_DIR` is set, its value is used as `<root>` instead of `<pwd>\lanren-cache`.
    - When `-CaptureLogFile` is provided, scripts mirror their log output to the caller-specified path in addition to the standard log file.
    - Older or more ad-hoc scripts at minimum support `-CaptureLogFile` and console output; new components should migrate to the shared logging helpers used by the installers above.
  - Manual downloads:
    - If manual downloads are required (e.g., MSI/ZIP/installer, standalone scripts), the script saves them under a component-scoped packages directory under the same root:
      - Packages: `<root>\packages\<component-name>\<filename>`
    - Package managers such as `winget`, `npm`, `uv`, and `pixi` are allowed to manage their own download locations; the above packages directory is only for explicit direct downloads initiated by the scripts.
  - If the component can be installed directly via a package manager other than `winget` (e.g., `npm`, `uv`) and no `winget` package exists or is appropriate, it may install directly without any explicit download step, again honoring the proxy setting.
  - For components with widely used, stable China-based mirrors (e.g., Tsinghua/USTC mirrors, domestic artifact proxies), the script should prefer the China-based source by default and fall back to the official upstream URL if the mirror is unavailable. When no reliable mirror exists, the official source is used directly.
  - To override this behavior, all installers must support a “from official” option:
    - PowerShell: a switch like `-FromOfficial` or `-UseOfficialSource`
    - When set, the script uses official URLs/repositories only; if the official source is already the default, this flag is effectively a no-op.
  - The PowerShell script should set proxy environment or command options as needed (e.g., `HTTP_PROXY`, `HTTPS_PROXY`, `winget`/`Invoke-WebRequest` options), honor `-FromOfficial` / `-Proxy` / `-AcceptDefaults` / `-Force`, and support `-CaptureLogFile`.

### `config-comp.ps1`

- Purpose: Apply post-install configuration for the component (for example, setting mirrors for `uv`/`pixi`/`nodejs`/`bun`).
- Files: `config-comp.ps1` (plus optional `.bat` wrapper).
- Arguments: Component-specific (e.g., API keys, paths, profile names). Each `.ps1` should:
  - Document its parameters via comment-based help.
  - Support an optional `-CaptureLogFile`.
  - Expose a "say yes" switch for accepting defaults.
- In addition to the generic `config-comp.ps1`, some components expose more focused configuration helpers that follow the same conventions, e.g.:
  - `components\claude-code-cli\config-skip-login.ps1`
  - `components\claude-code-cli\config-custom-api-key.ps1`
  - `components\claude-code-cli\config-context7-mcp.ps1`
  - `components\claude-code-cli\config-tavily-mcp.ps1`
  - `components\codex-cli\config-custom-api-key.ps1`
  - `components\codex-cli\config-context7-mcp.ps1`
  - `components\codex-cli\config-tavily-mcp.ps1`

## Component-Specific Scripts

A component directory may also contain additional helpers (e.g., `reset-comp.ps1`, `test-comp.ps1`, `export-comp-config.ps1`, `install-vscode-app.ps1`, `install-extensions.ps1`). These scripts are free-form but should:

- Keep naming consistent (`*-comp.*` or clear verbs like `install-*` / `config-*` where it makes sense).
- Use `-WhatIf` or dry-run options for destructive operations.
- Log clearly to the console and, where practical, reuse the shared logging helpers so output ends up in `lanren-cache`.

## Current Components (summary)

As of this version of the repo, the following components live under `components/`:

- `aria2/` – installs the `aria2c` command-line download utility.
- `bun/` – installs the Bun JavaScript runtime and optionally configures npm registry mirrors (`config-comp.ps1`).
- `claude-code-cli/` – installs the Anthropic Claude Code CLI and provides configuration helpers for skipping onboarding, setting custom API endpoints, and wiring Context7/Tavily MCP.
- `codex-cli/` – installs the OpenAI Codex CLI and provides configuration helpers for custom API endpoints and Context7/Tavily MCP.
- `git/` – installs Git for Windows.
- `jq/` – installs the `jq` JSON command-line processor.
- `markitdown/` – installs the MarkItDown document-to-Markdown tool (via `uv`).
- `nodejs/` – installs Node.js (LTS preferred) and optionally configures npm registry mirrors (`config-comp.ps1`).
- `pixi/` – installs the `pixi` environment manager and can configure conda/PyPI mirrors (`config-comp.ps1`).
- `powershell-7/` – installs PowerShell 7.
- `uv/` – installs the `uv` Python toolchain and can configure PyPI mirrors (`config-comp.ps1`).
- `vscode/` – installs VS Code itself (`install-vscode-app.*`) and, optionally, a curated extensions set (`install-extensions.*`).
- `winget/` – ensures the Windows Package Manager (`winget`) is present.
- `yq/` – installs the `yq` YAML/JSON/XML processor.

For detailed behavior, flags, and mirror choices, see the `README.md` inside each component subdirectory.
