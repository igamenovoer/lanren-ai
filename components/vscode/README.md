# Visual Studio Code

This component installs Visual Studio Code.

## Preferred installation (winget)

- Recommended command:
  ```powershell
  winget install -e --id Microsoft.VisualStudioCode
  ```

This installs VS Code via the official Microsoft installer. However, depending on defaults and how the underlying setup is invoked, the Explorer context menu entries (“Open with Code” for files and folders) may not be enabled by default.

## China-friendly installation (CDN)

- Microsoft provides a China CDN for VS Code downloads:
  - `https://vscode.cdn.azure.cn/`
- If `winget` is slow, you can:
  1. Download the VS Code installer from the China CDN (or from the official site, which may redirect to a regional CDN).
  2. Run the installer silently:
     ```powershell
     .\VSCodeUserSetup-*.exe /VERYSILENT /NORESTART /MERGETASKS="addcontextmenufiles,addcontextmenufolders,addtopath"
     ```
- Our `install-comp` script will:
  - Prefer `winget install -e --id Microsoft.VisualStudioCode` with an appropriate `/override` to ensure context menu integration, for example:
    ```powershell
    winget install --force Microsoft.VisualStudioCode --override '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
    ```
  - If `winget` does not expose the required options in a given environment, fall back to downloading the installer and running it with `/MERGETASKS="addcontextmenufiles,addcontextmenufolders,addtopath"` so that:
    - “Open with Code” appears in the file and folder context menus.
    - VS Code is added to `PATH`.
  - When a direct download is required, use the China CDN first when appropriate, then fall back to `https://code.visualstudio.com/Download`.
  - Respect `--proxy / -Proxy` and `--from-official` (forcing direct use of `code.visualstudio.com`).

## Official installation

- Official download:
  - https://code.visualstudio.com/Download
