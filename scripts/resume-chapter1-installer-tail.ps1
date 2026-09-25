param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\chapter1-release"),
  [string]$Checkpoint = (Join-Path $PSScriptRoot "..\CHAPTER1_PORTABLE_CHECKPOINT.json")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

$gitHead = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $gitHead) { throw "Unable to resolve Git HEAD." }
$status = @(git status --porcelain --untracked-files=all)
if ($status.Count -gt 0) {
  throw "Resume checkout is not clean, including untracked non-ignored files."
}
$shortHead = $candidateSourceCommit.Substring(0, 12)

if (-not (Test-Path -LiteralPath $Checkpoint)) {
  throw "Portable checkpoint missing: $Checkpoint"
}
$checkpointData = Get-Content -LiteralPath $Checkpoint -Raw | ConvertFrom-Json
if ($checkpointData.kind -ne "AETHERWAKE_CHAPTER1_PORTABLE_CHECKPOINT") {
  throw "Portable checkpoint kind mismatch."
}
$candidateSourceCommit = [string]$checkpointData.sourceCommit
if (-not ($candidateSourceCommit -match '^[0-9a-f]{40}
foreach ($key in @("chapter1Core","chapter1Visual","chapter1BrowserRoute",
  "titleAudioReady","chapter1SoundtrackReady","desktopPackageContract",
  "buildProvenance","windowsSaveCloseRelaunchContinue")) {
  if ($checkpointData.$key -ne "PASS") { throw "Portable checkpoint $key is not PASS." }
}
if (-not $checkpointData.desktopRuntimeReady -or -not $checkpointData.desktopFirstFrame) {
  throw "Portable checkpoint lacks runtime-ready/first-frame proof."
}

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exeFile = Get-ChildItem -LiteralPath $distRoot -Filter "Aetherwake.exe" -File -Recurse |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $exeFile) { throw "Fresh Aetherwake.exe missing under $distRoot." }
$package = Get-Item -LiteralPath $exeFile.DirectoryName
$packageProvenance = Join-Path $package.FullName "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $packageProvenance)) { throw "Build provenance missing from packaged runtime." }
$prov = Get-Content -LiteralPath $packageProvenance -Raw | ConvertFrom-Json
if ($prov.sourceCommit -ne $candidateSourceCommit) {
  throw "Packaged source provenance does not match Windows-tested checkpoint."
}
$packageTreeSha256 = (node scripts/hash-chapter1-package.js $package.FullName).Trim()
if ($LASTEXITCODE -ne 0 -or $packageTreeSha256 -notmatch '^[0-9a-f]{64} { Remove-Item -LiteralPath $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir | Out-Null
$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse
$candidateTreeSha256 = (node scripts/hash-chapter1-package.js $candidateDir).Trim()
if ($LASTEXITCODE -ne 0 -or $candidateTreeSha256 -ne $packageTreeSha256) {
  throw "Copied resumable candidate tree does not match the portable checkpoint package."
}
$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()

$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"
if (-not (Test-Path -LiteralPath $iexpress)) { throw "Windows IExpress unavailable." }

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installScriptName = "install-chapter1-$shortHead.ps1"
$installScript = Join-Path $OutputDir $installScriptName
@'
param([Parameter(Mandatory=$true)][string]$Archive)
$ErrorActionPreference = "Stop"
$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE) {
  $env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE
} else {
  Join-Path $env:LOCALAPPDATA "Programs\Aetherwake Chapter 1"
}
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Expand-Archive -LiteralPath (Join-Path $PSScriptRoot $Archive) -DestinationPath $installRoot -Force
$exe = Join-Path $installRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Installed Aetherwake.exe missing." }
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
'@ | Set-Content -LiteralPath $installScript -Encoding UTF8

$sed = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"
$sourceDir = $OutputDir.TrimEnd('\') + '\'
$appLaunched = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $installScriptName + '" -Archive "' + $zipName + '"'
@"
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
"@ | Set-Content -LiteralPath $sed -Encoding ASCII
& $iexpress /N /Q $sed
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installer)) {
  throw "IExpress installer creation failed."
}
Write-Host "CHAPTER1_INSTALLER_ENGINE=IEXPRESS"

$installRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installRoot
try {
  $p = Start-Process -FilePath $installer -ArgumentList @("/Q:U") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Installer exited with code $($p.ExitCode)." }
} finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}
$installedExe = Join-Path $installRoot "Aetherwake.exe"
$installedProvPath = Join-Path $installRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedExe)) { throw "Installed Aetherwake.exe missing." }
if (-not (Test-Path -LiteralPath $installedProvPath)) { throw "Installed provenance missing." }
$installedProv = Get-Content -LiteralPath $installedProvPath -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $candidateSourceCommit) { throw "Installed provenance mismatch." }

$marker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) { throw "Installed executable exited before readiness." }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $marker)) { throw "Installed executable readiness timeout." }
  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame -or $ready.setupOrder -notlike "*setup-done*") {
    throw "Installed executable readiness evidence invalid."
  }
} finally {
  if ($game -and -not $game.HasExited) { Stop-Process -Id $game.Id -Force }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}
Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"

$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) { Remove-Item -LiteralPath $persistenceRoot -Recurse -Force }
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null
function Invoke-InstalledPersistence([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) { Remove-Item -LiteralPath $phaseMarker -Force }
  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker
  $phase = Start-Process -FilePath $installedExe -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phase.HasExited) { throw "Installed persistence $Mode exited early." }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) { throw "Installed persistence $Mode timeout." }
    $result = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($result.result -ne "PASS" -or $result.phase -ne $Mode) { throw "Installed persistence $Mode failed." }
    return $result
  } finally {
    if ($phase -and -not $phase.HasExited) { Stop-Process -Id $phase.Id -Force }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}
$created = Invoke-InstalledPersistence "create"
$continued = Invoke-InstalledPersistence "continue"
if ($created.storageType -ne "nw-file" -or $continued.gameState -ne "world" -or
    $continued.slot -ne "manual-6" -or $continued.tileX -ne 17 -or
    $continued.tileY -ne 16 -or $continued.questState -ne "signal") {
  throw "Installed persistence restore evidence mismatch."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLower()
@(
  "$zipHash  $zipName",
  "$installerHash  $installerName"
) | Set-Content -LiteralPath (Join-Path $OutputDir "SHA256SUMS.txt") -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $candidateSourceCommit
  releaseToolCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = $checkpointData.chapter1Core
  chapter1Visual = $checkpointData.chapter1Visual
  chapter1BrowserRoute = $checkpointData.chapter1BrowserRoute
  titleAudioReady = $checkpointData.titleAudioReady
  chapter1SoundtrackReady = $checkpointData.chapter1SoundtrackReady
  desktopPackageContract = $checkpointData.desktopPackageContract
  buildProvenance = $checkpointData.buildProvenance
  buildProvenanceFile = "CHAPTER1_BUILD_PROVENANCE.json"
  desktopRuntimeReady = $checkpointData.desktopRuntimeReady
  desktopFirstFrame = $checkpointData.desktopFirstFrame
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $zipHash
  installer = $installerName
  installerEngine = "IEXPRESS"
  installerSha256 = $installerHash
  installerInstall = "PASS"
  installerRuntimeReady = $true
  installerProvenanceVerified = $true
  installerSaveCloseRelaunchContinue = "PASS"
  installerPersistenceStorageType = $created.storageType
  installerRestoredGameState = $continued.gameState
  installerRestoredSlot = $continued.slot
  installerRestoredTileX = $continued.tileX
  installerRestoredTileY = $continued.tileY
  installerRestoredQuestState = $continued.questState
  packagedProvenanceSourceCommit = $candidateSourceCommit
  packagedProvenanceVerified = $true
  packagedTreeSha256 = $candidateTreeSha256
  windowsSaveCloseRelaunchContinue = $checkpointData.windowsSaveCloseRelaunchContinue
  persistenceStorageType = $checkpointData.persistenceStorageType
  persistenceSavePath = $checkpointData.persistenceSavePath
  persistenceSlot = $checkpointData.persistenceSlot
  restoredGameState = $checkpointData.restoredGameState
  restoredTileX = $checkpointData.restoredTileX
  restoredTileY = $checkpointData.restoredTileY
  restoredQuestState = $checkpointData.restoredQuestState
  acceptance = "TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

node scripts/verify-chapter1-release-evidence.js $OutputDir
if ($LASTEXITCODE -ne 0) { throw "Independent release-evidence verification failed." }

Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $persistenceRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $sed -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installScript -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Checkpoint -Force -ErrorAction SilentlyContinue

Write-Host "CHAPTER1_INSTALLER_TAIL_RESUME=PASS"
Write-Host "SOURCE_COMMIT=$candidateSourceCommit"
Write-Host "RELEASE_TOOL_COMMIT=$gitHead"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$zipHash"
Write-Host "PACKAGE_TREE_SHA256=$candidateTreeSha256"
Write-Host "INSTALLER_SHA256=$installerHash"
Write-Host "EVIDENCE=$evidencePath"
) {
  throw "Unable to fingerprint the resumable packaged runtime."
}
if ($checkpointData.packageTreeSha256 -ne $packageTreeSha256) {
  throw "Packaged runtime tree changed after portable checkpoint."
}

