@echo off
setlocal enabledelayedexpansion
title TL Localization

:: ─────────────────────────────────────────────────────────────────────────────
set "REPO_API=https://api.github.com/repos/ferraghue/tl-localization/contents"
set "REPO_RAW=https://raw.githubusercontent.com/ferraghue/tl-localization/main"
set "CACHE=%APPDATA%\TL_Localization"
set "CONFIG=%CACHE%\config.txt"
set "SCRIPTS=%CACHE%\scripts"
set "PAYLOAD=%CACHE%\payload"
set "SHA_FILE=%CACHE%\locres.sha"

if not exist "%CACHE%"   mkdir "%CACHE%"
if not exist "%SCRIPTS%" mkdir "%SCRIPTS%"
if not exist "%PAYLOAD%" mkdir "%PAYLOAD%"

:: ─────────────────────────────────────────────────────────────────────────────
cls
echo.
echo  ================================================================
echo   TL Localization  ^|  English Translation for Astrum
echo  ================================================================
echo.
echo   WHAT THIS TOOL DOES
echo     Installs an English translation by placing a Game.locres
echo     into the game's loose localization folder, and optionally
echo     disabling the default Russian localization pak.
echo.
echo   WHAT THIS TOOL DOES NOT DO
echo     No .exe or .dll modification
echo     No game memory access
echo     No anti-cheat bypass
echo     No encrypted signature tampering
echo     Uses UE5 loose files feature - engine loads localization from
echo     disk before pak archives, so no pak modification is needed
echo.
echo   Coverage: ~135,010 / 138,748 lines translated
echo   Some skill/item descriptions may differ from current balance.
echo.
echo   Source: github.com/ferraghue/tl-localization
echo.
echo  ================================================================
echo.
echo   [1]  Install
echo   [2]  Uninstall
echo   [3]  Exit
echo.
choice /C 123 /N /M "  Choose [1/2/3]: "
set "MENU=%errorlevel%"
if "%MENU%"=="3" exit /b 0

:: ── Load saved game path ─────────────────────────────────────────────────────
set "GAME_DIR="
if exist "%CONFIG%" set /p GAME_DIR=<"%CONFIG%"

if defined GAME_DIR (
    echo.
    echo   Saved game directory:
    echo   !GAME_DIR!
    echo.
    choice /C YN /N /M "  Use this directory? [Y/N]: "
    if errorlevel 2 set "GAME_DIR="
)

:: ── Select / validate folder ─────────────────────────────────────────────────
if not defined GAME_DIR call :pick_folder

:validate
if not defined GAME_DIR (
    echo.
    echo   No game directory selected. Exiting.
    goto :end_err
)
set "GAME_DIR=!GAME_DIR:"=!"
if not exist "!GAME_DIR!" (
    echo.
    echo   Directory not found: !GAME_DIR!
    set "GAME_DIR="
    call :pick_folder
    goto :validate
)
if exist "!GAME_DIR!\Content\Paks" goto :dir_ok
if exist "!GAME_DIR!\TL\Content\Paks" goto :dir_ok
echo.
echo   Content\Paks not found under: !GAME_DIR!
echo   Select the root game folder, not the Paks folder itself.
set "GAME_DIR="
call :pick_folder
goto :validate

:dir_ok
>"!CONFIG!" echo !GAME_DIR!
echo.
echo   Game directory: !GAME_DIR!
echo.

if "%MENU%"=="1" goto :install
if "%MENU%"=="2" goto :uninstall
goto :end_err

:: ═════════════════════════════════════════════════════════════════════════════
:install
:: ═════════════════════════════════════════════════════════════════════════════
echo   Checking for script updates...
call :download_script install_tl_localization.ps1
if errorlevel 1 goto :end_err

echo   Checking for locres updates...
call :write_ps1_update
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\tl_locres_update.ps1"
if errorlevel 1 (
    if not exist "%PAYLOAD%\Game.locres" (
        echo.
        echo   ERROR: Game.locres not available and download failed.
        echo   Check your internet connection and try again.
        goto :end_err
    )
    echo   WARNING: Update check failed, proceeding with cached Game.locres.
)
del "%TEMP%\tl_locres_update.ps1" 2>nul

echo.
echo   Installing...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\install_tl_localization.ps1" -GameRoot "!GAME_DIR!" -Culture "ru" -LocresPath "%PAYLOAD%\Game.locres" -DisablePak
if errorlevel 1 (
    echo.
    echo   Installation failed. See errors above.
    goto :end_err
)
goto :end_ok

:: ═════════════════════════════════════════════════════════════════════════════
:uninstall
:: ═════════════════════════════════════════════════════════════════════════════
echo   Checking for script updates...
call :download_script restore_tl_localization.ps1
if errorlevel 1 goto :end_err

