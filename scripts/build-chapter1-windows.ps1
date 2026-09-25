param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\chapter1-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake Chapter 1 portable Windows candidate =="

$gitHead = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $gitHead) {
  throw "Unable to resolve Git HEAD. Run from an authenticated Git checkout."
}
$status = @(git status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) { throw "git status failed." }
if ($status.Count -gt 0) {
  throw "Tracked/staged source changes are present. Commit or restore them before candidate verification."
}
$shortHead = $gitHead.Substring(0, 12)
Write-Host "CHAPTER1_SOURCE_COMMIT=$gitHead"

npm ci
if ($LASTEXITCODE -ne 0) { throw "npm ci failed with code $LASTEXITCODE." }

# Browser proof is part of Chapter I acceptance. Install the pinned Playwright
# Chromium runtime if it is not already cached on this Windows machine.
npx playwright install chromium
if ($LASTEXITCODE -ne 0) { throw "Playwright Chromium installation failed with code $LASTEXITCODE." }

npm run test:chapter1-core
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 deterministic core gate failed with code $LASTEXITCODE." }

npm run test:chapter1-visual
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 visual/presentation gate failed with code $LASTEXITCODE." }
Write-Host 'CHAPTER1_VISUAL=PASS'

npm run test:chapter1-browser
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 full browser player-route gate failed with code $LASTEXITCODE." }

npm run test:chapter1-title-audio-ready
if ($LASTEXITCODE -ne 0) {
  throw "Chapter 1 title audio is not admitted/verified. Run scripts\\admit-title-audio.ps1 with the exact Skyward Arpeggio source first."
}

npm run test:chapter1-soundtrack-ready
if ($LASTEXITCODE -ne 0) {
  throw "Chapter 1 soundtrack is not fully admitted/verified. Admit the four governed non-title Chapter 1 tracks before building the candidate."
}

npm run test:desktop-package
if ($LASTEXITCODE -ne 0) { throw "Desktop package contract failed with code $LASTEXITCODE." }

$distPath = Join-Path $repo "..\aetherwake-dist"
if (Test-Path -LiteralPath $distPath) {
  Remove-Item -LiteralPath $distPath -Recurse -Force
}
Write-Host "CHAPTER1_DIST_CLEAN=PASS"

npm run package:windows
if ($LASTEXITCODE -ne 0) { throw "Windows package build failed with code $LASTEXITCODE." }

# Candidate evidence must still describe the exact source that was tested.
$afterBuildHead = (git rev-parse HEAD).Trim()
if ($afterBuildHead -ne $gitHead) {
  throw "Git HEAD changed during Chapter 1 candidate build."
}
$afterBuildStatus = @(git status --porcelain --untracked-files=no)
if ($afterBuildStatus.Count -gt 0) {
  throw "Tracked/staged source changed during Chapter 1 candidate build."
}

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exeFile = Get-ChildItem -LiteralPath $distRoot -Filter "Aetherwake.exe" -File -Recurse |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $exeFile) {
  throw "Aetherwake.exe not found anywhere under packaged runtime root: $distRoot"
}

$package = Get-Item -LiteralPath $exeFile.DirectoryName
$exe = $exeFile.FullName

$buildProvenance = [ordered]@{
  schemaVersion = 1
  kind = "AETHERWAKE_CHAPTER1_BUILD_PROVENANCE"
  sourceCommit = $gitHead
  sourceBranch = (git branch --show-current).Trim()
  builtAtUtc = [DateTime]::UtcNow.ToString("o")
}
$provenancePath = Join-Path $package.FullName "CHAPTER1_BUILD_PROVENANCE.json"
$buildProvenance | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $provenancePath -Encoding UTF8

$provenanceCheck = Get-Content -LiteralPath $provenancePath -Raw | ConvertFrom-Json
if ($provenanceCheck.sourceCommit -ne $gitHead) {
  throw "Packaged build provenance does not match exact Git source."
}

Write-Host "CHAPTER1_PACKAGE_ROOT=$($package.FullName)"
Write-Host "CHAPTER1_PACKAGE_EXE=$exe"
Write-Host "CHAPTER1_PACKAGE_PROVENANCE=$provenancePath"

$marker = Join-Path $env:TEMP "aetherwake-chapter1-ready.json"
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}

