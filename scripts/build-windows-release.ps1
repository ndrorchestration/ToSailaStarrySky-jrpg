param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\local-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake local Windows release build =="

npm ci
npm run test:desktop-package
npm run package:windows

$package = Get-ChildItem -Path (Join-Path $repo "..\aetherwake-dist") -Directory | Select-Object -First 1
if (-not $package) { throw "NW.js did not produce a package directory." }

$exe = Join-Path $package.FullName "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Aetherwake.exe not found in packaged runtime." }

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$zip = Join-Path $OutputDir "Aetherwake-Windows.zip"
Compress-Archive -Path (Join-Path $package.FullName "*") -DestinationPath $zip

$makensis = @(
  "C:\Program Files (x86)\NSIS\makensis.exe",
  "C:\Program Files\NSIS\makensis.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $makensis) {
  throw "NSIS makensis.exe not found. Install NSIS, then rerun this script."
}

$nsi = Join-Path $OutputDir "Aetherwake-Setup.nsi"
$source = $package.FullName.Replace('\','\\')
@"
Unicode true
Name "Aetherwake"
OutFile "$OutputDir\Aetherwake-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\Aetherwake"
RequestExecutionLevel user
SetCompressor /SOLID lzma

Page directory
Page instfiles

Section "Aetherwake" SEC_MAIN
  SetOutPath "$INSTDIR"
  File /r "$source\*"
  CreateShortCut "$DESKTOP\Aetherwake.lnk" "$INSTDIR\Aetherwake.exe"
  CreateDirectory "$SMPROGRAMS\Aetherwake"
  CreateShortCut "$SMPROGRAMS\Aetherwake\Aetherwake.lnk" "$INSTDIR\Aetherwake.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Aetherwake.lnk"
  Delete "$SMPROGRAMS\Aetherwake\Aetherwake.lnk"
  RMDir "$SMPROGRAMS\Aetherwake"
  RMDir /r "$INSTDIR"
SectionEnd
"@ | Set-Content -LiteralPath $nsi -Encoding UTF8

& $makensis $nsi
if ($LASTEXITCODE -ne 0) { throw "NSIS compilation failed with code $LASTEXITCODE." }

$installer = Join-Path $OutputDir "Aetherwake-Setup.exe"
if (-not (Test-Path -LiteralPath $installer)) { throw "Installer was not created." }

$installDir = Join-Path $env:TEMP "AetherwakeLocalReleaseSmoke"
if (Test-Path -LiteralPath $installDir) {
  Remove-Item -LiteralPath $installDir -Recurse -Force
}

$installProcess = Start-Process -FilePath $installer -ArgumentList @("/S", "/D=$installDir") -Wait -PassThru
if ($installProcess.ExitCode -ne 0) { throw "Installer exited with code $($installProcess.ExitCode)." }

$installedExe = Join-Path $installDir "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $installedExe)) { throw "Installed Aetherwake.exe was not found." }

$game = Start-Process -FilePath $installedExe -PassThru
Start-Sleep -Seconds 10
if ($game.HasExited) { throw "Installed Aetherwake.exe exited during launch smoke with code $($game.ExitCode)." }
Stop-Process -Id $game.Id -Force

$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
$lines = @()
foreach ($file in @($installer, $zip)) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file
  $lines += "$($hash.Hash.ToLower())  $([IO.Path]::GetFileName($file))"
}
$lines | Set-Content -LiteralPath $manifest -Encoding ASCII

Write-Host ""
Write-Host "LOCAL_WINDOWS_RELEASE=PASS"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "SHA256_MANIFEST=$manifest"
