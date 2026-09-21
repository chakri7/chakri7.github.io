@echo off
setlocal EnableExtensions
rem Dedicated CDP Chrome. Close EVERY Chrome window first so an old
rem "247 Game Frame" tab cannot stay in front of the live homepage.

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

echo Closing ALL Chrome windows (old Game Frame tabs hide the live table).
taskkill /F /IM chrome.exe /T >nul 2>&1
timeout /t 3 /nobreak >nul

if exist "%PROFILE%" (
  echo Wiping debug profile %PROFILE%
  rmdir /s /q "%PROFILE%"
)
mkdir "%PROFILE%"

echo Starting Chrome debugging on port %PORT%
echo Opening %POKER%  (not game/frame.html)
echo Profile: %PROFILE%
echo Binary: %CHROME%
echo Look at THIS new window only. Taskbar title becomes: JEV LIVE POKER homepage

start "Chrome Jev Debug" "%CHROME%" --remote-debugging-port=%PORT% --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --disable-session-crashed-bubble --hide-crash-restore-bubble --window-size=1280,840 --window-position=40,40 --disable-gpu "%POKER%"

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
echo.
echo === Debug Chrome tabs (this is the proof) ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0list-chrome-tabs.ps1"
if errorlevel 1 exit /b 1
echo.
echo If the yellow 247 GAMES art is UNDER a 247 FREE POKER header, that is the homepage iframe.
echo Isolated frame.html has NO site header and the tab title is 247 Game Frame.
exit /b 0