$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $exe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) {
      throw "Chapter 1 Aetherwake.exe exited before first-frame readiness with code $($game.ExitCode)."
    }
    Start-Sleep -Milliseconds 250
  }

  if (-not (Test-Path -LiteralPath $marker)) {
    throw "Chapter 1 Aetherwake.exe did not report runtime-ready + first-frame within 20 seconds."
  }

  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame) {
    throw "Chapter 1 readiness marker did not confirm runtimeReady and firstFrame."
  }
  if ($ready.width -ne 960 -or $ready.height -ne 640) {
    throw "Chapter 1 readiness marker reported unexpected canvas $($ready.width)x$($ready.height)."
  }
  if ($ready.setupOrder -notlike "*setup-done*") {
    throw "Chapter 1 readiness marker did not include setup-done."
  }
  if ($game.HasExited) {
    throw "Chapter 1 Aetherwake.exe exited immediately after first-frame readiness with code $($game.ExitCode)."
  }
  Write-Host "CHAPTER1_DESKTOP_RENDER_READINESS=PASS"
}
finally {
  if ($game -and -not $game.HasExited) {
    Stop-Process -Id $game.Id -Force
  }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}

# Prove standalone file persistence across two separate NW.js processes.
# Use an isolated save root so this verification never reads or overwrites a player's saves.
$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) {
  Remove-Item -LiteralPath $persistenceRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null

function Invoke-Chapter1PersistencePhase([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-persistence-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) {
    Remove-Item -LiteralPath $phaseMarker -Force
  }

  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker

  $phaseGame = Start-Process -FilePath $exe -PassThru
  try {
    $phaseDeadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $phaseDeadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phaseGame.HasExited) {
        throw "Chapter 1 persistence $Mode phase exited before evidence with code $($phaseGame.ExitCode)."
      }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) {
      throw "Chapter 1 persistence $Mode phase did not emit evidence within 20 seconds."
    }
    $phaseEvidence = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($phaseEvidence.result -ne "PASS" -or $phaseEvidence.phase -ne $Mode) {
      throw "Chapter 1 persistence $Mode phase failed: $($phaseEvidence.error)"
    }
    return $phaseEvidence
  }
  finally {
    if ($phaseGame -and -not $phaseGame.HasExited) {
      Stop-Process -Id $phaseGame.Id -Force
    }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}

$createEvidence = Invoke-Chapter1PersistencePhase "create"
if ($createEvidence.storageType -ne "nw-file" -or
    $createEvidence.slot -ne "manual-6" -or
    $createEvidence.tileX -ne 17 -or
    $createEvidence.tileY -ne 16) {
  throw "Chapter 1 persistence create evidence did not prove isolated NW-file storage."
}

$continueEvidence = Invoke-Chapter1PersistencePhase "continue"
if ($continueEvidence.gameState -ne "world" -or
    $continueEvidence.slot -ne "manual-6" -or
    $continueEvidence.tileX -ne 17 -or
    $continueEvidence.tileY -ne 16 -or
    $continueEvidence.questState -ne "signal") {
  throw "Chapter 1 relaunch Continue evidence did not restore the expected save state."
}
Write-Host "CHAPTER1_WINDOWS_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse

$candidateProvenance = Join-Path $candidateDir "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $candidateProvenance)) {
  throw "Copied Chapter 1 candidate is missing build provenance."
}
$candidateProvenanceCheck = Get-Content -LiteralPath $candidateProvenance -Raw | ConvertFrom-Json
if ($candidateProvenanceCheck.sourceCommit -ne $gitHead) {
  throw "Copied Chapter 1 candidate provenance does not match exact Git source."
}

$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip
$hashLower = $hash.Hash.ToLower()

