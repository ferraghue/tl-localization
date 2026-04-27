param(
    [Parameter(Mandatory=$true)]
    [string]$GameRoot,

    [Parameter(Mandatory=$true)]
    [string]$Culture,

    [Parameter(Mandatory=$true)]
    [string]$LocresPath,

    [switch]$DisablePak
)

$ErrorActionPreference = "Stop"

function Resolve-TLContentRoot {
    param([string]$Root)

    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    $steamLike = Join-Path $rootPath "TL\Content"
    $astrumLike = Join-Path $rootPath "Content"

    if (Test-Path -LiteralPath (Join-Path $steamLike "Paks")) {
        return $steamLike
    }

    if (Test-Path -LiteralPath (Join-Path $astrumLike "Paks")) {
        return $astrumLike
    }

    throw "Could not find TL Content\Paks under: $Root"
}

$running = Get-Process -Name TL -ErrorAction SilentlyContinue
if ($running) {
    throw "TL.exe is still running. Close the game before installing localization."
}

if (-not (Test-Path -LiteralPath $LocresPath)) {
    throw "Game.locres payload was not found: $LocresPath"
}

$contentRoot = Resolve-TLContentRoot -Root $GameRoot
$pakDir = Join-Path $contentRoot "Paks"
$looseRoot = Join-Path $contentRoot "Localization"
$targetDir = Join-Path $looseRoot "Game\$Culture"
$targetLocres = Join-Path $targetDir "Game.locres"
$backupRoot = Join-Path $contentRoot "_localization_mod_backups"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $backupRoot "install_${Culture}_$stamp"

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$disabledFiles = @()
$restoredLoose = $false

if (Test-Path -LiteralPath $targetDir) {
    $looseBackupDir = Join-Path $backupDir "previous_loose\Game\$Culture"
    New-Item -ItemType Directory -Force -Path $looseBackupDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $targetDir "*") -Destination $looseBackupDir -Recurse -Force
    Remove-Item -LiteralPath $targetDir -Recurse -Force
    $restoredLoose = $true
}

if ($DisablePak) {
    $pakCandidates = @(
        "pakchunk-Localization-$Culture.pak",
        "pakchunk-Localization-$Culture.sig"
    )

    foreach ($file in $pakCandidates) {
        $path = Join-Path $pakDir $file
        if (Test-Path -LiteralPath $path) {
            Move-Item -LiteralPath $path -Destination (Join-Path $backupDir $file) -Force
            $disabledFiles += $file
        }
    }
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -LiteralPath $LocresPath -Destination $targetLocres -Force

$manifest = [ordered]@{
    installed_at = (Get-Date -Format o)
    game_root = (Resolve-Path -LiteralPath $GameRoot).Path
    content_root = $contentRoot
    culture = $Culture
    locres_payload = (Resolve-Path -LiteralPath $LocresPath).Path
    target_locres = $targetLocres
    disabled_pak_files = $disabledFiles
    had_previous_loose_files = $restoredLoose
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backupDir "manifest.json") -Encoding UTF8

"Installed TL loose localization."
"Culture: $Culture"
"Content root: $contentRoot"
"Loose locres: $targetLocres"
"Backup: $backupDir"
if ($disabledFiles.Count -gt 0) {
    "Disabled pak files: $($disabledFiles -join ', ')"
}
