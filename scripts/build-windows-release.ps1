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

$dist = Join-Path $repo "..\aetherwake-dist"
$exe = Get-ChildItem -LiteralPath $dist -Filter "Aetherwake.exe" -File -Recurse | Select-Object -First 1
if (-not $exe) { throw "Aetherwake.exe not found in packaged runtime." }
$package = $exe.Directory

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
$outFile = (Join-Path $OutputDir "Aetherwake-Setup.exe").Replace('\','\\')
$template = @'
Unicode true
Name "Aetherwake"
OutFile "__OUTPUT__"
InstallDir "$LOCALAPPDATA\Programs\Aetherwake"
RequestExecutionLevel user
SetCompressor /SOLID lzma

Page directory
Page instfiles

Section "Aetherwake" SEC_MAIN
  SetOutPath "$INSTDIR"
  File /r "__SOURCE__\*"
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
'@
$template.Replace('__OUTPUT__', $outFile).Replace('__SOURCE__', $source) |
  Set-Content -LiteralPath $nsi -Encoding UTF8

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

$marker = Join-Path $env:TEMP "aetherwake-desktop-ready.json"
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -ArgumentList @("`"--aw-desktop-smoke-marker=$marker`"") -PassThru

$deadline = (Get-Date).AddSeconds(20)
while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
  if ($game.HasExited) {
    throw "Installed Aetherwake.exe exited before rendering a verified first frame with code $($game.ExitCode)."
  }
  Start-Sleep -Milliseconds 250
}
if (-not (Test-Path -LiteralPath $marker)) {
  throw "Installed Aetherwake.exe did not report runtime-ready + first-frame within 20 seconds."
}
$ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
if (-not $ready.runtimeReady -or -not $ready.firstFrame) {
  throw "Desktop readiness marker did not confirm runtimeReady and firstFrame."
}
if ($ready.width -ne 960 -or $ready.height -ne 640) {
  throw "Desktop readiness marker reported unexpected canvas $($ready.width)x$($ready.height)."
}
if ($ready.setupOrder -notlike "*setup-done*") {
  throw "Desktop readiness marker did not include setup-done."
}
if ($game.HasExited) {
  throw "Installed Aetherwake.exe exited immediately after first-frame readiness with code $($game.ExitCode)."
}
Write-Host "DESKTOP_RENDER_READINESS=PASS"
Stop-Process -Id $game.Id -Force
Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue

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