# Build a no-admin, one-click installer from the exact verified candidate.
$makensis = @(
  "C:\Program Files (x86)\NSIS\makensis.exe",
  "C:\Program Files\NSIS\makensis.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installerEngine = $null

if ($makensis) {
  $installerEngine = "NSIS"
  $nsi = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.nsi"
  $source = $candidateDir.Replace('\','\\')
  $outFile = $installer.Replace('\','\\')
  $nsiTemplate = @'
Unicode true
Name "Aetherwake Chapter 1 — First Wake"
OutFile "__OUTPUT__"
InstallDir "$LOCALAPPDATA\Programs\Aetherwake Chapter 1"
RequestExecutionLevel user
SetCompressor /SOLID lzma

Page directory
Page instfiles

Function .onInit
  ReadEnvStr $1 "AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE"
  StrCmp $1 "" install_root_ready
  StrCpy $INSTDIR $1
  install_root_ready:
FunctionEnd

Section "Aetherwake Chapter 1" SEC_MAIN
  SetOutPath "$INSTDIR"
  File /r "__SOURCE__\*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  ReadEnvStr $0 "AETHERWAKE_CHAPTER1_INSTALL_SMOKE"
  StrCmp $0 "1" skip_player_shell
  CreateShortCut "$DESKTOP\Aetherwake Chapter 1.lnk" "$INSTDIR\Aetherwake.exe"
  CreateDirectory "$SMPROGRAMS\Aetherwake"
  CreateShortCut "$SMPROGRAMS\Aetherwake\Aetherwake Chapter 1.lnk" "$INSTDIR\Aetherwake.exe"
  Exec '"$INSTDIR\Aetherwake.exe"'
  skip_player_shell:
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Aetherwake Chapter 1.lnk"
  Delete "$SMPROGRAMS\Aetherwake\Aetherwake Chapter 1.lnk"
  RMDir "$SMPROGRAMS\Aetherwake"
  RMDir /r "$INSTDIR"
SectionEnd
'@
  $nsiTemplate.Replace('__OUTPUT__', $outFile).Replace('__SOURCE__', $source) |
    Set-Content -LiteralPath $nsi -Encoding UTF8

  & $makensis $nsi
  if ($LASTEXITCODE -ne 0) { throw "Chapter 1 NSIS compilation failed with code $LASTEXITCODE." }
} elseif (Test-Path -LiteralPath $iexpress) {
  $installerEngine = "IEXPRESS"
  $installScriptName = "install-chapter1-$shortHead.ps1"
  $installScript = Join-Path $OutputDir $installScriptName
  $installScriptContent = @'
param([Parameter(Mandatory=$true)][string]$Archive)
$ErrorActionPreference = "Stop"
$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE) {
  $env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE
} else {
  Join-Path $env:LOCALAPPDATA "Programs\Aetherwake Chapter 1"
}
if (Test-Path -LiteralPath $installRoot) {
  Remove-Item -LiteralPath $installRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Expand-Archive -LiteralPath (Join-Path $PSScriptRoot $Archive) -DestinationPath $installRoot -Force

$exe = Join-Path $installRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Installed Aetherwake.exe missing after extraction." }

if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1") {
  $shell = New-Object -ComObject WScript.Shell
  $desktop = [Environment]::GetFolderPath("Desktop")
  $desktopShortcut = $shell.CreateShortcut((Join-Path $desktop "Aetherwake Chapter 1.lnk"))
  $desktopShortcut.TargetPath = $exe
  $desktopShortcut.WorkingDirectory = $installRoot
  $desktopShortcut.Save()

  $startMenu = Join-Path ([Environment]::GetFolderPath("Programs")) "Aetherwake"
  New-Item -ItemType Directory -Path $startMenu -Force | Out-Null
  $menuShortcut = $shell.CreateShortcut((Join-Path $startMenu "Aetherwake Chapter 1.lnk"))
  $menuShortcut.TargetPath = $exe
  $menuShortcut.WorkingDirectory = $installRoot
  $menuShortcut.Save()

  Start-Process -FilePath $exe | Out-Null
}
'@
  Set-Content -LiteralPath $installScript -Value $installScriptContent -Encoding UTF8

  $sed = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"
  $sourceDir = $OutputDir.TrimEnd('\') + '\'
  $appLaunched = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $installScriptName + '" -Archive "' + $zipName + '"'
  $sedText = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$installer
FriendlyName=Aetherwake Chapter 1 - First Wake
AppLaunched=$appLaunched
PostInstallCmd=<None>
AdminQuietInstCmd=$appLaunched
UserQuietInstCmd=$appLaunched
FILE0="$zipName"
FILE1="$installScriptName"
[SourceFiles]
SourceFiles0=$sourceDir
[SourceFiles0]
%FILE0%=
%FILE1%=
"@
  Set-Content -LiteralPath $sed -Value $sedText -Encoding ASCII
  & $iexpress /N /Q $sed
  if ($LASTEXITCODE -ne 0) { throw "Chapter 1 IExpress compilation failed with code $LASTEXITCODE." }
} else {
  throw "No supported no-admin installer engine found (NSIS or Windows IExpress)."
}

if (-not (Test-Path -LiteralPath $installer)) { throw "Chapter 1 installer was not created." }
Write-Host "CHAPTER1_INSTALLER_ENGINE=$installerEngine"

# Install silently into an isolated location and launch the installed executable.
$installerSmokeRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installerSmokeRoot) {
  Remove-Item -LiteralPath $installerSmokeRoot -Recurse -Force
}
$installerArgs = @()
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installerSmokeRoot
if ($installerEngine -eq "NSIS") {
  # NSIS reads the same isolated-root override as IExpress. Avoid /D= quoting
  # edge cases when the Windows temp path or user profile contains spaces.
  $installerArgs = @("/S")
} elseif ($installerEngine -eq "IEXPRESS") {
  $installerArgs = @("/Q:U")
}

try {
  $installProcess = Start-Process -FilePath $installer -ArgumentList $installerArgs -Wait -PassThru
  if ($installProcess.ExitCode -ne 0) {
    throw "Chapter 1 installer exited with code $($installProcess.ExitCode)."
  }
}
finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}
$installedExe = Join-Path $installerSmokeRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $installedExe)) {
  throw "Installed Chapter 1 Aetherwake.exe was not found."
}
$installedProvenance = Join-Path $installerSmokeRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedProvenance)) {
  throw "Installed Chapter 1 candidate is missing build provenance."
}
$installedProv = Get-Content -LiteralPath $installedProvenance -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $gitHead) {
  throw "Installed Chapter 1 candidate provenance does not match exact Git source."
}

$installedMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $installedMarker) { Remove-Item -LiteralPath $installedMarker -Force }
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $installedMarker
$installedGame = Start-Process -FilePath $installedExe -PassThru
try {
  $installedDeadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $installedDeadline -and -not (Test-Path -LiteralPath $installedMarker)) {
    if ($installedGame.HasExited) {
      throw "Installed Chapter 1 executable exited before first-frame readiness with code $($installedGame.ExitCode)."
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $installedMarker)) {
    throw "Installed Chapter 1 executable did not report first-frame readiness within 20 seconds."
  }
  $installedReady = Get-Content -LiteralPath $installedMarker -Raw | ConvertFrom-Json
  if (-not $installedReady.runtimeReady -or -not $installedReady.firstFrame -or
      $installedReady.setupOrder -notlike "*setup-done*") {
    throw "Installed Chapter 1 executable did not satisfy runtime readiness."
  }
  Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"
}
finally {
  if ($installedGame -and -not $installedGame.HasExited) {
    Stop-Process -Id $installedGame.Id -Force
  }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}

# Re-run the save/close/relaunch/Continue proof against the installed executable,
# not only the portable package.
$installedPersistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $installedPersistenceRoot) {
  Remove-Item -LiteralPath $installedPersistenceRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $installedPersistenceRoot | Out-Null

function Invoke-InstalledChapter1PersistencePhase([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) {
    Remove-Item -LiteralPath $phaseMarker -Force
  }

  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $installedPersistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker

  $phaseGame = Start-Process -FilePath $installedExe -PassThru
  try {
    $phaseDeadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $phaseDeadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phaseGame.HasExited) {
        throw "Installed Chapter 1 persistence $Mode phase exited before evidence with code $($phaseGame.ExitCode)."
      }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) {
      throw "Installed Chapter 1 persistence $Mode phase did not emit evidence within 20 seconds."
    }
    $phaseEvidence = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($phaseEvidence.result -ne "PASS" -or $phaseEvidence.phase -ne $Mode) {
      throw "Installed Chapter 1 persistence $Mode phase failed: $($phaseEvidence.error)"
    }
    return $phaseEvidence
  }
  finally {
    if ($phaseGame -and -not $phaseGame.HasExited) {
      Stop-Process -Id $phaseGame.Id -Force
    }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}

