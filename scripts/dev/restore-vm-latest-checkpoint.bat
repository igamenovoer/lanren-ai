@echo off
setlocal

rem ================================================================
rem Script:  restore-vm-latest-checkpoint.bat
rem Purpose: Restore a Hyper-V VM to its latest checkpoint (snapshot).
rem Usage:   restore-vm-latest-checkpoint.bat <VM-NAME> [--no-start]
rem Example: restore-vm-latest-checkpoint.bat win10-test
rem Notes:   Elevates to admin if needed and calls the companion
rem          PowerShell script restore-vm-latest-checkpoint.ps1.
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%restore-vm-latest-checkpoint.ps1"

rem Generate a unique temp log file name
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-restore-vm-latest-%LOG_ID%.log"

rem --- Parse arguments ---
set "VM_NAME="
set "NO_START=0"

:parse_args
if "%~1"=="" goto args_done

if "%VM_NAME%"=="" (
    set "VM_NAME=%~1"
    shift
    goto parse_args
)

if /I "%~1"=="--no-start" (
    set "NO_START=1"
    shift
    goto parse_args
)

echo Unknown argument: %~1
echo Usage: %~nx0 ^<VM-NAME^> [--no-start]
echo.
endlocal & exit /b 1

:args_done

if "%VM_NAME%"=="" (
    echo Usage: %~nx0 ^<VM-NAME^> [--no-start]
    echo.
    endlocal & exit /b 1
)

rem Ensure the PowerShell script exists
if not exist "%PS1_FILE%" (
    echo Error: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    endlocal & exit /b 1
)

rem Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges to restore latest checkpoint for "%VM_NAME%"...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $vm = '%VM_NAME%'; $noStart = %NO_START%;" ^
        " $argsList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-VMName',$vm,'-CaptureLogFile',$out);" ^
        " if ($noStart -eq 1) { $argsList += '-NoStart' }" ^
        " Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList $argsList"

    if exist "%OUT_FILE%" (
        type "%OUT_FILE%"
        del "%OUT_FILE%" >nul 2>&1
    ) else (
        echo No output received from elevated PowerShell process.
    )

    endlocal
    exit /b
)

rem Already running as admin: call PowerShell directly and capture log
if "%NO_START%"=="1" (
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -VMName "%VM_NAME%" -NoStart -CaptureLogFile "%OUT_FILE%"
) else (
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -VMName "%VM_NAME%" -CaptureLogFile "%OUT_FILE%"
)
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%

