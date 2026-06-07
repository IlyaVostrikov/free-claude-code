# Start GoodbyeDPI interactively (for testing / manual use)
param(
    [switch]$NoStatus
)

$dir = "$env:LOCALAPPDATA\GoodbyeDPI\goodbyedpi-0.2.2"
$exe = "$dir\x86_64\goodbyedpi.exe"
$bl  = "$dir\russia-blacklist.txt"

if (-not (Test-Path $exe)) {
    Write-Host "ERROR: GoodbyeDPI not found at $exe" -ForegroundColor Red
    Write-Host "Run .\fresh-install.ps1 first to download it."
    exit 1
}

# Check if already running
$existing = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "GoodbyeDPI already running (PID: $($existing.Id))" -ForegroundColor Yellow
    if (-not $NoStatus) {
        Write-Host "Use '.\stop.ps1' to stop it first, or '.\start.ps1 -NoStatus' to skip this check."
    }
    exit 0
}

Write-Host "Starting GoodbyeDPI..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $exe -ArgumentList @(
    "-5",
    "--dns-addr", "77.88.8.8",
    "--dns-port", "1253",
    "--dnsv6-addr", "2a02:6b8::feed:0ff",
    "--dnsv6-port", "1253",
    "--blacklist", $bl
) -WindowStyle Hidden -PassThru

Start-Sleep -Seconds 2

if ($proc.HasExited) {
    Write-Host "FAILED: GoodbyeDPI exited immediately (exit code: $($proc.ExitCode))" -ForegroundColor Red
    Write-Host "Try running it interactively to see errors:"
    Write-Host "  & `"$exe`" -5 --dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253 --blacklist `"$bl`""
    exit 1
}

Write-Host "GoodbyeDPI running (PID: $($proc.Id))" -ForegroundColor Green
