@echo off
setlocal
cd /d "%~dp0"
set "PANELCRAFT_ROOT=%~dp0"

echo.
echo Panel Craft - Local Testing Updater
echo -----------------------------------
echo The local test server must be stopped before updating.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $p=$null; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $h=@{'User-Agent'='PanelCraft-Local-Updater';'Accept'='application/vnd.github+json'}; $base='https://api.github.com/repos/shubh942213/Panel-craft-v21'; $br=Invoke-RestMethod -UseBasicParsing -Uri ($base+'/branches/local-testing') -Headers $h; $tree=Invoke-RestMethod -UseBasicParsing -Uri ($base+'/git/trees/'+$br.commit.commit.tree.sha+'?recursive=1') -Headers $h; if($tree.truncated){throw 'GitHub returned an incomplete file list.'}; $f=$tree.tree | Where-Object {$_.type -eq 'blob' -and $_.path -eq 'UPDATE-LOCAL-TEST.ps1'} | Select-Object -First 1; if(!$f){throw 'Could not find the updater script on local-testing.'}; $blob=Invoke-RestMethod -UseBasicParsing -Uri ($base+'/git/blobs/'+$f.sha) -Headers $h; if($blob.encoding -ne 'base64'){throw 'GitHub returned an unsupported updater format.'}; $p=Join-Path $env:TEMP ('PanelCraft-LocalUpdater-'+[guid]::NewGuid().ToString('N')+'.ps1'); [IO.File]::WriteAllBytes($p,[Convert]::FromBase64String(($blob.content -replace '\s',''))); & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p -ProjectRoot $env:PANELCRAFT_ROOT; $rc=$LASTEXITCODE; if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue}; exit $rc } catch { Write-Host $_ -ForegroundColor Red; if($p -and (Test-Path -LiteralPath $p)){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue}; exit 1 }"
if errorlevel 1 (
  echo.
  echo Update failed. Read the error above and try again.
) else (
  echo.
  echo Update completed.
)
echo.
pause
