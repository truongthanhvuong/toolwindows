@echo off
setlocal
cd /d "%~dp0"
title VUONGTT TOOLKIT 2026 - 1-CLICK RELEASE
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Publish-Update.ps1"
pause
