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
       script.includes('$_.ExecutablePath -and [IO.Path]::GetFullPath([string]$_.ExecutablePath).Equals($exeFull,[StringComparison]::OrdinalIgnoreCase)'),
  'uninstaller must scope process cleanup to the exact normalized installed native preview executable');
assert(script.includes('cd /d "%TEMP%"'),
  'uninstaller must leave its install directory before delayed deletion');
assert(script.includes('copy /Y "%~f0" "%CLEANUP%"') &&
       script.includes('"%CLEANUP%" --cleanup'),
  'uninstaller must hand cleanup to a temporary self-copy before deleting its install directory');
assert(script.includes("$marker=Join-Path $dest 'Aetherwake-Native-Preview.install'") &&
       script.includes("AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1") &&
       script.includes("if(-not (Test-Path -LiteralPath $marker)){exit 3}") &&
       script.includes("$owned=@($exe,$uninstall,$marker)") &&
       script.includes('for($i=0; $i -lt 12; $i++)') &&
       script.includes('$remainingOwned=@($owned | Where-Object {Test-Path -LiteralPath $_})') &&
       script.includes('$destRemaining=@(Get-ChildItem -LiteralPath $dest -Force)') &&
       script.includes('if($destRemaining.Count -eq 0){Remove-Item -LiteralPath $dest -Force}') &&
       !script.includes('Remove-Item -LiteralPath $dest -Recurse -Force'),
  'temporary cleanup must prove install ownership, retry only owned-file removal, preserve foreign files and remove the install directory only when empty');
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
assert(script.includes("Ender's bounded dock exploration position is persisted with Chapter I progress") &&
       script.includes('older compatible v1 saves that predate position persistence resume at a deterministic safe deck spawn') &&
       script.includes('previous valid generation is retained for backup recovery') &&
       script.includes('Formula Review, and active Wind Shear combat are transient and are not persisted') &&
       script.includes('without awarding hazard progress'),
  'native package instructions must explain position persistence, legacy safe-spawn fallback, backup recovery and fail-closed transient combat saves');

assert(script.includes('SHORTCUT_SLOT_OCCUPIED:') &&
       script.includes('set "MARKER=%DEST%\\Aetherwake-Native-Preview.install"') &&
       script.includes("if(Test-Path -LiteralPath $dest){$marker=Join-Path $dest 'Aetherwake-Native-Preview.install'") &&
       script.includes("if(-not (Test-Path -LiteralPath $marker)){exit 3}") &&
       script.includes("$owner=(Get-Content -LiteralPath $marker -Raw).Trim()") &&
       script.includes("if($owner -ne 'AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1'){exit 3}") &&
       script.includes("foreach($shortcutPath in @((Join-Path $desktop 'Aetherwake Native Preview.lnk'),(Join-Path $menu 'Aetherwake Native Preview.lnk')))") &&
       script.includes("if(-not ($target.Equals($exe,[StringComparison]::OrdinalIgnoreCase) -and $work.Equals([IO.Path]::GetFullPath($dest),[StringComparison]::OrdinalIgnoreCase))){throw ('SHORTCUT_SLOT_OCCUPIED:'+ $shortcutPath)}") &&
       script.indexOf('SHORTCUT_SLOT_OCCUPIED:') < script.indexOf('if not exist "%DEST%" mkdir "%DEST%"') &&
       script.includes('if not exist "%~dp0Aetherwake\\Aetherwake-First-Wake-Godot-Preview.exe" exit /b 5') &&
       script.includes('if not exist "%~dp0Aetherwake\\Uninstall-Aetherwake-Godot-Preview.cmd" exit /b 5') &&
       script.indexOf('if not exist "%~dp0Aetherwake\\Aetherwake-First-Wake-Godot-Preview.exe" exit /b 5') < script.indexOf('if not exist "%DEST%" mkdir "%DEST%"') &&
       script.indexOf('> "%MARKER%" echo AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1') < script.indexOf('copy /Y "%~dp0Aetherwake\\Aetherwake-First-Wake-Godot-Preview.exe"') &&
       !script.includes('EnableDelayedExpansion') &&
       script.includes('function Remove-OwnedShortcut') &&
       script.includes('$target.Equals($exeFull,[StringComparison]::OrdinalIgnoreCase)') &&
       script.includes('$work.Equals([IO.Path]::GetFullPath($dest),[StringComparison]::OrdinalIgnoreCase)') &&
       script.includes('$menuRemaining=@(Get-ChildItem -LiteralPath $menu -Force)') &&
       script.includes('both packaged payload files are checked before any install mutation') &&
       script.includes('interrupted/failed copy remains safely retryable as Aetherwake-owned state') &&
       script.includes('install directory carries a versioned Aetherwake ownership marker') &&
       script.includes('install directory is removed only when empty'),
  'native package must preflight ownership and packaged payload presence before mutation, mark directory ownership before copy, avoid delayed-expansion path risk and remove only content still owned by this exact preview install');
assert(script.includes('EXE_SHA256=$ExeHash') &&
       script.includes('INSTALL_WRAPPER_SHA256=$InstallHash') &&
       script.includes('UNINSTALL_WRAPPER_SHA256=$UninstallHash') &&
       script.includes('PAYLOAD_UNINSTALLER_SHA256=$PayloadUninstallHash') &&
       script.includes('README_SHA256=$ReadmeHash'),
  'package manifest must custody-bind every executable/wrapper/readme payload');
assert(script.includes('ADMIN_REQUIRED=NO') &&
       script.includes('PUBLIC_RELEASE_AUTHORIZED=NO'),
  'package manifest must preserve private/non-release boundaries');

console.log('Aetherwake Godot Windows preview package contract: PASS');
