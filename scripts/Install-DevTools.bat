@echo off
setlocal

:: Lanren AI - Batch launcher for the common-pack PowerShell installer
:: - Requests administrative privileges if needed
:: - Runs install-common-pack.ps1 with ExecutionPolicy Bypass

:: Determine the directory of this script
set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%install-common-pack.ps1"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoLogo -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Verify the PowerShell installer script exists
if not exist "%PS1_FILE%" (
    echo Error: PowerShell installer not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    exit /b 1
)

echo.
echo Running Lanren AI Common Pack installer...
echo (This may take several minutes.)
echo.

:: Run the PowerShell installer with execution policy bypass
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if %EXITCODE% neq 0 (
    echo Installer finished with errors. Exit code: %EXITCODE%
) else (
    echo Installer completed successfully.
)

echo.
pause
endlocal & exit /b %EXITCODE%

