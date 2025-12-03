@echo off
setlocal

:: Lanren AI - CN batch launcher (ASCII only)
:: - Requests administrative privileges
:: - Runs install-common-pack-cn.ps1 with ExecutionPolicy Bypass

:: Script directory
set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%install-common-pack-cn.ps1"

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges... please accept the UAC prompt.
    powershell -NoLogo -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Verify the PowerShell installer script exists
if not exist "%PS1_FILE%" (
    echo ERROR: PowerShell installer script not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    exit /b 1
)

echo.
echo Running "Lanren AI Common Pack (CN)" installer...
echo This may take several minutes. Please wait...
echo.

:: Run the CN installer script with ExecutionPolicy Bypass
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" &
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
