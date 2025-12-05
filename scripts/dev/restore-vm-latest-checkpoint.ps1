<#
.SYNOPSIS
Restores a Hyper-V VM to its latest checkpoint (snapshot).

.DESCRIPTION
Finds the most recent checkpoint for the specified Hyper-V VM and restores
the VM to that checkpoint. If the VM is currently running or paused, it is
stopped before the restore. By default, the VM is started again after the
restore completes; this can be disabled with -NoStart. When -CaptureLogFile
is provided, human-readable log output is written to that log file instead
of the console.

.PARAMETER VMName
The name of the Hyper-V virtual machine (as shown by Get-VM) to restore.

.PARAMETER NoStart
When specified, the VM is not started automatically after the checkpoint
is restored. The VM will remain in the restored state.

.PARAMETER CaptureLogFile
Optional path to a log file. When specified, human-readable output is
written to this file using the console default encoding instead of being
written to the console.

.EXAMPLE
.\restore-vm-latest-checkpoint.ps1 -VMName win10-test
Stops the VM if needed, restores the latest checkpoint for win10-test, and
starts the VM again.

.EXAMPLE
.\restore-vm-latest-checkpoint.ps1 -VMName win10-test -NoStart -CaptureLogFile C:\Temp\restore.log
Restores the latest checkpoint for win10-test, leaves the VM powered off,
and writes all output to C:\Temp\restore.log.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    [switch]$NoStart,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Restore Hyper-V VM to Latest Checkpoint ==="
$lines += ""
$lines += "VM Name: $VMName"
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
    $vm = Get-VM -Name $VMName -ErrorAction Stop
} catch {
    $lines += "Error: VM '$VMName' not found."
    $lines += "Details: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

try {
    $ckpt = Get-VMCheckpoint -VMName $VMName -ErrorAction Stop |
        Sort-Object CreationTime -Descending |
        Select-Object -First 1
} catch {
    $lines += "Error retrieving checkpoints for VM '$VMName': $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if (-not $ckpt) {
    $lines += "No checkpoints found for VM '$VMName'. Nothing to restore."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

$lines += ("Latest checkpoint: {0}" -f $ckpt.Name)
if ($ckpt.CreationTime) {
    $lines += ("CreationTime: {0}" -f $ckpt.CreationTime.ToString("o"))
}
$lines += ""

try {
    if ($vm.State -eq "Running" -or $vm.State -eq "Paused") {
        $lines += "VM is currently $($vm.State); stopping VM before restore..."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        $lines = @()

        $stopError = $null
        try {
            Stop-VM -Name $VMName -Force -ErrorAction Stop
        } catch {
            $stopError = $_
        }

        if ($stopError) {
            $lines += "Standard Stop-VM failed: $($stopError.Exception.Message)"
            $lines += "Attempting hard power off (Stop-VM -TurnOff -Force)..."
            Write-OutputLines -Content $lines -LogFile $CaptureLogFile
            $lines = @()

            try {
                Stop-VM -Name $VMName -TurnOff -Force -ErrorAction Stop
            } catch {
                throw
            }
        }

        $lines += "VM stopped."
        $lines += ""
    }
} catch {
    $lines += "Error stopping VM '$VMName' before restore: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

try {
    $lines += "Restoring VM to checkpoint '$($ckpt.Name)'..."
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    $lines = @()

    Restore-VMCheckpoint -VMName $VMName -Name $ckpt.Name -Confirm:$false -ErrorAction Stop | Out-Null

    $lines += "Checkpoint restore completed successfully."
} catch {
    $lines += "Error restoring checkpoint '$($ckpt.Name)' on VM '$VMName': $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if (-not $NoStart) {
    try {
        $lines += "Starting VM '$VMName' after restore..."
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        $lines = @()

        Start-VM -Name $VMName -ErrorAction Stop | Out-Null
        $lines += "VM '$VMName' started successfully."
    } catch {
        $lines += "Checkpoint was restored, but failed to start VM '$VMName': $($_.Exception.Message)"
        Write-OutputLines -Content $lines -LogFile $CaptureLogFile
        exit 1
    }
} else {
    $lines += "VM '$VMName' left in restored state (not started because -NoStart was specified)."
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0
