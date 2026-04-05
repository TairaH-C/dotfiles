#Requires -Version 5.1
<#
.SYNOPSIS
    Disk management utility for WSL2/Docker environments on Windows 11
    
.DESCRIPTION
    This script helps manage disk space used by Docker and WSL2 VHDX files.
    It includes Docker image/volume pruning and VHDX optimization capabilities.
    
.FEATURES
    - Display Docker disk usage (docker system df)
    - Prune unused Docker images, containers, volumes, and build cache
    - Display WSL2 VHDX file size and location
    - Optimize VHDX file (requires admin privileges and Hyper-V)
    - Before/after disk usage comparison
    - Confirmation prompts for destructive operations
    
.EXAMPLE
    powershell -NoProfile -File "C:\Users\YourName\dotfiles\scripts\disk-management.ps1"
    
.NOTES
    Requires Windows 11 with WSL2 and Docker installed
    Hyper-V module required for VHDX optimization (may not be available on all systems)
#>

param(
    [switch]$SkipConfirm,
    [switch]$SkipVhdxOptimization
)

# Colors for output
$colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
}

function Write-Status {
    param([string]$Message, [string]$Status = 'Info')
    $color = $colors[$Status]
    Write-Host "$Message" -ForegroundColor $color
}

function Get-IsAdmin {
    $currentUser = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $currentUser.IsInRole($adminRole)
}

function Get-DockerSystemDf {
    try {
        $output = docker system df 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $output
        }
    } catch {
        Write-Status "Docker not running or not found" Error
        return $null
    }
}

function Show-DockerDiskUsage {
    Write-Status "`n=== DOCKER DISK USAGE ===" Info
    $usage = Get-DockerSystemDf
    if ($usage) {
        $usage | ForEach-Object { Write-Host $_ }
    } else {
        Write-Status "Unable to retrieve Docker disk usage" Error
    }
}

function Get-Confirmation {
    param([string]$Prompt = "Continue?")
    
    if ($SkipConfirm) {
        return $true
    }
    
    $response = Read-Host "$Prompt (y/n)"
    return $response -eq 'y' -or $response -eq 'Y'
}

function Invoke-DockerPrune {
    Write-Status "`n=== DOCKER PRUNING ===" Info
    
    # Show before state
    Write-Status "`nBefore pruning:" Info
    Show-DockerDiskUsage
    
    # Get confirmation
    if (-not (Get-Confirmation "Prune unused Docker objects?")) {
        Write-Status "Docker pruning skipped" Warning
        return
    }
    
    # Prune containers
    Write-Status "`nPruning stopped containers..." Info
    docker container prune -f 2>&1 | Out-Null
    
    # Prune dangling images
    Write-Status "Pruning dangling images..." Info
    docker image prune -f 2>&1 | Out-Null
    
    # Prune build cache
    Write-Status "Pruning build cache..." Info
    docker builder prune -f 2>&1 | Out-Null
    
    # Prune dangling volumes
    Write-Status "Pruning dangling volumes..." Info
    docker volume prune -f 2>&1 | Out-Null
    
    Write-Status "`nAfter pruning:" Info
    Show-DockerDiskUsage
    
    Write-Status "`n✓ Docker pruning completed" Success
}

function Get-VhdxInfo {
    try {
        $vhdxPath = "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.UbuntuonWindows_*\LocalState\ext4.vhdx"
        $vhdxFile = Get-Item $vhdxPath -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($vhdxFile) {
            return @{
                Path = $vhdxFile.FullName
                Size = $vhdxFile.Length
                SizeGB = [math]::Round($vhdxFile.Length / 1GB, 2)
            }
        }
    } catch {
        # Silently handle any errors in VHDX detection
    }
    
    return $null
}

function Show-VhdxInfo {
    Write-Status "`n=== WSL2 VHDX INFO ===" Info
    
    $vhdx = Get-VhdxInfo
    if ($vhdx) {
        Write-Host "Location: $($vhdx.Path)"
        Write-Host "Current size: $($vhdx.SizeGB) GB"
        Write-Status "ℹ Note: VHDX size does not shrink automatically. Use Optimize-VHD (admin) to compact." Info
    } else {
        Write-Status "WSL2 VHDX not found. Ensure WSL2 with Ubuntu is installed." Warning
    }
}

