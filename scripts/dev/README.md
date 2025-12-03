# Dev Hyper-V Helper Scripts

This directory contains small, task-focused helpers for working with Hyper-V VMs from a Windows host. Each helper has a PowerShell implementation (`.ps1`) and a batch wrapper (`.bat`) that handles elevation and log capture.

## Prerequisites

- Windows 10/11 with Hyper-V enabled.
- Run from an elevated context (the `.bat` wrappers will request admin via UAC if needed).
- Hyper-V PowerShell module available (`Get-VM`, `Copy-VMFile`, etc.).

## Scripts

### `list-vm.*`

- Purpose: List running Hyper-V virtual machines on this host.
- Usage:
  - Batch: `scripts\dev\list-vm.bat`
  - PowerShell: `.\scripts\dev\list-vm.ps1`
- Notes: Shows `Name` and `State` for VMs with `State -eq 'Running'`.

### `enable-guest-service-integration.*`

- Purpose: Enable the “Guest Service Interface” integration service for a VM (required for `Copy-VMFile`).
- Usage:
  - Batch: `scripts\dev\enable-guest-service-integration.bat --vm-name <VM-NAME>`
  - PowerShell: `.\scripts\dev\enable-guest-service-integration.ps1 -VMName <VM-NAME>`
- Example:
  - `scripts\dev\enable-guest-service-integration.bat --vm-name win10-test`

### `copy-file-to-vm.*`

- Purpose: Copy a single file from the host into a running Hyper-V VM using `Copy-VMFile`.
- Usage:
  - Batch: `scripts\dev\copy-file-to-vm.bat <VM-NAME> <HOST-FILE-PATH> <VM-DESTINATION-PATH>`
  - PowerShell: `.\scripts\dev\copy-file-to-vm.ps1 -VMName <VM-NAME> -SourcePath <HOST-PATH> -DestinationPath <VM-PATH>`
- Examples:
  - Copy README to Public Desktop:  
    `scripts\dev\copy-file-to-vm.bat win10-test .\README.md "C:\Users\Public\Desktop\Lanren-README.md"`
  - Copy from PowerShell:  
    `.\scripts\dev\copy-file-to-vm.ps1 -VMName win10-test -SourcePath .\README.md -DestinationPath 'C:\Temp'`

## Logging and Elevation Pattern

- The `.bat` wrappers:
  - Detect admin via `net session` and relaunch with UAC if required.
  - Generate a unique `%TEMP%\lanren-<tool>-<GUID>.log` for each run.
  - Call the corresponding `.ps1` with `-CaptureLogFile` and then `type` and delete the log.
- The `.ps1` scripts:
  - Accept `-CaptureLogFile` (optional) and write output with `-Encoding Default` so logs can be printed cleanly in `cmd.exe`.
  - When run directly without `-CaptureLogFile`, they just write to the console.

