<#
.SYNOPSIS
Enables the "Guest Service Interface" integration service for a specific Hyper-V VM.

.DESCRIPTION
Checks the Guest Service Interface integration service for the given VM and enables it if it is currently disabled. This is required for Copy-VMFile and other host-to-guest operations. When -CaptureLogFile is provided, messages are written to the log file instead of the console.

.PARAMETER VMName
The name of the Hyper-V virtual machine (as shown by Get-VM) on which to enable the Guest Service Interface.

.PARAMETER CaptureLogFile
Optional path to a log file. When specified, all output is written to this file using the console default encoding instead of being written to the console.

.EXAMPLE
.\enable-guest-service-integration.ps1 -VMName win10-test
Enables the Guest Service Interface integration service on the VM named win10-test and prints progress to the console.

.EXAMPLE
.\enable-guest-service-integration.ps1 -VMName win10-test -CaptureLogFile C:\Temp\enable-guest.log
Enables the Guest Service Interface on win10-test and writes all output to C:\Temp\enable-guest.log for a caller (for example a .bat wrapper) to print.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Enable Guest Service Interface ==="
$lines += ""
$lines += "Target VM: $VMName"
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
    $service = Get-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
} catch {
    $lines += "Error querying integration service on '$VMName': $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if (-not $service) {
    $lines += "Guest Service Interface not found on VM '$VMName'."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if ($service.Enabled) {
    $lines += "Guest Service Interface is already enabled."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 0
}

try {
    $lines += "Enabling Guest Service Interface..."
    Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface" | Out-Null

    $service = Get-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
    if ($service.Enabled) {
        $lines += "Guest Service Interface has been enabled successfully."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 0
    }

    $lines += "Tried to enable Guest Service Interface, but it still appears disabled."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
} catch {
    $lines += "Error enabling Guest Service Interface on '$VMName': $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}
