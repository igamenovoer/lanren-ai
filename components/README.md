# Components Directory

The `components/` directory is a home for per-component installers and helpers. Each component (library, tool, or piece of software) gets its own subdirectory under `components/`, and that subdirectory contains the scripts and assets needed to download, install, and configure it.

Example structure:

- `components/vscode/`
- `components/docker-desktop/`
- `components/claude-code-cli/`

## Standard Scripts per Component

Each component subdirectory contains a PowerShell installer script.
- The `.ps1` script is standalone-callable (including from PowerShell/VSCode).
- **Important:** Before running any `.ps1` scripts, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.
- Per-component installers should be **self-contained** within their own directory under `components/` and must not depend on scripts located elsewhere in the repository (for example, do not call helpers under `scripts\` from `components\claude-code-cli\install-comp.ps1`; instead, embed the necessary logic directly in the per-component installer).

Where possible, component subdirectories should expose the following standard tools:

### `install-comp.ps1`

- Purpose: Perform the actual installation from a prepared directory.
- Files: `install-comp.ps1`.
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
  - Logging:
    - Every `install-comp.ps1` and `config-comp.ps1` writes its log output to a component-scoped file under the system temp directory:
      - Logs: `<system-temp>\lanren-ai\logs\<component-name>\<timestamp>.log`
    - When `-CaptureLogFile` is provided, scripts continue to mirror their log output to the caller-specified path in addition to the standard log file.
  - Manual downloads:
    - If manual downloads are required (e.g., MSI/ZIP/installer, standalone scripts), the script saves them under a component-scoped packages directory:
      - Packages: `<system-temp>\lanren-ai\packages\<component-name>\<filename>`
    - Package managers such as `winget`, `npm`, `uv`, and `pixi` are allowed to manage their own download locations; the above packages directory is only for explicit direct downloads initiated by the scripts.
  - If the component can be installed directly via a package manager other than `winget` (e.g., `npm`, `uv`) and no `winget` package exists or is appropriate, it may install directly without any explicit download step, again honoring the proxy setting.
  - For components with widely used, stable China-based mirrors (e.g., Tsinghua/USTC mirrors, domestic artifact proxies), the script should prefer the China-based source by default and fall back to the official upstream URL if the mirror is unavailable. When no reliable mirror exists, the official source is used directly.
  - To override this behavior, all installers must support a “from official” option:
    - PowerShell: a switch like `-FromOfficial` or `-UseOfficialSource`
    - When set, the script uses official URLs/repositories only; if the official source is already the default, this flag is effectively a no-op.
  - The PowerShell script should set proxy environment or command options as needed (e.g., `HTTP_PROXY`, `HTTPS_PROXY`, `winget`/`Invoke-WebRequest` options), honor `-FromOfficial` / `-Proxy` / `-AcceptDefaults` / `-Force`, and support `-CaptureLogFile`.

### `config-comp.ps1`

- Purpose: Apply post-install configuration for the component.
- Files: `config-comp.ps1`.
- Arguments: Component-specific (e.g., API keys, paths, profile names). Each `.ps1` must document its parameters via comment-based help, support an optional `-CaptureLogFile`, and expose a "say yes" switch for accepting defaults.

## Component-Specific Scripts

A component directory may also contain additional helpers (e.g., `reset-comp.ps1`, `test-comp.ps1`, `export-comp-config.ps1`). These scripts are free-form but should:

- Keep naming consistent (`*-comp.*` where it makes sense).
- Use `-WhatIf` or dry-run options for destructive operations.
- Log clearly to the console.
