param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$libraryPath = Join-Path $ProjectRoot 'public\components_library'
if (!(Test-Path -LiteralPath (Join-Path $ProjectRoot 'public\index.html'))) {
    throw 'Panel Craft folder not found. Keep UPDATE-LOCAL-TEST.bat in the project root and run it from there.'
}
if (!(Test-Path -LiteralPath (Join-Path $ProjectRoot 'package.json'))) {
    throw 'package.json is missing. This does not look like the Panel Craft project root.'
}
if (!(Test-Path -LiteralPath $libraryPath -PathType Container)) {
    throw 'The existing public\components_library folder was not found. Extract the full testing package once before using the small updater.'
}

$work = Join-Path $env:TEMP ('PanelCraftUpdate-' + [guid]::NewGuid().ToString('N'))
$stage = Join-Path $work 'changed-files'
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $branch = 'local-testing'
    $repoApi = 'https://api.github.com/repos/shubh942213/Panel-craft-v21'
    $headers = @{
        'User-Agent' = 'PanelCraft-Local-Updater'
        'Accept' = 'application/vnd.github+json'
    }

    Write-Host ''
    Write-Host 'Checking the latest Panel Craft update...' -ForegroundColor Cyan
    $branchInfo = Invoke-RestMethod -UseBasicParsing -Uri ($repoApi + '/branches/' + $branch) -Headers $headers
    $commitSha = [string]$branchInfo.commit.sha
    $treeSha = [string]$branchInfo.commit.commit.tree.sha
    if (!$commitSha -or !$treeSha) {
        throw 'Could not resolve the latest Panel Craft branch revision.'
    }

    $tree = Invoke-RestMethod -UseBasicParsing -Uri ($repoApi + '/git/trees/' + $treeSha + '?recursive=1') -Headers $headers
    if ($tree.truncated) {
        throw 'GitHub returned an incomplete file list. No local files were changed.'
    }
    if (!$tree.sha -or $tree.sha -ne $treeSha -or !$tree.tree) {
        throw 'Could not read the Panel Craft update file list.'
    }

    # Keep all existing component-library files on this PC. They are unchanged
    # by this updater and are deliberately never downloaded or overwritten.
    $files = @($tree.tree | Where-Object {
        $_.type -eq 'blob' -and
        -not ([string]$_.path).StartsWith('public/components_library/', [StringComparison]::OrdinalIgnoreCase) -and
        [string]$_.path -ne 'UPDATE-LOCAL-TEST.bat'
    })
    $libraryFiles = @($tree.tree | Where-Object {
        $_.type -eq 'blob' -and ([string]$_.path).StartsWith('public/components_library/', [StringComparison]::OrdinalIgnoreCase)
    })

    Write-Host ("Component library skipped: {0} files ({1:N1} MB)." -f $libraryFiles.Count, (($libraryFiles | Measure-Object -Property size -Sum).Sum / 1MB)) -ForegroundColor DarkGray
    Write-Host ("Downloading {0} other project files ({1:N1} KB)..." -f $files.Count, (($files | Measure-Object -Property size -Sum).Sum / 1KB)) -ForegroundColor Cyan

    $downloaded = 0

    foreach ($item in $files) {
        $relativePath = [string]$item.path
        if ([string]::IsNullOrWhiteSpace($relativePath) -or
            $relativePath.StartsWith('/') -or
            $relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
            throw ("Unsafe path received from GitHub: {0}" -f $relativePath)
        }

        $encodedPath = (($relativePath -split '/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
        $sourceFile = Join-Path $stage ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $sourceDir = Split-Path -Parent $sourceFile
        if (!(Test-Path -LiteralPath $sourceDir)) {
            New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
        }

        $blob = Invoke-RestMethod -UseBasicParsing -Uri ($repoApi + '/git/blobs/' + [string]$item.sha) -Headers $headers
        if ($blob.encoding -ne 'base64' -or !$blob.content) {
            throw ("GitHub did not return base64 content for {0}." -f $relativePath)
        }
        $bytes = [Convert]::FromBase64String(($blob.content -replace '\s', ''))
        [IO.File]::WriteAllBytes($sourceFile, $bytes)
        $actualSize = $bytes.Length
        if ($null -ne $item.size -and $actualSize -ne [int64]$item.size) {
            throw ("Download size mismatch for {0}. Expected {1} bytes, received {2} bytes." -f $relativePath, $item.size, $actualSize)
        }
        $downloaded++
    }

    Write-Host 'Applying the downloaded files to this folder...' -ForegroundColor Cyan
    foreach ($item in $files) {
        $relativePath = [string]$item.path
        $sourceFile = Join-Path $stage ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $destinationFile = Join-Path $ProjectRoot ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $destinationDir = Split-Path -Parent $destinationFile
        if (!(Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $sourceFile -Destination $destinationFile -Force
    }

    Write-Host ("Updated {0} project files. The component library was not downloaded or copied." -f $downloaded) -ForegroundColor Green

    Write-Host ''
    Write-Host 'The component library folder was not downloaded, copied, rebuilt, or modified.' -ForegroundColor Green
    Write-Host 'The updater BAT launcher was kept in place while it was running.' -ForegroundColor DarkGray

    Write-Host ''
    Write-Host 'Panel Craft has been updated in this folder.' -ForegroundColor Green
    Write-Host 'Your existing public\components_library folder was left completely untouched.'
    Write-Host 'Your node_modules, .git, and .netlify folders were also left untouched.'
    Write-Host 'Start the app using START-LOCAL-TEST.bat.'
}
finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}
