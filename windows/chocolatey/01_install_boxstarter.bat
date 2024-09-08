@echo off

cd installers
powershell -NoProfile -ExecutionPolicy bypass -command ". '%~dp0bootstrapper.ps1';Get-Boxstarter %*"
