@echo off
setlocal

rem ================================================================
rem Script:  list-vm.bat
rem Purpose: List running Hyper-V VMs (Name, State) on this host.
rem Usage:   list-vm.bat
rem Notes:   Elevates to admin if needed and uses list-vm.ps1 under
rem          the hood; output is printed back into this console.
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%list-vm.ps1"

rem Generate a unique temp log file name
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\\lanren-list-vm-%LOG_ID%.log"

rem Ensure the PowerShell script exists
if not exist "%PS1_FILE%" (
    echo Error: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    exit /b 1
)

rem Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges to query Hyper-V...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-CaptureLogFile',$out)"

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
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
