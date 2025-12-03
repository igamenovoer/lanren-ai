<#
.SYNOPSIS
Creates a Hyper-V VM checkpoint (snapshot) and optionally records its metadata to a file.

.DESCRIPTION
Creates a checkpoint for the specified Hyper-V VM using Checkpoint-VM. The checkpoint type can be Standard, Production, or ProductionOnly (default is Standard). After creation, the script can optionally write basic metadata about the checkpoint (VM name, checkpoint name, type, ID, creation time) to a host-side metadata file so other tools can use it later. When -CaptureLogFile is provided, human-readable log output is written to that log file instead of the console.

.PARAMETER VMName
The name of the Hyper-V virtual machine (as shown by Get-VM) to checkpoint.

.PARAMETER MetadataFile
Optional path on the host where checkpoint metadata will be written. The parent directory will be created if it does not exist.

.PARAMETER CheckpointName
Optional name for the checkpoint. If omitted or empty, a name like "LanrenCheckpoint-YYYYMMDD-HHMMSS" is generated.

.PARAMETER CheckpointType
Optional checkpoint type for the VM: Standard, Production, or ProductionOnly. Defaults to Standard.

.PARAMETER CaptureLogFile
Optional path to a log file. When specified, human-readable output is written to this file using the console default encoding instead of being written to the console.

.EXAMPLE
.\save-vm-snapshot.ps1 -VMName win10-test
Creates a Standard checkpoint for win10-test with an auto-generated name and logs progress to the console.

.EXAMPLE
.\save-vm-snapshot.ps1 -VMName win10-test -MetadataFile .\tmp\win10-test-ckpt.txt -CheckpointName "BeforeTools" -CheckpointType Production
Creates a Production checkpoint named "BeforeTools" and records its metadata to the specified output file.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    [string]$CheckpointName,
    [ValidateSet("Standard","Production","ProductionOnly")]
    [string]$CheckpointType = "Standard",
    [string]$MetadataFile,
    [string]$CaptureLogFile
)

$ErrorActionPreference = "Stop"

$lines = @()
$lines += ""
$lines += "=== Create Hyper-V VM Checkpoint ==="
$lines += ""
$lines += "VM Name: $VMName"
$lines += ("Checkpoint type: {0}" -f $CheckpointType)
if (-not [string]::IsNullOrWhiteSpace($CheckpointName)) {
    $lines += "Requested checkpoint name: $CheckpointName"
}
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
    Set-VM -Name $VMName -CheckpointType $CheckpointType -ErrorAction Stop
    $lines += "Checkpoint type for '$VMName' set to: $CheckpointType"
} catch {
    $lines += "Error configuring checkpoint settings on VM '$VMName'."
    $lines += "Details: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

if ([string]::IsNullOrWhiteSpace($CheckpointName)) {
    $CheckpointName = "LanrenCheckpoint-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    $lines += "Generated checkpoint name: $CheckpointName"
} else {
    $lines += "Using checkpoint name: $CheckpointName"
}

try {
    $lines += "Creating checkpoint..."
    Checkpoint-VM -Name $VMName -SnapshotName $CheckpointName -ErrorAction Stop | Out-Null
} catch {
    $lines += "Error creating checkpoint on VM '$VMName'."
    $lines += "Details: $($_.Exception.Message)"
    Write-OutputLines -Content $lines -LogFile $CaptureLogFile
    exit 1
}

try {
    $ckpt = Get-VMCheckpoint -VMName $VMName | Where-Object { $_.Name -eq $CheckpointName } | Sort-Object CreationTime -Descending | Select-Object -First 1
} catch {
    $ckpt = $null
}

if ($ckpt) {
    $lines += "Checkpoint created successfully."
    if ($ckpt.Id) {
        $lines += "CheckpointId: $($ckpt.Id)"
    }
    if ($ckpt.CreationTime) {
        $lines += "CreationTime: $($ckpt.CreationTime.ToString('o'))"
    }
    if ($ckpt.ParentCheckpointName) {
        $lines += "ParentCheckpointName: $($ckpt.ParentCheckpointName)"
    }
} else {
    $lines += "Checkpoint created successfully, but checkpoint details could not be retrieved."
}

if (-not [string]::IsNullOrWhiteSpace($MetadataFile)) {
    try {
        $outDir = Split-Path -LiteralPath $MetadataFile -Parent
        if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        $ckptInfo = @()
        $ckptInfo += "VMName: $VMName"
        $ckptInfo += "CheckpointName: $CheckpointName"
        if (-not [string]::IsNullOrWhiteSpace($CheckpointType)) {
            $ckptInfo += "CheckpointType: $CheckpointType"
        }
        if ($ckpt) {
            if ($ckpt.Id) {
                $ckptInfo += "CheckpointId: $($ckpt.Id)"
            }
            if ($ckpt.CreationTime) {
                $ckptInfo += "CreationTime: $($ckpt.CreationTime.ToString('o'))"
            }
            if ($ckpt.ParentCheckpointName) {
                $ckptInfo += "ParentCheckpointName: $($ckpt.ParentCheckpointName)"
            }
        }

        $ckptInfo -join "`r`n" | Set-Content -Path $MetadataFile -Encoding Default -Force
        $lines += "Checkpoint metadata written to: $MetadataFile"
    } catch {
        $lines += "Warning: Failed to write checkpoint metadata file '$MetadataFile'."
        $lines += "Details: $($_.Exception.Message)"
    }
}

Write-OutputLines -Content $lines -LogFile $CaptureLogFile
exit 0
