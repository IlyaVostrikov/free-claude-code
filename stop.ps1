# Stop GoodbyeDPI processes
param(
    [switch]$Force
)

$procs = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue

if (-not $procs) {
    Write-Host "GoodbyeDPI is not running" -ForegroundColor Yellow
    exit 0
}

Write-Host "Stopping GoodbyeDPI..." -ForegroundColor Cyan
$procs | ForEach-Object {
    Write-Host "  Killing PID $($_.Id)..." -NoNewline
    Stop-Process -Id $_.Id -Force
    Write-Host " stopped" -ForegroundColor Green
}

Start-Sleep -Seconds 1

$still = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
if ($still) {
    Write-Host "Some processes survived, using taskkill /f..." -ForegroundColor Yellow
    taskkill /f /im goodbyedpi.exe 2>&1 | Out-Null
}

Write-Host "GoodbyeDPI stopped" -ForegroundColor Green
