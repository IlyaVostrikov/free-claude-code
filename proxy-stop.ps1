# Stop the DeepSeek proxy server
param(
    [int]$Port = 8082
)

# 1. Find process holding the port
Write-Host "Looking for proxy on port $Port..." -ForegroundColor Cyan

$found = $false

# Try TCP connection check
$listener = netstat -ano 2>$null | Select-String "127.0.0.1:${Port}"
if ($listener) {
    $found = $true
    Write-Host "Port $Port is in use:" -ForegroundColor Yellow
    $listener | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    # Extract PIDs
    $pids = $listener | ForEach-Object {
        $line = $_ -replace '\s+', ' '
        $parts = $line.Split(' ')
        $parts[-1]
    } | Sort-Object -Unique

    foreach ($pid in $pids) {
        try {
            $proc = Get-Process -Id $pid -ErrorAction Stop
            Write-Host "  Killing $($proc.ProcessName) (PID: $pid)..." -NoNewline
            Stop-Process -Id $pid -Force
            Write-Host " stopped" -ForegroundColor Green
        } catch {
            Write-Host "  PID $pid already gone" -ForegroundColor Gray
        }
    }
}

# 2. Also look for python/uvicorn processes
$pythonProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match 'uvicorn' -or $_.CommandLine -match 'server:app'
}
if ($pythonProcs) {
    $found = $true
    $pythonProcs | ForEach-Object {
        Write-Host "  Killing $($_.ProcessName) (PID: $($_.Id))..." -NoNewline
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host " stopped" -ForegroundColor Green
    }
}

# 3. Verify
Start-Sleep -Seconds 1
$still = netstat -ano 2>$null | Select-String "127.0.0.1:${Port}"
if ($still) {
    Write-Host "WARNING: Port $Port still in use. Try:" -ForegroundColor Red
    Write-Host "  netstat -ano | findstr $Port"
    Write-Host "  taskkill /f /pid <PID>"
} else {
    if ($found) {
        Write-Host "Proxy stopped" -ForegroundColor Green
    } else {
        Write-Host "Proxy was not running on port $Port" -ForegroundColor Yellow
    }
}
