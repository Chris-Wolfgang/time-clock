@echo off
rem Starts Time Clock (hidden) and opens it in the default browser. No admin rights needed.
rem To start it at logon, put a shortcut to this file in the folder opened by:  shell:startup
start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0time-clock.ps1"
