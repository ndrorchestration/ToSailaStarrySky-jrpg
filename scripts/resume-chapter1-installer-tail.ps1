param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\chapter1-release"),
  [string]$Checkpoint = (Join-Path $PSScriptRoot "..\CHAPTER1_PORTABLE_CHECKPOINT.json")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake Chapter 1 installer-tail resume =="

function Get-Sha256Hex([string]$Path) {
  if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "SHA-256 source file missing: $Path"
  }

  $fileHashCommand = Get-Command Get-FileHash -ErrorAction SilentlyContinue
  if ($fileHashCommand) {
    $nativeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    if ($nativeHash -notmatch '^[0-9A-Fa-f]{64}$') {
      throw "Get-FileHash returned an invalid SHA-256 value for $Path"
    }
    return $nativeHash.ToLowerInvariant()
  }

  $stream = [System.IO.File]::Open(
    $Path,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read,
    [System.IO.FileShare]::Read
  )
  try {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hashBytes = $sha256.ComputeHash($stream)
      $fallbackHash = ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
      if ($fallbackHash -notmatch '^[0-9a-f]{64}$') {
        throw "Fallback SHA-256 computation returned an invalid value for $Path"
      }
      return $fallbackHash
    }
    finally {
      if ($sha256) { $sha256.Dispose() }
    }
  }
  finally {
    $stream.Dispose()
  }
}

function Stop-ProcessAndWait($Process, [int]$TimeoutMs = 5000) {
  if (-not $Process) { return }
  try {
    if (-not $Process.HasExited) {
      Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
    [void]$Process.WaitForExit($TimeoutMs)
  } catch {
    # Cleanup retry below remains the final authority for file-release timing.
  }
}

function Remove-PathWithRetry([string]$Path, [int]$Attempts = 20, [int]$DelayMs = 250) {
  if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return }
  for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    try {
      Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
      return
    } catch {
      if ($attempt -eq $Attempts) { throw }
      Start-Sleep -Milliseconds $DelayMs
    }
  }
}

function Stop-ProcessesFromRoot([string]$Root, [int]$Attempts = 20, [int]$DelayMs = 250) {
  if (-not $Root) { return }
  for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    $rooted = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.ExecutablePath -and $_.ExecutablePath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($rooted.Count -eq 0) { return }
    foreach ($proc in $rooted) {
      Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds $DelayMs
  }
  $remaining = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ExecutablePath -and $_.ExecutablePath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)
  })
  if ($remaining.Count -gt 0) {
    throw "Processes remain rooted in temporary Chapter 1 install path: $($remaining.ProcessId -join ', ')"
  }
}

$gitHead = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $gitHead) {
  throw "Unable to resolve Git HEAD."
}

$status = @(git status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0) { throw "git status failed." }
if ($status.Count -gt 0) {
  throw "Resume checkout is not clean, including untracked non-ignored files."
}

if (-not (Test-Path -LiteralPath $Checkpoint)) {
  throw "Portable checkpoint missing: $Checkpoint"
}
$checkpointData = Get-Content -LiteralPath $Checkpoint -Raw | ConvertFrom-Json
if ($checkpointData.kind -ne "AETHERWAKE_CHAPTER1_PORTABLE_CHECKPOINT") {
  throw "Portable checkpoint kind mismatch."
}

$candidateSourceCommit = [string]$checkpointData.sourceCommit
if ($candidateSourceCommit -notmatch '^[0-9a-f]{40}$') {
  throw "Portable checkpoint sourceCommit is not a full Git SHA."
}
$shortHead = $candidateSourceCommit.Substring(0, 12)

