# Visual Studio Code

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs Visual Studio Code.

## Preferred installation (winget)

- Recommended command:
  ```powershell
  winget install -e --id Microsoft.VisualStudioCode
  ```

This installs VS Code via the official Microsoft installer.

## China-friendly installation (CDN)

- Microsoft provides a China CDN for VS Code downloads:
  - `https://vscode.cdn.azure.cn/`
- If `winget` is slow, you can:
  1. Download the VS Code installer from the China CDN (or from the official site, which may redirect to a regional CDN).
  2. Run the installer silently:
     ```powershell
     .\VSCodeUserSetup-*.exe /VERYSILENT /NORESTART /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"
     ```
- Our `install-comp` script will:
  - Prefer `winget install -e --id Microsoft.VisualStudioCode` with an appropriate `/override` to ensure non-interactive install, Explorer context menus, and PATH integration, for example:
    ```powershell
    winget install --force Microsoft.VisualStudioCode --override '/VERYSILENT /SP- /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"'
    ```
  - If `winget` does not expose the required options in a given environment, fall back to downloading the installer and running it with `/MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"` so that:
    - “Open with Code” appears in the file and folder context menus.
    - VS Code is added to `PATH`.
  - When a direct download is required, use the China CDN first when appropriate, then fall back to `https://code.visualstudio.com/Download`.
  - Respect `--proxy / -Proxy` and `--from-official` (forcing direct use of `code.visualstudio.com`).

## Official installation

- Official download:
  - https://code.visualstudio.com/Download

## Linux/macOS (POSIX) scripts

- Install VS Code + extensions:
  ```bash
  cd components/vscode
  sh ./install-comp.sh --dry-run
  sh ./install-comp.sh --accept-defaults
  ```
- Notes:
  - Installing the `code` CLI may require a manual step on macOS: VS Code → Command Palette → “Shell Command: Install 'code' command in PATH”.
