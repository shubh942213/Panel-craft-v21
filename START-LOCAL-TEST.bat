@echo off
setlocal
cd /d "%~dp0"
echo ==============================================
echo       PANEL CRAFT - LOCAL DEVELOPMENT
echo ==============================================
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is not installed. Install Node.js 22.12 or newer.
  pause
  exit /b 1
)
for /f "tokens=1" %%v in ('node -p "process.versions.node.split('.')[0]"') do set NODEMAJOR=%%v
if %NODEMAJOR% LSS 22 (
  echo Please install Node.js 22.12 or newer.
  pause
  exit /b 1
)
if not exist "node_modules" (
  echo Installing project dependencies...
  call npm install
  if errorlevel 1 goto :error
)
echo Generating component catalogue...
call npm run build
if errorlevel 1 goto :error
echo.
echo Starting Panel Craft at http://localhost:8888
echo Keep this window open while testing.
call npm run dev
goto :end
:error
echo.
echo Local setup failed. Read LOCAL-TESTING.md for troubleshooting.
pause
:end
endlocal
