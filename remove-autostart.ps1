# Remove GoodbyeDPI autostart — kill process + delete scheduled task
param(
    [switch]$Force  # Skip confirmation
)

$taskName = "GoodbyeDPI AutoStart"

if (-not $Force) {
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Stop all GoodbyeDPI processes"
    Write-Host "  2. Remove scheduled task '$taskName'"
    Write-Host ""
    $confirm = Read-Host "Continue? [y/N]"
    if ($confirm -notmatch '^[yY]') {
        Write-Host "Cancelled."
        exit 0
    }
}

# 1. Kill processes
Write-Host "Stopping GoodbyeDPI processes..." -ForegroundColor Cyan
$procs = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    taskkill /f /im goodbyedpi.exe 2>&1 | Out-Null
    Write-Host "  Processes stopped" -ForegroundColor Green
} else {
    Write-Host "  No running processes found" -ForegroundColor Gray
}

# 2. Remove scheduled task (try both registration methods)
Write-Host "Removing scheduled task..." -ForegroundColor Cyan
$removed = $false

# PowerShell cmdlet removal
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  Removed via Unregister-ScheduledTask" -ForegroundColor Green
    $removed = $true
}

# schtasks removal (fallback / different task namespace)
schtasks /delete /tn "$taskName" /f 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Removed via schtasks" -ForegroundColor Green
    $removed = $true
}

if (-not $removed) {
    Write-Host "  No scheduled task found" -ForegroundColor Gray
}

# 3. Verify
$procs = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

Write-Host ""
if (-not $procs -and -not $task) {
    Write-Host "Cleanup complete — no processes, no scheduled task" -ForegroundColor Green
} else {
    if ($procs) { Write-Host "WARNING: Process still running (PID: $($procs.Id))" -ForegroundColor Red }
    if ($task)  { Write-Host "WARNING: Scheduled task still exists" -ForegroundColor Red }
}