if (Test-Path -LiteralPath $OutputDir) { Remove-Item -LiteralPath $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir | Out-Null
$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse
$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()

$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"
if (-not (Test-Path -LiteralPath $iexpress)) { throw "Windows IExpress unavailable." }

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installScriptName = "install-chapter1-$shortHead.ps1"
$installScript = Join-Path $OutputDir $installScriptName
@'
param([Parameter(Mandatory=$true)][string]$Archive)
$ErrorActionPreference = "Stop"
$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE) {
  $env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE
} else {
  Join-Path $env:LOCALAPPDATA "Programs\Aetherwake Chapter 1"
}
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Expand-Archive -LiteralPath (Join-Path $PSScriptRoot $Archive) -DestinationPath $installRoot -Force
$exe = Join-Path $installRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Installed Aetherwake.exe missing." }
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
'@ | Set-Content -LiteralPath $installScript -Encoding UTF8

$sed = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"
$sourceDir = $OutputDir.TrimEnd('\') + '\'
$appLaunched = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $installScriptName + '" -Archive "' + $zipName + '"'
@"
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
"@ | Set-Content -LiteralPath $sed -Encoding ASCII
& $iexpress /N /Q $sed
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installer)) {
  throw "IExpress installer creation failed."
}
Write-Host "CHAPTER1_INSTALLER_ENGINE=IEXPRESS"

$installRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installRoot
try {
  $p = Start-Process -FilePath $installer -ArgumentList @("/Q:U") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Installer exited with code $($p.ExitCode)." }
} finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}
$installedExe = Join-Path $installRoot "Aetherwake.exe"
$installedProvPath = Join-Path $installRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedExe)) { throw "Installed Aetherwake.exe missing." }
if (-not (Test-Path -LiteralPath $installedProvPath)) { throw "Installed provenance missing." }
$installedProv = Get-Content -LiteralPath $installedProvPath -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $candidateSourceCommit) { throw "Installed provenance mismatch." }

$marker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) { throw "Installed executable exited before readiness." }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $marker)) { throw "Installed executable readiness timeout." }
  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame -or $ready.setupOrder -notlike "*setup-done*") {
    throw "Installed executable readiness evidence invalid."
  }
} finally {
  if ($game -and -not $game.HasExited) { Stop-Process -Id $game.Id -Force }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}
Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"

