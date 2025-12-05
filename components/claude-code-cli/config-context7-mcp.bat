@echo off
setlocal

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" -NoExit %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" -NoExit %*
)

endlocal

