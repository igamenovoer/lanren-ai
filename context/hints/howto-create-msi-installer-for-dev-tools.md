# How to Create an MSI Installer for Development Tools Package

## HEADER
- **Purpose**: Guide for creating a one-click MSI installer to install multiple development tools (from common-pack.md)
- **Status**: Active
- **Date**: 2025-12-01
- **Dependencies**: Windows development environment
- **Target**: Developers creating automated installation packages

## Overview

This guide covers the best approaches for creating an MSI installer that can install multiple development tools in one click. The installer should handle tools from the common-pack including: Claude Code CLI, Codex CLI, VSCode, VSCode extensions, Node.js, Python tools (uv, pixi), utilities (jq, yq, pandoc), and MCP servers.

## Problem: Unsigned PowerShell Scripts

**Challenge**: Users cannot simply double-click a `.ps1` file because:
- PowerShell execution policy blocks unsigned scripts by default
- Users would need to right-click and "Run with PowerShell" or type commands
- Requires technical knowledge to bypass execution policy

**Solution**: Wrap the PowerShell script in a launcher that bypasses execution policy and requests admin rights via GUI (UAC prompt).

---

## Double-Click Solutions for Non-Technical Users

### Solution 1: VBScript Wrapper (Recommended for Simplicity)

**Best for**: Simplest double-click experience, no compilation needed

Create a `.vbs` file that launches PowerShell with elevated permissions and bypasses execution policy.

**File: `install-dev-tools.vbs`**

```vbscript
' VBScript wrapper to launch PowerShell installer with elevated privileges
' User just double-clicks this file - UAC will prompt for admin rights

Set objShell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

' Get the directory where this VBS file is located
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1File = scriptDir & "\install-dev-tools.ps1"

' Check if PowerShell script exists
If Not fso.FileExists(ps1File) Then
    MsgBox "Error: install-dev-tools.ps1 not found!" & vbCrLf & _
           "Expected location: " & ps1File, vbCritical, "Installation Error"
    WScript.Quit 1
End If

' Launch PowerShell with:
' - ExecutionPolicy Bypass (allows unsigned scripts)
' - NoProfile (faster startup)
' - File parameter (runs the script)
' - "runas" verb (requests UAC elevation)
objShell.ShellExecute "powershell.exe", _
    "-ExecutionPolicy Bypass -NoProfile -File """ & ps1File & """", _
    "", "runas", 1

' Show confirmation message
MsgBox "Installation started! Please wait for the PowerShell window to complete.", _
       vbInformation, "Dev Tools Installer"
```

**Distribution**:
1. Package both files together: `install-dev-tools.vbs` + `install-dev-tools.ps1`
2. User double-clicks the `.vbs` file
3. UAC prompt appears (user clicks "Yes")
4. PowerShell script runs with admin rights

**Advantages**:
- ✅ True double-click experience
- ✅ No compilation needed
- ✅ UAC prompt is familiar to users
- ✅ Works on all Windows versions
- ✅ No code signing required