$installedCreateEvidence = Invoke-InstalledChapter1PersistencePhase "create"
$installedContinueEvidence = Invoke-InstalledChapter1PersistencePhase "continue"
if ($installedCreateEvidence.storageType -ne "nw-file" -or
    $installedContinueEvidence.gameState -ne "world" -or
    $installedContinueEvidence.slot -ne "manual-6" -or
    $installedContinueEvidence.tileX -ne 17 -or
    $installedContinueEvidence.tileY -ne 16 -or
    $installedContinueEvidence.questState -ne "signal") {
  throw "Installed Chapter 1 save/close/relaunch/Continue proof did not restore the expected state."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = Get-FileHash -Algorithm SHA256 -LiteralPath $installer
$installerHashLower = $installerHash.Hash.ToLower()
$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
@(
  "$hashLower  $zipName",
  "$installerHashLower  $installerName"
) | Set-Content -LiteralPath $manifest -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = "PASS"
  chapter1Visual = "PASS"
  chapter1BrowserRoute = "PASS"
  titleAudioReady = "PASS"
  chapter1SoundtrackReady = "PASS"
  desktopPackageContract = "PASS"
  buildProvenance = "PASS"
  buildProvenanceFile = "CHAPTER1_BUILD_PROVENANCE.json"
  desktopRuntimeReady = $true
  desktopFirstFrame = $true
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $hashLower
  installer = $installerName
  installerEngine = $installerEngine
  installerSha256 = $installerHashLower
  installerInstall = "PASS"
  installerRuntimeReady = $true
  installerProvenanceVerified = $true
  installerSaveCloseRelaunchContinue = "PASS"
  installerPersistenceStorageType = $installedCreateEvidence.storageType
  installerRestoredGameState = $installedContinueEvidence.gameState
  installerRestoredSlot = $installedContinueEvidence.slot
  installerRestoredTileX = $installedContinueEvidence.tileX
  installerRestoredTileY = $installedContinueEvidence.tileY
  installerRestoredQuestState = $installedContinueEvidence.questState
  packagedProvenanceSourceCommit = $candidateProvenanceCheck.sourceCommit
  packagedProvenanceVerified = $true
  windowsSaveCloseRelaunchContinue = "PASS"
  persistenceStorageType = $createEvidence.storageType
  persistenceSavePath = $createEvidence.savePath
  persistenceSlot = $continueEvidence.slot
  restoredGameState = $continueEvidence.gameState
  restoredTileX = $continueEvidence.tileX
  restoredTileY = $continueEvidence.tileY
  restoredQuestState = $continueEvidence.questState
  acceptance = "TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

node scripts/verify-chapter1-release-evidence.js $OutputDir
if ($LASTEXITCODE -ne 0) {
  throw "Independent Chapter 1 release-evidence verification failed with code $LASTEXITCODE."
}
Write-Host "CHAPTER1_RELEASE_EVIDENCE_INDEPENDENT_VERIFY=PASS"

# Preserve failure-state material for diagnosis, but leave a successful run clean.
foreach ($cleanupPath in @($installerSmokeRoot, $persistenceRoot, $installedPersistenceRoot)) {
  if ($cleanupPath -and (Test-Path -LiteralPath $cleanupPath)) {
    Remove-Item -LiteralPath $cleanupPath -Recurse -Force
  }
}
foreach ($buildDebris in @(
  (Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.nsi"),
  (Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"),
  (Join-Path $OutputDir "install-chapter1-$shortHead.ps1")
)) {
  if (Test-Path -LiteralPath $buildDebris) {
    Remove-Item -LiteralPath $buildDebris -Force
  }
}
Write-Host "CHAPTER1_SUCCESS_CLEANUP=PASS"

Write-Host ""
Write-Host "AETHERWAKE_CHAPTER1_WINDOWS_CANDIDATE=PASS"
Write-Host "SOURCE_COMMIT=$gitHead"
Write-Host "PORTABLE_EXE=$(Join-Path $candidateDir 'Aetherwake.exe')"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$hashLower"
Write-Host "INSTALLER_SHA256=$installerHashLower"
Write-Host "EVIDENCE=$evidencePath"
Write-Host "WINDOWS_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"
Write-Host "INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"
