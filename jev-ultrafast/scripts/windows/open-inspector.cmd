@echo off
setlocal EnableExtensions
rem Open the inspector inside the debug Chrome profile (not everyday Chrome).
timeout /t 3 /nobreak >nul
set "PROFILE=%TEMP%\chrome-jev-debug"
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if not defined CHROME exit /b 1
start "" "%CHROME%" --user-data-dir="%PROFILE%" --remote-debugging-port=9222 "http://127.0.0.1:8766/?scenario=poker"
exit /b 0