function Invoke-VhdxOptimization {
    if ($SkipVhdxOptimization) {
        Write-Status "`nVHDX optimization skipped (--SkipVhdxOptimization)" Warning
        return
    }
    
    Write-Status "`n=== VHDX OPTIMIZATION ===" Info
    
    if (-not (Get-IsAdmin)) {
        Write-Status "❌ Admin privileges required for VHDX optimization" Error
        Write-Status "Run PowerShell as Administrator and retry" Info
        return
    }
    
    # Check if Hyper-V module is available
    $hyperVModule = Get-Module -Name Hyper-V -ListAvailable -ErrorAction SilentlyContinue
    if (-not $hyperVModule) {
        Write-Status "⚠ Hyper-V module not available. Cannot optimize VHDX." Warning
        Write-Status "Enable Windows feature 'Hyper-V' or skip with --SkipVhdxOptimization" Info
        return
    }
    
    try {
        Import-Module Hyper-V -ErrorAction Stop
    } catch {
        Write-Status "Failed to import Hyper-V module: $_" Error
        return
    }
    
    $vhdx = Get-VhdxInfo
    if (-not $vhdx) {
        Write-Status "VHDX file not found for optimization" Error
        return
    }
    
    $beforeSize = $vhdx.SizeGB
    Write-Status "Before optimization: $beforeSize GB" Info
    
    if (-not (Get-Confirmation "Optimize VHDX file (may take several minutes)?")) {
        Write-Status "VHDX optimization skipped" Warning
        return
    }
    
    Write-Status "Optimizing VHDX (this may take 5-10 minutes)..." Info
    
    try {
        # Note: Optimize-VHD requires VHDX to not be in use
        # WSL2 must be shut down first with: wsl --shutdown
        $optimizeParams = @{
            Path = $vhdx.Path
            Mode = 'Full'
            ErrorAction = 'Stop'
        }
        
        Optimize-VHD @optimizeParams
        
        # Get new size
        $vhdxUpdated = Get-VhdxInfo
        $afterSize = $vhdxUpdated.SizeGB
        $savedGB = $beforeSize - $afterSize
        
        Write-Status "`n✓ VHDX optimization completed" Success
        Write-Host "Before: $beforeSize GB"
        Write-Host "After: $afterSize GB"
        Write-Status "Space saved: $savedGB GB" Success
    } catch {
        Write-Status "VHDX optimization failed: $_" Error
        Write-Status "Ensure WSL2 is shut down with: wsl --shutdown" Info
    }
}

function Show-Help {
    Write-Host @"
DISK MANAGEMENT UTILITY - WSL2/Docker on Windows 11

SYNOPSIS:
    This script manages disk space used by Docker and WSL2

USAGE:
    powershell -NoProfile -File disk-management.ps1 [options]

OPTIONS:
    -SkipConfirm              Skip confirmation prompts (useful for automation)
    -SkipVhdxOptimization     Skip VHDX optimization section
    -Help                     Show this help message

EXAMPLES:
    # Interactive mode with confirmation prompts
    ./disk-management.ps1
    
    # Non-interactive mode (auto-confirm all prompts)
    ./disk-management.ps1 -SkipConfirm
    
    # Skip VHDX optimization (faster)
    ./disk-management.ps1 -SkipVhdxOptimization

REQUIREMENTS:
    - Windows 11 with WSL2
    - Docker installed and configured
    - PowerShell 5.1 or later
    - Admin privileges (for VHDX optimization only)
    - Hyper-V module (for VHDX optimization only)

NOTES:
    - Docker pruning removes unused images, containers, volumes, and build cache
    - VHDX optimization compacts the WSL2 disk image (requires shutdown first)
    - Use 'wsl --shutdown' before VHDX optimization
    - VHDX file does not shrink automatically; regular optimization recommended

"@
}

# Main execution
try {
    Write-Status "=== WSL2/Docker Disk Management ===" Info
    Write-Host "Windows 11 Disk Space Manager`n"
    
    # Show current Docker usage
    Show-DockerDiskUsage
    
    # Run Docker pruning
    Invoke-DockerPrune
    
    # Show VHDX info
    Show-VhdxInfo
    
    # Attempt VHDX optimization
    Invoke-VhdxOptimization
    
    Write-Status "`n=== Summary ===" Info
    Write-Host "Docker images, containers, and volumes have been reviewed"
    Write-Host "VHDX optimization can be run when needed (admin required)"
    Write-Status "`nUse 'wsl --shutdown' before VHDX optimization for best results" Info
    
} catch {
    Write-Status "Error during execution: $_" Error
    exit 1
}
