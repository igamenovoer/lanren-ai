<#
.SYNOPSIS
Configures pixi global settings (mirrors for conda and PyPI).

.DESCRIPTION
Updates the global pixi configuration using the `pixi config` command.
Sets mirrors for conda-forge and PyPI.

.PARAMETER Mirror
General preset.
Options:
- 'cn': Uses Tsinghua (tuna) mirrors for both conda-forge and PyPI.
- 'official': Removes mirror configurations.

.PARAMETER MirrorConda
Specific mirror for Conda. Overrides -Mirror.
Options: 'cn', 'official', 'tuna'.

.PARAMETER MirrorPypi
Specific mirror for PyPI. Overrides -Mirror.
Options: 'cn', 'official', 'aliyun', 'tuna'.

.PARAMETER NoExit
When specified, the script will wait for a key press before exiting.
This is useful when running from a double-clicked .bat file.
#>

[CmdletBinding()]
param(
    [switch]$NoExit,
    [Parameter(Mandatory=$false)
]
    [ValidateSet("cn", "official")]
    [string]$Mirror,

    [Parameter(Mandatory=$false)]
    [ValidateSet("cn", "official", "tuna")]
    [string]$MirrorConda,

    [Parameter(Mandatory=$false)]
    [ValidateSet("cn", "official", "aliyun", "tuna")]
    [string]$MirrorPypi
)
function Exit-WithWait {
    param([int]$Code = 0)
    if ($NoExit) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit $Code
}



if (-not $Mirror -and -not $MirrorConda -and -not $MirrorPypi) {
    Write-Output "Usage: .\config-comp.ps1 [-Mirror <cn|official>] [-MirrorConda <cn|official|tuna>] [-MirrorPypi <cn|official|aliyun|tuna>]"
    Write-Output "  -Mirror      : Sets both Conda and PyPI to preset (cn=tuna)"
    Write-Output "  -MirrorConda : Overrides Conda mirror"
    Write-Output "  -MirrorPypi  : Overrides PyPI mirror"
}

$ErrorActionPreference = "Stop"

if (-not (Get-Command pixi -ErrorAction SilentlyContinue)) {
    Write-Error "pixi command not found. Please install pixi first."
    Exit-WithWait 1
}

Write-Output "=== Configuring pixi Global Mirrors ==="

# URLs
$urls = @{
    "tuna_conda"   = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"
    "tuna_pypi"    = "https://pypi.tuna.tsinghua.edu.cn/simple"
    "aliyun_pypi"  = "https://mirrors.aliyun.com/pypi/simple/"
}

# Determine effective settings
# Default to $Mirror if set, otherwise null
$effectiveConda = if ($Mirror) { $Mirror } else { $null }
$effectivePypi = if ($Mirror) { $Mirror } else { $null }

# Override if specific params are set
if ($MirrorConda) { $effectiveConda = $MirrorConda }
if ($MirrorPypi) { $effectivePypi = $MirrorPypi }

# Resolve aliases
# Conda: cn -> tuna
if ($effectiveConda -eq "cn") { $effectiveConda = "tuna" }

# PyPI: cn -> tuna (default for pixi in this repo context)
if ($effectivePypi -eq "cn") { $effectivePypi = "tuna" }

# Apply Conda Config
if ($effectiveConda) {
    if ($effectiveConda -eq "official") {
        Write-Output "Unsetting conda-forge mirror..."
        # We use try/catch or ignore error because unset might fail if key doesn't exist (depending on version)
        # Also try unsetting the whole mirrors block if we can't target the specific key easily, 
        # but 'pixi config unset mirrors' is safer if we assume we manage the whole block.
        try {
            pixi config unset mirrors --global 2>$null
        } catch {
            Write-Warning "Failed to unset pixi conda-forge mirror: $($_.Exception.Message)"
        }
    } elseif ($effectiveConda -eq "tuna") {
        $urlKey = "${effectiveConda}_conda"
        $url = $urls[$urlKey]
        Write-Output "Setting conda-forge mirror to $effectiveConda ($url)..."
        
        # Construct JSON object for mirrors
        # { "https://conda.anaconda.org/conda-forge": ["url"] }
        $jsonVal = '{ "https://conda.anaconda.org/conda-forge": ["' + $url + '"] }'
        
        pixi config set mirrors $jsonVal --global
    }
}

# Apply PyPI Config
if ($effectivePypi) {
    $pypiKey = "pypi-config.index-url"
    
    if ($effectivePypi -eq "official") {
        Write-Output "Unsetting PyPI index-url..."
        try {
            pixi config unset $pypiKey --global 2>$null
        } catch {
            Write-Warning "Failed to unset pixi PyPI index-url: $($_.Exception.Message)"
        }
    } else {
        $url = $null
        if ($effectivePypi -eq "tuna") { $url = $urls["tuna_pypi"] }
        elseif ($effectivePypi -eq "aliyun") { $url = $urls["aliyun_pypi"] }
        
        if ($url) {
            Write-Output "Setting PyPI index-url to $effectivePypi ($url)..."
            pixi config set $pypiKey $url --global
        }
    }
}

Write-Output "Configuration complete."


Exit-WithWait 0
