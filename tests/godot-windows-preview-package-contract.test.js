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
assert(script.includes('Aetherwake\\Uninstall-Aetherwake-Godot-Preview.cmd') &&
       script.includes('%DEST%\\Uninstall-Aetherwake-Godot-Preview.cmd'),
  'installer must copy the packaged uninstaller into the installed native preview');
assert(script.includes("GetFolderPath('Desktop')"),
  'installer/uninstaller must resolve the real Windows Desktop known folder');
assert(script.includes('Get-CimInstance Win32_Process') &&
       script.includes('ExecutablePath -eq $exe'),
  'uninstaller must scope process cleanup to the installed native preview executable');
assert(script.includes('cd /d "%TEMP%"'),
  'uninstaller must leave its install directory before delayed deletion');
assert(script.includes('copy /Y "%~f0" "%CLEANUP%"') &&
       script.includes('"%CLEANUP%" --cleanup'),
  'uninstaller must hand cleanup to a temporary self-copy before deleting its install directory');
assert(script.includes('for($i=0; $i -lt 12 -and (Test-Path -LiteralPath $dest); $i++)') &&
       script.includes('Remove-Item -LiteralPath $dest -Recurse -Force') &&
       script.includes('if(Test-Path -LiteralPath $dest){exit 2}'),
  'temporary cleanup must retry install-directory removal and fail closed if it remains');
assert(!/makensis|\.nsi(?:\s|["'])|NSIS\\|nsis\.exe/i.test(script),
  'native preview package must not invoke NSIS tooling');
assert(!/runas|Start-Process[^\n]*-Verb\s+RunAs/i.test(script),
  'native preview package must not request elevation');
assert(script.includes('F5 - save durable Chapter I progress') &&
       script.includes('F9 - load the local Chapter I save'),
  'native package instructions must expose durable save/load controls');
assert(script.includes('Crossing: interact with Wind Shear to open its current-story combat encounter') &&
       script.includes('Clear Wind Shear, then C to confirm that Crossing hazard') &&
       script.includes('Loose Cargo Sweep and Dock Authority Hold remain noncombat Chapter I hazards'),
  'native package instructions must distinguish authored Wind Shear combat from noncombat hazards');
assert(script.includes('Wind Shear retaliates after successful turns with its current live Gale Force: 2 damage') &&
       script.includes('If Ender is downed, C closes the transient encounter and Crossing progress is unchanged'),
  'native package instructions must explain authored retaliation and fail-closed defeat');
assert(script.includes("Current Crossing party surface shows Ender + Lyra; only Ender's formula actions are authorized") &&
       script.includes("Lyra's combat actions remain intentionally unavailable until explicit action authority exists"),
  'native package instructions must preserve fail-closed companion combat authority');
assert(script.includes('previous valid generation is retained for backup recovery') &&
       script.includes('Formula Review, and active Wind Shear combat are transient and are not persisted') &&
       script.includes('without awarding hazard progress'),
  'native package instructions must explain backup recovery and fail-closed transient combat saves');
assert(script.includes('ADMIN_REQUIRED=NO') &&
       script.includes('PUBLIC_RELEASE_AUTHORIZED=NO'),
  'package manifest must preserve private/non-release boundaries');

console.log('Aetherwake Godot Windows preview package contract: PASS');
