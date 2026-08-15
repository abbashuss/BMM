[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Test-Executable {
    param([Parameter(Mandatory)][string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-LoopbackEndpoint {
    param([Parameter(Mandatory)][string]$Uri)

    try {
        $response = Invoke-WebRequest -Uri $Uri -TimeoutSec 2 -UseBasicParsing
        return [ordered]@{ reachable = $true; status_code = [int]$response.StatusCode }
    }
    catch {
        return [ordered]@{ reachable = $false; status_code = $null }
    }
}

$displayDevices = @()
$pnpOutput = & pnputil.exe /enum-devices /class Display 2>$null
foreach ($line in $pnpOutput) {
    if ($line -match '^\s*Device Description:\s*(.+)$') {
        $displayDevices += $Matches[1].Trim()
    }
}

$nvidia = $null
if (Test-Executable -Name 'nvidia-smi.exe') {
    $nvidia = (& nvidia-smi.exe --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null)
}

$result = [ordered]@{
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    display_devices = $displayDevices
    nvidia_smi = [ordered]@{
        available = Test-Executable -Name 'nvidia-smi.exe'
        summary = $nvidia
    }
    executables = [ordered]@{
        ollama = Test-Executable -Name 'ollama.exe'
        tailscale = Test-Executable -Name 'tailscale.exe'
        comfy = Test-Executable -Name 'comfy.exe'
    }
    endpoints = [ordered]@{
        app = Test-LoopbackEndpoint -Uri 'http://127.0.0.1:8000/api/v1/health'
        ollama = Test-LoopbackEndpoint -Uri 'http://127.0.0.1:11434/api/version'
        comfyui = Test-LoopbackEndpoint -Uri 'http://127.0.0.1:8188/system_stats'
        sdcpp = Test-LoopbackEndpoint -Uri 'http://127.0.0.1:7861/'
    }
}

$result | ConvertTo-Json -Depth 5
