# Start the DeepSeek proxy server
# By default opens in a new window so you can see logs.
# Use -Background to run silently (for autostart scenarios).
param(
    [switch]$Background,
    [switch]$SkipGoodbyeDPI,
    [int]$Port = 8082
)

$repo = "D:\AI BASE\DEEPSEEK"
$url = "http://127.0.0.1:${Port}"

# 1. Ensure GoodbyeDPI is running (proxy needs DPI bypass to reach api.deepseek.com)
if (-not $SkipGoodbyeDPI) {
    $gdpi = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
    if (-not $gdpi) {
        Write-Host "GoodbyeDPI not running. Starting it first..." -ForegroundColor Yellow
        & "$PSScriptRoot\start.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to start GoodbyeDPI. Run .\start.ps1 manually to diagnose." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "GoodbyeDPI: running (PID: $($gdpi.Id))" -ForegroundColor Gray
    }
}

# 2. Check if proxy already running
try {
    $check = Invoke-WebRequest -Uri "$url/v1/models" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "Proxy already running at $url" -ForegroundColor Green
    Write-Host "Admin UI: $url/admin"
    exit 0
} catch {
    # Not running — proceed
}

# 3. Start proxy
Write-Host "Starting proxy at $url ..." -ForegroundColor Cyan

if ($Background) {
    # Silent background: redirect output to temp log
    $log = "$env:TEMP\fcc-proxy.log"
    Write-Host "  Background mode — logs: $log" -ForegroundColor Gray
    $proc = Start-Process -FilePath "uv" `
        -ArgumentList "run", "uvicorn", "server:app", "--host", "127.0.0.1", "--port", $Port `
        -WorkingDirectory $repo `
        -WindowStyle Hidden `
        -RedirectStandardOutput $log `
        -RedirectStandardError $log `
        -PassThru
    Write-Host "  PID: $($proc.Id)"
} else {
    # New visible window
    Start-Process -FilePath "pwsh" `
        -ArgumentList "-NoExit", "-Command", "cd `"$repo`"; Write-Host 'Proxy starting...' -ForegroundColor Cyan; uv run uvicorn server:app --host 127.0.0.1 --port $Port" `
        -WindowStyle Normal
}

# 4. Wait for it to be ready
Write-Host "Waiting for proxy to be ready..." -NoNewline
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    Write-Host -NoNewline "."
    try {
        $check = Invoke-WebRequest -Uri "$url/v1/models" -TimeoutSec 2 -ErrorAction Stop
        Write-Host ""
        Write-Host "Proxy ready at $url" -ForegroundColor Green
        Write-Host "Admin UI: $url/admin"
        exit 0
    } catch {
        continue
    }
}

Write-Host ""
Write-Host "WARNING: Proxy didn't respond after 30s. Check the server window for errors." -ForegroundColor Yellow
exit 1
