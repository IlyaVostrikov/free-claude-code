$url = 'https://github.com/ValdikSS/GoodbyeDPI/releases/download/0.2.2/goodbyedpi-0.2.2.zip'
$zip = "$env:TEMP\goodbyedpi-fresh.zip"
$dir = "$env:LOCALAPPDATA\GoodbyeDPI"

Write-Host "[1/3] Downloading..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zip

Write-Host "[2/3] Extracting..."
Expand-Archive -Path $zip -DestinationPath $dir -Force
Remove-Item $zip

Write-Host "[3/3] Done. Files in: $dir"
Write-Host ""
Write-Host "Now run from ADMIN PowerShell:"
Write-Host "  cd $dir\goodbyedpi-0.2.2"
Write-Host "  .\1_russia_blacklist_dnsredir.cmd"