$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) { Remove-Item -LiteralPath $persistenceRoot -Recurse -Force }
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null
function Invoke-InstalledPersistence([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) { Remove-Item -LiteralPath $phaseMarker -Force }
  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker
  $phase = Start-Process -FilePath $installedExe -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phase.HasExited) { throw "Installed persistence $Mode exited early." }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) { throw "Installed persistence $Mode timeout." }
    $result = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($result.result -ne "PASS" -or $result.phase -ne $Mode) { throw "Installed persistence $Mode failed." }
    return $result
  } finally {
    if ($phase -and -not $phase.HasExited) { Stop-Process -Id $phase.Id -Force }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}
$created = Invoke-InstalledPersistence "create"
$continued = Invoke-InstalledPersistence "continue"
if ($created.storageType -ne "nw-file" -or $continued.gameState -ne "world" -or
    $continued.slot -ne "manual-6" -or $continued.tileX -ne 17 -or
    $continued.tileY -ne 16 -or $continued.questState -ne "signal") {
  throw "Installed persistence restore evidence mismatch."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLower()
@(
  "$zipHash  $zipName",
  "$installerHash  $installerName"
) | Set-Content -LiteralPath (Join-Path $OutputDir "SHA256SUMS.txt") -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = $checkpointData.chapter1Core
  chapter1Visual = $checkpointData.chapter1Visual
  chapter1BrowserRoute = $checkpointData.chapter1BrowserRoute
  titleAudioReady = $checkpointData.titleAudioReady
  chapter1SoundtrackReady = $checkpointData.chapter1SoundtrackReady
  desktopPackageContract = $checkpointData.desktopPackageContract
  buildProvenance = $checkpointData.buildProvenance
  buildProvenanceFile = "CHAPTER1_BUILD_PROVENANCE.json"
  desktopRuntimeReady = $checkpointData.desktopRuntimeReady
  desktopFirstFrame = $checkpointData.desktopFirstFrame
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $zipHash
  installer = $installerName
  installerEngine = "IEXPRESS"
  installerSha256 = $installerHash
  installerInstall = "PASS"
  installerRuntimeReady = $true
  installerProvenanceVerified = $true
  installerSaveCloseRelaunchContinue = "PASS"
  installerPersistenceStorageType = $created.storageType
  installerRestoredGameState = $continued.gameState
  installerRestoredSlot = $continued.slot
  installerRestoredTileX = $continued.tileX
  installerRestoredTileY = $continued.tileY
  installerRestoredQuestState = $continued.questState
  packagedProvenanceSourceCommit = $prov.sourceCommit
  packagedProvenanceVerified = $true
  windowsSaveCloseRelaunchContinue = $checkpointData.windowsSaveCloseRelaunchContinue
  persistenceStorageType = $checkpointData.persistenceStorageType
  persistenceSavePath = $checkpointData.persistenceSavePath
  persistenceSlot = $checkpointData.persistenceSlot
  restoredGameState = $checkpointData.restoredGameState
  restoredTileX = $checkpointData.restoredTileX
  restoredTileY = $checkpointData.restoredTileY
  restoredQuestState = $checkpointData.restoredQuestState
  acceptance = "TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

node scripts/verify-chapter1-release-evidence.js $OutputDir
if ($LASTEXITCODE -ne 0) { throw "Independent release-evidence verification failed." }

Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $persistenceRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $sed -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installScript -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Checkpoint -Force -ErrorAction SilentlyContinue

Write-Host "CHAPTER1_INSTALLER_TAIL_RESUME=PASS"
Write-Host "SOURCE_COMMIT=$gitHead"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$zipHash"
Write-Host "INSTALLER_SHA256=$installerHash"
Write-Host "EVIDENCE=$evidencePath"
)) {
  throw "Portable checkpoint sourceCommit is not a full Git SHA."
}

