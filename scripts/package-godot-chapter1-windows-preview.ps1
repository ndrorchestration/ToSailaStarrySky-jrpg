param(
    [Parameter(Mandatory=$true)]
    [string]$ExportedExe,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
function Get-Sha256Hex([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return (($sha.ComputeHash($stream) | ForEach-Object ToString x2) -join '')
    }
    finally {
        $stream.Dispose()
    }
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "build\godot-first-wake-package"
}
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$Staging = Join-Path $OutputDir "staging"
$Payload = Join-Path $Staging "Aetherwake"
$Zip = Join-Path $OutputDir "Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip"

if (-not (Test-Path -LiteralPath $ExportedExe)) {
    throw "EXPORTED_EXE_NOT_FOUND: $ExportedExe"
}

if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $Payload -Force | Out-Null

$PayloadExe = Join-Path $Payload "Aetherwake-First-Wake-Godot-Preview.exe"
Copy-Item -LiteralPath $ExportedExe -Destination $PayloadExe -Force

$Install = @'
@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "DEST=%LOCALAPPDATA%\Programs\Aetherwake-Godot-Native-Preview"
set "EXE=%DEST%\Aetherwake-First-Wake-Godot-Preview.exe"
set "MARKER=%DEST%\Aetherwake-Native-Preview.install"
if exist "%DEST%" (
  if not exist "%MARKER%" exit /b 3
  set "OWNER="
  set /p OWNER=<"%MARKER%"
  if /I not "!OWNER!"=="AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1" exit /b 3
)
if not exist "%DEST%" mkdir "%DEST%"
copy /Y "%~dp0Aetherwake\Aetherwake-First-Wake-Godot-Preview.exe" "%EXE%" >nul
if errorlevel 1 exit /b 1
copy /Y "%~dp0Aetherwake\Uninstall-Aetherwake-Godot-Preview.cmd" "%DEST%\Uninstall-Aetherwake-Godot-Preview.cmd" >nul
if errorlevel 1 exit /b 1
> "%MARKER%" echo AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1
if errorlevel 1 exit /b 1
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $dest=Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake-Godot-Native-Preview'; $exe=Join-Path $dest 'Aetherwake-First-Wake-Godot-Preview.exe'; $exeFull=[IO.Path]::GetFullPath($exe); $shell=New-Object -ComObject WScript.Shell; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake Native Preview'; New-Item -ItemType Directory -Path $menu -Force | Out-Null; foreach($shortcutPath in @((Join-Path $desktop 'Aetherwake Native Preview.lnk'),(Join-Path $menu 'Aetherwake Native Preview.lnk'))){if(Test-Path -LiteralPath $shortcutPath){$existing=$shell.CreateShortcut($shortcutPath); $existingTarget=[IO.Path]::GetFullPath([string]$existing.TargetPath); if(-not $existingTarget.Equals($exeFull,[StringComparison]::OrdinalIgnoreCase)){throw ('SHORTCUT_SLOT_OCCUPIED:'+ $shortcutPath)}}; $shortcut=$shell.CreateShortcut($shortcutPath); $shortcut.TargetPath=$exe; $shortcut.WorkingDirectory=$dest; $shortcut.Save()}"
if errorlevel 1 exit /b 1
start "" "%EXE%"
exit /b 0
'@

$Uninstall = @'
@echo off
setlocal
set "DEST=%LOCALAPPDATA%\Programs\Aetherwake-Godot-Native-Preview"
set "CLEANUP=%TEMP%\Aetherwake-Godot-Native-Preview-Uninstall.cmd"
if /I "%~1"=="--cleanup" goto cleanup
copy /Y "%~f0" "%CLEANUP%" >nul
if errorlevel 1 exit /b 1
start "" /min cmd /c ""%CLEANUP%" --cleanup"
exit /b 0

:cleanup
cd /d "%TEMP%"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $dest=Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake-Godot-Native-Preview'; $exe=Join-Path $dest 'Aetherwake-First-Wake-Godot-Preview.exe'; $uninstall=Join-Path $dest 'Uninstall-Aetherwake-Godot-Preview.cmd'; $marker=Join-Path $dest 'Aetherwake-Native-Preview.install'; if(-not (Test-Path -LiteralPath $marker)){exit 3}; $owner=(Get-Content -LiteralPath $marker -Raw).Trim(); if($owner -ne 'AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1'){exit 3}; $exeFull=[IO.Path]::GetFullPath($exe); Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -and [IO.Path]::GetFullPath([string]$_.ExecutablePath).Equals($exeFull,[StringComparison]::OrdinalIgnoreCase)} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; $shell=New-Object -ComObject WScript.Shell; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake Native Preview'; function Remove-OwnedShortcut([string]$shortcutPath){if(-not (Test-Path -LiteralPath $shortcutPath)){return}; $shortcut=$shell.CreateShortcut($shortcutPath); $target=[IO.Path]::GetFullPath([string]$shortcut.TargetPath); $work=[IO.Path]::GetFullPath([string]$shortcut.WorkingDirectory); if($target.Equals($exeFull,[StringComparison]::OrdinalIgnoreCase) -and $work.Equals([IO.Path]::GetFullPath($dest),[StringComparison]::OrdinalIgnoreCase)){Remove-Item -LiteralPath $shortcutPath -Force}}; Remove-OwnedShortcut (Join-Path $desktop 'Aetherwake Native Preview.lnk'); Remove-OwnedShortcut (Join-Path $menu 'Aetherwake Native Preview.lnk'); if(Test-Path -LiteralPath $menu){$menuRemaining=@(Get-ChildItem -LiteralPath $menu -Force); if($menuRemaining.Count -eq 0){Remove-Item -LiteralPath $menu -Force}}; $owned=@($exe,$uninstall,$marker); Start-Sleep -Milliseconds 500; for($i=0; $i -lt 12; $i++){foreach($ownedPath in $owned){Remove-Item -LiteralPath $ownedPath -Force -ErrorAction SilentlyContinue}; $remainingOwned=@($owned | Where-Object {Test-Path -LiteralPath $_}); if($remainingOwned.Count -eq 0){break}; Start-Sleep -Milliseconds 500}; if(@($owned | Where-Object {Test-Path -LiteralPath $_}).Count -gt 0){exit 2}; if(Test-Path -LiteralPath $dest){$destRemaining=@(Get-ChildItem -LiteralPath $dest -Force); if($destRemaining.Count -eq 0){Remove-Item -LiteralPath $dest -Force}}"
if errorlevel 1 exit /b 2
del /q "%~f0"
exit /b 0
'@

$Readme = @'
AETHERWAKE — FIRST WAKE CHAPTER I NATIVE GODOT PREVIEW

Private pre-alpha migration preview.

Install:
1. Extract this ZIP completely.
2. Double-click Install-Aetherwake-Godot-Preview.cmd.
3. The native Godot preview installs per-user and launches automatically.
4. A Desktop shortcut and Start Menu shortcut are created.

Play:
- WASD / arrows - move
- E - interact / continue dialogue
- Crossing: interact with Wind Shear to open its current-story combat encounter
- Wind Shear combat: 1 Staff Strike, 2 Uncover Truth, 3 Hold, 4 Rest
- Wind Shear retaliates after successful turns with its current live Gale Force: 2 damage
- Current Crossing party surface shows Ender + Lyra; only Ender's formula actions are authorized
- Lyra's combat actions remain intentionally unavailable until explicit action authority exists
- If Ender is downed, C closes the transient encounter and Crossing progress is unchanged
- Clear Wind Shear, then C to confirm that Crossing hazard
- Loose Cargo Sweep and Dock Authority Hold remain noncombat Chapter I hazards
- 1 / 2 / 3 - Chapter I choice when prompted
- C - open/close the separate explicit noncanonical Formula Review
- Formula Review: 1 Staff Strike, 2 Uncover Truth, 3 Hold, 4 Rest
- F5 - save durable Chapter I progress
- F9 - load the local Chapter I save

Save behavior:
- one local Chapter I slot is stored in Godot's per-user data directory;
- saves are semantically validated before write;
- Ender's bounded dock exploration position is persisted with Chapter I progress;
- older compatible v1 saves that predate position persistence resume at a deterministic safe deck spawn;
- the previous valid generation is retained for backup recovery;
- dialogue cursor, Formula Review, and active Wind Shear combat are transient and are not persisted;
- loading during unresolved Wind Shear combat closes that transient encounter without awarding hazard progress;
- loading closes transient dialogue/combat state before resuming exploration.

Uninstall:
Run Uninstall-Aetherwake-Godot-Preview.cmd from the extracted ZIP or the installed copy.
- the install directory carries a versioned Aetherwake ownership marker; installer/uninstaller fail closed if that ownership cannot be proven;
- uninstall removes only the owned EXE, uninstaller, marker, and shortcuts that still target this exact preview install;
- the install directory is removed only when empty, so user-added/unrelated files and shortcut/menu content are preserved.

Security:
- no administrator elevation;
- no NSIS;
- no Defender exclusion or allowlisting;
- the preview installs separately from the current NW.js owner-playtest build.

Scope:
This is a native Godot migration preview, not yet the parity-complete replacement
for the current packaged Chapter I build. Keep the current owner build as rollback.
'@

Set-Content -LiteralPath (Join-Path $Staging "Install-Aetherwake-Godot-Preview.cmd") -Value $Install -Encoding ASCII
Set-Content -LiteralPath (Join-Path $Staging "Uninstall-Aetherwake-Godot-Preview.cmd") -Value $Uninstall -Encoding ASCII
Set-Content -LiteralPath (Join-Path $Payload "Uninstall-Aetherwake-Godot-Preview.cmd") -Value $Uninstall -Encoding ASCII
Set-Content -LiteralPath (Join-Path $Staging "README-FIRST.txt") -Value $Readme -Encoding UTF8

$InstallPath = Join-Path $Staging "Install-Aetherwake-Godot-Preview.cmd"
$UninstallPath = Join-Path $Staging "Uninstall-Aetherwake-Godot-Preview.cmd"
$PayloadUninstallPath = Join-Path $Payload "Uninstall-Aetherwake-Godot-Preview.cmd"
$ReadmePath = Join-Path $Staging "README-FIRST.txt"

$ExeHash = Get-Sha256Hex $PayloadExe
$InstallHash = Get-Sha256Hex $InstallPath
$UninstallHash = Get-Sha256Hex $UninstallPath
$PayloadUninstallHash = Get-Sha256Hex $PayloadUninstallPath
$ReadmeHash = Get-Sha256Hex $ReadmePath

$Manifest = @"
EXE_SHA256=$ExeHash
INSTALL_WRAPPER_SHA256=$InstallHash
UNINSTALL_WRAPPER_SHA256=$UninstallHash
PAYLOAD_UNINSTALLER_SHA256=$PayloadUninstallHash
README_SHA256=$ReadmeHash
NSIS_INCLUDED=NO
ADMIN_REQUIRED=NO
PUBLIC_RELEASE_AUTHORIZED=NO
"@
Set-Content -LiteralPath (Join-Path $Staging "SHA256SUMS.txt") -Value $Manifest -Encoding ASCII

Compress-Archive -Path (Join-Path $Staging "*") -DestinationPath $Zip -CompressionLevel Optimal -Force
$ZipHash = Get-Sha256Hex $Zip
$ZipBytes = (Get-Item -LiteralPath $Zip).Length

Write-Output "AETHERWAKE_GODOT_NATIVE_PACKAGE_ZIP=$Zip"
Write-Output "AETHERWAKE_GODOT_NATIVE_PACKAGE_BYTES=$ZipBytes"
Write-Output "AETHERWAKE_GODOT_NATIVE_PACKAGE_SHA256=$ZipHash"
Write-Output "AETHERWAKE_GODOT_NATIVE_PACKAGE_EXE_SHA256=$ExeHash"
Write-Output "AETHERWAKE_GODOT_NATIVE_PACKAGE_PASS"
