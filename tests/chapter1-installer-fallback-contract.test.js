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

console.log('CHAPTER1_INSTALLER_FALLBACK_CONTRACT=PASS');
