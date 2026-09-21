@echo off
setlocal EnableExtensions
rem Dedicated CDP Chrome. Kill leftover debug Chrome first — re-running without
rem that leaves the old 247 Game Frame tab in front.

set "PORT=9222"
set "PROFILE=%TEMP%\chrome-jev-debug"
set "POKER=https://www.247freepoker.com/"
set "CHROME="

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  echo Chrome not found. Install Google Chrome, then run this again.
  exit /b 1
)

echo Killing leftover Chrome that used profile chrome-jev-debug
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'chrome' -and $_.CommandLine -and ($_.CommandLine -like '*chrome-jev-debug*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
timeout /t 2 /nobreak >nul

if exist "%PROFILE%" (
  echo Wiping debug profile %PROFILE%
  rmdir /s /q "%PROFILE%"
)
mkdir "%PROFILE%"

echo Starting Chrome debugging on port %PORT%
echo Opening %POKER%  ^(not game/frame.html^)
echo Profile: %PROFILE%
echo Binary: %CHROME%

start "Chrome Jev Debug" "%CHROME%" --remote-debugging-port=%PORT% --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --disable-session-crashed-bubble --hide-crash-restore-bubble --disable-gpu "%POKER%"

set /a tries=0
:wait
set /a tries+=1
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:%PORT%/json/version -TimeoutSec 1).StatusCode } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto ready
if %tries% GEQ 30 (
  echo Chrome did not open port %PORT% in time.
  echo Close every Chrome window that was started by these scripts, then run once more.
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait

:ready
echo Chrome remote debugging is up: http://127.0.0.1:%PORT%/json/version
echo Look at the address bar: it must be %POKER%
echo The yellow 247 GAMES art is the game IFRAME, not a redirect.
exit /b 0
