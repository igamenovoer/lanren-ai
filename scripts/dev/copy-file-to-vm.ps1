<#
.SYNOPSIS
Copies a single file from the Hyper-V host into a guest VM using Copy-VMFile.

.DESCRIPTION
Validates the host source file, VM existence, VM running state, and Guest Service Interface integration service, then uses Copy-VMFile to copy one file into the guest. The destination can be a full path (including filename) or a directory; when a directory is given, the source filename is appended. When -CaptureLogFile is provided, messages are written to the log file instead of the console.

.PARAMETER VMName
The name of the Hyper-V virtual machine (as shown by Get-VM) that will receive the file.

.PARAMETER SourcePath
Path to the file on the host to copy into the VM. Must refer to a single file, not a directory.

.PARAMETER DestinationPath
Destination path inside the VM. If this is a directory or ends with a slash, the source filename is appended.

.PARAMETER CaptureLogFile
Optional path to a log file. When specified, all output is written to this file using the console default encoding instead of being written to the console.

.EXAMPLE
.\copy-file-to-vm.ps1 -VMName win10-test -SourcePath .\README.md -DestinationPath 'C:\Users\Public\Desktop\Lanren-README.md'
Copies README.md from the host into the Public Desktop of the VM win10-test.

.EXAMPLE
.\copy-file-to-vm.ps1 -VMName win10-test -SourcePath .\README.md -DestinationPath 'C:\Temp' -CaptureLogFile C:\Temp\copy-to-vm.log
Copies README.md into C:\Temp inside win10-test and logs details to C:\Temp\copy-to-vm.log for a caller (for example a .bat wrapper) to print.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Copy File to Hyper-V VM ==="
$lines += ""
$lines += "VM Name: $VMName"
$lines += "Host Source: $SourcePath"
$lines += "VM Destination: $DestinationPath"
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

try {
    $resolvedSource = Resolve-Path -LiteralPath $SourcePath -ErrorAction Stop
} catch {
    $lines += "Error: Source file not found on host: '$SourcePath'."
    $lines += "Details: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if ((Get-Item -LiteralPath $resolvedSource).PSIsContainer) {
    $lines += "Error: Source path refers to a directory. This helper only copies single files. Use a loop or archive for folders."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

try {
    $vm = Get-VM -Name $VMName -ErrorAction Stop
} catch {
    $lines += "Error: VM '$VMName' not found."
    $lines += "Details: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if ($vm.State -ne 'Running') {
    $lines += "Error: VM '$VMName' is not running. Current state: $($vm.State)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

try {
    $service = Get-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
} catch {
    $lines += "Error querying Guest Service Interface on '$VMName': $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if (-not $service) {
    $lines += "Error: Guest Service Interface integration service not found on VM '$VMName'."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if (-not $service.Enabled) {
    $lines += "Error: Guest Service Interface is not enabled on '$VMName'."
    $lines += "Hint: Run enable-guest-service-integration.bat --vm-name $VMName first."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

$destPath = $DestinationPath

if ($destPath.EndsWith('\') -or $destPath.EndsWith('/')) {
    $destPath = $destPath.TrimEnd('\', '/')
    $destPath = [IO.Path]::Combine($destPath, [IO.Path]::GetFileName($resolvedSource))
} elseif ([string]::IsNullOrWhiteSpace([IO.Path]::GetFileName($destPath))) {
    $destPath = [IO.Path]::Combine($destPath, [IO.Path]::GetFileName($resolvedSource))
}

try {
    $lines += "Starting Copy-VMFile..."
    Copy-VMFile -VMName $VMName `
        -SourcePath $resolvedSource `
        -DestinationPath $destPath `
        -FileSource Host `
        -CreateFullPath `
        -Force
    $lines += "Copy completed successfully."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 0
} catch {
    $lines += "Error copying file to VM:"
    $lines += $($_.Exception.Message)
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}
