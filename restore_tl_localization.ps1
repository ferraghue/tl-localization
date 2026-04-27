param(
    [Parameter(Mandatory=$true)]
    [string]$GameRoot,

    [Parameter(Mandatory=$true)]
    [string]$Culture
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
    throw "TL.exe is still running. Close the game before restoring localization."
}

$contentRoot = Resolve-TLContentRoot -Root $GameRoot
$pakDir = Join-Path $contentRoot "Paks"
$backupRoot = Join-Path $contentRoot "_localization_mod_backups"

if (-not (Test-Path -LiteralPath $backupRoot)) {
    throw "No localization mod backups were found under: $backupRoot"
}

$latest = Get-ChildItem -LiteralPath $backupRoot -Directory -Filter "install_${Culture}_*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latest) {
    throw "No backup for culture '$Culture' was found under: $backupRoot"
}

$manifestPath = Join-Path $latest.FullName "manifest.json"
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} else {
    $manifest = $null
}

$targetDir = Join-Path $contentRoot "Localization\Game\$Culture"
if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}

$previousLoose = Join-Path $latest.FullName "previous_loose\Game\$Culture"
if (Test-Path -LiteralPath $previousLoose) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $previousLoose "*") -Destination $targetDir -Recurse -Force
}

$disabledFiles = @()
if ($manifest -and $manifest.disabled_pak_files) {
    $disabledFiles = @($manifest.disabled_pak_files)
} else {
    $disabledFiles = @(
        "pakchunk-Localization-$Culture.pak",
        "pakchunk-Localization-$Culture.sig"
    )
}

foreach ($file in $disabledFiles) {
    $backupFile = Join-Path $latest.FullName $file
    if (Test-Path -LiteralPath $backupFile) {
        Move-Item -LiteralPath $backupFile -Destination (Join-Path $pakDir $file) -Force
    }
}

"Restored TL localization state."
"Culture: $Culture"
"Content root: $contentRoot"
"Backup used: $($latest.FullName)"
