# Paired .bat/.ps1 Script Contract

This document establishes the contract for paired `.bat` and `.ps1` scripts in this repository. The pattern addresses two common pain points on Windows:

1. **ExecutionPolicy restrictions** – Users often cannot run `.ps1` files directly due to PowerShell's default policy.
2. **Admin elevation** – Many operations (e.g., Hyper-V management) require elevated privileges, but UAC prompts spawn a new console whose output is invisible to the caller.

By following this contract, users can double-click (or call from `cmd.exe`) the `.bat` file, which handles elevation and captures output back to the original console.

---

## File Naming Convention

| PowerShell Script         | Batch Wrapper              |
|---------------------------|----------------------------|
| `<tool-name>.ps1`         | `<tool-name>.bat`          |

Both files **must** reside in the same directory so the `.bat` can locate its companion via `%~dp0`.

---

## Batch Wrapper Responsibilities (`.bat`)

### 1. Locate the companion `.ps1`

```bat
set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%<tool-name>.ps1"

if not exist "%PS1_FILE%" (
    echo Error: PowerShell script not found: "%PS1_FILE%"
    exit /b 1
)
```

### 2. Parse command-line arguments

Support positional and/or named arguments as appropriate for the tool. Validate required parameters early and print usage on error.

Every wrapper should also support a **"say yes" / non-interactive option**, typically:

- `--yes` (and optionally `-y`) to accept all default settings and suppress prompts.

When `--yes` is present, the `.bat` passes the corresponding PowerShell switch (for example, `-AcceptDefaults:$true`) to the companion `.ps1` script.

### 3. Generate a unique temp log file

Use a GUID to avoid collisions when multiple instances run concurrently:

```bat
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-<tool-name>-%LOG_ID%.log"
```

### 4. Check for administrative privileges

```bat
net session >nul 2>&1
if %errorlevel% neq 0 (
    rem Not admin – need to elevate
    ...
)
```

### 5. Elevate and capture output (non-admin path)

When elevation is required, use `Start-Process -Verb RunAs -Wait` to spawn an elevated PowerShell that writes to the temp log. After it completes, `type` the log and delete it:

```bat
powershell -NoLogo -NoProfile -Command ^
    "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; ... ; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,...,'-CaptureLogFile',$out)"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
) else (
    echo No output received from elevated PowerShell process.
)
```

### 6. Direct call when already admin

If already elevated, call the `.ps1` directly (still capturing to the log for consistency):

```bat
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" ... -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
```

### 7. Use `setlocal` / `endlocal`

Wrap all variable assignments with `setlocal` at the top and `endlocal & exit /b %EXITCODE%` at the end to avoid polluting the caller's environment.

---

## PowerShell Script Responsibilities (`.ps1`)

### 1. Accept a `-CaptureLogFile` parameter

```powershell
param(
    # ... other parameters ...
    [string]$CaptureLogFile
)
```

This parameter is **optional**. When omitted, the script writes to the console.

### 2. Accept a "say yes" / non-interactive switch

Each script should expose a switch (for example, `[switch]$AcceptDefaults` or `[switch]$YesToAll`) that signals it should:

- Use sensible defaults for all optional inputs.
- Avoid interactive prompts unless a value truly cannot be determined automatically and is required to proceed.

The batch wrapper maps `--yes` to this switch.

### 3. Collect output in an array

Instead of calling `Write-Host` throughout, accumulate messages in an array:

```powershell
$lines = @()
$lines += "=== Tool Banner ==="
$lines += ""
$lines += "Parameter1: $Value1"
...
```

### 4. Define a helper to flush output

```powershell
function Write-OutputLines {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        $Content | ForEach-Object { Write-Host $_ }
    }
}
```

**Key points:**
- Use `-Encoding Default` (system ANSI code page) so `type` in `cmd.exe` renders correctly.
- Use `"`r`n"` (CRLF) for Windows-friendly line endings.

### 5. Call `Write-OutputLines` at each exit point

Before every `exit`, flush the accumulated lines:

```powershell
Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0   # or exit 1 on error
```

### 6. Use proper exit codes

- `exit 0` on success
- `exit 1` (or another non-zero) on failure

The `.bat` wrapper captures `%ERRORLEVEL%` and propagates it.

### 7. Include standard PowerShell help

Document the script with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` blocks so users can run `Get-Help .\<tool-name>.ps1 -Full`.

---

## Template: Minimal Paired Scripts

### `example-tool.bat`

```bat
@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%example-tool.ps1"

rem --- Parse arguments (example: one required positional arg) ---
set "MY_ARG=%~1"
if "%MY_ARG%"=="" (
    echo Usage: %~nx0 ^<MY_ARG^>
    endlocal & exit /b 1
)

rem Ensure PS1 exists
if not exist "%PS1_FILE%" (
    echo Error: PowerShell script not found: "%PS1_FILE%"
    endlocal & exit /b 1
)

rem Generate unique log file
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-example-tool-%LOG_ID%.log"

rem Check admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $arg = '%MY_ARG%'; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-MyArg',$arg,'-CaptureLogFile',$out)"
    if exist "%OUT_FILE%" (
        type "%OUT_FILE%"
        del "%OUT_FILE%" >nul 2>&1
    ) else (
        echo No output received from elevated process.
    )
    endlocal
    exit /b
)

rem Already admin
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -MyArg "%MY_ARG%" -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
```

### `example-tool.ps1`

```powershell
<#
.SYNOPSIS
Example tool demonstrating the paired .bat/.ps1 contract.

.PARAMETER MyArg
A required argument for demonstration.

.PARAMETER CaptureLogFile
Optional log file path. When specified, output is written here instead of the console.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$MyArg,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Example Tool ==="
$lines += ""
$lines += "MyArg: $MyArg"
$lines += ""

function Write-OutputLines {
    param([string[]]$Content, [string]$LogFile)
    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        $Content | ForEach-Object { Write-Host $_ }
    }
}

# ... do work ...
$lines += "Work completed successfully."

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0
```

---

## Why This Pattern?

| Problem                                      | Solution                                                  |
|----------------------------------------------|-----------------------------------------------------------|
| **ExecutionPolicy blocks `.ps1` execution**  | `.bat` calls PowerShell with `-ExecutionPolicy Bypass`.   |
| **UAC spawns a separate console**            | Use `Start-Process -Verb RunAs -Wait` + temp log file.    |
| **Output lost after elevation**              | Log captured to `%TEMP%` and `type`d back to caller.      |
| **Log file collisions**                      | GUID-based filename ensures uniqueness.                   |
| **Encoding issues in `cmd.exe`**             | `-Encoding Default` matches system ANSI code page.        |

---

## Checklist for New Paired Scripts

- [ ] `.bat` and `.ps1` have matching base names and live in the same directory.
- [ ] `.bat` uses `setlocal` / `endlocal`.
- [ ] `.bat` validates required arguments and prints usage on error.
- [ ] `.bat` generates a GUID-based temp log path.
- [ ] `.bat` checks admin with `net session` and elevates if needed.
- [ ] `.bat` passes `-CaptureLogFile` in both the elevated and direct paths.
- [ ] `.bat` `type`s and `del`s the log file after execution.
- [ ] `.ps1` declares `-CaptureLogFile` as an optional `[string]` parameter.
- [ ] `.ps1` accumulates output in `$lines` and flushes via `Write-OutputLines`.
- [ ] `.ps1` uses `-Encoding Default` when writing the log file.
- [ ] `.ps1` exits with appropriate exit codes (`0` for success, non-zero for failure).
- [ ] `.ps1` includes `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` help blocks.
