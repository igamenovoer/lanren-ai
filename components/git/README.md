# Git (Git for Windows)

> **Note:** Before running the `.ps1` script, please run the `<workspace>/enable-ps1-permission.bat` script once to allow PowerShell script execution.

This component installs Git for Windows.

## Preferred installation (winget)

- Recommended command:
  ```powershell
  winget install -e --id Git.Git
  ```
- This uses the official Git for Windows package maintained in the winget repository.

## China-friendly installation (mirrors)

If you need an offline installer or winget is slow, you can use Chinese mirrors:

- **Tsinghua University mirror (GitHub releases for Git for Windows)**  
  - https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/
- **npmmirror (Taobao) mirror**  
  - https://npmmirror.com/mirrors/git-for-windows/

A typical flow:

1. Download the appropriate `.exe` from one of the mirrors.
2. Install silently with:
   ```powershell
   .\Git-*-64-bit.exe /VERYSILENT /NORESTART
   ```
3. Ensure `git` is available in `PATH`.

Our `install-comp` script for Git will:

- Prefer `winget install -e --id Git.Git`.
- If a direct installer is needed, try Tsinghua/npmmirror first, then fall back to `https://gitforwindows.org/`.
- Honor `--proxy / -Proxy` and `--from-official` (forcing direct download from official Git for Windows URLs).

## Official installation

- Official downloads:
  - https://gitforwindows.org/
- When `--from-official` is used, the installer skips domestic mirrors and pulls directly from the official site or via winget.

