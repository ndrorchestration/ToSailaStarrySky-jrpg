'use strict';

const fs = require('fs');
const path = require('path');

function fail(message) {
  console.error('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=FAIL');
  console.error(message);
  process.exit(1);
}

const buildScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'build-chapter1-windows.ps1'),
  'utf8'
);

if (buildScript.includes('(git branch --show-current).Trim()')) {
  fail('Chapter 1 Windows builder must not call Trim directly on a possibly empty detached-HEAD branch result');
}
for (const required of [
  'python -m pip install --disable-pip-version-check --no-cache-dir Pillow==12.3.0',
  'Pinned Python visual-test dependency installation failed',
  '$gitBranchOutput = @(git branch --show-current)',
  'if ($gitBranchOutput.Count -gt 0 -and $null -ne $gitBranchOutput[0])',
  'if (-not $gitBranch) { $gitBranch = "DETACHED" }',
]) {
  if (!buildScript.includes(required)) fail('missing detached-HEAD builder contract: ' + required);
}


const pillowInstall = buildScript.indexOf('Pillow==12.3.0');
const visualGate = buildScript.indexOf('npm run test:chapter1-visual');
if (!(pillowInstall >= 0 && visualGate > pillowInstall)) {
  fail('Chapter 1 Windows builder must install the pinned visual dependency before the visual gate');
}

const scriptPath = path.join(__dirname, '..', 'scripts', 'resume-chapter1-installer-tail.ps1');
const script = fs.readFileSync(scriptPath, 'utf8');

for (const required of [
  'AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE',
  '$installerEngine -eq "NSIS"',
  '@("/S")',
  '@("/Q:U")',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue',
  'AETHERWAKE_CHAPTER1_INSTALL_SMOKE',
  'Exec \'"$INSTDIR\\Aetherwake.exe"\'',
  'Start-Process -FilePath $exe | Out-Null',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue',
  'AdminQuietInstCmd=$appLaunched',
  'UserQuietInstCmd=$appLaunched',
  'Aetherwake-Chapter1-$shortHead-Setup.sed',
  'install-chapter1-$shortHead.ps1',
  'CHAPTER1_INSTALLER_TAIL_RESUME=PASS',
  'Remove-Item -LiteralPath $Checkpoint',
  '$iexpressUsesStaging = $OutputDir -match',
  'AetherwakeChapter1IExpress-',
  'Copy-Item -LiteralPath $zip -Destination (Join-Path $iexpressWorkDir $zipName) -Force',
  '$env:TMP = $iexpressWorkDir',
  'Copy-Item -LiteralPath $iexpressInstaller -Destination $installer -Force',
  'Remove-PathWithRetry $iexpressWorkDir',
  'Remove-Item Env:TMP -ErrorAction SilentlyContinue',
  'Start-Process -FilePath $iexpress',
  '-Wait -PassThru',
  'function Get-Sha256Hex([string]$Path)',
  'Get-Command Get-FileHash -ErrorAction SilentlyContinue',
  '[System.Security.Cryptography.SHA256]::Create()',
  '[System.BitConverter]::ToString($hashBytes)',
  '$zipHash = Get-Sha256Hex $zip',
  '$installerHash = Get-Sha256Hex $installer',
  'function Stop-ProcessAndWait',
  '[void]$Process.WaitForExit($TimeoutMs)',
  'function Remove-PathWithRetry',
  'Remove-PathWithRetry $cleanupPath',
  'function Stop-ProcessesFromRoot',
  'Get-CimInstance Win32_Process',
  'ExecutablePath.StartsWith($Root',
  'Stop-ProcessesFromRoot $installRoot',
]) {
  if (!script.includes(required)) fail('missing installer-tail contract: ' + required);
}

