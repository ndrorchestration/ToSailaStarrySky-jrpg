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
  '$installerArgs = @("/Q")',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE -ErrorAction SilentlyContinue',
  'AETHERWAKE_CHAPTER1_INSTALL_SMOKE',
  'Exec \'"$INSTDIR\\Aetherwake.exe"\'',
  'Start-Process -FilePath $exe | Out-Null',
  'Remove-Item Env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ErrorAction SilentlyContinue',
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
  script.includes('StrCmp $0 "1" skip_player_launch');
if (!nsisLaunchGuard) {
  fail('NSIS player auto-launch must be suppressed during automated installer smoke');
}
if (!script.includes('if ($env:AETHERWAKE_CHAPTER1_INSTALL_SMOKE -ne "1")')) {
  fail('IExpress player auto-launch must be suppressed during automated installer smoke');
}

console.log('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=PASS');