**Sources**:
- [Run VBScript with UAC Elevation](https://ss64.com/vb/syntax-elevate.html)
- [VBScripts and UAC Elevation](https://www.winhelponline.com/blog/vbscripts-and-uac-elevation/)

---

### Solution 2: Batch File Wrapper (Simpler, But Less Polished)

**Best for**: Minimal dependencies, quick deployment

Create a `.bat` or `.cmd` file that launches PowerShell.

**File: `install-dev-tools.bat`**

```batch
@echo off
:: Batch wrapper to run PowerShell script with execution policy bypass
:: User double-clicks this file

echo ========================================
echo  Dev Tools Installer
echo ========================================
echo.
echo This will install development tools.
echo Administrator privileges required.
echo.
pause

:: Run PowerShell script with bypass
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0install-dev-tools.ps1"

:: Check if script succeeded
if %ERRORLEVEL% EQU 0 (
    echo.
    echo Installation completed successfully!
) else (
    echo.
    echo Installation failed with error code: %ERRORLEVEL%
)

echo.
pause
```

**Note**: This requires the user to run the batch file **as administrator** (right-click → "Run as administrator"). For true double-click, combine with VBScript wrapper:

**File: `install-dev-tools.vbs`** (to launch batch elevated):

```vbscript
Set objShell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
batFile = scriptDir & "\install-dev-tools.bat"

objShell.ShellExecute batFile, "", "", "runas", 1
```

**Sources**:
- [Bypass PowerShell Execution Policy](https://www.netspi.com/blog/technical-blog/network-pentesting/15-ways-to-bypass-the-powershell-execution-policy/)
- [Batch File ExecutionPolicy Bypass](https://stackoverflow.com/questions/42897554/powershell-executionpolicy-change-bypass)

---

### Solution 3: PS2EXE - Convert to Standalone EXE (Most Professional)

**Best for**: Professional distribution, single-file deployment

Convert the PowerShell script into a standalone `.exe` file using the free PS2EXE tool.

**Installation**:

```powershell
# Install PS2EXE module (requires admin)
Install-Module ps2exe -Scope CurrentUser
```

**Conversion**:

```powershell
# Convert PowerShell script to EXE
Invoke-PS2EXE -inputFile ".\install-dev-tools.ps1" `
              -outputFile ".\DevToolsInstaller.exe" `
              -title "Development Tools Installer" `
              -description "One-click installer for development tools" `
              -company "Your Company" `
              -version "1.0.0.0" `
              -requireAdmin `
              -noConsole `
              -iconFile ".\installer-icon.ico"
```

**Parameters explained**:
- `-requireAdmin`: Automatically requests UAC elevation
- `-noConsole`: Hides the PowerShell console window (use for GUI)
- `-iconFile`: Sets custom icon for the EXE
- `-title`, `-description`, `-company`, `-version`: Metadata visible in file properties

**For console-based installer** (show progress):

```powershell
Invoke-PS2EXE -inputFile ".\install-dev-tools.ps1" `
              -outputFile ".\DevToolsInstaller.exe" `
              -requireAdmin `
              -title "Development Tools Installer"
```

**Distribution**:
- Single `.exe` file
- User double-clicks → UAC prompt → installs

**Important Warning**: Some antivirus software may flag PS2EXE-generated executables as suspicious ([known issue](https://github.com/MScholtes/PS2EXE)). Report as false positive to AV vendors or use code signing certificate.

**Advantages**:
- ✅ Single EXE file (no separate .ps1 needed)
- ✅ Professional appearance
- ✅ Can add custom icon and metadata
- ✅ Auto-requests UAC elevation

**Disadvantages**:
- ⚠️ May trigger antivirus false positives
- ⚠️ Requires PS2EXE installation to build
- ⚠️ Script modifications require recompilation

**Sources**:
- [PS2EXE GitHub Repository](https://github.com/MScholtes/PS2EXE)
- [Convert PowerShell to EXE Guide](https://windowsreport.com/convert-powershell-to-exe/)
- [PS2EXE Tutorial](https://4sysops.com/archives/convert-a-powershell-script-into-an-exe-with-ps2exe-and-win-ps2exe/)

---

### Solution 4: C# WPF GUI Launcher (Advanced)

**Best for**: Professional installers with progress UI, custom branding

Create a small C# WPF application that:
- Shows a GUI with progress bar
- Runs PowerShell script in background
- Displays installation status
- Handles errors gracefully

**Minimal C# Console Launcher**:

```csharp
// SimpleInstaller.cs
using System;
using System.Diagnostics;

class SimpleInstaller
{
    static void Main(string[] args)
    {
        Console.Title = "Development Tools Installer";
        Console.WriteLine("Starting installation...\n");

        // Get the directory where the EXE is located
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;
        string ps1Path = System.IO.Path.Combine(exeDir, "install-dev-tools.ps1");

        if (!System.IO.File.Exists(ps1Path))
        {
            Console.WriteLine("Error: install-dev-tools.ps1 not found!");
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
            Environment.Exit(1);
        }

        // Launch PowerShell with bypass
        ProcessStartInfo psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-ExecutionPolicy Bypass -NoProfile -File \"{ps1Path}\"",
            UseShellExecute = true,
            Verb = "runas" // Request UAC elevation
        };

        try
        {
            Process process = Process.Start(psi);
            process.WaitForExit();

            if (process.ExitCode == 0)
            {
                Console.WriteLine("\nInstallation completed successfully!");
            }
            else
            {
                Console.WriteLine($"\nInstallation failed with code: {process.ExitCode}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }

        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
    }
}
```

**Compile**:

```powershell
# Compile to EXE (requires .NET SDK)
csc.exe /target:winexe /out:DevToolsInstaller.exe SimpleInstaller.cs
```

**For WPF GUI with Progress Bar**: See detailed examples at [Create GUI for PowerShell with WPF](https://4sysops.com/archives/create-a-gui-for-your-powershell-script-with-wpf/)

**Advantages**:
- ✅ Professional appearance with custom UI
- ✅ Can show real-time progress
- ✅ Better error handling and messaging
- ✅ Smaller file size than PS2EXE

**Disadvantages**:
- ⚠️ Requires C# development knowledge
- ⚠️ More complex to build and maintain

**Sources**:
- [Create GUI for PowerShell with WPF](https://4sysops.com/archives/create-a-gui-for-your-powershell-script-with-wpf/)
- [Simple GUI to Launch PowerShell](https://stackoverflow.com/questions/9990554/simple-gui-to-launch-a-powershell-script-and-pass-parameters)

---

## Recommended Distribution Strategy

### For Non-Technical Users (Your Use Case)

**Option A: VBScript + PowerShell (Simplest)**

```
📦 dev-tools-installer/
├── install-dev-tools.vbs    (Double-click this!)
├── install-dev-tools.ps1    (PowerShell script)
└── README.txt               (Instructions: "Double-click the .vbs file")
```

**User experience**:
1. User double-clicks `install-dev-tools.vbs`
2. UAC prompt appears: "Do you want to allow this app to make changes?" → User clicks **Yes**
3. PowerShell window opens and shows installation progress
4. Done!

**Option B: PS2EXE (Professional)**

```
📦 dev-tools-installer/
└── DevToolsInstaller.exe    (Double-click this!)
```

**User experience**:
1. User double-clicks `DevToolsInstaller.exe`
2. UAC prompt appears → User clicks **Yes**
3. Installation runs
4. Done!

**⚠️ Antivirus Note**: If using PS2EXE, test with major antivirus software first. Consider code signing certificate for enterprise distribution.

---

## Recommended Approaches (Ranked)

### 1. WinGet + PowerShell Script (Easiest & Most Maintainable)

**Best for**: Quick deployment, easy maintenance, leveraging existing package managers

Instead of creating a traditional MSI, create a **PowerShell script that uses WinGet** to install packages. This is simpler, more maintainable, and leverages Microsoft's official package manager.

**Advantages**:
- No complex MSI creation required
- Automatically gets updates from WinGet repository
- Easy to modify and extend
- Native Windows integration ([WinGet supports MSI, EXE, MSIX packages](https://learn.microsoft.com/en-us/windows/package-manager/winget/))
- Can be wrapped in a simple launcher EXE if needed

**Implementation**:

```powershell
# install-dev-tools.ps1
# Automated installation script for development tools

# Enable strict error handling
$ErrorActionPreference = "Stop"

Write-Host "Installing Development Tools Package..." -ForegroundColor Green

# Function to check if WinGet is installed
function Test-WinGetInstalled {
    try {
        winget --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Install WinGet if not present
if (-not (Test-WinGetInstalled)) {
    Write-Host "WinGet not found. Installing..." -ForegroundColor Yellow
    # Install WinGet from Microsoft Store or via GitHub releases
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

# List of applications to install
$apps = @(
    "Anthropic.ClaudeCode",           # Claude Code CLI
    "Microsoft.VisualStudioCode",     # VSCode
    "OpenJS.NodeJS.LTS",              # Node.js LTS
    "jqlang.jq",                      # jq
    "MikeFarah.yq",                   # yq
    "JohnMacFarlane.Pandoc",          # pandoc
    "prefix-dev.pixi"                 # pixi
)

# Install each application
foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Cyan
    winget install --id $app --silent --accept-package-agreements --accept-source-agreements
}

# Install VSCode extensions
Write-Host "Installing VSCode extensions..." -ForegroundColor Cyan
$extensions = @(
    "saoudrizwan.claude-dev",
    "kilocode.Kilo-Code",
    "openai.chatgpt",
    "anthropic.claude-code",
    "ms-python.python",
    "shd101wyy.markdown-preview-enhanced"
)

foreach ($ext in $extensions) {
    Write-Host "Installing extension: $ext" -ForegroundColor Gray
    code --install-extension $ext --force
}

# Install uv (Python package manager)
Write-Host "Installing uv..." -ForegroundColor Cyan
irm https://astral.sh/uv/install.ps1 | iex

# Install markitdown via uv
Write-Host "Installing markitdown..." -ForegroundColor Cyan
uv tool install markitdown

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "Please restart your terminal for changes to take effect." -ForegroundColor Yellow
```

**Distribution**: Package this script as a signed `.ps1` file or wrap it in a simple launcher using tools like PS2EXE.

**Sources**:
- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Automate WinGet with PowerShell](https://chosengambit.com/2024/11/ict/automate-winget-with-powershell-to-install-multiple-applications/)
- [WinGet Complete Guide 2025](https://talent500.com/blog/what-is-winget/)

---

### 2. WiX Toolset (Most Professional, Open Source)

**Best for**: Professional installers, complex requirements, open-source projects

WiX is the most popular open-source tool for creating Windows installers ([downloaded over 11 million times](https://wixtoolset.org/)).

**Advantages**:
- Industry standard, open-source
- Full control over installation process
- Integrates with Visual Studio and CI/CD
- Can handle complex scenarios (IIS, SQL Server, COM+, firewall rules)
- Text-based (XML) for version control

**Disadvantages**:
- Steep learning curve ([requires good understanding of Windows Installer](https://stackoverflow.com/questions/1544292/what-installation-product-to-use-installshield-wix-wise-advanced-installer))
- More complex for simple installers
- XML-based configuration

**Technology**: C# + XML (WiX markup)

**WiX v4 Example** (simplified):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="DevTools Installer"
           Manufacturer="Your Company"
           Version="1.0.0.0"
           UpgradeCode="PUT-GUID-HERE">

    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />

    <Feature Id="ProductFeature" Title="Development Tools" Level="1">

      <!-- Custom Action to run PowerShell script -->
      <CustomAction Id="InstallDevTools"
                    Execute="deferred"
                    Impersonate="no"
                    Directory="INSTALLFOLDER"
                    ExeCommand='powershell.exe -ExecutionPolicy Bypass -File "[INSTALLFOLDER]install-dev-tools.ps1"'
                    Return="check" />

      <InstallExecuteSequence>
        <Custom Action="InstallDevTools" After="InstallFiles">NOT Installed</Custom>
      </InstallExecuteSequence>

    </Feature>
  </Package>
</Wix>
```

**Alternative: WixSharp** (C# instead of XML):

```csharp
using WixSharp;

class Script
{
    static void Main()
    {
        var project = new Project("DevTools Installer",
            new Dir(@"%ProgramFiles%\DevTools",
                new File(@"install-dev-tools.ps1")),

            new ElevatedManagedAction(CustomActions.InstallTools,
                Return.check,
                When.After,
                Step.InstallFiles,
                Condition.NOT_Installed)
        );

        project.GUID = new Guid("PUT-GUID-HERE");
        project.BuildMsi();
    }
}

public class CustomActions
{
    [CustomAction]
    public static ActionResult InstallTools(Session session)
    {
        // Execute WinGet commands or PowerShell script
        return ActionResult.Success;
    }
}
```

**Getting Started**:
1. Install WiX Toolset from [wixtoolset.org](https://wixtoolset.org/)
2. Install Visual Studio extension (HeatWave for VS2022)
3. Create new "MSI Package (WiX v4)" project

**Sources**:
- [WiX Toolset Official Site](https://wixtoolset.org/)
- [How to Create MSI with WiX](https://stackoverflow.com/questions/28414986/how-to-create-msi-installer-with-wix)
- [Create MSI Installer with WiX Toolset](https://www.noser.com/techblog/create-msi-installer-using-wix-toolset/)
- [WixSharp Tutorial](https://github.com/oleg-shilo/wixsharp/wiki/Building-MSI-–-Step-by-step-tutorial)

---

### 3. Advanced Installer (Easiest GUI, Commercial)

**Best for**: Teams wanting GUI tools, rapid development, professional support

Advanced Installer provides a [GUI-based approach](https://www.advancedinstaller.com/versus/wix-toolset.html) that's much easier to use than WiX but is a commercial product (free edition available with limitations).

**Advantages**:
- Intuitive GUI interface
- No coding required for basic installers
- Built-in templates and wizards
- Can create suite installers (multiple apps in one)
- Professional support

**Disadvantages**:
- Commercial license required for full features
- Less control than WiX
- Not as suitable for version control (GUI-based project files)

**Creating Suite Installer** (multiple apps):

1. Open Advanced Installer
2. Select "Suite Installer" template ([introduced in v23.0](https://www.advancedinstaller.com/introducing-suite-installer-in-advanced-installer.html))
3. Add MSI/EXE packages to bundle
4. Configure installation sequence
5. Build the installer

**Technology**: GUI tool, outputs MSI or EXE bundles

**Sources**:
- [Advanced Installer vs WiX](https://www.advancedinstaller.com/versus/wix-toolset.html)
- [Creating Suite Installations](https://www.advancedinstaller.com/user-guide/tutorial-creating-suite-installations.html)
- [MSI Wrapper over EXE](https://www.advancedinstaller.com/user-guide/qa-msi-wrapper-over-exe.html)

---

### 4. Python-Based Solution

**Best for**: Python developers, cross-platform considerations

If you prefer Python, you can create an installer using PyInstaller + MSI creation tools.

**Advantages**:
- Familiar if you're a Python developer
- Can package Python-based installer logic

**Disadvantages**:
- Extra layer of complexity (Python → EXE → MSI)
- Larger file sizes
- Still needs WiX or Advanced Installer for final MSI

**Approach**:

```python
# installer.py
import subprocess
import sys

def install_winget_package(package_id):
    """Install a package using winget"""
    try:
        subprocess.run(['winget', 'install', '--id', package_id,
                       '--silent', '--accept-package-agreements',
                       '--accept-source-agreements'],
                      check=True)
        print(f"✓ Installed {package_id}")
    except subprocess.CalledProcessError:
        print(f"✗ Failed to install {package_id}")
        return False
    return True

def main():
    packages = [
        "Anthropic.ClaudeCode",
        "Microsoft.VisualStudioCode",
        "OpenJS.NodeJS.LTS",
        # ... more packages
    ]

    print("Installing development tools...")
    for pkg in packages:
        install_winget_package(pkg)

    print("Installation complete!")

if __name__ == "__main__":
    main()
```

**Convert to EXE**: `pyinstaller --onefile --windowed installer.py`

**Convert to MSI**: Use Advanced Installer or WiX to wrap the EXE

**Sources**:
- [Create MSI for Python Application](https://www.advancedinstaller.com/create-msi-python-executable.html)
- [Python to MSI with PyInstaller](https://www.pythontutorials.net/blog/python-files-to-an-msi-windows-installer/)
- [msicreator - Python MSI Generator](https://github.com/jpakkane/msicreator)

---

## Recommended Strategy for Common-Pack Tools

### Hybrid Approach (Best of Both Worlds)

1. **Use WinGet PowerShell script** for most installations
2. **Wrap with WiX Toolset** to create professional MSI package
3. **Include offline installers** as fallback (optional)

**Why this works**:
- WinGet handles package management (no need to bundle 500MB+ of installers)
- MSI provides professional deployment (Group Policy, SCCM compatible)
- Fallback ensures reliability in restricted networks

### Implementation Steps

1. **Create PowerShell script** (see approach #1) with:
   - WinGet package installation
   - VSCode extension installation
   - Python tools (uv) installation
   - MCP server configuration

2. **Create WiX installer** that:
   - Installs the PowerShell script to Program Files
   - Runs the script as a Custom Action with elevated privileges
   - Provides proper uninstall support

3. **Handle special cases**:
   - **Codex CLI**: Requires WSL on Windows, document in installer notes
   - **MCP servers**: Configuration files, not installed via WinGet
   - **VSCode extensions**: Installed via `code` CLI after VSCode is installed

**Example Custom Action in WiX to run WinGet**:

```xml
<CustomAction Id="RunWinGetInstaller"
              Execute="deferred"
              Impersonate="no"
              Directory="INSTALLFOLDER"
              ExeCommand='powershell.exe -ExecutionPolicy Bypass -NoProfile -File "[INSTALLFOLDER]install-dev-tools.ps1"'
              Return="check" />

<InstallExecuteSequence>
  <Custom Action="RunWinGetInstaller" After="InstallFiles">
    NOT Installed AND NOT REMOVE
  </Custom>
</InstallExecuteSequence>
```

**Sources**:
- [Execute WinGet in MSI with WiX](https://stackoverflow.com/questions/78314557/execute-winget-install-command-in-msi-installer-made-by-wix-4-0-5)
- [WinGet Windows Package Management Guide](https://www.advancedinstaller.com/winget-windows-package-management.html)

---

## Key Considerations

### Internet Connectivity
Most approaches require internet to download packages. For offline scenarios:
- Bundle installers directly (increases MSI size significantly)
- Use WinGet's offline mode with local source
- Create network share with cached packages

### Administrator Privileges
MSI installation requires admin rights. Ensure:
- Installer is signed with code signing certificate
- Custom Actions run with elevated privileges (`Impersonate="no"`)
- User is informed about UAC prompts

### Error Handling
Implement robust error handling:
- Log installation progress to file
- Provide rollback capability
- Show clear error messages to users
- Validate prerequisites (Windows version, .NET runtime if using C#)

### Uninstallation
Properly handle uninstall:
- Remove installed tools (or leave them for user to manage)
- Clean up configuration files
- Remove added PATH entries

### MCP Server Configuration
MCP servers require JSON configuration files in specific locations:
- Claude Desktop: `%APPDATA%\Claude\claude_desktop_config.json`
- Create configuration files during install
- Prompt for API keys (Tavily, Context7) post-install

---

## Final Recommendation

**For the common-pack.md installer, I recommend**:

### For Non-Technical Users (RECOMMENDED)

**Option 1: VBScript + PowerShell (Easiest)**
- ✅ **Development time**: 2-4 hours
- ✅ **User experience**: Double-click .vbs file → UAC prompt → Done
- ✅ **Maintenance**: Easy to modify PowerShell script
- ✅ **No special tools**: Just create two text files
- ✅ **Works everywhere**: All Windows versions
- ⚠️ **Distribution**: 2 files (.vbs + .ps1)

**Implementation**:
```
📦 Package Contents:
├── install-dev-tools.vbs    (User double-clicks this)
└── install-dev-tools.ps1    (Contains installation logic)
```

**Option 2: PS2EXE (Most Professional)**
- ✅ **Development time**: 3-5 hours
- ✅ **User experience**: Double-click .exe → UAC prompt → Done
- ✅ **Distribution**: Single .exe file
- ✅ **Professional**: Custom icon, metadata, branding
- ⚠️ **Antivirus**: May trigger false positives
- ⚠️ **Updates**: Requires recompilation for changes

**Implementation**:
```
📦 Package Contents:
└── DevToolsInstaller.exe    (Single file)
```

---

### For Enterprise Distribution

**Option 3: WiX Toolset MSI**
- ✅ **Development time**: 1-2 days (learning curve)
- ✅ **Enterprise features**: GPO deployment, SCCM integration
- ✅ **Professional**: Proper Windows Installer integration
- ✅ **Uninstall support**: Clean removal via Control Panel
- ⚠️ **Complexity**: Requires Windows Installer knowledge
- ⚠️ **Maintenance**: XML-based configuration

**Best for**:
- Corporate deployments
- IT department managed installations
- Group Policy distribution
- Need uninstall/upgrade support

---

### Technology Choice Summary:

| Scenario | Recommended Approach | Technology | Complexity | Time |
|----------|---------------------|------------|------------|------|
| **Personal use, friends** | VBScript + PowerShell | VBScript + PowerShell | Low | 2-4 hrs |
| **Public distribution** | PS2EXE | PowerShell → EXE | Low-Medium | 3-5 hrs |
| **Enterprise/Corporate** | WiX + PowerShell | XML/C# + PowerShell | Medium-High | 1-2 days |
| **Advanced custom UI** | C# WPF + PowerShell | C# + PowerShell | High | 2-3 days |

### My Specific Recommendation for Your Use Case:

Based on your requirements:
- ✅ Users just double-click
- ✅ Can accept UAC prompt via GUI
- ✅ Cannot type commands or troubleshoot
- ❌ Cannot sign PowerShell scripts

**Use: VBScript Wrapper + PowerShell Script**

**Why**:
1. Zero compilation needed - just create two text files
2. True double-click experience - users don't need to know anything
3. UAC prompt is familiar - users already understand "Yes/No"
4. Easy to update - modify .ps1 file, distribute both files again
5. No antivirus issues - plain text scripts, not executables
6. No special tools required - works on any Windows machine

**If you need single-file distribution**: Use PS2EXE, but test with major antivirus software first.

**Avoid**:
- Plain .ps1 files (execution policy issues)
- Python-based solutions (unnecessary complexity)
- Traditional MSI unless you need enterprise features

---

### Quick Start Guide

**Step 1**: Create `install-dev-tools.ps1` (the PowerShell script from earlier in this guide)

**Step 2**: Create `install-dev-tools.vbs` (the VBScript wrapper from "Solution 1" above)

**Step 3**: Package both files together in a ZIP file

**Step 4**: Send to users with instructions: "Extract and double-click the .vbs file"

**That's it!** No compilation, no signing, no special tools needed.

**Development Time Estimates**:
- VBScript + PowerShell: 2-4 hours
- PS2EXE: 3-5 hours
- WiX + PowerShell: 1-2 days (learning curve for WiX)
- Advanced Installer + PowerShell: 4-8 hours (faster with GUI)
- C# WPF GUI: 2-3 days

---

## Additional Resources

### Tools
- [WiX Toolset](https://wixtoolset.org/) - Open-source MSI creation
- [WixSharp](https://github.com/oleg-shilo/wixsharp) - C# alternative to WiX XML
- [Advanced Installer](https://www.advancedinstaller.com/) - Commercial GUI tool
- [MSI Wrapper](https://sugggest.com/software/msi-wrapper) - Wrap EXE in MSI
- [PS2EXE](https://github.com/MScholtes/PS2EXE) - PowerShell to EXE converter

### Documentation
- [Windows Installer XML (WiX) Tutorial](https://www.firegiant.com/wix/tutorial/)
- [WinGet Package Management](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [MSI Packaging Training](https://www.advancedinstaller.com/application-packaging-training/msi/ebook/create-suite-installations.html)
- [Creating Chained MSI Packages](https://www.advancedinstaller.com/user-guide/qa-chained-packages.html)

### Community Resources
- [Stack Overflow: WiX vs Other Installers](https://stackoverflow.com/questions/1544292/what-installation-product-to-use-installshield-wix-wise-advanced-installer)
- [Choosing Windows Packaging Tool](https://www.advancedinstaller.com/choosing-the-right-windows-packaging-tool-as-developer.html)
- [Silent Install Scripts](https://silentinstall.org/multiple-installations-scripting)

---

## Related Documentation

- See `context/design/packs/common-pack.md` for complete list of tools to install
- See `context/instructions/` for PowerShell script templates
- See `context/tools/` for custom installation utilities
