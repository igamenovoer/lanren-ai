<#
.SYNOPSIS
Entry point for the VS Code component.

.DESCRIPTION
For backward compatibility, this script now orchestrates the full
VS Code setup:
- Installs the VS Code application (`install-vscode-app.ps1`)
- Configures the Explorer "Open in VS Code" context menu
  (`config-context-menu.ps1`)
- Installs common VS Code extensions (`install-extensions.ps1`)
#>

[CmdletBinding()]
param(
    [string]$Proxy,
    [switch]$AcceptDefaults,
    [switch]$FromOfficial,
    [switch]$Force,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$appScript   = Join-Path -Path $PSScriptRoot -ChildPath "install-vscode-app.ps1"
$menuScript  = Join-Path -Path $PSScriptRoot -ChildPath "config-context-menu.ps1"
$extScript   = Join-Path -Path $PSScriptRoot -ChildPath "install-extensions.ps1"

if (-not (Test-Path $appScript)) {
    Write-Error "install-vscode-app.ps1 not found in $PSScriptRoot."
    exit 1
}
if (-not (Test-Path $menuScript)) {
    Write-Error "config-context-menu.ps1 not found in $PSScriptRoot."
    exit 1
}
if (-not (Test-Path $extScript)) {
    Write-Error "install-extensions.ps1 not found in $PSScriptRoot."
    exit 1
}

& $appScript -Proxy $Proxy -AcceptDefaults:$AcceptDefaults -FromOfficial:$FromOfficial -Force:$Force -CaptureLogFile $CaptureLogFile
$appExit = $LASTEXITCODE
if ($appExit -ne 0) {
    exit $appExit
}

& $menuScript -CaptureLogFile $CaptureLogFile
$menuExit = $LASTEXITCODE
if ($menuExit -ne 0) {
    exit $menuExit
}

& $extScript -CaptureLogFile $CaptureLogFile
exit $LASTEXITCODE