# Recovery may run from a later release-tooling head, but never after gameplay/runtime
# content drift. The packaged candidate remains bound to the Windows-tested commit.
git merge-base --is-ancestor $candidateSourceCommit $gitHead
if ($LASTEXITCODE -ne 0) {
  throw "Portable checkpoint sourceCommit is not an ancestor of current Git HEAD."
}
$allowedReleaseOnly = @(
  '.gitignore',
  'package.json',
  'docs/CHAPTER1_CLOSURE_AUDIT.md',
  'docs/CHAPTER1_PLAYER_ACCEPTANCE.md',
  'scripts/build-chapter1-windows.ps1',
  'scripts/resume-chapter1-installer-tail.ps1',
  'scripts/verify-chapter1-release-evidence.js',
  'tests/chapter1-convergence-contract.test.js',
  'tests/chapter1-installer-fallback-contract.test.js',
  'tests/chapter1-release-evidence-verifier.test.js'
)
$deltaFiles = @(git diff --name-only "$candidateSourceCommit..$gitHead")
$unexpectedDelta = @($deltaFiles | Where-Object { $_ -notin $allowedReleaseOnly })
if ($unexpectedDelta.Count -gt 0) {
  throw "Resume blocked: runtime/content drift exists after tested checkpoint: $($unexpectedDelta -join ', ')"
}
Write-Host "CHAPTER1_RESUME_RELEASE_ONLY_DELTA=PASS"
Write-Host "CHAPTER1_CANDIDATE_SOURCE_COMMIT=$candidateSourceCommit"
Write-Host "CHAPTER1_RELEASE_TOOL_HEAD=$gitHead"
foreach ($key in @("chapter1Core","chapter1Visual","chapter1BrowserRoute",
  "titleAudioReady","chapter1SoundtrackReady","desktopPackageContract",
  "buildProvenance","windowsSaveCloseRelaunchContinue")) {
  if ($checkpointData.$key -ne "PASS") { throw "Portable checkpoint $key is not PASS." }
}
if (-not $checkpointData.desktopRuntimeReady -or -not $checkpointData.desktopFirstFrame) {
  throw "Portable checkpoint lacks runtime-ready/first-frame proof."
}

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exeFile = Get-ChildItem -LiteralPath $distRoot -Filter "Aetherwake.exe" -File -Recurse |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $exeFile) { throw "Fresh Aetherwake.exe missing under $distRoot." }
$package = Get-Item -LiteralPath $exeFile.DirectoryName
$packageProvenance = Join-Path $package.FullName "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $packageProvenance)) { throw "Build provenance missing from packaged runtime." }
$prov = Get-Content -LiteralPath $packageProvenance -Raw | ConvertFrom-Json
if ($prov.sourceCommit -ne $gitHead) { throw "Packaged source provenance does not match checkpoint/Git HEAD." }
$packageTreeSha256 = (node scripts/hash-chapter1-package.js $package.FullName).Trim()
if ($LASTEXITCODE -ne 0 -or $packageTreeSha256 -notmatch '^[0-9a-f]{64} { Remove-Item -LiteralPath $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir | Out-Null
$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse
$candidateTreeSha256 = (node scripts/hash-chapter1-package.js $candidateDir).Trim()
if ($LASTEXITCODE -ne 0 -or $candidateTreeSha256 -ne $packageTreeSha256) {
  throw "Copied resumable candidate tree does not match the portable checkpoint package."
}
$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()

$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"
if (-not (Test-Path -LiteralPath $iexpress)) { throw "Windows IExpress unavailable." }

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installScriptName = "install-chapter1-$shortHead.ps1"
$installScript = Join-Path $OutputDir $installScriptName
@'
param([Parameter(Mandatory=$true)][string]$Archive)
$ErrorActionPreference = "Stop"
$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE) {
  $env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE
} else {
  Join-Path $env:LOCALAPPDATA "Programs\Aetherwake Chapter 1"
}
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Expand-Archive -LiteralPath (Join-Path $PSScriptRoot $Archive) -DestinationPath $installRoot -Force
$exe = Join-Path $installRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Installed Aetherwake.exe missing." }
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
'@ | Set-Content -LiteralPath $installScript -Encoding UTF8

