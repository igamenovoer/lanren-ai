# How to Copy and Execute Files from Windows 11 Host to Windows 10 Hyper-V VM Using PowerShell

This guide explains how to use PowerShell to copy files from a Windows 11 host to a Windows 10 virtual machine running in Hyper-V, and then execute those files or commands within the VM. This approach uses PowerShell Direct and related Hyper-V cmdlets, eliminating the need for network connectivity between the host and VM.

## Prerequisites

- Windows 11 host with Hyper-V installed
- Windows 10 VM (or newer) running on Hyper-V
- Administrative privileges on the Hyper-V host
- VM credentials with administrative rights
- VM must be in a running state

## Key Technologies

**PowerShell Direct**: A feature that allows direct PowerShell access to VMs through the Virtual Machine Bus (VMBus), bypassing network requirements, firewall rules, and remote management settings.

**Copy-VMFile**: A cmdlet for copying files from host to VM without network connectivity.

**Guest Services Integration**: Required for Copy-VMFile to function properly.

## Step 1: Enable Guest Services Integration

Before copying files, ensure Guest Services is enabled on the target VM.

### Check if Guest Services is Enabled

```powershell
Get-VMIntegrationService -VMName "YourVMName" -Name "Guest Service Interface"
```

### Enable Guest Services

```powershell
Enable-VMIntegrationService -VMName "YourVMName" -Name "Guest Service Interface"
```

You can also enable it for multiple VMs:

```powershell
Get-VM | Enable-VMIntegrationService -Name "Guest Service Interface"
```

## Step 2: Copy Files from Host to VM

Use the `Copy-VMFile` cmdlet to transfer files from the host to the VM.

### Basic File Copy

```powershell
Copy-VMFile -VMName "YourVMName" `
    -SourcePath "C:\HostFolder\script.ps1" `
    -DestinationPath "C:\VMFolder\script.ps1" `
    -FileSource Host `
    -CreateFullPath
```

**Parameters:**
- `-VMName`: The VM name as shown in Hyper-V Manager (not the hostname)
- `-SourcePath`: Full path to the file on the host
- `-DestinationPath`: Target path on the VM
- `-FileSource Host`: Indicates copying from host to VM
- `-CreateFullPath`: Automatically creates destination folders if they don't exist
- `-Force`: Overwrites existing files without prompting

### Copy Multiple Files

To copy multiple files, use a loop:

```powershell
$files = Get-ChildItem "C:\HostFolder\*.ps1"
foreach ($file in $files) {
    $destination = "C:\VMFolder\$($file.Name)"
    Copy-VMFile -VMName "YourVMName" `
        -SourcePath $file.FullName `
        -DestinationPath $destination `
        -FileSource Host `
        -CreateFullPath `
        -Force
}
```

### Copy to Multiple VMs

```powershell
$vmNames = @("VM1", "VM2", "VM3")
foreach ($vmName in $vmNames) {
    Copy-VMFile -VMName $vmName `
        -SourcePath "C:\HostFolder\file.txt" `
        -DestinationPath "C:\VMFolder\file.txt" `
        -FileSource Host `
        -CreateFullPath
}
```

### Copy Folders (Workaround)

`Copy-VMFile` only copies files, not folders. To copy a folder, either:

1. Compress the folder to a ZIP file and copy it, or
2. Use a loop to copy all files recursively:

```powershell
$sourceFolder = "C:\HostFolder"
$destFolder = "C:\VMFolder"
Get-ChildItem -Path $sourceFolder -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceFolder.Length)
    $destination = Join-Path $destFolder $relativePath
    Copy-VMFile -VMName "YourVMName" `
        -SourcePath $_.FullName `
        -DestinationPath $destination `
        -FileSource Host `
        -CreateFullPath
}
```

## Step 3: Execute Commands or Scripts on the VM

After copying files, use PowerShell Direct to execute commands or scripts within the VM.

### Execute a Single Command

```powershell
Invoke-Command -VMName "YourVMName" -Credential (Get-Credential) -ScriptBlock {
    Get-Process | Where-Object {$_.CPU -gt 10}
}
```

### Execute a Script File on the VM

First copy the script, then execute it:

```powershell
# Copy the script
Copy-VMFile -VMName "YourVMName" `
    -SourcePath "C:\HostScripts\setup.ps1" `
    -DestinationPath "C:\Temp\setup.ps1" `
    -FileSource Host `
    -CreateFullPath

# Execute the script
Invoke-Command -VMName "YourVMName" -Credential (Get-Credential) -ScriptBlock {
    & "C:\Temp\setup.ps1"
}
```

### Execute a Script from Host Directly

You can execute a script from the host filesystem without copying it first:

```powershell
Invoke-Command -VMName "YourVMName" `
    -Credential (Get-Credential) `
    -FilePath "C:\HostScripts\setup.ps1"
```

### Store Credentials for Reuse

To avoid entering credentials repeatedly:

```powershell
$cred = Get-Credential
Invoke-Command -VMName "YourVMName" -Credential $cred -ScriptBlock {
    # Your commands here
}
```

Or create a secure credential programmatically:

```powershell
$username = "Administrator"
$password = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($username, $password)
```

## Step 4: Advanced Scenarios

### Interactive Session

For running multiple commands interactively:

```powershell
Enter-PSSession -VMName "YourVMName" -Credential (Get-Credential)
# Now you're inside the VM's PowerShell session
# Run commands as if you were logged in locally
Get-Service
Install-WindowsFeature SomeFeature
# Exit when done
Exit-PSSession
```

### Persistent Session with Copy-Item

For more flexibility in file transfers, use a persistent session:

```powershell
# Create a session
$session = New-PSSession -VMName "YourVMName" -Credential (Get-Credential)

