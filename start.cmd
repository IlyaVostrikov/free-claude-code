@echo off
set DIR=%LOCALAPPDATA%\GoodbyeDPI\goodbyedpi-0.2.2
set EXE=%DIR%\x86_64\goodbyedpi.exe
set BL=%DIR%\russia-blacklist.txt

echo Starting GoodbyeDPI...
start "" /B "%EXE%" -5 --dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253 --blacklist "%BL%"

timeout /t 2 /nobreak >nul
tasklist /fi "imagename eq goodbyedpi.exe" | find /i "goodbyedpi" >nul
if %errorlevel%==0 (
    echo GoodbyeDPI is RUNNING
) else (
    echo FAILED to start GoodbyeDPI
)
pause
