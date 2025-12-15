# PowerShell 7

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs PowerShell 7 (cross-platform PowerShell).

## Preferred installation (winget)

- Latest stable:
  ```powershell
  winget install -e --id Microsoft.PowerShell
  ```

## China-friendly installation

- PowerShell 7 packages are published by Microsoft and distributed via global CDNs; there is no widely used China-specific mirror.
- For slow or firewalled environments:
  - Prefer `winget` with a system HTTP/HTTPS proxy (`--proxy / -Proxy` in our installer).
  - Alternatively, download the MSI or `.zip` manually (using any enterprise mirror or acceleration you have) and let the installer run it.

Our `install-comp` script will:

- Prefer `winget install -e --id Microsoft.PowerShell`.
- Fall back to direct downloads from the official GitHub releases for PowerShell.
- Respect `--proxy / -Proxy` and `--from-official` (always true here, since Microsoft is the only upstream).

## Official installation

- Microsoft docs:
  - https://learn.microsoft.com/powershell/
  - https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows
- GitHub releases:
  - https://github.com/PowerShell/PowerShell/releases

## Linux/macOS (POSIX) scripts

- Install:
  ```bash
  cd components/powershell-7
  sh ./install-comp.sh --dry-run
  sh ./install-comp.sh
  ```
- Notes:
  - On macOS (Apple Silicon) it prefers Homebrew when available.
  - On Linux it installs a user-scoped `pwsh` and symlinks `~/.local/bin/pwsh`.