echo.
echo   Restoring original localization...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTS%\restore_tl_localization.ps1" -GameRoot "!GAME_DIR!" -Culture "ru"
if errorlevel 1 (
    echo.
    echo   Restore failed. See errors above.
    goto :end_err
)
goto :end_ok

:: ═════════════════════════════════════════════════════════════════════════════
:end_ok
echo.
echo   Done.
echo.
pause
exit /b 0

:end_err
echo.
pause
exit /b 1

:: ═════════════════════════════════════════════════════════════════════════════
:: SUBROUTINES
:: ═════════════════════════════════════════════════════════════════════════════

:download_script
:: Download %1 from GitHub into SCRIPTS dir. Falls back to cached copy on error.
set "_SCRIPT=%~1"
set "_DEST=%SCRIPTS%\%_SCRIPT%"
set "_TMP=%SCRIPTS%\%_SCRIPT%.tmp"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%REPO_RAW%/%_SCRIPT%' -OutFile '!_TMP!' -UseBasicParsing -Headers @{'User-Agent'='TL-Installer'}"
if not errorlevel 1 (
    move /y "!_TMP!" "!_DEST!" >nul
    exit /b 0
)
del "!_TMP!" 2>nul
if exist "!_DEST!" (
    echo   WARNING: Download failed, using cached %_SCRIPT%.
    exit /b 0
)
echo   ERROR: Could not download %_SCRIPT% and no cached copy exists.
exit /b 1

:pick_folder
echo.
echo   Press Enter, then select your TL game folder in the dialog.
pause >nul
call :write_ps1_folder
for /f "usebackq delims=" %%G in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\tl_folder_pick.ps1" 2^>nul`) do set "GAME_DIR=%%G"
del "%TEMP%\tl_folder_pick.ps1" 2>nul
exit /b 0

:write_ps1_folder
> "%TEMP%\tl_folder_pick.ps1" echo Add-Type -AssemblyName System.Windows.Forms
>> "%TEMP%\tl_folder_pick.ps1" echo $d = New-Object System.Windows.Forms.FolderBrowserDialog
>> "%TEMP%\tl_folder_pick.ps1" echo $d.Description = 'Select your Throne and Liberty root game folder'
>> "%TEMP%\tl_folder_pick.ps1" echo $d.ShowNewFolderButton = $false
>> "%TEMP%\tl_folder_pick.ps1" echo $res = $d.ShowDialog^(^)
>> "%TEMP%\tl_folder_pick.ps1" echo if ^($res.ToString^(^) -eq 'OK'^) { Write-Output $d.SelectedPath }
exit /b 0

:write_ps1_update
> "%TEMP%\tl_locres_update.ps1" echo $ErrorActionPreference = 'Stop'
>> "%TEMP%\tl_locres_update.ps1" echo $ProgressPreference = 'SilentlyContinue'
>> "%TEMP%\tl_locres_update.ps1" echo $headers = @{'User-Agent'='TL-Installer'}
>> "%TEMP%\tl_locres_update.ps1" echo try {
>> "%TEMP%\tl_locres_update.ps1" echo     $r = Invoke-RestMethod -Uri '%REPO_API%/payload/Game.locres' -Headers $headers
>> "%TEMP%\tl_locres_update.ps1" echo     $localSha = ''
>> "%TEMP%\tl_locres_update.ps1" echo     if ^(Test-Path '%SHA_FILE%'^) { $localSha = ^(Get-Content '%SHA_FILE%' -Raw^).Trim^(^) }
>> "%TEMP%\tl_locres_update.ps1" echo     if ^($r.sha -eq $localSha^) {
>> "%TEMP%\tl_locres_update.ps1" echo         Write-Host '  Game.locres is up to date.'
>> "%TEMP%\tl_locres_update.ps1" echo     } else {
>> "%TEMP%\tl_locres_update.ps1" echo         Write-Host '  Downloading Game.locres...'
>> "%TEMP%\tl_locres_update.ps1" echo         Invoke-WebRequest -Uri $r.download_url -OutFile '%PAYLOAD%\Game.locres' -UseBasicParsing -Headers $headers
>> "%TEMP%\tl_locres_update.ps1" echo         Set-Content -Path '%SHA_FILE%' -Value $r.sha -NoNewline
>> "%TEMP%\tl_locres_update.ps1" echo         Write-Host '  Game.locres updated.'
>> "%TEMP%\tl_locres_update.ps1" echo     }
>> "%TEMP%\tl_locres_update.ps1" echo } catch {
>> "%TEMP%\tl_locres_update.ps1" echo     Write-Host "  Update check error: $_"
>> "%TEMP%\tl_locres_update.ps1" echo     exit 1
>> "%TEMP%\tl_locres_update.ps1" echo }
exit /b 0
