@echo off
setlocal

:: add-tavily-to-claude-code.bat
:: Windows batch launcher for:
::   add-tavily-to-claude-code.ps1
:: Adds the Tavily MCP server to Claude Code CLI (user scope),
:: using Bun (bunx) as the MCP runner.

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%add-tavily-to-claude-code.ps1"

if not exist "%PS1_FILE%" (
    echo [add-tavily-to-claude-code.bat] ERROR: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    pause
    endlocal & exit /b 1
)

echo.
echo Adding Tavily MCP server to Claude Code (user scope)...
echo.

:: Prefer PowerShell 7 (pwsh) when available
set "PS_CMD="
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PS_CMD=pwsh"
) else (
    set "PS_CMD=powershell"
)

%PS_CMD% -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
    echo Tavily MCP setup finished with errors. Exit code: %EXITCODE%
) else (
    echo Tavily MCP setup completed successfully.
)

echo.
pause
endlocal & exit /b %EXITCODE%
