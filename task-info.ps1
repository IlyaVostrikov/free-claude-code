$info = Get-ScheduledTaskInfo -TaskName "GoodbyeDPI AutoStart" -ErrorAction Stop
Write-Host "LastRunTime: $($info.LastRunTime)"
Write-Host "LastTaskResult: $($info.LastTaskResult)"
Write-Host "NextRunTime: $($info.NextRunTime)"
Write-Host "NumberOfMissedRuns: $($info.NumberOfMissedRuns)"
