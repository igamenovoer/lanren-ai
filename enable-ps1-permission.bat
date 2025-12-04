@echo off
setlocal

:: enable-ps1-permission.bat
:: Sets PowerShell execution policy to Unrestricted for the current user.
:: After running this, you can execute any .ps1 scripts without policy errors.
:: Does NOT require administrator privileges.
::
:: Policy levels:
::   Restricted     - No scripts can run (default on some systems)
::   AllSigned      - Only signed scripts can run
::   RemoteSigned   - Local scripts can run; downloaded scripts need signature
::   Unrestricted   - All scripts can run (warns for downloaded scripts)
::   Bypass         - Nothing is blocked, no warnings
::
:: We use Unrestricted to allow all scripts including downloaded/non-signed ones.

echo.
echo ============================================================
echo   PowerShell Execution Policy Configuration
echo ============================================================
echo.
echo This will set the execution policy to "Unrestricted" for
echo the current user, allowing ALL .ps1 scripts to run
echo (including downloaded and non-signed scripts).
echo.
echo Current policy:

:: Show current policy
powershell -NoProfile -Command "Get-ExecutionPolicy -Scope CurrentUser"

echo.
echo Press any key to set policy to Unrestricted, or Ctrl+C to cancel...
pause >nul

:: Set execution policy for current user (does not require admin)
powershell -NoProfile -Command "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Execution policy set to Unrestricted for current user.
    echo.
    echo New policy:
    powershell -NoProfile -Command "Get-ExecutionPolicy -Scope CurrentUser"
) else (
    echo.
    echo [ERROR] Failed to set execution policy. Exit code: %ERRORLEVEL%
)

echo.
echo ============================================================
echo   Done. You can now run .ps1 scripts without policy errors.
echo ============================================================
echo.
pause
endlocal
