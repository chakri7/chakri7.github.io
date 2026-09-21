@echo off
setlocal EnableExtensions
rem Run from the repo root on Windows. Do not assume a user folder name.
cd /d "%~dp0jev-ultrafast\scripts\windows"
if errorlevel 1 (
  echo This file must live at the root of the chakri7.github.io clone.
  echo Clone: git clone -b cursor/jev-ultrafast-poker-4ef6 https://github.com/chakri7/chakri7.github.io.git
  exit /b 1
)
call run-all.cmd
exit /b %ERRORLEVEL%
