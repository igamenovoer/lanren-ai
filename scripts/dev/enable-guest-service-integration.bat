@echo off
setlocal

rem ================================================================
rem Script:  enable-guest-service-integration.bat
rem Purpose: Enable the Hyper-V "Guest Service Interface" integration
rem          service for a specific VM so Copy-VMFile and other
rem          host-to-guest operations work.
rem Usage:   enable-guest-service-integration.bat --vm-name <VM-NAME>
rem Example: enable-guest-service-integration.bat --vm-name win10-test
rem Notes:   Elevates to admin if needed and calls the companion
rem          PowerShell script enable-guest-service-integration.ps1.
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%enable-guest-service-integration.ps1"

rem Generate a unique temp log file name
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\\lanren-enable-guest-service-%LOG_ID%.log"

rem --- Parse arguments ---
set "VM_NAME="

:parse_args
if "%~1"=="" goto args_done

if /I "%~1"=="--vm-name" (
    set "VM_NAME=%~2"
    shift
    shift
    goto parse_args
)

echo Unknown argument: %~1
echo Usage: %~nx0 --vm-name ^<VM-NAME^>
echo.
endlocal & exit /b 1

:args_done

if "%VM_NAME%"=="" (
    echo Usage: %~nx0 --vm-name ^<VM-NAME^>
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
    echo Requesting administrative privileges to enable Guest Service Interface on "%VM_NAME%"...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $vm = '%VM_NAME%'; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-VMName',$vm,'-CaptureLogFile',$out)"

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
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -VMName "%VM_NAME%" -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
