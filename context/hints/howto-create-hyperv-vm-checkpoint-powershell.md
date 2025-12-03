# How to create and manage Hyper-V VM checkpoints using PowerShell

This guide explains how to create, list, restore, and remove Hyper-V virtual machine checkpoints (snapshots) using PowerShell. Checkpoints allow you to capture the state of a virtual machine at a specific point in time and revert to it later.

## Prerequisites

- PowerShell running with Administrator privileges.
- Hyper-V module installed and loaded (usually available on Windows with Hyper-V enabled).

## Checkpoint Types

Hyper-V supports two types of checkpoints:

| Type | Description | Use Case |
|------|-------------|----------|
| **Standard** | Captures VM state including memory. Not data-consistent for systems like Active Directory. | Development, testing, troubleshooting |
| **Production** | Uses VSS (Windows) or File System Freeze (Linux) to create a data-consistent backup. Does not capture memory state. VM will be in "Off" state after restore. | Production environments |

Production checkpoints are selected by default.

### Configure Checkpoint Type

```powershell
# Set to Standard checkpoint
Set-VM -Name "DevBox" -CheckpointType Standard

# Set to Production checkpoint (falls back to Standard if Production fails)
Set-VM -Name "DevBox" -CheckpointType Production

# Set to Production only (no fallback)
Set-VM -Name "DevBox" -CheckpointType ProductionOnly
```

## Checkpoint Storage Location

By default, checkpoint files (`.avhdx`) are stored in:
```
%systemroot%\ProgramData\Microsoft\Windows\Hyper-V\Snapshots
```

> **Note:** Although Hyper-V renamed "Snapshots" to "Checkpoints" in the UI (since Server 2012 R2), the PowerShell parameter is still named `-SnapshotFileLocation`, not `-CheckpointFileLocation`.

### View Current Checkpoint Location

```powershell
# Get checkpoint file location for a VM (property is named CheckpointFileLocation in output)
Get-VM -Name "DevBox" | Select-Object Name, CheckpointFileLocation
```

### Change Checkpoint Storage Location

You can only change the checkpoint location when there are no existing checkpoints for the VM.

```powershell
# Set checkpoint file location to a custom path (use -SnapshotFileLocation parameter)
Set-VM -Name "DevBox" -SnapshotFileLocation "D:\HyperV\Checkpoints\DevBox"

# Set both checkpoint type and location
Set-VM -Name "DevBox" -CheckpointType Standard -SnapshotFileLocation "D:\HyperV\Checkpoints\DevBox"
```

### Enable or Disable Checkpoints

```powershell
# Disable checkpoints for a VM
Set-VM -Name "DevBox" -CheckpointType Disabled

# Re-enable checkpoints (set to Standard or Production)
Set-VM -Name "DevBox" -CheckpointType Standard
```

## Common Operations

### 1. Create a Checkpoint

```powershell
# Syntax: Checkpoint-VM -Name <VMName> -SnapshotName <CheckpointName>

# Create a checkpoint named "FreshInstall" for VM "DevBox"
Checkpoint-VM -Name "DevBox" -SnapshotName "FreshInstall"
```

### 2. List Checkpoints

```powershell
# List all checkpoints for a VM
Get-VMCheckpoint -VMName "DevBox"

# List checkpoints with more details
Get-VMCheckpoint -VMName "DevBox" | Select-Object Name, CreationTime, ParentCheckpointName
```

### 3. Restore a Checkpoint

Reverts the VM to a previous state. **Note:** This discards the current state unless you create a new checkpoint before restoring.

```powershell
# Restore to a specific checkpoint
Restore-VMCheckpoint -Name "FreshInstall" -VMName "DevBox" -Confirm:$false
```

> **Important:** After restoring a Production checkpoint, the VM will be in an "Off" state and needs to be started manually.

### 4. Remove a Checkpoint

Deletes a checkpoint and merges the `.avhdx` file with its parent. Do not delete `.avhdx` files manually.

```powershell
# Remove a specific checkpoint
Remove-VMCheckpoint -VMName "DevBox" -Name "FreshInstall"

# Remove a checkpoint and all its children (subtree)
Remove-VMCheckpoint -VMName "DevBox" -Name "FreshInstall" -IncludeAllChildCheckpoints
```

### 5. Rename a Checkpoint

```powershell
# Rename a checkpoint
Rename-VMCheckpoint -VMName "DevBox" -Name "FreshInstall" -NewName "BaseSetup"
```

### 6. Export a Checkpoint

Exports a checkpoint as a standalone VM that can be imported elsewhere.

```powershell
# Export a checkpoint to a specified path
Export-VMCheckpoint -VMName "DevBox" -Name "FreshInstall" -Path "D:\Exports"
```

## References

- [Using checkpoints (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/checkpoints)
- [Checkpoint-VM (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/hyper-v/checkpoint-vm)
- [Restore-VMCheckpoint (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/hyper-v/restore-vmcheckpoint)
- [Get-VMCheckpoint (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/hyper-v/get-vmcheckpoint)
- [Set-VM (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/hyper-v/set-vm)
