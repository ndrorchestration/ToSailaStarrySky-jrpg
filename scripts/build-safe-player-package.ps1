param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\safe-player-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake safe player package (no NSIS) =="

npm run test:first-wake-opening
npm run test:first-wake-chapter1
npm run test:first-wake-guidance
npm run test:first-wake-readability
npm run test:first-wake-presentation
npm run test:desktop-package
npm run test:smoke
npm run package:windows

$dist = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exe = Join-Path $dist "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) {
  throw "Packaged Aetherwake.exe not found."
}

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$bundle = Join-Path $OutputDir "Aetherwake-First-Wake-Chapter1"
$app = Join-Path $bundle "Aetherwake"
New-Item -ItemType Directory -Path $app -Force | Out-Null
Copy-Item -Path (Join-Path $dist "*") -Destination $app -Recurse -Force

$install = @'
@echo off
setlocal
set "SRC=%~dp0Aetherwake"
set "DEST=%LOCALAPPDATA%\Programs\Aetherwake"
if not exist "%SRC%\Aetherwake.exe" (
  echo Aetherwake.exe was not found next to this installer.
  pause
  exit /b 1
)
if exist "%DEST%" rmdir /s /q "%DEST%"
mkdir "%DEST%" || exit /b 1
robocopy "%SRC%" "%DEST%" /E /R:1 /W:1 >nul
if errorlevel 8 (
  echo Copy failed.
  pause
  exit /b 1
)
powershell -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake'; New-Item -ItemType Directory -Force -Path $menu | Out-Null; foreach($p in @((Join-Path $desktop 'Aetherwake.lnk'),(Join-Path $menu 'Aetherwake.lnk'))){$s=$w.CreateShortcut($p);$s.TargetPath=(Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake\Aetherwake.exe');$s.WorkingDirectory=(Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake');$s.Save()}"
if errorlevel 1 (
  echo Shortcut creation failed.
  pause
  exit /b 1
)
echo.
echo Aetherwake installed for this Windows user.
start "" "%DEST%\Aetherwake.exe"
exit /b 0
'@
[IO.File]::WriteAllText((Join-Path $bundle "Install-Aetherwake.cmd"),$install,(New-Object Text.ASCIIEncoding))

$uninstall = @'
@echo off
setlocal
set "DEST=%LOCALAPPDATA%\Programs\Aetherwake"
powershell -NoProfile -Command "$dest=Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake'; $exe=Join-Path $dest 'Aetherwake.exe'; Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq $exe} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake'; Remove-Item -LiteralPath (Join-Path $desktop 'Aetherwake.lnk') -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue"
start "" /min cmd /c "timeout /t 2 /nobreak >nul & rmdir /s /q ""%DEST%"""
echo Aetherwake uninstall scheduled.
exit /b 0
'@
[IO.File]::WriteAllText((Join-Path $app "Uninstall-Aetherwake.cmd"),$uninstall,(New-Object Text.ASCIIEncoding))

$readme = @"
AETHERWAKE - FIRST WAKE CHAPTER 1 PRE-ALPHA

INSTALL
Double-click Install-Aetherwake.cmd.
It installs only for your Windows user under:
%LOCALAPPDATA%\Programs\Aetherwake

No administrator rights are required.

PLAY
The installer launches Aetherwake after copying the files.
Later, use the Desktop or Start Menu Aetherwake shortcut.

UNINSTALL
Run Uninstall-Aetherwake.cmd from the installed Aetherwake folder.

SECURITY
This package intentionally does not use the NSIS installer/uninstaller path tracked by issue #293.
Do not bypass or whitelist Windows Security if it reports a detection.

STATUS
This is the fullest currently verified packaged First Wake runtime, but remains pre-alpha and is not the final completed Chapter 1 or completed Godot migration.
"@
[IO.File]::WriteAllText((Join-Path $bundle "README-FIRST.txt"),$readme,(New-Object Text.UTF8Encoding($false)))

$zip = Join-Path $OutputDir "Aetherwake-First-Wake-Chapter1-Installable-Windows.zip"
Compress-Archive -Path (Join-Path $bundle "*") -DestinationPath $zip -CompressionLevel Optimal

Write-Host "SAFE_PLAYER_PACKAGE=BUILT"
Write-Host "ZIP=$zip"
