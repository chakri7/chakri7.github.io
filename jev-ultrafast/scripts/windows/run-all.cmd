@echo off
setlocal EnableExtensions
rem Windows: open Chrome in debugging mode, then run every local test.
cd /d "%~dp0..\.."

echo Poker URL is https://www.247freepoker.com/ — never game/frame.html
git -C .. rev-parse --short HEAD 2>nul
echo.

echo === 1/5 Chrome remote debugging ===
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
echo === 2/5 uv sync ===
call uv sync
if errorlevel 1 exit /b 1

echo.
echo === 3/5 browser-harness doctor ===
call uv run browser-harness --doctor
echo doctor exit %ERRORLEVEL%

echo.
echo === 4/5 observe 247 Free Poker (no Jev API call) ===
call uv run python examples\observe_poker.py
if errorlevel 1 (
  echo observe_poker failed. Chrome debug must stay open.
  exit /b 1
)

echo.
echo === 5/5 Jev inspector ===
echo Opening http://127.0.0.1:8766/?scenario=poker in the debug Chrome profile.
start "" http://127.0.0.1:8766/?scenario=poker
echo Poker starts on the homepage. Do not open game/frame.html.
echo Then: Start demo -^> Choose next.
echo This window stays on uv run jev. Ctrl+C stops the inspector.
call uv run jev
exit /b %ERRORLEVEL%
