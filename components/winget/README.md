# Windows Package Manager (winget)

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component ensures the Windows Package Manager (`winget`) is available, as many other components prefer winget when possible.

## Preferred installation (official)

- On most modern Windows 10/11 systems, winget is installed via the **App Installer** package from Microsoft Store.
- To install or update App Installer:
  - Open Microsoft Store and search for “App Installer”.
  - Or download the latest `AppInstaller.msixbundle` from:
    - https://aka.ms/getwinget

## China-friendly installation

- There is no widely recognized China mirror for winget itself; App Installer is distributed directly by Microsoft.
- For slow or restricted networks:
  - Use `--proxy / -Proxy` so our scripts can download `AppInstaller.msixbundle` through your HTTP/HTTPS proxy.
  - If necessary, pre-download the `.msixbundle` via an enterprise mirror or local file server and let the installer add it with `Add-AppxPackage`.

Our `install-comp` script for winget will:

- Detect whether `winget` is already available (`Get-Command winget`).
- If not present, download App Installer from `https://aka.ms/getwinget` and install it.
- Respect `--proxy` and `--from-official` (always effective here, since Microsoft is the only upstream).

## Official references

- Winget docs: https://learn.microsoft.com/windows/package-manager/winget/

