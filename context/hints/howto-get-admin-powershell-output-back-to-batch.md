# How to Get Admin PowerShell Output Back to a Caller Batch File

When you start PowerShell with `Start-Process -Verb RunAs` from a `.bat`, the elevated process runs in its own console, so you cannot reliably capture its standard output directly. A simple and robust pattern is to have the elevated PowerShell script write to a uniquely named temporary file, then print that file from the original batch and delete it.

## Pattern Overview

1. Batch file:
   - Detect admin; if not admin, relaunch an elevated PowerShell that runs the real script and passes a unique log file path via `-CaptureLogFile <path>`.
   - After the elevated process exits, `type` the log file so the user sees the result in the original console, then delete it.

2. PowerShell script:
   - Accept an optional `-CaptureLogFile` parameter.
   - Accumulate human-readable lines, then either write to the log file (when provided) or to the console (when run directly).

## Example PowerShell Script

```powershell
param(
    [string]$CaptureLogFile
)

$lines = @()
$lines += "=== Some Admin Task ==="

try {
    $result = Get-VM | Where-Object State -eq 'Running' | Select-Object Name, State
    $lines += ($result | Format-Table -AutoSize | Out-String)
} catch {
    $lines += "Error: $($_.Exception.Message)"
}

if ($CaptureLogFile) {
    # Use Default (ANSI) here so 'type' in cmd.exe does not print a BOM as garbled characters
    $lines -join "`r`n" | Out-File -FilePath $CaptureLogFile -Encoding Default -Force
} else {
    $lines | ForEach-Object { Write-Host $_ }
}
```

## Example Batch Wrapper (UUID Log File)

```bat
set "PS1_FILE=%~dp0admin-task.ps1"
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\admin-task-%LOG_ID%.log"

net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoLogo -NoProfile -Command ^
    "$ps1='%PS1_FILE%'; $out='%OUT_FILE%'; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-CaptureLogFile',$out)"
  if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
  )
  exit /b
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
```

This pattern avoids temp file name collisions, cleans up after itself, and keeps the PowerShell script usable both as a standalone tool (console output only) and when called from a `.bat` that wants to capture admin output. When targeting a legacy console code page (for example on Chinese Windows), prefer `-Encoding Default` instead of UTF8 to avoid a UTF-8 BOM showing up as extra characters like `锘?` when using `type` on the log file. For related discussion on elevation patterns, see: https://superuser.com/questions/108207/how-to-run-a-powershell-script-as-administrator and https://superuser.com/questions/788924/is-it-possible-to-automatically-run-a-batch-file-as-administrator.
