#Requires -Version 5.1
<#
.SYNOPSIS
    Windows 11 initial setup - installs development tools via winget.

.DESCRIPTION
    Installs the standard development software stack on a fresh Windows 11 machine.
    User scope is preferred wherever supported so that future updates do not
    require administrator privileges. Packages that only support machine scope
    or require Windows features are flagged and can be skipped with
    -SkipAdminPackages when running as a non-admin user.

.EXAMPLE
    # Recommended: run from an ordinary PowerShell window
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1

.EXAMPLE
    # Only install user-scope packages (no admin prompts)
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
    [switch]$SkipAdminPackages,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Package catalog
# ---------------------------------------------------------------------------
# scope: 'user'    -> install with --scope user (no admin needed)
#        'machine' -> install with --scope machine (admin required)
#        'either'  -> try user first, fall back to machine
# ---------------------------------------------------------------------------
$packages = @(
    @{ Id = 'Microsoft.PowerToys';               Name = 'Microsoft PowerToys';            Scope = 'user'    }
    @{ Id = 'Microsoft.VisualStudioCode';        Name = 'Visual Studio Code';             Scope = 'user'    }
    @{ Id = 'Microsoft.Azure.StorageExplorer';   Name = 'Azure Storage Explorer';         Scope = 'user'    }
    @{ Id = 'astral-sh.uv';                      Name = 'uv (Python package manager)';    Scope = 'user'    }
    @{ Id = 'Git.Git';                           Name = 'Git';                            Scope = 'either'  }
    @{ Id = 'OpenJS.NodeJS.LTS';                 Name = 'Node.js (LTS)';                  Scope = 'either'  }
    @{ Id = 'GoLang.Go';                         Name = 'Go';                             Scope = 'either'  }
    @{ Id = 'Zoom.Zoom';                         Name = 'Zoom';                           Scope = 'user'    }
    @{ Id = 'Microsoft.AzureCLI';                Name = 'Azure CLI';                      Scope = 'machine' }
    @{ Id = 'Microsoft.Azure.FunctionsCoreTools';Name = 'Azure Functions Core Tools';     Scope = 'machine' }
    @{ Id = 'Microsoft.SQLServerManagementStudio';Name = 'SQL Server Management Studio';  Scope = 'machine' }
    @{ Id = 'SUSE.RancherDesktop';               Name = 'Rancher Desktop';                Scope = 'machine' }
    @{ Id = 'Microsoft.Office';                  Name = 'Microsoft 365 (Office)';         Scope = 'machine' }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Section($Text) {
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Write-Info($Text)    { Write-Host "  $Text" -ForegroundColor Gray }
function Write-Ok($Text)      { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Skip($Text)    { Write-Host "  [SKIP] $Text" -ForegroundColor DarkGray }
function Write-Warn2($Text)   { Write-Host "  [WARN] $Text" -ForegroundColor Yellow }
function Write-Fail($Text)    { Write-Host "  [FAIL] $Text" -ForegroundColor Red }

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-PackageInstalled {
    param([string]$Id)
    try {
        $output = winget list --id $Id --exact --accept-source-agreements 2>&1 | Out-String
        return ($output -match [regex]::Escape($Id))
    } catch {
        return $false
    }
}

function Invoke-WingetInstall {
    param(
        [string]$Id,
        [string]$Scope  # 'user' | 'machine'
    )
    if ($DryRun) {
        Write-Info "(dry-run) winget install --id $Id --scope $Scope --silent"
        return 0
    }
    $args = @(
        'install', '--id', $Id, '--exact',
        '--scope', $Scope,
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements'
    )
    & winget @args | Out-Host
    return $LASTEXITCODE
}

function Install-Package {
    param([hashtable]$Pkg)

    Write-Host ''
    Write-Host ("-> {0} ({1})" -f $Pkg.Name, $Pkg.Id) -ForegroundColor White

    if (-not $Force -and (Test-PackageInstalled -Id $Pkg.Id)) {
        Write-Skip 'already installed'
        return 'SKIP'
    }

    switch ($Pkg.Scope) {
        'user' {
            $code = Invoke-WingetInstall -Id $Pkg.Id -Scope 'user'
            if ($code -eq 0) { Write-Ok 'installed (user scope)'; return 'OK' }
            Write-Fail "winget exit code $code"
            return 'FAIL'
        }
        'machine' {
            if ($SkipAdminPackages) {
                Write-Warn2 'requires admin - skipped (-SkipAdminPackages)'
                return 'DEFER'
            }
            if (-not (Test-IsAdmin)) {
                Write-Warn2 'requires admin - re-run elevated or use -SkipAdminPackages'
                return 'DEFER'
            }
            $code = Invoke-WingetInstall -Id $Pkg.Id -Scope 'machine'
            if ($code -eq 0) { Write-Ok 'installed (machine scope)'; return 'OK' }
            Write-Fail "winget exit code $code"
            return 'FAIL'
        }
        'either' {
            $code = Invoke-WingetInstall -Id $Pkg.Id -Scope 'user'
            if ($code -eq 0) { Write-Ok 'installed (user scope)'; return 'OK' }
            Write-Warn2 "user scope failed (exit $code); retrying with machine scope"
            if ($SkipAdminPackages -or -not (Test-IsAdmin)) {
                Write-Warn2 'skipping machine-scope fallback (no admin)'
                return 'DEFER'
            }
            $code = Invoke-WingetInstall -Id $Pkg.Id -Scope 'machine'
            if ($code -eq 0) { Write-Ok 'installed (machine scope)'; return 'OK' }
            Write-Fail "winget exit code $code"
            return 'FAIL'
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
Write-Section 'Windows initial setup'
Write-Info ("Running as {0} | Admin={1} | DryRun={2}" -f $env:USERNAME, (Test-IsAdmin), $DryRun)

if (-not (Test-WingetAvailable)) {
    Write-Fail 'winget not found. Install "App Installer" from Microsoft Store, then re-run.'
    exit 1
}

$results = @{ OK = 0; SKIP = 0; FAIL = 0; DEFER = 0 }
$deferred = @()
$failed   = @()

foreach ($pkg in $packages) {
    try {
        $status = Install-Package -Pkg $pkg
    } catch {
        Write-Fail $_.Exception.Message
        $status = 'FAIL'
    }
    $results[$status]++
    if ($status -eq 'DEFER') { $deferred += $pkg }
    if ($status -eq 'FAIL')  { $failed   += $pkg }
}

Write-Section 'Summary'
Write-Host ("  installed : {0}" -f $results.OK)    -ForegroundColor Green
Write-Host ("  skipped   : {0}" -f $results.SKIP)  -ForegroundColor DarkGray
Write-Host ("  deferred  : {0}" -f $results.DEFER) -ForegroundColor Yellow
Write-Host ("  failed    : {0}" -f $results.FAIL)  -ForegroundColor Red

if ($deferred.Count -gt 0) {
    Write-Section 'Needs admin (re-run elevated)'
    $deferred | ForEach-Object { Write-Warn2 ("{0}  ({1})" -f $_.Name, $_.Id) }
}
if ($failed.Count -gt 0) {
    Write-Section 'Failed - see README manual install section'
    $failed | ForEach-Object { Write-Fail ("{0}  ({1})" -f $_.Name, $_.Id) }
}

Write-Section 'Manual follow-up'
Write-Info 'WSL2             : run `wsl --install` from an elevated PowerShell, then reboot.'
Write-Info 'Rancher Desktop  : after install, launch once and choose `dockerd (moby)` + enable WSL integration.'
Write-Info 'Microsoft 365    : sign in with the organization account to complete activation.'
Write-Info 'SSMS             : machine-scope only; requires elevated winget or manual installer.'

if ($results.FAIL -gt 0) { exit 1 } else { exit 0 }