$sed = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"
$sourceDir = $OutputDir.TrimEnd('\') + '\'
$appLaunched = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $installScriptName + '" -Archive "' + $zipName + '"'
@"
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
"@ | Set-Content -LiteralPath $sed -Encoding ASCII
& $iexpress /N /Q $sed
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installer)) {
  throw "IExpress installer creation failed."
}
Write-Host "CHAPTER1_INSTALLER_ENGINE=IEXPRESS"

$installRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installRoot
try {
  $p = Start-Process -FilePath $installer -ArgumentList @("/Q:U") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Installer exited with code $($p.ExitCode)." }
} finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}
$installedExe = Join-Path $installRoot "Aetherwake.exe"
$installedProvPath = Join-Path $installRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedExe)) { throw "Installed Aetherwake.exe missing." }
if (-not (Test-Path -LiteralPath $installedProvPath)) { throw "Installed provenance missing." }
$installedProv = Get-Content -LiteralPath $installedProvPath -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $candidateSourceCommit) { throw "Installed provenance mismatch." }

$marker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) { throw "Installed executable exited before readiness." }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $marker)) { throw "Installed executable readiness timeout." }
  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame -or $ready.setupOrder -notlike "*setup-done*") {
    throw "Installed executable readiness evidence invalid."
  }
} finally {
  if ($game -and -not $game.HasExited) { Stop-Process -Id $game.Id -Force }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}
Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"

$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) { Remove-Item -LiteralPath $persistenceRoot -Recurse -Force }
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null
function Invoke-InstalledPersistence([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) { Remove-Item -LiteralPath $phaseMarker -Force }
  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker
  $phase = Start-Process -FilePath $installedExe -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phase.HasExited) { throw "Installed persistence $Mode exited early." }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) { throw "Installed persistence $Mode timeout." }
    $result = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($result.result -ne "PASS" -or $result.phase -ne $Mode) { throw "Installed persistence $Mode failed." }
    return $result
  } finally {
    if ($phase -and -not $phase.HasExited) { Stop-Process -Id $phase.Id -Force }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}
$created = Invoke-InstalledPersistence "create"
$continued = Invoke-InstalledPersistence "continue"
if ($created.storageType -ne "nw-file" -or $continued.gameState -ne "world" -or
    $continued.slot -ne "manual-6" -or $continued.tileX -ne 17 -or
    $continued.tileY -ne 16 -or $continued.questState -ne "signal") {
  throw "Installed persistence restore evidence mismatch."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLower()
@(
  "$zipHash  $zipName",
  "$installerHash  $installerName"
) | Set-Content -LiteralPath (Join-Path $OutputDir "SHA256SUMS.txt") -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = $checkpointData.chapter1Core
  chapter1Visual = $checkpointData.chapter1Visual
  chapter1BrowserRoute = $checkpointData.chapter1BrowserRoute
  titleAudioReady = $checkpointData.titleAudioReady
  chapter1SoundtrackReady = $checkpointData.chapter1SoundtrackReady
  desktopPackageContract = $checkpointData.desktopPackageContract
  buildProvenance = $checkpointData.buildProvenance
  buildProvenanceFile = "CHAPTER1_BUILD_PROVENANCE.json"
  desktopRuntimeReady = $checkpointData.desktopRuntimeReady
  desktopFirstFrame = $checkpointData.desktopFirstFrame
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $zipHash
  installer = $installerName
  installerEngine = "IEXPRESS"
  installerSha256 = $installerHash
  installerInstall = "PASS"
  installerRuntimeReady = $true
  installerProvenanceVerified = $true
  installerSaveCloseRelaunchContinue = "PASS"
  installerPersistenceStorageType = $created.storageType
  installerRestoredGameState = $continued.gameState
  installerRestoredSlot = $continued.slot
  installerRestoredTileX = $continued.tileX
  installerRestoredTileY = $continued.tileY
  installerRestoredQuestState = $continued.questState
  packagedProvenanceSourceCommit = $prov.sourceCommit
  packagedProvenanceVerified = $true
  packagedTreeSha256 = $candidateTreeSha256
  windowsSaveCloseRelaunchContinue = $checkpointData.windowsSaveCloseRelaunchContinue
  persistenceStorageType = $checkpointData.persistenceStorageType
  persistenceSavePath = $checkpointData.persistenceSavePath
  persistenceSlot = $checkpointData.persistenceSlot
  restoredGameState = $checkpointData.restoredGameState
  restoredTileX = $checkpointData.restoredTileX
  restoredTileY = $checkpointData.restoredTileY
  restoredQuestState = $checkpointData.restoredQuestState
  acceptance = "TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

node scripts/verify-chapter1-release-evidence.js $OutputDir
if ($LASTEXITCODE -ne 0) { throw "Independent release-evidence verification failed." }

Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $persistenceRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $sed -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installScript -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Checkpoint -Force -ErrorAction SilentlyContinue

Write-Host "CHAPTER1_INSTALLER_TAIL_RESUME=PASS"
Write-Host "SOURCE_COMMIT=$gitHead"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$zipHash"
Write-Host "PACKAGE_TREE_SHA256=$candidateTreeSha256"
Write-Host "INSTALLER_SHA256=$installerHash"
Write-Host "EVIDENCE=$evidencePath"
) {
  throw "Unable to fingerprint the resumable packaged runtime."
}
if ($checkpointData.packageTreeSha256 -ne $packageTreeSha256) {
  throw "Packaged runtime tree changed after portable checkpoint."
}

