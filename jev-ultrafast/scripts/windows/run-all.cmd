@echo off
setlocal EnableExtensions
rem Windows: one debug Chrome on the poker homepage, then autostart the inspector.
cd /d "%~dp0..\.."

echo Poker URL is https://www.247freepoker.com/ - never game/frame.html
git -C .. rev-parse --short HEAD 2>nul
echo.

echo === 1/4 Chrome remote debugging ===
call "%~dp0start-chrome-debug.cmd"
if errorlevel 1 exit /b 1

where uv >nul 2>&1
if errorlevel 1 (
  echo.
  echo uv is not on PATH.
  echo Install: powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
  echo Then close and reopen this window and run run-all.cmd again.
  exit /b 1
)

if not exist ".env" (
  copy ".env.example" ".env" >nul
  echo Created .env from .env.example
  echo Put TYPESAFE_API_KEY in jev-ultrafast\.env for Choose next / Run automatically.
)

echo.
echo === 2/4 uv sync ===
call uv sync
if errorlevel 1 exit /b 1

echo.
echo === 3/4 browser-harness doctor ===
call uv run browser-harness --doctor
echo doctor exit %ERRORLEVEL%

echo.
echo === 4/4 Jev inspector ^(autostarts poker, no extra Start demo click^) ===
set JEV_AUTOSTART=poker
echo Address bar in the debug Chrome must stay https://www.247freepoker.com/
echo game/frame.html inside that page is the iframe. That is the real table.
echo Inspector: http://127.0.0.1:8766/?scenario=poker
echo Inspector will open in the SAME debug Chrome, not your everyday Chrome.
start "" cmd /c "%~dp0open-inspector.cmd"
echo This window stays on uv run jev. Ctrl+C stops the inspector.
call uv run jev
exit /b %ERRORLEVEL%
