@echo off
setlocal EnableExtensions
rem Dump the 247 Free Poker action table (no TypeSafe call).
cd /d "%~dp0..\.."
where uv >nul 2>&1
if errorlevel 1 (
  echo uv is not on PATH. Install from https://docs.astral.sh/uv/ then reopen this terminal.
  exit /b 1
)
if not exist ".env" copy ".env.example" ".env" >nul
call uv sync
if errorlevel 1 exit /b 1
call uv run python examples\observe_poker.py
exit /b %ERRORLEVEL%