if (script.includes('$zipHash = (Get-FileHash') ||
    script.includes('$installerHash = (Get-FileHash')) {
  fail('installer tail must not rely directly on Get-FileHash for release artifact hashes');
}
if (!script.includes('$zipHash = Get-Sha256Hex $zip') ||
    !script.includes('$installerHash = Get-Sha256Hex $installer')) {
  fail('installer tail must route both ZIP and installer hashing through the resilient SHA-256 helper');
}
const nativeHashBranch = script.indexOf('Get-Command Get-FileHash -ErrorAction SilentlyContinue');
const dotNetHashBranch = script.indexOf('[System.Security.Cryptography.SHA256]::Create()');
if (!(nativeHashBranch >= 0 && dotNetHashBranch > nativeHashBranch)) {
  fail('installer tail must retain a .NET SHA-256 fallback after the native Get-FileHash branch');
}

if (script.includes('"/D=$installerSmokeRoot"') || script.includes('"/D=$installRoot"')) {
  fail('installer smoke must not depend on NSIS /D= path parsing');
}
if (!script.includes('Function .onInit') ||
    !script.includes('ReadEnvStr $1 "AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE"') ||
    !script.includes('StrCpy $INSTDIR $1')) {
  fail('NSIS must honor the same isolated install-root override as IExpress');
}

const embeddedInstallRoot = '$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE)';
if (!script.includes(embeddedInstallRoot)) {
  fail('IExpress embedded installer must honor the isolated smoke-root override');
}

const nsisLaunchGuard =
  script.includes('ReadEnvStr $0 "AETHERWAKE_CHAPTER1_INSTALL_SMOKE"') &&
  script.includes('StrCmp $0 "1" skip_player_shell');
if (!nsisLaunchGuard) {
  fail('NSIS player shell changes must be suppressed during automated installer smoke');
}
if (!script.includes('if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1")')) {
  fail('IExpress player shell changes must be suppressed during automated installer smoke');
}

const nsisSectionStart = script.indexOf('Section "Aetherwake Chapter 1" SEC_MAIN');
const nsisGuard = script.indexOf('StrCmp $0 "1" skip_player_shell', nsisSectionStart);
const nsisDesktopShortcut = script.indexOf('CreateShortCut "$DESKTOP\\Aetherwake Chapter 1.lnk"', nsisSectionStart);
const nsisLaunch = script.indexOf('Exec \'"$INSTDIR\\Aetherwake.exe"\'', nsisSectionStart);
const nsisSkip = script.indexOf('skip_player_shell:', nsisSectionStart);
if (!(nsisSectionStart >= 0 && nsisGuard < nsisDesktopShortcut &&
      nsisDesktopShortcut < nsisSkip && nsisLaunch < nsisSkip)) {
  fail('NSIS smoke guard must bypass player shortcuts and auto-launch');
}

const ieGuard = script.indexOf('if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1")');
const ieDesktopShortcut = script.indexOf('$desktopShortcut = $shell.CreateShortcut', ieGuard);
const ieStartMenu = script.indexOf('$menuShortcut = $shell.CreateShortcut', ieGuard);
const ieLaunch = script.indexOf('Start-Process -FilePath $exe | Out-Null', ieGuard);
const ieGuardEnd = script.indexOf('\n}', ieLaunch);
if (!(ieGuard >= 0 && ieDesktopShortcut > ieGuard && ieStartMenu > ieDesktopShortcut &&
      ieLaunch > ieStartMenu && ieGuardEnd > ieLaunch)) {
  fail('IExpress smoke guard must contain Desktop/Start-menu shortcuts and auto-launch');
}

if (!script.includes('AdminQuietInstCmd=$appLaunched') ||
    !script.includes('UserQuietInstCmd=$appLaunched')) {
  fail('IExpress quiet smoke must execute the same embedded installer command');
}

if ((script.match(/CHAPTER1_INSTALLER_TAIL_RESUME=PASS/g) || []).length !== 1) {
  fail('installer-tail authority must contain exactly one terminal PASS path');
}

console.log('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=PASS');
