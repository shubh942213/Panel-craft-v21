@echo off
setlocal
cd /d "%~dp0"
set "PANELCRAFT_ROOT=%~dp0"

echo.
echo Panel Craft - Local Testing Updater
echo -----------------------------------
echo The local test server must be stopped before updating.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $u='https://raw.githubusercontent.com/shubh942213/Panel-craft-v21/local-testing/UPDATE-LOCAL-TEST.ps1'; $p=Join-Path $env:TEMP 'PanelCraft-LocalUpdater.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; & $p -ProjectRoot $env:PANELCRAFT_ROOT; if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE } } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
  echo.
  echo Update failed. Read the error above and try again.
) else (
  echo.
  echo Update completed.
)
echo.
pause
