@echo off
REM Quick launcher for Islands Dark Cursor installer
REM This runs the PowerShell installer with appropriate execution policy

echo Islands Dark Theme - Cursor Installer
echo =====================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-cursor.ps1"

pause
