'use strict';

const fs = require('fs');
const path = require('path');

function fail(message) {
  console.error('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=FAIL');
  console.error(message);
  process.exit(1);
}

const scriptPath = path.join(__dirname, '..', 'scripts', 'build-chapter1-windows.ps1');
const script = fs.readFileSync(scriptPath, 'utf8');

for (const required of [
  'AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE',
  '$installerEngine -eq "NSIS"',
  '$installerEngine -eq "IEXPRESS"',
  '$installerArgs = @("/S", "/D=$installerSmokeRoot")',
  '$installerArgs = @("/Q:U")',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue',
  'AETHERWAKE_CHAPTER1_INSTALL_SMOKE',
  'Exec \'"$INSTDIR\\Aetherwake.exe"\'',
  'Start-Process -FilePath $exe | Out-Null',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue',
  'AdminQuietInstCmd=$appLaunched',
  'UserQuietInstCmd=$appLaunched',
  'CHAPTER1_SUCCESS_CLEANUP=PASS',
  'Aetherwake-Chapter1-$shortHead-Setup.sed',
  'install-chapter1-$shortHead.ps1',
]) {
  if (!script.includes(required)) fail('missing installer fallback contract: ' + required);
}

if (script.includes('Start-Process -FilePath $installer -ArgumentList @("/S", "/D=$installerSmokeRoot")')) {
  fail('installer smoke must not apply NSIS-only /D= semantics unconditionally');
}

const embeddedInstallRoot = '$installRoot = if ($env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE)';
if (!script.includes(embeddedInstallRoot)) {
  fail('IExpress embedded installer must honor the isolated smoke-root override');
}


const nsisLaunchGuard =
  script.includes('ReadEnvStr $0 "AETHERWAKE_CHAPTER1_INSTALL_SMOKE"') &&
  script.includes('StrCmp $0 "1" skip_player_shell');
if (!nsisLaunchGuard) {
  fail('NSIS player auto-launch must be suppressed during automated installer smoke');
}
if (!script.includes('if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1")')) {
  fail('IExpress player shell changes must be suppressed during automated installer smoke');
}

const nsisSectionStart = script.indexOf('Section "Aetherwake Chapter 1" SEC_MAIN');
const nsisGuard = script.indexOf('StrCmp $0 "1" skip_player_shell', nsisSectionStart);
const nsisDesktopShortcut = script.indexOf('CreateShortCut "$DESKTOP\\Aetherwake Chapter 1.lnk"', nsisSectionStart);
const nsisLaunch = script.indexOf('Exec \'"$INSTDIR\\Aetherwake.exe"\'', nsisSectionStart);
const nsisSkip = script.indexOf('skip_player_shell:', nsisSectionStart);
if (!(nsisSectionStart >= 0 && nsisGuard < nsisDesktopShortcut && nsisDesktopShortcut < nsisSkip &&
      nsisLaunch < nsisSkip)) {
  fail('NSIS smoke guard must bypass player shortcuts and auto-launch');
}

const ieGuard = script.indexOf('if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1")');
const ieDesktopShortcut = script.indexOf('$desktopShortcut = $shell.CreateShortcut', ieGuard);
const ieLaunch = script.indexOf('Start-Process -FilePath $exe | Out-Null', ieGuard);
const ieGuardEnd = script.indexOf("\n}", ieLaunch);
if (!(ieGuard >= 0 && ieDesktopShortcut > ieGuard && ieLaunch > ieDesktopShortcut && ieGuardEnd > ieLaunch)) {
  fail('IExpress smoke guard must contain player shortcuts and auto-launch');
}
if (!script.includes('AdminQuietInstCmd=$appLaunched') ||
    !script.includes('UserQuietInstCmd=$appLaunched')) {
  fail('IExpress quiet smoke must execute the same embedded installer command');
}

console.log('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=PASS');
