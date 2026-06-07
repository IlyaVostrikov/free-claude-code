# Install GoodbyeDPI autostart (scheduled task at logon)
# Consolidated from register-autostart.ps1 + update-autostart.ps1 + install-autostart.ps1
#
# Uses PowerShell ScheduledTask cmdlets (not schtasks) for reliable registration.
# The task waits 15s after logon, then launches GoodbyeDPI silently.
#
# Usage:
#   .\install-autostart.ps1           # Install and test
#   .\install-autostart.ps1 -TestOnly # Only test if it starts (no install)

param(
    [switch]$TestOnly,
    [switch]$SkipTest
)

$taskName = "GoodbyeDPI AutoStart"
$dir = "$env:LOCALAPPDATA\GoodbyeDPI\goodbyedpi-0.2.2"
$exe = "$dir\x86_64\goodbyedpi.exe"
$bl  = "$dir\russia-blacklist.txt"

# ── Pre-flight checks ──
if (-not (Test-Path $exe)) {
    Write-Host "ERROR: GoodbyeDPI not found at $exe" -ForegroundColor Red
    Write-Host "Run .\fresh-install.ps1 first to download and extract it."
    exit 1
}
if (-not (Test-Path $bl)) {
    Write-Host "ERROR: Blacklist not found at $bl" -ForegroundColor Red
    Write-Host "Re-download GoodbyeDPI with .\fresh-install.ps1"
    exit 1
}
Write-Host "GoodbyeDPI: $exe" -ForegroundColor Gray
Write-Host "Blacklist:    $bl" -ForegroundColor Gray
Write-Host ""

# ── Install ──
if (-not $TestOnly) {
    Write-Host "=== Installing scheduled task ===" -ForegroundColor Cyan

    # 1. Clean up any old registration (service + task)
    Write-Host "[1/5] Cleaning up old installations..."
    sc.exe stop GoodbyeDPI 2>&1 | Out-Null
    sc.exe delete GoodbyeDPI 2>&1 | Out-Null
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    schtasks /delete /tn "$taskName" /f 2>&1 | Out-Null

    # Kill any running instances
    Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "  Done"

    # 2. Build the delayed launcher command
    # Waits 15s for network stack to be ready, then starts GoodbyeDPI silently
    Write-Host "[2/5] Building launch command..."
    $actionArgs = "/c `"timeout /t 15 /nobreak >nul && start `"`" /B `"$exe`" -5 --dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253 --blacklist `"$bl`"`""
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument $actionArgs
    Write-Host "  Command: cmd.exe $actionArgs" -ForegroundColor Gray

    # 3. Trigger: at user logon
    Write-Host "[3/5] Setting trigger (at logon)..."
    $trigger = New-ScheduledTaskTrigger -AtLogon
    Write-Host "  Trigger: AtLogon"

    # 4. Principal: current user, interactive, highest privileges
    Write-Host "[4/5] Configuring principal..."
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    Write-Host "  User: $env:USERDOMAIN\$env:USERNAME (Highest)"

    # 5. Settings: allow on battery, start when available
    Write-Host "[5/5] Registering task..."
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

    Register-ScheduledTask -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force `
        -Description "Passive DPI bypass — auto-starts 15s after logon" | Out-Null

    Write-Host ""
    Write-Host "Task registered successfully" -ForegroundColor Green
    Write-Host ""
}

# ── Test ──
if (-not $SkipTest) {
    Write-Host "=== Testing: starting task now ===" -ForegroundColor Cyan
    Write-Host "(Task has a built-in 15s delay before GoodbyeDPI starts)"
    Write-Host ""

    Start-ScheduledTask -TaskName $taskName
    Write-Host "Waiting 22s for delayed launch..." -ForegroundColor Gray

    for ($i = 1; $i -le 22; $i++) {
        Start-Sleep -Seconds 1
        Write-Host -NoNewline "."
    }
    Write-Host ""

    $proc = Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host ""
        Write-Host "SUCCESS: GoodbyeDPI running" -ForegroundColor Green
        Write-Host "  PID:      $($proc.Id)"
        Write-Host "  Started:  $($proc.StartTime)"
        Write-Host "  Memory:   $([math]::Round($proc.WorkingSet64 / 1MB, 1)) MB"
        Write-Host ""
        Write-Host "Autostart will run at every login. To remove: .\remove-autostart.ps1"
    } else {
        Write-Host ""
        Write-Host "WARNING: Not running after 22s" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Diagnostic steps:"
        Write-Host "  1. Check task exists:  .\check-task.ps1"
        Write-Host "  2. Check last run:     .\task-info.ps1"
        Write-Host "  3. Manual test:        .\start.ps1"
        Write-Host "  4. Interactive debug:  & `"$exe`" -5 --blacklist `"$bl`""
    }
} else {
    Write-Host "Skipping test. Task will activate at next logon." -ForegroundColor Gray
}
