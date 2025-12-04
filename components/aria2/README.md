# aria2 (command-line download utility)

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs [`aria2`](https://aria2.github.io/), a lightweight multi-protocol & multi-source command-line download utility.

## Preferred installation (winget)

- Official package:
  ```powershell
  winget install -e --id aria2.aria2
  ```
- This uses the official aria2 package maintained in the winget repository.

## Manual installation

- If `winget` is unavailable or fails, you can manually install aria2:
  1. Go to the [GitHub Releases page](https://github.com/aria2/aria2/releases).
  2. Download the latest Windows 64-bit zip file (e.g., `aria2-1.37.0-win-64bit-build1.zip`).
  3. Extract the contents to a folder (e.g., `C:\Tools\aria2`).
  4. Add the folder path to your system's `PATH` environment variable.
  5. Restart your terminal to verify `aria2c` is available.

## Usage

Once installed, you can use `aria2c` from the command line.
```powershell
aria2c https://example.com/file.zip
```
