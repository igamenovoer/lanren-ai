# yq (YAML/JSON/XML processor)

This component installs [`yq`](https://github.com/mikefarah/yq), a lightweight and portable command-line YAML, JSON, and XML processor.

## Preferred installation (winget)

- Official package:
  ```powershell
  winget install -e --id MikeFarah.yq
  ```
- This uses the official yq package maintained in the winget repository.

## China-friendly installation

- If `winget` is slow or blocked, you can download the yq binary directly and add it to `PATH`:
  - Official releases: https://github.com/mikefarah/yq/releases
  - Download the appropriate `yq_windows_amd64.exe` (or `_arm64`) and rename it to `yq.exe`, then place it in a tools directory that is on your `PATH` (for example `C:\Tools\yq\yq.exe`).
- Our `install-comp` script will:
  - Prefer `winget install -e --id MikeFarah.yq` when possible.
  - As a fallback, download the Windows binary into a system temp directory (honoring `--proxy / -Proxy`), move it into a standard tools directory, and ensure that directory is on `PATH`.
  - Honor `--from-official` by downloading from the official GitHub releases instead of any local mirrors.

## Official installation

- yq project and releases:
  - https://github.com/mikefarah/yq
  - https://github.com/mikefarah/yq/releases

