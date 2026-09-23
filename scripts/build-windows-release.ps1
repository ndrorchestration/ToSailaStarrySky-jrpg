param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\local-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake local Windows release build =="

$gitHead = (& git rev-parse HEAD 2>$null)
$gitStatus = (& git status --porcelain=v1 2>$null) -join "
"
if ([string]::IsNullOrWhiteSpace([string]$gitHead)) {
  throw "Local Windows release requires readable Git HEAD provenance."
}
if (-not [string]::IsNullOrWhiteSpace([string]$gitStatus)) {
  throw "Local Windows release requires a clean working tree."
}
Write-Host "SOURCE_COMMIT=$gitHead"

npm ci
npm run test:desktop-package
npm run test:m0-title-audio-ready
npm run package:windows

$package = Get-ChildItem -Path (Join-Path $repo "..\aetherwake-dist") -Directory | Select-Object -First 1
if (-not $package) { throw "NW.js did not produce a package directory." }

npm run verify:packaged-title-audio -- "$($package.FullName)"
if ($LASTEXITCODE -ne 0) { throw "Packaged title-audio verification failed with code $LASTEXITCODE." }
Write-Host "PACKAGED_TITLE_AUDIO=PASS"

$exe = Join-Path $package.FullName "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Aetherwake.exe not found in packaged runtime." }

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$zip = Join-Path $OutputDir "Aetherwake-Windows.zip"
Compress-Archive -Path (Join-Path $package.FullName "*") -DestinationPath $zip

$portableVerify = Join-Path $env:TEMP "AetherwakePortableVerify"
if (Test-Path -LiteralPath $portableVerify) {
  Remove-Item -LiteralPath $portableVerify -Recurse -Force
}
Expand-Archive -LiteralPath $zip -DestinationPath $portableVerify
if (-not (Test-Path -LiteralPath (Join-Path $portableVerify "Aetherwake.exe"))) {
  throw "Portable Aetherwake.exe was not found after extraction."
}
npm run verify:packaged-title-audio -- "$portableVerify"
if ($LASTEXITCODE -ne 0) { throw "Portable title-audio verification failed with code $LASTEXITCODE." }
Write-Host "PORTABLE_TITLE_AUDIO=PASS"

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

npm run verify:packaged-title-audio -- "$installDir"
if ($LASTEXITCODE -ne 0) { throw "Installed title-audio verification failed with code $LASTEXITCODE." }
Write-Host "INSTALLED_TITLE_AUDIO=PASS"

$marker = Join-Path $env:TEMP "aetherwake-desktop-ready.json"
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru

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

# Prove the packaged NW.js runtime persists a semantic save across process restart
# using an isolated Chromium/NW.js user-data directory so real player saves are untouched.
$saveProfile = Join-Path $env:TEMP "AetherwakeSaveSmokeProfile"
if (Test-Path -LiteralPath $saveProfile) {
  Remove-Item -LiteralPath $saveProfile -Recurse -Force
}
New-Item -ItemType Directory -Path $saveProfile | Out-Null

function Invoke-AetherwakeSaveSmokePhase {
  param(
    [Parameter(Mandatory=$true)][string]$Phase,
    [Parameter(Mandatory=$true)][string]$MarkerPath
  )

  if (Test-Path -LiteralPath $MarkerPath) {
    Remove-Item -LiteralPath $MarkerPath -Force
  }
  $env:AETHERWAKE_SAVE_PERSISTENCE_PHASE = $Phase
  $env:AETHERWAKE_SAVE_PERSISTENCE_MARKER = $MarkerPath
  $proc = Start-Process -FilePath $installedExe -ArgumentList @("--user-data-dir=$saveProfile") -PassThru

  $limit = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $limit -and -not (Test-Path -LiteralPath $MarkerPath)) {
    if ($proc.HasExited) {
      throw "Packaged save smoke phase '$Phase' exited before writing its marker with code $($proc.ExitCode)."
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $MarkerPath)) {
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    throw "Packaged save smoke phase '$Phase' did not report within 20 seconds."
  }

  $result = Get-Content -LiteralPath $MarkerPath -Raw | ConvertFrom-Json
  Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
  if ($result.error) {
    throw "Packaged save smoke phase '$Phase' failed: $($result.error)"
  }
  return $result
}

$saveWriteMarker = Join-Path $env:TEMP "aetherwake-save-write.json"
$saveLoadMarker = Join-Path $env:TEMP "aetherwake-save-load.json"
$writeResult = Invoke-AetherwakeSaveSmokePhase -Phase "write" -MarkerPath $saveWriteMarker
if (-not $writeResult.saved -or $writeResult.storageType -ne "nw-file") {
  throw "Packaged save write did not use NW.js file persistence."
}
if ($writeResult.tileX -ne 9 -or $writeResult.tileY -ne 11) {
  throw "Packaged save write marker reported unexpected semantic state."
}
if (-not $writeResult.savePath -or -not (Test-Path -LiteralPath $writeResult.savePath)) {
  throw "Packaged save file was not created at the reported NW.js path."
}

$loadResult = Invoke-AetherwakeSaveSmokePhase -Phase "load" -MarkerPath $saveLoadMarker
if (-not $loadResult.restored) {
  throw "Packaged save did not restore semantic state after relaunch."
}
if ($loadResult.tileX -ne 9 -or $loadResult.tileY -ne 11) {
  throw "Packaged relaunch restored the wrong player position."
}
if ($loadResult.questState -ne $writeResult.questState) {
  throw "Packaged relaunch restored the wrong quest state."
}
$writeActiveIds = @($writeResult.activeIds)
$loadActiveIds = @($loadResult.activeIds)
if ($writeActiveIds.Count -ne $loadActiveIds.Count -or
    (Compare-Object -ReferenceObject $writeActiveIds -DifferenceObject $loadActiveIds -SyncWindow 0)) {
  throw "Packaged relaunch restored the wrong active-party membership/order."
}
if ($loadResult.savePath -ne $writeResult.savePath) {
  throw "Packaged relaunch did not use the same persistent save path."
}
if ($loadResult.dataPath -ne $writeResult.dataPath) {
  throw "Packaged relaunch did not use the same isolated NW.js data path."
}
Write-Host "DESKTOP_SAVE_RESTART=PASS"
Remove-Item Env:AETHERWAKE_SAVE_PERSISTENCE_PHASE -ErrorAction SilentlyContinue
Remove-Item Env:AETHERWAKE_SAVE_PERSISTENCE_MARKER -ErrorAction SilentlyContinue

$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
$lines = @()
foreach ($file in @($installer, $zip)) {
  $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file
  $lines += "$($hash.Hash.ToLower())  $([IO.Path]::GetFileName($file))"
}
$lines | Set-Content -LiteralPath $manifest -Encoding ASCII

$releaseEvidence = Join-Path $OutputDir "RELEASE_EVIDENCE.json"
npm run write:release-evidence -- --installer "$installer" --zip "$zip" --output "$releaseEvidence"
if ($LASTEXITCODE -ne 0) { throw "Release evidence generation failed with code $LASTEXITCODE." }

Write-Host ""
Write-Host "LOCAL_WINDOWS_RELEASE=PASS"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "SHA256_MANIFEST=$manifest"
Write-Host "RELEASE_EVIDENCE=$releaseEvidence"
