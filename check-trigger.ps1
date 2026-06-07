$t = Get-ScheduledTask -TaskName "GoodbyeDPI AutoStart" -ErrorAction Stop
foreach ($trigger in $t.Triggers) {
    Write-Host "Trigger type: $($trigger.GetType().Name)"
    Write-Host "CIM class: $($trigger.CimClass.CimClassName)"
}
