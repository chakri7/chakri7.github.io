@echo off
setlocal EnableExtensions
rem Run from the repo root on Windows. Pull this branch first so poker is not frame.html.
cd /d "%~dp0"
if errorlevel 1 (
  echo This file must live at the root of the chakri7.github.io clone.
  echo Clone: git clone -b cursor/jev-ultrafast-poker-4ef6 https://github.com/chakri7/chakri7.github.io.git
  exit /b 1
)
where git >nul 2>&1
if not errorlevel 1 (
  git fetch origin cursor/jev-ultrafast-poker-4ef6
  git checkout cursor/jev-ultrafast-poker-4ef6
  git reset --hard origin/cursor/jev-ultrafast-poker-4ef6
  echo Running commit:
  git rev-parse --short HEAD
)
cd /d "%~dp0jev-ultrafast\scripts\windows"
if errorlevel 1 (
  echo Missing jev-ultrafast\scripts\windows. You are not on cursor/jev-ultrafast-poker-4ef6.
  exit /b 1
)
call run-all.cmd
exit /b %ERRORLEVEL%
