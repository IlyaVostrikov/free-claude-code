$t = Get-ScheduledTask -TaskName "GoodbyeDPI AutoStart" -ErrorAction Stop
Write-Host "=== Principal ==="
$t.Principal | Format-List
Write-Host "=== Triggers ==="
$t.Triggers | Format-List
Write-Host "=== Actions ==="
$t.Actions | Format-List
Write-Host "=== Settings ==="
$t.Settings | Format-List
