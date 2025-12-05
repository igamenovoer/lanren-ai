<#
.SYNOPSIS
Configures Windows Explorer \"Open in VS Code\" context menu entries.

.DESCRIPTION
Creates per-user registry entries under HKCU so that files and folders
in Explorer have an \"Open in VS Code\" option. Attempts to locate the
VS Code CLI (`code`) and uses its path for the context menu commands.

.PARAMETER CaptureLogFile
Optional log file path. When provided, all output is written here using
the console default encoding so a .bat wrapper can print it.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
This is useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
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
if (-not $script:LanrenComponentName) { $script:LanrenComponentName = "vscode" }

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

$lines = @()
$lines += ""
$lines += "=== Configuring Explorer 'Open in VS Code' context menu ==="
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

try {
    $codePath = $null

    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $codePath = $codeCmd.Path
        $lines += "Found VS Code CLI via PATH: $codePath"
    } else {
        $candidates = @()
        if ($env:LOCALAPPDATA) {
            $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd')
        }
        if ($env:ProgramFiles) {
            $candidates += (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
        }
        if (${env:ProgramFiles(x86)}) {
            $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\bin\code.cmd')
        }

        foreach ($candidate in $candidates) {
            if (Test-Path $candidate) {
                $codePath = $candidate
                $lines += "Found VS Code CLI at known location: $codePath"
                break
            }
        }
    }

    if (-not $codePath) {
        $lines += "Unable to locate VS Code CLI ('code'). Context menu entries not configured."
        Write-OutputLine -Content $lines -LogFile $CaptureLogFile
        Exit-WithWait 1
    }

    $commandForFiles = "`"$codePath`" `"%1`""
    $commandForDirs = "`"$codePath`" `"%V`""

    # Files: *\shell\OpenInVSCode
    $fileKey = "HKCU:\Software\Classes\*\shell\OpenInVSCode"
    New-Item -Path $fileKey -Force | Out-Null
    Set-ItemProperty -Path $fileKey -Name "(default)" -Value "Open in VS Code"
    Set-ItemProperty -Path $fileKey -Name "Icon" -Value $codePath

    $fileCmdKey = Join-Path $fileKey "command"
    New-Item -Path $fileCmdKey -Force | Out-Null
    Set-ItemProperty -Path $fileCmdKey -Name "(default)" -Value $commandForFiles

    # Directories: Directory\shell\OpenInVSCode
    $dirKey = "HKCU:\Software\Classes\Directory\shell\OpenInVSCode"
    New-Item -Path $dirKey -Force | Out-Null
    Set-ItemProperty -Path $dirKey -Name "(default)" -Value "Open in VS Code"
    Set-ItemProperty -Path $dirKey -Name "Icon" -Value $codePath

    $dirCmdKey = Join-Path $dirKey "command"
    New-Item -Path $dirCmdKey -Force | Out-Null
    Set-ItemProperty -Path $dirCmdKey -Name "(default)" -Value $commandForDirs

    $lines += "Configured 'Open in VS Code' context menu for files and directories."
} catch {
    $lines += "Error configuring Explorer context menu: $($_.Exception.Message)"
    Write-OutputLine -Content $lines -LogFile $CaptureLogFile
    Exit-WithWait 1
}

Write-OutputLine -Content $lines -LogFile $CaptureLogFile
if ($NoExit) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Exit-WithWait 0
