@echo off
setlocal EnableExtensions
rem CDP Chrome only. Do not open 247freepoker here -- Browser Use (127.0.0.1:8766) owns that tab.

set "PORT=9222"
set "PROFILE=%TEMP%\chrome-jev-debug"
set "CHROME="

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  echo Chrome not found. Install Google Chrome, then run this again.
  exit /b 1
)

echo Closing ALL Chrome windows so only the Browser Use debug profile remains.
taskkill /F /IM chrome.exe /T >nul 2>&1
timeout /t 3 /nobreak >nul

if exist "%PROFILE%" (
  echo Wiping debug profile %PROFILE%
  rmdir /s /q "%PROFILE%"
)
mkdir "%PROFILE%"

echo Starting Chrome debugging on port %PORT%
echo Opening about:blank  (poker loads inside Browser Use, not this tab)
echo Profile: %PROFILE%
echo Binary: %CHROME%

start "Chrome Jev Debug" "%CHROME%" --remote-debugging-port=%PORT% --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --disable-session-crashed-bubble --hide-crash-restore-bubble --disable-site-isolation-trials --disable-features=IsolateOrigins,site-per-process --window-size=1280,840 --window-position=40,40 --disable-gpu about:blank

set /a tries=0
:wait
set /a tries+=1
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:%PORT%/json/version -TimeoutSec 1).StatusCode } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto ready
if %tries% GEQ 30 (
  echo Chrome did not open port %PORT% in time.
  echo Close every Chrome window, then run once more.
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait

:ready
echo Chrome remote debugging is up: http://127.0.0.1:%PORT%/json/version
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0list-chrome-tabs.ps1"
echo.
echo Next: uv run jev opens Browser Use at http://127.0.0.1:8766
echo Watch THAT page. The 247 table is the screenshot inside it.
exit /b 0
