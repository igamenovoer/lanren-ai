@echo off
setlocal

:: install-everything.bat
:: One-click sequential installer for all recommended components in this repo.
:: High-level steps:
::   1. Relax PowerShell execution policy (calls enable-ps1-permission.bat)
::   2. Install winget, PowerShell 7, VS Code
::   3. Install jq / yq / git
::   4. Install uv / pixi / nodejs / bun / aria2
::   5. Install Claude Code CLI, Codex CLI, Context7 MCP, MarkItDown
:: Notes:
::   - Each child installer is designed to be idempotent; re-running is usually safe.
::   - Some steps require network access; make sure you can reach the internet or a mirror.

set "ROOT=%~dp0"

echo.
echo ============================================================
echo   Lanren AI - Install all components
echo ============================================================
echo Root directory: %ROOT%
echo.
echo This script will install, in the same order as the README:
echo   - winget / PowerShell 7 / VS Code
echo   - jq / yq / git
echo   - uv / pixi / nodejs / bun / aria2
echo   - Claude Code CLI / Codex CLI / Context7 MCP / MarkItDown
echo.
echo It is recommended to close heavy disk-usage programs
echo (large downloads, games, etc.) before running.
echo.
echo Press any key to start, or Ctrl+C to cancel...
pause >nul

:: Helper: run a single step script if it exists
:run_step
rem %1 = script path, %2 = short description
set "STEP_SCRIPT=%~1"
set "STEP_DESC=%~2"

echo.
echo ------------------------------------------------------------
echo [STEP] %STEP_DESC%
echo [FILE] %STEP_SCRIPT%

if not exist "%STEP_SCRIPT%" (
    echo [WARN] Script file not found, skipping this step.
    goto :eof
)

call "%STEP_SCRIPT%"
set "STEP_CODE=%ERRORLEVEL%"

if not "%STEP_CODE%"=="0" (
    echo [WARN] Step script exited with error code: %STEP_CODE%
    echo        If this is due to a transient network issue or mirror failure,
    echo        you can retry this component later from its components\... folder.
    echo        Press any key to continue with the next step, or Ctrl+C to abort.
    pause >nul
) else (
    echo [OK] Step completed successfully.
)

goto :eof

:: 1. Set execution policy (allow running .ps1 for current user)
call :run_step "%ROOT%enable-ps1-permission.bat" "Set PowerShell execution policy (CurrentUser)"

:: 2. Install winget / PowerShell 7 / VS Code
call :run_step "%ROOT%components\winget\install-comp.bat"        "Install winget (Windows Package Manager)"
call :run_step "%ROOT%components\powershell-7\install-comp.bat"  "Install PowerShell 7"
call :run_step "%ROOT%components\vscode\install-vscode-app.bat"  "Install VS Code editor"
call :run_step "%ROOT%components\vscode\install-extensions.bat"  "Install VS Code recommended extensions"

:: 3. Install common CLI tools
call :run_step "%ROOT%components\jq\install-comp.bat"            "Install jq (JSON tool)"
call :run_step "%ROOT%components\yq\install-comp.bat"            "Install yq (YAML tool)"
call :run_step "%ROOT%components\git\install-comp.bat"           "Install Git (version control)"

:: 4. Install development runtimes / package managers
call :run_step "%ROOT%components\uv\install-comp.bat"            "Install uv (Python toolchain)"
call :run_step "%ROOT%components\pixi\install-comp.bat"          "Install pixi (Conda environment tool)"
call :run_step "%ROOT%components\nodejs\install-comp.bat"        "Install Node.js and npm"
call :run_step "%ROOT%components\bun\install-comp.bat"           "Install Bun (JS runtime)"
call :run_step "%ROOT%components\aria2\install-comp.bat"         "Install aria2 (download helper, optional)"

:: 5. Install AI CLIs and MCP-related components
call :run_step "%ROOT%components\claude-code-cli\install-comp.bat" "Install Claude Code CLI"
call :run_step "%ROOT%components\codex-cli\install-comp.bat"       "Install OpenAI Codex CLI"
call :run_step "%ROOT%components\context7-mcp\install-comp.bat"    "Install Context7 MCP"
call :run_step "%ROOT%components\markitdown\install-comp.bat"      "Install MarkItDown"

echo.
echo ============================================================
echo   All bulk install steps have finished.
echo ============================================================
echo.
echo - If any step failed, please open the corresponding
echo   components\...\ folder and re-run its install-comp.bat manually.
echo - Next, you can follow the README to optionally run
echo   claude-code-cli / codex-cli config-*.bat scripts for extra setup.
echo.
echo Press any key to exit this installer...
pause >nul

endlocal
exit /b 0
