@echo off
echo Stopping GoodbyeDPI...
taskkill /f /im goodbyedpi.exe >nul 2>&1
if %errorlevel%==0 (
    echo GoodbyeDPI stopped
) else (
    echo GoodbyeDPI was not running
)
pause