if (Test-Path -LiteralPath $OutputDir) { Remove-Item -LiteralPath $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir | Out-Null
$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse
$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()

$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"
if (-not (Test-Path -LiteralPath $iexpress)) { throw "Windows IExpress unavailable." }

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installScriptName = "install-chapter1-$shortHead.ps1"
$installScript = Join-Path $OutputDir $installScriptName
@'
param([Parameter(Mandatory=$true)][string]$Archive)
$ErrorActionPreference = "Stop"
$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE) {
  $env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE
} else {
  Join-Path $env:LOCALAPPDATA "Programs\Aetherwake Chapter 1"
}
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Expand-Archive -LiteralPath (Join-Path $PSScriptRoot $Archive) -DestinationPath $installRoot -Force
$exe = Join-Path $installRoot "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Installed Aetherwake.exe missing." }
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
'@ | Set-Content -LiteralPath $installScript -Encoding UTF8

$sed = Join-Path $OutputDir "Aetherwake-Chapter1-$shortHead-Setup.sed"
$sourceDir = $OutputDir.TrimEnd('\') + '\'
$appLaunched = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $installScriptName + '" -Archive "' + $zipName + '"'
@"
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
"@ | Set-Content -LiteralPath $sed -Encoding ASCII
& $iexpress /N /Q $sed
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installer)) {
  throw "IExpress installer creation failed."
}
Write-Host "CHAPTER1_INSTALLER_ENGINE=IEXPRESS"

$installRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installRoot
try {
  $p = Start-Process -FilePath $installer -ArgumentList @("/Q:U") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Installer exited with code $($p.ExitCode)." }
} finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}
$installedExe = Join-Path $installRoot "Aetherwake.exe"
$installedProvPath = Join-Path $installRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedExe)) { throw "Installed Aetherwake.exe missing." }
if (-not (Test-Path -LiteralPath $installedProvPath)) { throw "Installed provenance missing." }
$installedProv = Get-Content -LiteralPath $installedProvPath -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $candidateSourceCommit) { throw "Installed provenance mismatch." }

$marker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) { throw "Installed executable exited before readiness." }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $marker)) { throw "Installed executable readiness timeout." }
  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame -or $ready.setupOrder -notlike "*setup-done*") {
    throw "Installed executable readiness evidence invalid."
  }
} finally {
  if ($game -and -not $game.HasExited) { Stop-Process -Id $game.Id -Force }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}
Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"

