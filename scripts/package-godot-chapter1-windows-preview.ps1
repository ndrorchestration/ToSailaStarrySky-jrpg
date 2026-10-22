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
setlocal
set "DEST=%LOCALAPPDATA%\Programs\Aetherwake-Godot-Native-Preview"
set "EXE=%DEST%\Aetherwake-First-Wake-Godot-Preview.exe"
if not exist "%DEST%" mkdir "%DEST%"
copy /Y "%~dp0Aetherwake\Aetherwake-First-Wake-Godot-Preview.exe" "%EXE%" >nul
if errorlevel 1 exit /b 1
copy /Y "%~dp0Aetherwake\Uninstall-Aetherwake-Godot-Preview.cmd" "%DEST%\Uninstall-Aetherwake-Godot-Preview.cmd" >nul
if errorlevel 1 exit /b 1
powershell -NoProfile -Command "$dest=Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake-Godot-Native-Preview'; $exe=Join-Path $dest 'Aetherwake-First-Wake-Godot-Preview.exe'; $shell=New-Object -ComObject WScript.Shell; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake Native Preview'; New-Item -ItemType Directory -Path $menu -Force | Out-Null; foreach($shortcutPath in @((Join-Path $desktop 'Aetherwake Native Preview.lnk'),(Join-Path $menu 'Aetherwake Native Preview.lnk'))){$shortcut=$shell.CreateShortcut($shortcutPath); $shortcut.TargetPath=$exe; $shortcut.WorkingDirectory=$dest; $shortcut.Save()}"
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
powershell -NoProfile -Command "$dest=Join-Path $env:LOCALAPPDATA 'Programs\Aetherwake-Godot-Native-Preview'; $exe=Join-Path $dest 'Aetherwake-First-Wake-Godot-Preview.exe'; Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq $exe} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}; $desktop=[Environment]::GetFolderPath('Desktop'); $menu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Aetherwake Native Preview'; Remove-Item -LiteralPath (Join-Path $desktop 'Aetherwake Native Preview.lnk') -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500; for($i=0; $i -lt 12 -and (Test-Path -LiteralPath $dest); $i++){Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue; if(Test-Path -LiteralPath $dest){Start-Sleep -Milliseconds 500}}; if(Test-Path -LiteralPath $dest){exit 2}"
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

Uninstall:
Run Uninstall-Aetherwake-Godot-Preview.cmd from the extracted ZIP or the installed copy.

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

$ExeHash = Get-Sha256Hex $PayloadExe
$Manifest = @"
EXE_SHA256=$ExeHash
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
