<#
.SYNOPSIS
Installs yq (YAML/JSON/XML processor) on Windows.

.DESCRIPTION
Prefers installation via winget. If winget is unavailable or fails, downloads
the Windows yq binary from official GitHub releases and adds it to PATH.

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

$script:LanrenComponentName = Split-Path -Leaf $PSScriptRoot
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "yq" }

function Get-LanrenAiRoot {
    $envRoot = $env:LRAI_MASTER_OUTPUT_DIR
    if (-not [string]::IsNullOrWhiteSpace($envRoot)) {
        return $envRoot
    }

    $cwd = (Get-Location).Path
    return (Join-Path $cwd "lanren-cache")
}

function Get-LanrenComponentLogFile {
    param(
        [string]$ComponentName
    )



    if (-not $ComponentName) {
        $ComponentName = $script:LanrenComponentName
    }

    $root = Get-LanrenAiRoot
    $logDir = Join-Path $root ("logs\" + $ComponentName)
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Join-Path $logDir ("$ComponentName-$timestamp.log")
}

function Get-LanrenComponentPackagePath {
    param(
        [string]$FileName,
        [string]$ComponentName
    )



    if (-not $ComponentName) {
        $ComponentName = $script:LanrenComponentName
    }

    $root = Get-LanrenAiRoot
    $pkgDir = Join-Path $root ("packages\" + $ComponentName)
    if (-not (Test-Path $pkgDir)) {
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
    }

    if ($FileName) {
        return Join-Path $pkgDir $FileName
    }

    return $pkgDir
}

$script:LanrenDefaultLogFile = Get-LanrenComponentLogFile -ComponentName $script:LanrenComponentName
$script:LanrenLogFiles = @($script:LanrenDefaultLogFile)
if ($CaptureLogFile) {
    $script:LanrenLogFiles += $CaptureLogFile
}

$null = $FromOfficial

$lines = @()
$lines += ""
$lines += "=== Installing yq (YAML/JSON/XML processor) ==="
$lines += ""

function Write-OutputLine {
    param(
        [string[]]$Content,
        [string]$LogFile
    )



    $targets = @()
    if ($script:LanrenLogFiles) {
        $targets = $script:LanrenLogFiles
    } elseif ($LogFile) {
        $targets = @($LogFile)
    }

    if ($targets.Count -gt 0) {
        $text = $Content -join "`r`n"
        foreach ($t in $targets) {
            if (-not [string]::IsNullOrWhiteSpace($t)) {
                $dir = Split-Path -Parent $t
                if ($dir -and -not (Test-Path $dir)) {
                    New-Item -ItemType Directory -Path $dir -Force | Out-Null
                }
                $text | Out-File -FilePath $t -Encoding Default -Force
            }
        }
    } else {
        $Content | ForEach-Object { Write-Output $_ }
    }
}

function Test-ToolOnPath {
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
    if ((Test-ToolOnPath -CommandName "yq") -and -not $Force) {
        $lines += "yq is already available on PATH. Use -Force to reinstall."
        $lines += "No installation performed."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    }

    if ($Proxy) {
        $env:HTTP_PROXY = $Proxy
        $env:HTTPS_PROXY = $Proxy
        $lines += "Using proxy for winget/network: $Proxy"
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    $installed = $false

    if ($wingetCmd) {
        $wingetArgs = @("install","-e","--id","MikeFarah.yq")
        if ($AcceptDefaults) {
            $wingetArgs += @("--accept-source-agreements","--accept-package-agreements")
        }

        $lines += "Running: winget $($wingetArgs -join ' ')"
        & winget @wingetArgs
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Test-ToolOnPath -CommandName "yq")) {
            $lines += "yq installed successfully via winget."
            $installed = $true
        } else {
            $lines += "winget install for yq did not complete successfully (exit code $exitCode)."
        }
    } else {
        $lines += "winget is not available; attempting direct yq binary download."
    }

    if (-not $installed) {
        $downloadUrl = "https://github.com/mikefarah/yq/releases/latest/download/yq_windows_amd64.exe"
        $tempFile = Get-LanrenComponentPackagePath -FileName "yq_windows_amd64.exe"

        $lines += "Downloading yq from: $downloadUrl"
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

        $toolsDir = Join-Path ${env:ProgramFiles} "yq"
        if (-not (Test-Path $toolsDir)) {
            New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        }

        $target = Join-Path $toolsDir "yq.exe"
        Copy-Item -Path $tempFile -Destination $target -Force

        Add-DirectoryToUserPath -Directory $toolsDir

        if (-not (Test-ToolOnPath -CommandName "yq")) {
            $lines += "yq binary was installed, but PATH may not reflect it yet."
            $lines += "You may need to restart your shell or sign out and back in."
        } else {
            $lines += "yq installed successfully to $toolsDir and added to user PATH."
        }
    }
} catch {
    $lines += "Error installing yq: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
Exit-WithWait 0
