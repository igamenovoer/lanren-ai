# How to Install WinGet in China via Command Line

This guide provides methods to install Windows Package Manager (winget) in China using accessible mirrors and direct download links to bypass slow CDN connectivity.

## Background

The official winget CDN (`cdn.winget.microsoft.com`) often has slow connectivity from China, as it resolves to IP `152.199.39.108` which has limited bandwidth for Chinese users. This guide provides alternative installation methods using direct downloads and mirrors.

## Prerequisites

- Windows 10 version 1809 (build 17763) or later, or Windows 11
- Administrator privileges
- PowerShell or Command Prompt access

## Method 1: PowerShell One-Liner from CMD

Run this from an elevated Command Prompt:

```cmd
powershell -Command "& { Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'; Add-AppxPackage -Path 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx'; Add-AppxPackage -Path 'https://aka.ms/getwinget' }"
```

## Method 2: Batch Script Installation

Create a file named `install-winget-cn.bat` with the following content:

```cmd
@echo off
echo Installing WinGet dependencies and WinGet itself...

REM Download and install VCLibs
powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%TEMP%\VCLibs.appx'"
powershell -Command "Add-AppxPackage -Path '%TEMP%\VCLibs.appx'"

REM Download and install UI.Xaml 2.8
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile '%TEMP%\UIXaml.appx'"
powershell -Command "Add-AppxPackage -Path '%TEMP%\UIXaml.appx'"

REM Download and install WinGet
powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile '%TEMP%\winget.msixbundle'"
powershell -Command "Add-AppxPackage -Path '%TEMP%\winget.msixbundle'"

REM Cleanup
del "%TEMP%\VCLibs.appx"
del "%TEMP%\UIXaml.appx"
del "%TEMP%\winget.msixbundle"

echo Installation complete!
pause
```

Run the batch file as administrator.

## Method 3: PowerShell Script with Error Handling

Create a PowerShell script `install-winget-cn.ps1`:

```powershell
# Check if winget version is less than 1.22.1000
IF ([System.Version](Get-AppxPackage Microsoft.DesktopAppInstaller).Version -lt [System.Version]'1.22.1000' ) {
    Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    Add-AppxPackage -Path "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    Add-AppxPackage -Path "https://aka.ms/getwinget"
}
```

Run with: `powershell -ExecutionPolicy Bypass -File install-winget-cn.ps1`

## Method 4: Using CDN Cache Source (Alternative)

If the main installation fails, try installing from the CDN cache:

```cmd
powershell -Command "Add-AppxPackage -Path 'https://cdn.winget.microsoft.com/cache/source.msix'"
```

## Method 5: Manual Download and Install

If online installation is too slow, download files manually:

1. **Download VCLibs**: https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
2. **Download UI.Xaml 2.8**: https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx
3. **Download WinGet**: https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

Then install locally:

```cmd
powershell -Command "Add-AppxPackage -Path 'C:\path\to\VCLibs.appx'"
powershell -Command "Add-AppxPackage -Path 'C:\path\to\UIXaml.appx'"
powershell -Command "Add-AppxPackage -Path 'C:\path\to\winget.msixbundle'"
```

## Verification

After installation, verify winget is working:

```cmd
winget --version
```

You should see output like: `v1.7.11132`

## Troubleshooting

### Error: Package depends on framework that could not be found

This means dependencies are missing. Ensure you install in this order:
1. Microsoft.VCLibs (C++ Runtime)
2. Microsoft.UI.Xaml.2.8 (UI Framework)
3. Microsoft.DesktopAppInstaller (WinGet)

### Error: Failed when opening source(s)

Run these commands:

```cmd
winget source reset
Add-AppxPackage -Path https://cdn.winget.microsoft.com/cache/source.msix
```

### Slow Download Speeds

Consider:
- Using a VPN or proxy for GitHub access
- Downloading files manually during off-peak hours
- Using a download manager with resume capability

## China-Specific Considerations

1. **GitHub Access**: GitHub may have variable connectivity in China. Consider downloading during off-peak hours or using a mirror service.

2. **CDN Performance**: The Microsoft CDN (`cdn.winget.microsoft.com`) has known performance issues in China. The direct GitHub links often work better.

3. **Alternative Mirrors**: Currently, there is no official Azure China mirror for winget. This is a known issue tracked in [microsoft/winget-cli#2489](https://github.com/microsoft/winget-cli/issues/2489).

4. **Proxy Configuration**: If using a corporate proxy, configure winget after installation:

```cmd
winget settings --enable ProxyCommandLineOptions
winget install <package> --proxy http://proxy.example.com:8080
```

## Related Resources

- [Official WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [WinGet CLI GitHub Repository](https://github.com/microsoft/winget-cli)
- [WinGet Package Repository](https://github.com/microsoft/winget-pkgs)
- [China Connectivity Issue Tracking](https://github.com/microsoft/winget-cli/issues/2489)
- [Microsoft UI.Xaml Releases](https://github.com/microsoft/microsoft-ui-xaml/releases)

## See Also

- `howto-create-msi-installer-for-dev-tools.md` - Creating installers for development tools
- `design-of-ps1-installer.md` - PowerShell installer design patterns
