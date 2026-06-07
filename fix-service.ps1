Write-Host "=== Stopping all GoodbyeDPI ==="
sc.exe stop GoodbyeDPI 2>&1
Start-Sleep -Seconds 2

Get-Process -Name "goodbyedpi" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "=== Recreating service ==="
sc.exe delete GoodbyeDPI 2>&1

$dir = "$env:LOCALAPPDATA\GoodbyeDPI\goodbyedpi-0.2.2"
$exe = "$dir\x86_64\goodbyedpi.exe"
$bl = "$dir\russia-blacklist.txt"

Write-Host "EXE: $exe"
Write-Host "Blacklist: $bl"
Write-Host "EXE exists: $(Test-Path $exe)"
Write-Host "BL exists: $(Test-Path $bl)"
Write-Host "BL lines: $((Get-Content $bl).Count)"

$binPath = "$exe -5 --blacklist $bl"
Write-Host "Service cmd: $binPath"

sc.exe create "GoodbyeDPI" binPath= $binPath start= "auto" 2>&1
sc.exe description "GoodbyeDPI" "Passive DPI blocker" 2>&1
sc.exe start "GoodbyeDPI" 2>&1

Start-Sleep -Seconds 2
Get-Service "GoodbyeDPI" | Format-List Name, Status
