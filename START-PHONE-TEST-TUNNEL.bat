@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0cloudflared.exe" (
  "%~dp0cloudflared.exe" tunnel --url http://localhost:8888
  goto :end
)
where cloudflared >nul 2>nul
if errorlevel 1 (
  echo cloudflared was not found.
  echo Download the Windows 64-bit executable from:
  echo https://developers.cloudflare.com/tunnel/downloads/
  echo Save cloudflared.exe beside this BAT file, then run this again.
  pause
  exit /b 1
)
cloudflared tunnel --url http://localhost:8888
:end
endlocal
