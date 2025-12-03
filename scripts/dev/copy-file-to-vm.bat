@echo off
setlocal

rem ================================================================
rem Script:  copy-file-to-vm.bat
rem Purpose: Copy a single file from the Hyper-V host into a guest VM
rem          using Copy-VMFile and the Guest Service Interface.
rem Usage:   copy-file-to-vm.bat <VM-NAME> <HOST-FILE-PATH> <VM-DESTINATION-PATH>
rem Example: copy-file-to-vm.bat win10-test .\README.md ^
rem          "C:\Users\Public\Desktop\Lanren-README.md"
rem Notes:   Elevates to admin if needed and calls copy-file-to-vm.ps1.
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%copy-file-to-vm.ps1"

rem --- Parse positional arguments ---
set "VM_NAME=%~1"
set "HOST_PATH=%~2"
set "VM_DEST=%~3"

if "%VM_NAME%"=="" (
    echo Usage: %~nx0 ^<VM-NAME^> ^<HOST-FILE-PATH^> ^<VM-DESTINATION-PATH^>
    echo Example: %~nx0 win10-test ".\AGENTS.md" "C:\Temp\AGENTS.md"
    echo.
    endlocal & exit /b 1
)

if "%HOST_PATH%"=="" (
    echo Usage: %~nx0 ^<VM-NAME^> ^<HOST-FILE-PATH^> ^<VM-DESTINATION-PATH^>
    echo.
    endlocal & exit /b 1
)

if "%VM_DEST%"=="" (
    echo Usage: %~nx0 ^<VM-NAME^> ^<HOST-FILE-PATH^> ^<VM-DESTINATION-PATH^>
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

rem Expand host path to an absolute path
for %%I in ("%HOST_PATH%") do set "HOST_PATH=%%~fI"

rem Generate a unique temp log file name
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-copy-file-to-vm-%LOG_ID%.log"

rem Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges to copy file into VM "%VM_NAME%"...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $vm = '%VM_NAME%'; $src = '%HOST_PATH%'; $dest = '%VM_DEST%'; Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-VMName',$vm,'-SourcePath',$src,'-DestinationPath',$dest,'-CaptureLogFile',$out)"

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
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -VMName "%VM_NAME%" -SourcePath "%HOST_PATH%" -DestinationPath "%VM_DEST%" -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
