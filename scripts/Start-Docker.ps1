#Requires -Version 5.1
<#
.SYNOPSIS
    Start Rancher Desktop, wait for Docker, then enter the devenv container.

.DESCRIPTION
    Use this as the commandline in a Windows Terminal profile:
      powershell.exe -ExecutionPolicy Bypass -NoExit -File "...\scripts\Start-Docker.ps1"

    The container is long-lived (docker compose up -d). All user state
    (Claude Code login, shell history, plugins, ...) lives in the
    devenv_home volume and survives container re-creation.

.PARAMETER Rebuild
    Rebuild the image and re-create the container before entering.
    Safe: home state is kept in the devenv_home volume.

.PARAMETER NoTmux
    Enter a plain zsh instead of attaching to the "main" tmux session.

.PARAMETER MaxRetries
    Max number of retries when checking Docker (default: 12).

.PARAMETER RetryIntervalSec
    Seconds between retries (default: 5).
#>
param(
    [switch]$Rebuild,
    [switch]$NoTmux,
    [int]$MaxRetries       = 12,
    [int]$RetryIntervalSec = 5
)

# ---------------------------------------------------------------------------
# 1. Wait for Docker
# ---------------------------------------------------------------------------
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    $rdExe = Join-Path $env:LOCALAPPDATA 'Programs\Rancher Desktop\Rancher Desktop.exe'
    if (-not (Test-Path $rdExe)) {
        Write-Host '[docker] Rancher Desktop not found.' -ForegroundColor Yellow
        return
    }

    $rdRunning = Get-Process -Name 'RancherDesktop' -ErrorAction SilentlyContinue
    if ($rdRunning) {
        Write-Host '[docker] Rancher Desktop is running. Waiting for Docker...' -ForegroundColor Cyan
    } else {
        Write-Host '[docker] Starting Rancher Desktop...' -ForegroundColor Cyan
        Start-Process -FilePath $rdExe
    }

    $ready = $false
    for ($i = 1; $i -le $MaxRetries; $i++) {
        Start-Sleep -Seconds $RetryIntervalSec
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            break
        }
        Write-Host ("[docker] Waiting... ({0}/{1})" -f $i, $MaxRetries) -ForegroundColor DarkGray
    }

    if (-not $ready) {
        Write-Host '[docker] Docker did not respond. Rancher Desktop may still be starting.' -ForegroundColor Yellow
        return
    }
}

Write-Host '[docker] Docker is ready.' -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Ensure the devenv container is up to date and running
# ---------------------------------------------------------------------------
$dotfilesDir = Split-Path $PSScriptRoot -Parent
$composeFile = Join-Path $dotfilesDir 'docker\docker-compose.yml'

if (-not (Test-Path $composeFile)) {
    Write-Host ('[docker] docker-compose.yml not found: {0}' -f $composeFile) -ForegroundColor Yellow
    return
}

if (-not $env:WORKSPACE_ROOT) {
    $env:WORKSPACE_ROOT = Split-Path $dotfilesDir -Parent
}

if ($Rebuild) {
    Write-Host '[docker] Rebuilding devenv image...' -ForegroundColor Cyan
    docker compose -f $composeFile build
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[docker] Image build failed.' -ForegroundColor Red
        return
    }
    docker compose -f $composeFile up -d --force-recreate
} else {
    # Idempotent: starts, or re-creates on config change, or does nothing.
    docker compose -f $composeFile up -d
}
if ($LASTEXITCODE -ne 0) {
    Write-Host '[docker] Failed to start devenv container.' -ForegroundColor Red
    return
}

# ---------------------------------------------------------------------------
# 3. Enter the container
# ---------------------------------------------------------------------------
if ($NoTmux) {
    Write-Host '[docker] Entering devenv (zsh)...' -ForegroundColor Cyan
    docker exec -it -u dev -w /home/dev/workspace devenv zsh
} else {
    Write-Host '[docker] Entering devenv (tmux session: main)...' -ForegroundColor Cyan
    docker exec -it -u dev -w /home/dev/workspace devenv tmux new-session -A -s main
}
