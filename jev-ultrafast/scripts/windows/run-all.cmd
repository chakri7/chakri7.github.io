@echo off
setlocal EnableExtensions
rem Windows: debug Chrome, then Browser Use inspector with poker inside it.
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
echo === 4/4 Browser Use inspector ===
echo Watch http://127.0.0.1:8766  -- that is Browser Use x TypeSafe.
echo Poker is the LIVE screenshot inside that inspector, not a raw 247freepoker tab.
set JEV_AUTOSTART=poker
echo This window stays on uv run jev. Ctrl+C stops the inspector.
call uv run jev
exit /b %ERRORLEVEL%
