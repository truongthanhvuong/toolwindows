@echo off
chcp 65001 >nul
title VUONGTT TOOLKIT 2026 - 1-CLICK RELEASE & AUTO-UPDATE PUBLISHER
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Publish-Update.ps1"
pause
