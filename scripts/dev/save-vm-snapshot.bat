@echo off
setlocal

rem ================================================================
rem Script:  save-vm-snapshot.bat
rem Purpose: Create a Hyper-V VM checkpoint (snapshot) and optionally
rem          record its metadata to a host-side file.
rem Usage:   save-vm-snapshot.bat <VM-NAME> [CKPT-METADATA-FILE] ^
rem          [--ckpt-name <CHECKPOINT-NAME>] ^
rem          [--ckpt-type <Standard|Production|ProductionOnly>]
rem Example: save-vm-snapshot.bat win10-test .\tmp\win10-test-ckpt.txt ^
rem          --ckpt-name BeforeTools --ckpt-type Production
rem Notes:   Elevates to admin if needed and calls save-vm-snapshot.ps1.
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%save-vm-snapshot.ps1"

rem --- Parse arguments ---
set "VM_NAME="
set "CKPT_META="
set "CKPT_NAME="
set "CKPT_TYPE="

:parse_args
if "%~1"=="" goto args_done

if "%VM_NAME%"=="" (
    set "VM_NAME=%~1"
    shift
    goto parse_args
)

if /I "%~1"=="--ckpt-name" (
    set "CKPT_NAME=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--ckpt-type" (
    set "CKPT_TYPE=%~2"
    shift
    shift
    goto parse_args
)

if "%CKPT_META%"=="" (
    set "CKPT_META=%~1"
    shift
    goto parse_args
)

echo Unknown argument: %~1
echo Usage: %~nx0 ^<VM-NAME^> [CKPT-METADATA-FILE] [--ckpt-name ^<NAME^>] [--ckpt-type ^<TYPE^>]
echo.
endlocal & exit /b 1

:args_done

if "%VM_NAME%"=="" (
    echo Usage: %~nx0 ^<VM-NAME^> [CKPT-METADATA-FILE] [--ckpt-name ^<NAME^>] [--ckpt-type ^<TYPE^>]
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

rem Expand metadata file path to an absolute path (if provided)
if not "%CKPT_META%"=="" (
    for %%I in ("%CKPT_META%") do set "CKPT_META=%%~fI"
)

rem Generate a unique temp log file name
for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-save-vm-snapshot-%LOG_ID%.log"

rem Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges to create a checkpoint for VM "%VM_NAME%"...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $vm = '%VM_NAME%'; $meta = '%CKPT_META%'; $ckptName = '%CKPT_NAME%'; $ckptType = '%CKPT_TYPE%';" ^
        " $argsList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1,'-VMName',$vm);" ^
        " if (-not [string]::IsNullOrWhiteSpace($meta)) { $argsList += @('-MetadataFile',$meta) }" ^
        " if (-not [string]::IsNullOrWhiteSpace($ckptName)) { $argsList += @('-CheckpointName',$ckptName) }" ^
        " if (-not [string]::IsNullOrWhiteSpace($ckptType)) { $argsList += @('-CheckpointType',$ckptType) }" ^
        " $argsList += @('-CaptureLogFile',$out);" ^
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
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -VMName "%VM_NAME%" -MetadataFile "%CKPT_META%" -CheckpointName "%CKPT_NAME%" -CheckpointType "%CKPT_TYPE%" -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%
