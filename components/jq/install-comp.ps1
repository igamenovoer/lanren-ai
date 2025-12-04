<#
.SYNOPSIS
Installs jq (command-line JSON processor) on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, downloads
the Windows jq binary from official GitHub releases and adds it to PATH.

.PARAMETER Proxy
Optional HTTP/HTTPS proxy URL to use for winget and downloads.

.PARAMETER AcceptDefaults
When specified, passes non-interactive flags to winget where applicable.

.PARAMETER FromOfficial
When specified, ensures downloads come from official GitHub releases instead
of other mirrors.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using the
console default encoding so a .bat wrapper can print it.
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

$lines = @()
$lines += ""
$lines += "=== Installing jq (JSON processor) ==="
$lines += ""

function Write-OutputLines {
    param(
        [string[]]$Content,
        [string]$LogFile
    )

    if ($LogFile) {
        $Content -join "`r`n" | Out-File -FilePath $LogFile -Encoding Default -Force
    } else {
        $Content | ForEach-Object { Write-Host $_ }
    }
}

function Ensure-ToolOnPath {
    param(
        [string]$CommandName
    )
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$cmd
}

function Add-DirectoryToUserPath {
    param(
        [string]$Directory
    )

    $current = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($current -and $current.Split(";") -contains $Directory) {
        return
    }

    if ($current) {
        $newPath = "$current;$Directory"
    } else {
        $newPath = $Directory
    }

    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}

try {
    if ((Ensure-ToolOnPath -CommandName "jq") -and -not $Force) {
        $lines += "jq is already available on PATH. Use -Force to reinstall."
        $lines += "No installation performed."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for winget/network: $Proxy"
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    $installed = $false

    if ($wingetCmd) {
        $args = @("install","-e","--id","jqlang.jq")
        if ($AcceptDefaults) {
            $args += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($args -join ' ')"
        & winget @args
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Ensure-ToolOnPath -CommandName "jq")) {
            $lines += "jq installed successfully via winget."
            $installed = $true
        } else {
            $lines += "winget install for jq did not complete successfully (exit code $exitCode)."
        }
    } else {
        $lines += "winget is not available; attempting direct jq binary download."
    }

    if (-not $installed) {
        $downloadUrl = "https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
        $tempDir = [System.IO.Path]::GetTempPath()
        $tempFile = Join-Path $tempDir "jq-win64.exe"

        $lines += "Downloading jq from: $downloadUrl"
        $invokeParams = @{
            Uri             = $downloadUrl
            OutFile         = $tempFile
            UseBasicParsing = $true
        }
        if ($Proxy) {
            $invokeParams["Proxy"] = $Proxy
            $invokeParams["ProxyUseDefaultCredentials"] = $true
        }

        Invoke-WebRequest @invokeParams

        $toolsDir = Join-Path ${env:ProgramFiles} "jq"
        if (-not (Test-Path $toolsDir)) {
            New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        }

        $target = Join-Path $toolsDir "jq.exe"
        Copy-Item -Path $tempFile -Destination $target -Force

        Add-DirectoryToUserPath -Directory $toolsDir

        if (-not (Ensure-ToolOnPath -CommandName "jq")) {
            $lines += "jq binary was installed, but PATH may not reflect it yet."
            $lines += "You may need to restart your shell or sign out and back in."
        } else {
            $lines += "jq installed successfully to $toolsDir and added to user PATH."
        }
    }
} catch {
    $lines += "Error installing jq: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0

