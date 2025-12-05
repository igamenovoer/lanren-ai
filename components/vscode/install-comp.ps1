<#
.SYNOPSIS
Entry point for the VS Code component.

.DESCRIPTION
For backward compatibility, this script now orchestrates the full
VS Code setup:
- Installs the VS Code application (`install-vscode-app.ps1`)
- Installs common VS Code extensions (`install-extensions.ps1`)

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
This is useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [string]$Proxy,
    [switch]$AcceptDefaults,
    [switch]$FromOfficial,
    [switch]$Force,
    [string]$CaptureLogFile
)
function Exit-WithWait {
    param([int]$Code = 0)
    if ($NoExit) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit $Code
}




$ErrorActionPreference = "Stop"

$appScript   = Join-Path -Path $PSScriptRoot -ChildPath "install-vscode-app.ps1"
$extScript   = Join-Path -Path $PSScriptRoot -ChildPath "install-extensions.ps1"

if (-not (Test-Path $appScript)) {
    Write-Error "install-vscode-app.ps1 not found in $PSScriptRoot."
    Exit-WithWait 1
}
if (-not (Test-Path $extScript)) {
    Write-Error "install-extensions.ps1 not found in $PSScriptRoot."
    Exit-WithWait 1
}

& $appScript -Proxy $Proxy -AcceptDefaults:$AcceptDefaults -FromOfficial:$FromOfficial -Force:$Force -CaptureLogFile $CaptureLogFile
$appExit = $LASTEXITCODE
if ($appExit -ne 0) {
    exit $appExit
}

& $extScript -CaptureLogFile $CaptureLogFile
if ($LASTEXITCODE -ne 0) {
    Exit-WithWait $LASTEXITCODE
}


Exit-WithWait 0
