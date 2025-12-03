@echo off
setlocal

:: skip-cc-login.bat
:: Windows batch launcher for:
::   skip-cc-login.ps1
:: Configures Claude Code CLI to skip the onboarding/login flow
:: by updating the per-user .claude.json file.
::
:: Notes:
:: - Runs the PowerShell script with ExecutionPolicy Bypass so it
::   works even when script execution is restricted.
:: - Does NOT require administrator privileges; the script only
::   touches files in the current user's profile.

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%skip-cc-login.ps1"

if not exist "%PS1_FILE%" (
    echo [skip-cc-login.bat] ERROR: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    endlocal & exit /b 1
)

echo.
echo Skipping Claude Code onboarding/login for the current user...
echo.

:: Prefer PowerShell 7 (pwsh) when available
set "PS_CMD="
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PS_CMD=pwsh"
) else (
    set "PS_CMD=powershell"
)

:: Run the PowerShell helper with execution policy bypass
%PS_CMD% -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
    echo Skip-login helper finished with errors. Exit code: %EXITCODE%
) else (
    echo Skip-login helper completed successfully.
)

echo.
pause
endlocal & exit /b %EXITCODE%