$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) { Remove-Item -LiteralPath $persistenceRoot -Recurse -Force }
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null
function Invoke-InstalledPersistence([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) { Remove-Item -LiteralPath $phaseMarker -Force }
  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker
  $phase = Start-Process -FilePath $installedExe -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phase.HasExited) { throw "Installed persistence $Mode exited early." }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) { throw "Installed persistence $Mode timeout." }
    $result = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($result.result -ne "PASS" -or $result.phase -ne $Mode) { throw "Installed persistence $Mode failed." }
    return $result
  } finally {
    if ($phase -and -not $phase.HasExited) { Stop-Process -Id $phase.Id -Force }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}
$created = Invoke-InstalledPersistence "create"
$continued = Invoke-InstalledPersistence "continue"
if ($created.storageType -ne "nw-file" -or $continued.gameState -ne "world" -or
    $continued.slot -ne "manual-6" -or $continued.tileX -ne 17 -or
    $continued.tileY -ne 16 -or $continued.questState -ne "signal") {
  throw "Installed persistence restore evidence mismatch."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installer).Hash.ToLower()
@(
  "$zipHash  $zipName",
  "$installerHash  $installerName"
) | Set-Content -LiteralPath (Join-Path $OutputDir "SHA256SUMS.txt") -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = $checkpointData.chapter1Core
  chapter1Visual = $checkpointData.chapter1Visual
  chapter1BrowserRoute = $checkpointData.chapter1BrowserRoute
  titleAudioReady = $checkpointData.titleAudioReady
  chapter1SoundtrackReady = $checkpointData.chapter1SoundtrackReady
  desktopPackageContract = $checkpointData.desktopPackageContract
  buildProvenance = $checkpointData.buildProvenance
  buildProvenanceFile = "CHAPTER1_BUILD_PROVENANCE.json"
  desktopRuntimeReady = $checkpointData.desktopRuntimeReady
  desktopFirstFrame = $checkpointData.desktopFirstFrame
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $zipHash
  installer = $installerName
  installerEngine = "IEXPRESS"
  installerSha256 = $installerHash
  installerInstall = "PASS"
  installerRuntimeReady = $true
  installerProvenanceVerified = $true
  installerSaveCloseRelaunchContinue = "PASS"
  installerPersistenceStorageType = $created.storageType
  installerRestoredGameState = $continued.gameState
  installerRestoredSlot = $continued.slot
  installerRestoredTileX = $continued.tileX
  installerRestoredTileY = $continued.tileY
  installerRestoredQuestState = $continued.questState
  packagedProvenanceSourceCommit = $prov.sourceCommit
  packagedProvenanceVerified = $true
  windowsSaveCloseRelaunchContinue = $checkpointData.windowsSaveCloseRelaunchContinue
  persistenceStorageType = $checkpointData.persistenceStorageType
  persistenceSavePath = $checkpointData.persistenceSavePath
  persistenceSlot = $checkpointData.persistenceSlot
  restoredGameState = $checkpointData.restoredGameState
  restoredTileX = $checkpointData.restoredTileX
  restoredTileY = $checkpointData.restoredTileY
  restoredQuestState = $checkpointData.restoredQuestState
  acceptance = "TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

node scripts/verify-chapter1-release-evidence.js $OutputDir
if ($LASTEXITCODE -ne 0) { throw "Independent release-evidence verification failed." }

Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $persistenceRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $sed -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installScript -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Checkpoint -Force -ErrorAction SilentlyContinue

Write-Host "CHAPTER1_INSTALLER_TAIL_RESUME=PASS"
Write-Host "SOURCE_COMMIT=$gitHead"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$zipHash"
Write-Host "INSTALLER_SHA256=$installerHash"
Write-Host "EVIDENCE=$evidencePath"
