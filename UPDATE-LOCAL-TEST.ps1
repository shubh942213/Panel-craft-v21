param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

if (!(Test-Path -LiteralPath (Join-Path $ProjectRoot 'public\index.html'))) {
    throw 'Panel Craft folder not found. Keep UPDATE-LOCAL-TEST.bat in the project root and run it from there.'
}
if (!(Test-Path -LiteralPath (Join-Path $ProjectRoot 'package.json'))) {
    throw 'package.json is missing. This does not look like the Panel Craft project root.'
}

$work = Join-Path $env:TEMP ('PanelCraftUpdate-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zipPath = Join-Path $work 'local-testing.zip'
    $extractPath = Join-Path $work 'extract'
    $archiveUrl = 'https://github.com/shubh942213/Panel-craft-v21/archive/refs/heads/local-testing.zip'

    Write-Host ''
    Write-Host 'Downloading latest Panel Craft local-testing files...' -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing -Uri $archiveUrl -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $source = Get-ChildItem -LiteralPath $extractPath -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'public\index.html') } |
        Select-Object -First 1

    if (!$source) {
        throw 'The downloaded archive did not contain the expected Panel Craft files.'
    }

    Write-Host 'Applying update to this folder...' -ForegroundColor Cyan
    & robocopy.exe $source.FullName $ProjectRoot /E /R:2 /W:1 /XD '.git' 'node_modules' '.netlify'
    $copyCode = $LASTEXITCODE
    if ($copyCode -ge 8) {
        throw "File copy failed (Robocopy exit code $copyCode)."
    }

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host ''
        Write-Host 'Refreshing the component library manifest...' -ForegroundColor Cyan
        Push-Location $ProjectRoot
        try {
            & npm run build
            if ($LASTEXITCODE -ne 0) {
                throw 'The Panel Craft build step failed. Review the message above.'
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host 'npm was not found; skipped the manifest build. Run START-LOCAL-TEST.bat to start the app.' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host 'Panel Craft has been updated in this folder.' -ForegroundColor Green
    Write-Host 'Your node_modules, .git, and .netlify folders were left untouched.'
    Write-Host 'Start the app using START-LOCAL-TEST.bat.'
}
finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}
