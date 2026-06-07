# Full work session starter: GoodbyeDPI → Proxy → Ready for Claude Code
# Run this in a PowerShell window before starting Claude Code in ds mode.
param(
    [switch]$SkipProxy,
    [int]$Port = 8082
)

$repo = "D:\AI BASE\DEEPSEEK"
$green = "Green"
$cyan  = "Cyan"
$gray  = "Gray"

Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  DeepSeek → Claude Code Launcher    " -ForegroundColor $cyan
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""

# ── Step 1: GoodbyeDPI ──
Write-Host "[1/2] GoodbyeDPI (DPI bypass)" -ForegroundColor $cyan
$gdpi = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
if ($gdpi) {
    Write-Host "  Already running (PID: $($gdpi.Id))" -ForegroundColor $green
} else {
    & "$PSScriptRoot\start.ps1" -NoStatus
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED — run .\start.ps1 to diagnose" -ForegroundColor Red
        exit 1
    }
}

# ── Step 2: Proxy ──
if (-not $SkipProxy) {
    Write-Host "[2/2] DeepSeek proxy" -ForegroundColor $cyan
    & "$PSScriptRoot\proxy-start.ps1" -SkipGoodbyeDPI -Port $Port
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED — run .\proxy-start.ps1 to diagnose" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[2/2] Proxy: skipped (-SkipProxy)" -ForegroundColor $gray
}

# ── Done ──
Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  Setup complete. Now run:           " -ForegroundColor $green
Write-Host "                                     "
Write-Host "    ds                               " -ForegroundColor $green
Write-Host "                                     "
Write-Host "  (if ds alias is configured)        " -ForegroundColor $gray
Write-Host "  (or: proxy-start.ps1 in one window)" -ForegroundColor $gray
Write-Host "  (     ds in another window)        " -ForegroundColor $gray
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""