# Resume is allowed from a later release-tooling commit, but never after gameplay/runtime
# drift. The packaged candidate remains bound to the Windows-tested checkpoint commit.
git merge-base --is-ancestor $candidateSourceCommit $gitHead
if ($LASTEXITCODE -ne 0) {
  throw "Portable checkpoint sourceCommit is not an ancestor of current Git HEAD."
}
$allowedReleaseOnly = @(
  '.gitignore',
  'package.json',
  'docs/CHAPTER1_CLOSURE_AUDIT.md',
  'docs/CHAPTER1_PLAYER_ACCEPTANCE.md',
  '.github/workflows/chapter1-windows-candidate.yml',
  'scripts/build-chapter1-windows.ps1',
  'scripts/hash-chapter1-package.js',
  'scripts/resume-chapter1-installer-tail.ps1',
  'scripts/verify-chapter1-release-evidence.js',
  'tests/chapter1-convergence-contract.test.js',
  'tests/chapter1-installer-fallback-contract.test.js',
  'tests/chapter1-package-fingerprint.test.js',
  'tests/chapter1-release-evidence-verifier.test.js'
)
$deltaFiles = @(git diff --name-only "$candidateSourceCommit..$gitHead")
if ($LASTEXITCODE -ne 0) { throw "Unable to compare checkpoint commit with release-tooling head." }
$unexpectedDelta = @($deltaFiles | Where-Object { $_ -notin $allowedReleaseOnly })
if ($unexpectedDelta.Count -gt 0) {
  throw "Resume blocked: runtime/content drift exists after tested checkpoint: $($unexpectedDelta -join ', ')"
}
Write-Host "CHAPTER1_RESUME_RELEASE_ONLY_DELTA=PASS"
Write-Host "CHAPTER1_CANDIDATE_SOURCE_COMMIT=$candidateSourceCommit"
Write-Host "CHAPTER1_RELEASE_TOOL_HEAD=$gitHead"

foreach ($key in @(
  "chapter1Core",
  "chapter1Visual",
  "chapter1BrowserRoute",
  "titleAudioReady",
  "chapter1SoundtrackReady",
  "desktopPackageContract",
  "buildProvenance",
  "windowsSaveCloseRelaunchContinue"
)) {
  if ($checkpointData.$key -ne "PASS") {
    throw "Portable checkpoint $key is not PASS."
  }
}
if (-not $checkpointData.desktopRuntimeReady -or -not $checkpointData.desktopFirstFrame) {
  throw "Portable checkpoint lacks runtime-ready/first-frame proof."
}
if ($checkpointData.persistenceStorageType -ne "nw-file" -or
    $checkpointData.persistenceSlot -ne "manual-6" -or
    $checkpointData.restoredGameState -ne "world" -or
    $checkpointData.restoredTileX -ne 17 -or
    $checkpointData.restoredTileY -ne 16 -or
    $checkpointData.restoredQuestState -ne "signal") {
  throw "Portable checkpoint persistence semantics are invalid."
}
if ([string]$checkpointData.packageTreeSha256 -notmatch '^[0-9a-f]{64}$') {
  throw "Portable checkpoint packageTreeSha256 is invalid."
}

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exeFile = Get-ChildItem -LiteralPath $distRoot -Filter "Aetherwake.exe" -File -Recurse |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $exeFile) {
  throw "Aetherwake.exe missing under resumable package root: $distRoot"
}
$package = Get-Item -LiteralPath $exeFile.DirectoryName
$packageProvenance = Join-Path $package.FullName "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $packageProvenance)) {
  throw "Build provenance missing from packaged runtime."
}
$prov = Get-Content -LiteralPath $packageProvenance -Raw | ConvertFrom-Json
if ($prov.sourceCommit -ne $candidateSourceCommit) {
  throw "Packaged source provenance does not match Windows-tested checkpoint."
}

$packageTreeSha256 = (node scripts/hash-chapter1-package.js $package.FullName).Trim()
if ($LASTEXITCODE -ne 0 -or $packageTreeSha256 -notmatch '^[0-9a-f]{64}$') {
  throw "Unable to fingerprint the resumable packaged runtime."
}
if ($checkpointData.packageTreeSha256 -ne $packageTreeSha256) {
  throw "Packaged runtime tree changed after portable checkpoint."
}
Write-Host "CHAPTER1_RESUME_PACKAGE_TREE=PASS"

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
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
$zipHash = Get-Sha256Hex $zip

