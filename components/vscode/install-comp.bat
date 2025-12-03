@echo off
setlocal

rem ================================================================
rem Script:  install-comp.bat (VS Code)
rem Purpose: Install Visual Studio Code on Windows.
rem Usage:   install-comp.bat [--proxy <URL>] [--yes] [--from-official]
rem ================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%install-comp.ps1"

set "PROXY="
set "YES_FLAG="
set "FROM_OFFICIAL="

:parse_args
if "%~1"=="" goto args_done

if /I "%~1"=="--proxy" (
    set "PROXY=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--yes" (
    set "YES_FLAG=1"
    shift
    goto parse_args
)

if /I "%~1"=="--from-official" (
    set "FROM_OFFICIAL=1"
    shift
    goto parse_args
)

echo Unknown argument: %~1
echo Usage: %~nx0 [--proxy ^<URL^>] [--yes] [--from-official]
echo.
endlocal & exit /b 1

:args_done

if not exist "%PS1_FILE%" (
    echo Error: PowerShell script not found:
    echo   "%PS1_FILE%"
    echo.
    endlocal & exit /b 1
)

for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "[guid]::NewGuid().ToString()"`) do set "LOG_ID=%%G"
set "OUT_FILE=%TEMP%\lanren-vscode-install-%LOG_ID%.log"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges to install Visual Studio Code...

    powershell -NoLogo -NoProfile -Command ^
        "$ps1 = '%PS1_FILE%'; $out = '%OUT_FILE%'; $proxy = '%PROXY%'; $fromOfficial = '%FROM_OFFICIAL%'; $yes = '%YES_FLAG%';" ^
        " $argsList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$ps1);" ^
        " if (-not [string]::IsNullOrWhiteSpace($proxy)) { $argsList += @('-Proxy',$proxy) }" ^
        " if (-not [string]::IsNullOrWhiteSpace($fromOfficial)) { $argsList += @('-FromOfficial') }" ^
        " if (-not [string]::IsNullOrWhiteSpace($yes)) { $argsList += @('-AcceptDefaults') }" ^
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

set "PS_ARGS="
if not "%PROXY%"=="" set "PS_ARGS=%PS_ARGS% -Proxy \"%PROXY%\""
if not "%FROM_OFFICIAL%"=="" set "PS_ARGS=%PS_ARGS% -FromOfficial"
if not "%YES_FLAG%"=="" set "PS_ARGS=%PS_ARGS% -AcceptDefaults"

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" %PS_ARGS% -CaptureLogFile "%OUT_FILE%"
set "EXITCODE=%ERRORLEVEL%"

if exist "%OUT_FILE%" (
    type "%OUT_FILE%"
    del "%OUT_FILE%" >nul 2>&1
)

endlocal & exit /b %EXITCODE%

