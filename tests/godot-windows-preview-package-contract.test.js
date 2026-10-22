const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const script = fs.readFileSync(
  path.resolve(__dirname, '..', 'scripts', 'package-godot-chapter1-windows-preview.ps1'),
  'utf8'
);

assert(script.includes('Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip'),
  'native preview ZIP name is missing');
assert(script.includes('Programs\\Aetherwake-Godot-Native-Preview'),
  'native preview must install into a separate per-user path');
assert(script.includes("GetFolderPath('Desktop')"),
  'installer/uninstaller must resolve the real Windows Desktop known folder');
assert(script.includes('Get-CimInstance Win32_Process') &&
       script.includes('ExecutablePath -eq $exe'),
  'uninstaller must scope process cleanup to the installed native preview executable');
assert(script.includes('cd /d "%TEMP%"'),
  'uninstaller must leave its install directory before delayed deletion');
assert(!/makensis|\.nsi(?:\s|["'])|NSIS\\|nsis\.exe/i.test(script),
  'native preview package must not invoke NSIS tooling');
assert(!/runas|Start-Process[^\n]*-Verb\s+RunAs/i.test(script),
  'native preview package must not request elevation');
assert(script.includes('ADMIN_REQUIRED=NO') &&
       script.includes('PUBLIC_RELEASE_AUTHORIZED=NO'),
  'package manifest must preserve private/non-release boundaries');

console.log('Aetherwake Godot Windows preview package contract: PASS');
