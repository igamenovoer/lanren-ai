@echo off
setlocal

:: add-custom-api-for-cc.bat
:: Windows batch wrapper for the Bash script:
::   add-custom-api-for-cc.sh
:: It forwards all arguments to the Bash script so you can run
:: the Linux-style helper from a double-click or cmd.exe.
::
:: Requirements:
::   - Git Bash or another Bash implementation available on Windows
::     (e.g. "C:\Program Files\Git\bin\bash.exe" or bash in PATH)

set "SCRIPT_DIR=%~dp0"
set "BASH_SCRIPT=%SCRIPT_DIR%add-custom-api-for-cc.sh"

if not exist "%BASH_SCRIPT%" (
    echo [%~nx0] ERROR: Cannot find Bash script:
    echo   "%BASH_SCRIPT%"
    echo Please ensure add-custom-api-for-cc.sh exists next to this .bat file.
    endlocal & exit /b 1
)

set "BASH_EXE="

:: Prefer Git Bash if installed in the default location
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
) else if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
    set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"
)

:: Fallback: any bash in PATH
if not defined BASH_EXE (
    where bash >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set "BASH_EXE=bash"
    )
)

if not defined BASH_EXE (
    echo [%~nx0] ERROR: Could not find a usable 'bash' on this system.
    echo Install Git for Windows (which includes Git Bash), or run:
    echo   bash "%BASH_SCRIPT%" [args...]
    endlocal & exit /b 1
)

echo Running add-custom-api-for-cc.sh via "%BASH_EXE%"...
echo.
"%BASH_EXE%" "%BASH_SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%

