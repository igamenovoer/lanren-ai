# jq (command-line JSON processor)

This component installs [`jq`](https://jqlang.org/), a lightweight and flexible command-line JSON processor.

## Preferred installation (winget)

- Official package:
  ```powershell
  winget install -e --id jqlang.jq
  ```
- This uses the official jq package maintained in the winget repository and is typically the easiest and most reliable way to install jq on Windows.

## China-friendly installation

- jq binaries are relatively small and are hosted on multiple mirrors. If `winget` is slow or blocked:
  - You can download the Windows binary directly from:
    - Official downloads: https://jqlang.org/download/
    - GitHub releases: https://github.com/jqlang/jq/releases
    - SourceForge mirror: https://sourceforge.net/projects/stedolan-jq.mirror/
  - Save `jq-win64.exe` into a directory on your `PATH` (for example, `C:\Tools\jq\jq.exe`) and add that directory to `PATH`.
- Our `install-comp` script will:
  - Prefer `winget install -e --id jqlang.jq` when possible.
  - If needed, download `jq-win64.exe` into a system temp directory via a proxy or HTTPS (using `--proxy / -Proxy`).
  - Move or copy the binary into a standard tools directory (for example `%ProgramFiles%\jq\jq.exe` or a configurable tools root) and ensure it is reachable via `PATH`.
  - Honor `--from-official` by downloading from the official jq release URLs instead of third-party mirrors.

## Official installation

- jq download page:
  - https://jqlang.org/download/
- Windows installers/binaries:
  - https://github.com/jqlang/jq/releases

