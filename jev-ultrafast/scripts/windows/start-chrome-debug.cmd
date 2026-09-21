@echo off
setlocal EnableExtensions
rem Open Google Chrome with CDP on 9222 using a dedicated profile.
rem A dedicated profile is required: a Chrome that was already running without
rem --remote-debugging-port cannot be retrofitted.

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

if not exist "%PROFILE%" mkdir "%PROFILE%"
del /q "%PROFILE%\Default\Current Session" 2>nul
del /q "%PROFILE%\Default\Current Tabs" 2>nul
del /q "%PROFILE%\Default\Last Session" 2>nul
del /q "%PROFILE%\Default\Last Tabs" 2>nul

echo Starting Chrome debugging on port %PORT%
echo Profile: %PROFILE%
echo Binary: %CHROME%

start "Chrome Jev Debug" "%CHROME%" --remote-debugging-port=%PORT% --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --disable-session-crashed-bubble --hide-crash-restore-bubble --disable-gpu about:blank

set /a tries=0
:wait
set /a tries+=1
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:%PORT%/json/version -TimeoutSec 1).StatusCode } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto ready
if %tries% GEQ 30 (
  echo Chrome did not open port %PORT% in time.
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait

:ready
echo Chrome remote debugging is up: http://127.0.0.1:%PORT%/json/version
exit /b 0
