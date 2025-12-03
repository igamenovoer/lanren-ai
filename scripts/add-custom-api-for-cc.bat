@echo off
setlocal

:: add-custom-api-for-cc.bat
:: Windows batch launcher for the PowerShell helper:
::   add-custom-api-for-cc.ps1
:: It forwards all arguments to the PowerShell script, which then
:: invokes the underlying Bash helper script.
::
:: Note: This helper only modifies files in your user profile and
:: does not require administrator privileges.

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%add-custom-api-for-cc.ps1"

if not exist "%PS1_FILE%" (
    echo [%~nx0] ERROR: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    endlocal & exit /b 1
)

echo.
echo Running Claude Code custom-API helper...
echo.

:: Choose PowerShell host:
:: - Prefer PowerShell 7 (pwsh) if available
:: - Fall back to Windows PowerShell (powershell)
set "PS_CMD="
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PS_CMD=pwsh"
) else (
    set "PS_CMD=powershell"
)

:: Run the PowerShell helper with execution policy bypass so that
:: the .ps1 script can run even if scripts are restricted.
%PS_CMD% -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" %*
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
    echo Helper finished with errors. Exit code: %EXITCODE%
) else (
    echo Helper completed successfully.
)

echo.
pause
endlocal & exit /b %EXITCODE%