# Copy files to VM
Copy-Item -ToSession $session -Path "C:\HostFolder\data.txt" -Destination "C:\VMFolder\" -Recurse

# Copy files from VM to host
Copy-Item -FromSession $session -Path "C:\VMFolder\output.log" -Destination "C:\HostFolder\"

# Run commands in the session
Invoke-Command -Session $session -ScriptBlock {
    Get-ChildItem C:\VMFolder
}

# Close the session
Remove-PSSession $session
```

### Wait for PowerShell Direct to be Ready

After a VM starts, PowerShell Direct may not be immediately available. Use this pattern to wait:

```powershell
$vmName = "YourVMName"
$cred = Get-Credential

# Wait for PowerShell Direct to respond
while ($true) {
    try {
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            Write-Host "Ready"
        } -ErrorAction Stop
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}
Write-Host "PowerShell Direct is ready on $vmName"
```

### Copy and Execute Pattern

Complete example combining copy and execution:

```powershell
$vmName = "Win10-VM"
$hostScript = "C:\Scripts\install-tools.ps1"
$vmScript = "C:\Temp\install-tools.ps1"
$cred = Get-Credential

# Ensure Guest Services is enabled
Enable-VMIntegrationService -VMName $vmName -Name "Guest Service Interface"

# Copy the script to VM
Copy-VMFile -VMName $vmName `
    -SourcePath $hostScript `
    -DestinationPath $vmScript `
    -FileSource Host `
    -CreateFullPath `
    -Force

# Execute the script with parameters
Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($scriptPath, $param1, $param2)
    & $scriptPath -Parameter1 $param1 -Parameter2 $param2
} -ArgumentList $vmScript, "value1", "value2"
```

### Execute in Multiple VMs Sequentially

```powershell
$vmNames = @("VM1", "VM2", "VM3")
$cred = Get-Credential
$scriptPath = "C:\Scripts\update.ps1"

foreach ($vmName in $vmNames) {
    Write-Host "Processing $vmName..."
    
    # Copy script
    Copy-VMFile -VMName $vmName `
        -SourcePath $scriptPath `
        -DestinationPath "C:\Temp\update.ps1" `
        -FileSource Host `
        -CreateFullPath
    
    # Execute script
    Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
        & "C:\Temp\update.ps1"
    }
}
```

## Important Notes and Limitations

1. **Copy-VMFile Direction**: The `Copy-VMFile` cmdlet only works from host to VM, not from VM to host. Use `Copy-Item` with sessions for bidirectional transfers.

2. **File-Only Copy**: `Copy-VMFile` cannot copy folders directly. You must copy files individually or compress folders first.

3. **VM State**: The VM must be in a running state for PowerShell Direct to work.

4. **Integration Services Version**: The VM must have integration services version 6.3.9600.16384 or later. Check with:

```powershell
Get-VM -VMName "YourVMName" | Select-Object Name, IntegrationServicesVersion
```

5. **Guest OS Requirements**: PowerShell Direct requires Windows 10, Windows Server 2016, or newer guest operating systems.

6. **Credentials**: You always need valid administrative credentials for the guest VM when using `Invoke-Command` or `Enter-PSSession`.

7. **Network Independence**: These methods work regardless of network configuration, making them ideal for isolated or network-restricted VMs.

8. **Execution Policy**: Be aware of PowerShell execution policies in the guest VM. You may need to set the execution policy:

```powershell
Invoke-Command -VMName "YourVMName" -Credential $cred -ScriptBlock {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
}
```

## Troubleshooting

### Error: "The virtual machine cannot be found"
- Verify the VM name matches exactly as shown in Hyper-V Manager
- Check that the VM is running: `Get-VM -VMName "YourVMName" | Select-Object Name, State`

### Error: "Guest services are not enabled"
- Enable Guest Services as shown in Step 1
- Restart the VM if necessary

### Error: "PowerShell Direct is not responding"
- Wait for the VM to fully boot
- Verify integration services are up to date
- Check that the guest OS is Windows 10 or newer

### Timeout Issues
- For long-running commands, use `-AsJob` parameter with `Invoke-Command`
- Or increase timeout settings in session options

## References

- [Microsoft Learn: Manage Windows Virtual Machines with PowerShell Direct](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct)
- [Microsoft Learn: Copy-VMFile cmdlet](https://learn.microsoft.com/en-us/powershell/module/hyper-v/copy-vmfile)
- [Microsoft Learn: Enable-VMIntegrationService cmdlet](https://learn.microsoft.com/en-us/powershell/module/hyper-v/enable-vmintegrationservice)
- [PowerShell Magazine: Using Copy-VMFile cmdlet](https://powershellmagazine.com/2013/12/16/using-copy-vmfile-cmdlet-in-windows-server-2012-r2-hyper-v/)
- [TechTarget: Copy files from host to Hyper-V machine](https://www.techtarget.com/searchitoperations/tip/Copy-files-from-the-host-to-a-Hyper-V-machine)
- [NAKIVO Blog: How to Copy Files to Hyper-V Server and VMs](https://www.nakivo.com/blog/copy-files-to-hyper-v-server/)