# Build the same no-admin installer shape as the full candidate lane.
$makensis = @(
  "C:\Program Files (x86)\NSIS\makensis.exe",
  "C:\Program Files\NSIS\makensis.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"

$installerName = "Aetherwake-Chapter1-$shortHead-Setup.exe"
$installer = Join-Path $OutputDir $installerName
$installerEngine = $null
$nsi = $null
$sed = $null
$installScript = $null

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
  if ($LASTEXITCODE -ne 0) {
    throw "Chapter 1 NSIS compilation failed with code $LASTEXITCODE."
  }
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
if (-not (Test-Path -LiteralPath $exe)) {
  throw "Installed Aetherwake.exe missing after extraction."
}

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

  # IExpress is brittle when its source/target workspace contains spaces.
  # Stage only the self-extractor inputs in a short temporary path, then copy
  # the completed installer back to the requested release directory.
  $iexpressUsesStaging = $OutputDir -match '\s'
  $iexpressWorkDir = $OutputDir
  if ($iexpressUsesStaging) {
    $iexpressWorkDir = Join-Path $env:TEMP ("AetherwakeChapter1IExpress-" + $shortHead)
    if (Test-Path -LiteralPath $iexpressWorkDir) {
      Remove-PathWithRetry $iexpressWorkDir
    }
    New-Item -ItemType Directory -Path $iexpressWorkDir -Force | Out-Null
    Copy-Item -LiteralPath $zip -Destination (Join-Path $iexpressWorkDir $zipName) -Force
    Copy-Item -LiteralPath $installScript -Destination (Join-Path $iexpressWorkDir $installScriptName) -Force
  }
  $iexpressInstaller = if ($iexpressUsesStaging) {
    Join-Path $iexpressWorkDir ([System.IO.Path]::GetFileName($installer))
  } else {
    $installer
  }
  $sedName = "Aetherwake-Chapter1-$shortHead-Setup.sed"
  $sed = Join-Path $iexpressWorkDir $sedName
  $sourceDir = $iexpressWorkDir.TrimEnd('\') + '\'
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
TargetName=$iexpressInstaller
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
  # IExpress delegates CAB creation to MakeCab, which requires TMP to resolve to
  # a writable directory. Some remote/non-interactive Windows sessions leave TMP unset.
  $previousTmp = $env:TMP
  $env:TMP = $iexpressWorkDir
  try {
    $iexpressProcess = Start-Process -FilePath $iexpress -ArgumentList @("/N", "/Q", $sed) -Wait -PassThru
    $iexpressExitCode = $iexpressProcess.ExitCode
  } finally {
    if ([string]::IsNullOrEmpty($previousTmp)) {
      Remove-Item Env:TMP -ErrorAction SilentlyContinue
    } else {
      $env:TMP = $previousTmp
    }
  }
  if ($iexpressExitCode -ne 0) {
    throw "Chapter 1 IExpress compilation failed with code $iexpressExitCode."
  }
  if ($iexpressUsesStaging) {
    if (-not (Test-Path -LiteralPath $iexpressInstaller)) {
      throw "Chapter 1 staged IExpress installer was not created."
    }
    Copy-Item -LiteralPath $iexpressInstaller -Destination $installer -Force
    Copy-Item -LiteralPath $sed -Destination (Join-Path $OutputDir $sedName) -Force
    Remove-PathWithRetry $iexpressWorkDir
  }
} else {
  throw "No supported no-admin installer engine found (NSIS or Windows IExpress)."
}

if (-not (Test-Path -LiteralPath $installer)) {
  throw "Chapter 1 installer was not created."
}
Write-Host "CHAPTER1_INSTALLER_ENGINE=$installerEngine"

# Install silently into an isolated location; player shortcuts/auto-launch stay suppressed.
$installRoot = Join-Path $env:TEMP ("AetherwakeChapter1Installer-" + $shortHead)
if (Test-Path -LiteralPath $installRoot) {
  Stop-ProcessesFromRoot $installRoot
  Remove-PathWithRetry $installRoot
}
$env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE = "1"
$env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE = $installRoot
$installerArgs = if ($installerEngine -eq "NSIS") { @("/S") } else { @("/Q:U") }
try {
  $p = Start-Process -FilePath $installer -ArgumentList $installerArgs -Wait -PassThru
  if ($p.ExitCode -ne 0) {
    throw "Installer exited with code $($p.ExitCode)."
  }
} finally {
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue
}

$installedExe = Join-Path $installRoot "Aetherwake.exe"
$installedProvPath = Join-Path $installRoot "CHAPTER1_BUILD_PROVENANCE.json"
if (-not (Test-Path -LiteralPath $installedExe)) {
  throw "Installed Aetherwake.exe missing."
}
if (-not (Test-Path -LiteralPath $installedProvPath)) {
  throw "Installed provenance missing."
}
$installedProv = Get-Content -LiteralPath $installedProvPath -Raw | ConvertFrom-Json
if ($installedProv.sourceCommit -ne $candidateSourceCommit) {
  throw "Installed provenance mismatch."
}

$marker = Join-Path $env:TEMP ("aetherwake-chapter1-installer-ready-" + $shortHead + ".json")
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}
$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $installedExe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) {
      throw "Installed executable exited before readiness."
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path -LiteralPath $marker)) {
    throw "Installed executable readiness timeout."
  }
  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame -or
      $ready.width -ne 960 -or $ready.height -ne 640 -or
      $ready.setupOrder -notlike "*setup-done*") {
    throw "Installed executable readiness evidence invalid."
  }
} finally {
  if ($game -and -not $game.HasExited) {
    Stop-ProcessAndWait $game
  }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}
