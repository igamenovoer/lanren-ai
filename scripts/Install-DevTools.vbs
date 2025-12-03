' VBScript launcher - handles UAC elevation and execution policy bypass
' Launches the common-pack PowerShell installer

Option Explicit

Dim objShell, fso, scriptDir, ps1File, args

Set objShell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1File = scriptDir & "\install-common-pack.ps1"

' Verify PowerShell script exists
If Not fso.FileExists(ps1File) Then
    MsgBox "Error: install-common-pack.ps1 not found in " & scriptDir & "!", vbCritical, "Lanren AI Installer"
    WScript.Quit 1
End If

' Build arguments for PowerShell
args = "-ExecutionPolicy Bypass -NoProfile -File """ & ps1File & """"

' Launch with elevation and execution policy bypass
On Error Resume Next
objShell.ShellExecute "powershell.exe", args, "", "runas", 1

If Err.Number <> 0 Then
    MsgBox "Failed to start PowerShell installer." & vbCrLf & "Error: " & Err.Description, vbCritical, "Lanren AI Installer"
    WScript.Quit 1
End If

