#Requires -Version 5.1
<#
.SYNOPSIS
    Windows 11 initial setup - installs development tools via winget.

.DESCRIPTION
    Run from a NORMAL (non-elevated) PowerShell window.

    Admin-required packages are installed FIRST in a single UAC-elevated child
    PowerShell window (one prompt covers the whole admin batch). Once that
    window closes, the parent session continues with the user-scope packages.
    The winget executable path is resolved in the user session and passed to
    the elevated child explicitly, so installs work even when winget is not
    on the elevated PATH (e.g. when the elevated profile differs).

.EXAMPLE
    # Normal run from an ordinary PowerShell window
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1

.EXAMPLE
    # Skip everything that would require UAC elevation
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1 -SkipAdminPackages

.EXAMPLE
    # Preview the install plan without making changes
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1 -DryRun

.NOTES
    - Requires winget (App Installer) 1.6 or newer.
    - WSL2 enablement is admin-only and is NOT performed here; run
      `wsl --install` separately from an elevated PowerShell.
#>

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipAdminPackages,
    # Internal: re-entrant flags used when this script re-invokes itself
    # inside an elevated PowerShell window for the admin batch.
    [switch]$AdminBatchOnly,
    [string]$ResultsFile,
    [string]$WingetPath
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Package catalog
# ---------------------------------------------------------------------------
# Admin-required packages are listed first to make the install order explicit:
# the UAC batch runs before any user-scope work begins.
# ---------------------------------------------------------------------------
$packages = @(
    @{ Id = 'Microsoft.Office';                    Name = 'Microsoft 365 (Office)';        RequiresAdmin = $true  }
    @{ Id = 'SUSE.RancherDesktop';                 Name = 'Rancher Desktop';               RequiresAdmin = $true  }
    @{ Id = 'Microsoft.AzureCLI';                  Name = 'Azure CLI';                     RequiresAdmin = $true  }
    @{ Id = 'Microsoft.Azure.FunctionsCoreTools';  Name = 'Azure Functions Core Tools';    RequiresAdmin = $true  }
    @{ Id = 'Microsoft.SQLServerManagementStudio'; Name = 'SQL Server Management Studio';  RequiresAdmin = $true  }
    @{ Id = 'Microsoft.PowerShell';                Name = 'PowerShell 7';                  RequiresAdmin = $true  }
    @{ Id = 'yuru7.PlemolJP';                      Name = 'PlemolJP (Nerd Font)';          RequiresAdmin = $true  }
    @{ Id = 'Microsoft.PowerToys';                 Name = 'Microsoft PowerToys';           RequiresAdmin = $false }
    @{ Id = 'Microsoft.WindowsTerminal';           Name = 'Windows Terminal';              RequiresAdmin = $false }
    @{ Id = 'Microsoft.VisualStudioCode';          Name = 'Visual Studio Code';            RequiresAdmin = $false }
    @{ Id = 'Microsoft.Azure.StorageExplorer';     Name = 'Azure Storage Explorer';        RequiresAdmin = $false }
    @{ Id = 'astral-sh.uv';                        Name = 'uv (Python package manager)';   RequiresAdmin = $false }
    @{ Id = 'Git.Git';                             Name = 'Git';                           RequiresAdmin = $false }
    @{ Id = 'OpenJS.NodeJS.LTS';                   Name = 'Node.js (LTS)';                 RequiresAdmin = $false }
    @{ Id = 'GoLang.Go';                           Name = 'Go';                            RequiresAdmin = $false }
    @{ Id = 'Zoom.Zoom';                           Name = 'Zoom';                          RequiresAdmin = $false }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Section($Text) {
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}
function Write-Info($Text)  { Write-Host "  $Text" -ForegroundColor Gray }
function Write-Ok($Text)    { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Skip($Text)  { Write-Host "  [SKIP] $Text" -ForegroundColor DarkGray }
function Write-Warn2($Text) { Write-Host "  [WARN] $Text" -ForegroundColor Yellow }
function Write-Fail($Text)  { Write-Host "  [FAIL] $Text" -ForegroundColor Red }

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-WingetPath {
    # winget is installed per-user under WindowsApps and the alias may not be
    # on PATH inside elevated sessions or the built-in Administrator account.
    # Resolve the executable explicitly so we never rely on the alias.
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $candidate) { return $candidate }
    $pkg = Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending | Select-Object -First 1
    if ($pkg) {
        $exe = Join-Path $pkg.InstallLocation 'winget.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

function Test-PackageInstalled {
    param([string]$Winget, [string]$Id)
    try {
        $output = & $Winget list --id $Id --exact --accept-source-agreements 2>&1 | Out-String
        return ($output -match [regex]::Escape($Id))
    } catch {
        return $false
    }
}

function Invoke-WingetInstall {
    param([string]$Winget, [string]$Id, [string]$Scope)
    if ($DryRun) {
        Write-Info "(dry-run) winget install --id $Id --scope $Scope --silent"
        return 0
    }
    & $Winget install --id $Id --exact --scope $Scope --silent `
        --accept-package-agreements --accept-source-agreements | Out-Host
    return $LASTEXITCODE
}

function Install-OnePackage {
    param([string]$Winget, [hashtable]$Pkg, [string]$Scope)
    Write-Host ''
    Write-Host ("-> {0} ({1}) [{2}]" -f $Pkg.Name, $Pkg.Id, $Scope) -ForegroundColor White
    if (-not $Force -and (Test-PackageInstalled -Winget $Winget -Id $Pkg.Id)) {
        Write-Skip 'already installed'
        return @{ Status = 'SKIP'; Code = 0 }
    }
    $code = Invoke-WingetInstall -Winget $Winget -Id $Pkg.Id -Scope $Scope
    if ($code -eq 0) {
        Write-Ok ("installed ({0} scope)" -f $Scope)
        return @{ Status = 'OK'; Code = $code }
    }
    Write-Fail "winget exit code $code"
    return @{ Status = 'FAIL'; Code = $code }
}

# ---------------------------------------------------------------------------
# Re-entrant: admin-only batch (executed inside the elevated child window)
# ---------------------------------------------------------------------------
if ($AdminBatchOnly) {
    Write-Section 'Admin-scope packages (elevated session)'
    $winget = if ($WingetPath -and (Test-Path $WingetPath)) { $WingetPath } else { Resolve-WingetPath }
    if (-not $winget) {
        Write-Fail 'winget not found in elevated context.'
        if ($ResultsFile) { '[]' | Set-Content -LiteralPath $ResultsFile -Encoding UTF8 }
        Write-Host ''
        Write-Host 'Press any key to close this window...' -ForegroundColor Cyan
        [System.Console]::ReadKey($true) | Out-Null
        exit 1
    }
    Write-Info ("winget : {0}" -f $winget)

    $results = @()
    foreach ($pkg in $packages) {
        if (-not $pkg.RequiresAdmin) { continue }
        try {
            $r = Install-OnePackage -Winget $winget -Pkg $pkg -Scope 'machine'
        } catch {
            Write-Fail $_.Exception.Message
            $r = @{ Status = 'FAIL'; Code = -1 }
        }
        $results += [pscustomobject]@{
            Id     = $pkg.Id
            Name   = $pkg.Name
            Status = $r.Status
            Code   = $r.Code
        }
    }
    if ($ResultsFile) {
        $results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $ResultsFile -Encoding UTF8
    }
    Write-Host ''
    Write-Host 'Admin batch finished. Press any key to close this window...' -ForegroundColor Cyan
    [System.Console]::ReadKey($true) | Out-Null
    exit 0
}

# ---------------------------------------------------------------------------
# Main (user session)
# ---------------------------------------------------------------------------
Write-Section 'Windows initial setup'
Write-Info ("Running as {0} | Elevated={1} | DryRun={2}" -f $env:USERNAME, (Test-IsAdmin), $DryRun)

$winget = Resolve-WingetPath
if (-not $winget) {
    Write-Fail 'winget not found. Install "App Installer" from Microsoft Store, then re-run.'
    exit 1
}
Write-Info ("winget : {0}" -f $winget)

$results = @{ OK = 0; SKIP = 0; FAIL = 0; DEFER = 0 }

# 1) Admin packages first (high priority)
$adminPkgs = @($packages | Where-Object { $_.RequiresAdmin })
if ($adminPkgs.Count -gt 0) {
    if ($SkipAdminPackages) {
        Write-Section 'Admin-scope packages skipped (-SkipAdminPackages)'
        $adminPkgs | ForEach-Object { Write-Skip ("{0} ({1})" -f $_.Name, $_.Id) }
        $results.DEFER += $adminPkgs.Count
    } else {
        Write-Section 'Admin-scope packages (high priority)'
        Write-Info 'A UAC prompt will appear. An elevated PowerShell window will run all admin installs in one batch.'
        $adminPkgs | ForEach-Object { Write-Info ("- {0} ({1})" -f $_.Name, $_.Id) }

        $resultsFile = Join-Path $env:TEMP ("winget-admin-{0}.json" -f ([guid]::NewGuid()))
        $selfPath = $PSCommandPath
        if (-not $selfPath) { $selfPath = $MyInvocation.MyCommand.Path }
        $childArgs = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', $selfPath,
            '-AdminBatchOnly',
            '-ResultsFile', $resultsFile,
            '-WingetPath', $winget
        )
        if ($Force)  { $childArgs += '-Force' }
        if ($DryRun) { $childArgs += '-DryRun' }

        $elevationOk = $true
        try {
            Start-Process -FilePath 'powershell.exe' -ArgumentList $childArgs -Verb RunAs -Wait | Out-Null
        } catch {
            $elevationOk = $false
            Write-Fail ("UAC elevation cancelled or failed: {0}" -f $_.Exception.Message)
        }

        if ($elevationOk -and (Test-Path $resultsFile)) {
            $adminResults = Get-Content -LiteralPath $resultsFile -Raw | ConvertFrom-Json
            Remove-Item -LiteralPath $resultsFile -Force -ErrorAction SilentlyContinue
            Write-Host ''
            Write-Host '  Admin batch results:' -ForegroundColor Cyan
            foreach ($r in $adminResults) {
                $color = switch ($r.Status) {
                    'OK'   { 'Green' }
                    'SKIP' { 'DarkGray' }
                    default { 'Red' }
                }
                Write-Host ("    {0,-40} {1}" -f $r.Name, $r.Status) -ForegroundColor $color
                $results[$r.Status]++
            }
        } else {
            Write-Warn2 'Admin batch produced no results (elevation declined or child crashed).'
            $results.FAIL += $adminPkgs.Count
        }
    }
}

# 2) User-scope packages
Write-Section 'User-scope packages'
foreach ($pkg in @($packages | Where-Object { -not $_.RequiresAdmin })) {
    try {
        $r = Install-OnePackage -Winget $winget -Pkg $pkg -Scope 'user'
        $results[$r.Status]++
    } catch {
        Write-Fail $_.Exception.Message
        $results.FAIL++
    }
}

# 3) Summary
Write-Section 'Summary'
Write-Host ("  installed : {0}" -f $results.OK)    -ForegroundColor Green
Write-Host ("  skipped   : {0}" -f $results.SKIP)  -ForegroundColor DarkGray
Write-Host ("  deferred  : {0}" -f $results.DEFER) -ForegroundColor Yellow
Write-Host ("  failed    : {0}" -f $results.FAIL)  -ForegroundColor Red

Write-Section 'Manual follow-up'
Write-Info 'WSL2             : run `wsl --install` from an elevated PowerShell, then reboot.'
Write-Info 'Rancher Desktop  : after install, launch once and choose `dockerd (moby)` + enable WSL integration.'
Write-Info 'Microsoft 365    : sign in with the organization account to complete activation.'
Write-Info 'PowerToys        : enable FancyZones / PowerToys Run / Keyboard Manager on first launch.'

if ($results.FAIL -gt 0) { exit 1 } else { exit 0 }