Write-Host "CHAPTER1_INSTALLER_RENDER_READINESS=PASS"

$persistenceRoot = Join-Path $env:TEMP ("aetherwake-chapter1-installed-persistence-" + $shortHead)
if (Test-Path -LiteralPath $persistenceRoot) {
  Remove-Item -LiteralPath $persistenceRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $persistenceRoot | Out-Null

function Invoke-InstalledPersistence([string]$Mode) {
  $phaseMarker = Join-Path $env:TEMP ("aetherwake-chapter1-installed-" + $Mode + ".json")
  if (Test-Path -LiteralPath $phaseMarker) {
    Remove-Item -LiteralPath $phaseMarker -Force
  }

  $env:AETHERWAKE_SAVE_ROOT_OVERRIDE = $persistenceRoot
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE = $Mode
  $env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER = $phaseMarker

  $phase = Start-Process -FilePath $installedExe -PassThru
  try {
    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $phaseMarker)) {
      if ($phase.HasExited) {
        throw "Installed persistence $Mode exited early."
      }
      Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $phaseMarker)) {
      throw "Installed persistence $Mode timeout."
    }
    $result = Get-Content -LiteralPath $phaseMarker -Raw | ConvertFrom-Json
    if ($result.result -ne "PASS" -or $result.phase -ne $Mode) {
      throw "Installed persistence $Mode failed."
    }
    return $result
  } finally {
    if ($phase -and -not $phase.HasExited) {
      Stop-ProcessAndWait $phase
    }
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER -ErrorAction SilentlyContinue
    Remove-Item Env:AETHERWAKE_SAVE_ROOT_OVERRIDE -ErrorAction SilentlyContinue
  }
}

$created = Invoke-InstalledPersistence "create"
$continued = Invoke-InstalledPersistence "continue"
if ($created.storageType -ne "nw-file" -or
    $continued.gameState -ne "world" -or
    $continued.slot -ne "manual-6" -or
    $continued.tileX -ne 17 -or
    $continued.tileY -ne 16 -or
    $continued.questState -ne "signal") {
  throw "Installed persistence restore evidence mismatch."
}
Write-Host "CHAPTER1_INSTALLER_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS"

$installerHash = Get-Sha256Hex $installer
$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
@(
  "$zipHash  $zipName",
  "$installerHash  $installerName"
) | Set-Content -LiteralPath $manifest -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $candidateSourceCommit
  releaseToolCommit = $gitHead
  releaseOnlyDeltaVerified = $true
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
  installerEngine = $installerEngine
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
if ($LASTEXITCODE -ne 0) {
  throw "Independent release-evidence verification failed."
}
Write-Host "CHAPTER1_RELEASE_EVIDENCE_INDEPENDENT_VERIFY=PASS"

# Keep failure-state material for diagnosis; clean only after the complete tail passes.
Stop-ProcessesFromRoot $installRoot
foreach ($cleanupPath in @($installRoot, $persistenceRoot)) {
  if ($cleanupPath -and (Test-Path -LiteralPath $cleanupPath)) {
    Remove-PathWithRetry $cleanupPath
  }
}
foreach ($debris in @($nsi, $sed, $installScript)) {
  if ($debris -and (Test-Path -LiteralPath $debris)) {
    Remove-Item -LiteralPath $debris -Force
  }
}
if (Test-Path -LiteralPath $Checkpoint) {
  Remove-Item -LiteralPath $Checkpoint -Force
}

Write-Host "CHAPTER1_INSTALLER_TAIL_RESUME=PASS"
Write-Host "SOURCE_COMMIT=$candidateSourceCommit"
Write-Host "RELEASE_TOOL_COMMIT=$gitHead"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "INSTALLER=$installer"
Write-Host "PORTABLE_ZIP_SHA256=$zipHash"
Write-Host "PACKAGE_TREE_SHA256=$candidateTreeSha256"
Write-Host "INSTALLER_SHA256=$installerHash"
Write-Host "EVIDENCE=$evidencePath"
