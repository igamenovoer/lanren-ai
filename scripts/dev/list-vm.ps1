<#
.SYNOPSIS
Lists running Hyper-V virtual machines on the local host.

.DESCRIPTION
Uses Get-VM to query Hyper-V and prints the Name and State of all VMs that are currently running. When -CaptureLogFile is provided, output is written to the specified log file so that a calling batch script can display it later.

.PARAMETER CaptureLogFile
Optional path to a log file. When specified, all output is written to this file using the console default encoding instead of being written to the console.

.EXAMPLE
.\list-vm.ps1
Lists all running Hyper-V VMs in the current console.

.EXAMPLE
.\list-vm.ps1 -CaptureLogFile C:\Temp\list-vm.log
Writes the list of running VMs to C:\Temp\list-vm.log for a caller (for example a .bat wrapper) to print.
#>

param(
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Running Hyper-V VMs ==="
$lines += ""

try {
    $vms = Get-VM |
        Where-Object { $_.State -eq 'Running' } |
        Select-Object Name, State
} catch {
    $lines += "Error querying Hyper-V VMs: $($_.Exception.Message)"

    if ($CaptureLogFile) {
        $lines -join "`r`n" | Out-File -FilePath $CaptureLogFile -Encoding Default -Force
    } else {
        $lines | ForEach-Object { Write-Host $_ }
    }

    exit 1
}

if (-not $vms -or $vms.Count -eq 0) {
    $lines += "No running Hyper-V virtual machines found."
} else {
    $lines += ($vms | Format-Table -AutoSize | Out-String)
}

if ($CaptureLogFile) {
    $lines -join "`r`n" | Out-File -FilePath $CaptureLogFile -Encoding Default -Force
} else {
    $lines | ForEach-Object { Write-Host $_ }
}
