@echo off
timeout /t 15 /nobreak >nul
set DIR=%LOCALAPPDATA%\GoodbyeDPI\goodbyedpi-0.2.2
start "" /B "%DIR%\x86_64\goodbyedpi.exe" -5 --dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253 --blacklist "%DIR%\russia-blacklist.txt"
