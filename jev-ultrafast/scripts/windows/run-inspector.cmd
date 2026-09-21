@echo off
setlocal EnableExtensions
rem Start the Jev Ultrafast inspector. Chrome must already be in debug mode.
cd /d "%~dp0..\.."
where uv >nul 2>&1
if errorlevel 1 (
  echo uv is not on PATH. Install from https://docs.astral.sh/uv/ then reopen this terminal.
  exit /b 1
)
if not exist ".env" copy ".env.example" ".env" >nul
call uv sync
if errorlevel 1 exit /b 1
set JEV_AUTOSTART=poker
echo Inspector: http://127.0.0.1:8766/?scenario=poker
echo Autostarts poker on the homepage. Address bar must not be game/frame.html.
echo Choose next needs TYPESAFE_API_KEY in .env
call uv run jev
exit /b %ERRORLEVEL%
