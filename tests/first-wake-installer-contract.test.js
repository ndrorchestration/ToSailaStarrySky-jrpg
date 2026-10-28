const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const read = (p) => fs.readFileSync(path.join(root, p), 'utf8');
const nsi = read('packaging/windows/ToSailTheStarrySky.nsi');
const build = read('scripts/build-first-wake-godot-installer.ps1');
const qa = read('.github/workflows/godot-exact-windows-qa.yml');
const project = read('godot/project.godot');
const entry = read('godot/scripts/first_wake_game.gd');
const docs = read('docs/desktop/FIRST_WAKE_INSTALLER_DELIVERY.md');

for (const x of [
  'RequestExecutionLevel user',
  'ToSailTheStarrySky.exe',
  'TSTSS-FirstWake.install',
  'To Sail the Starry Sky (First Wake).lnk',
  'Uninstall-ToSailTheStarrySky.exe',
  'CreateShortcut',
  'RMDir "$INSTDIR"',
]) {
  assert(nsi.includes(x), 'NSIS ownership or player shortcut missing: ' + x);
}
assert(!nsi.includes('RMDir /r "$INSTDIR"'), 'uninstall may not recursively destroy foreign files');
assert(!/RequestExecutionLevel\s+admin/i.test(nsi), 'the game must never require admin');
assert(build.includes('first_wake_game_entry_test.gd') && build.includes('binary_format/embed_pck=true'),
  'packaging requires actual revised First Wake scene, physical gate and embedded game resources');
for (const marker of [
  'TSTSS_INSTALLER_PUBLIC_RELEASE_AUTHORIZED=NO',
  'TSTSS_INSTALLER_DEFENDER_CUSTODY=NOT_ESTABLISHED',
  'TSTSS_INSTALLER_AUTHENTICODE_SIGNING=NOT_ESTABLISHED',
]) {
  assert(build.includes(marker), 'nonpublication/security claim missing: ' + marker);
}
assert(qa.includes('Compile and exercise actual First Wake Windows Setup.exe') &&
  qa.includes('TSTSS_INSTALLER_LOCAL_FUNCTIONAL_PROOF=PASS') &&
  qa.includes('TSTSS_INSTALLER_DEFENDER_QA=NOT_ESTABLISHED'),
  'functional Windows install/window/uninstall chain must be present and not misreport defender');
assert(qa.includes('Preflight unchanged Defender custody requirements') &&
  qa.includes('WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED'),
  'existing Defender custody preflight may not be removed or bypassed');
assert(project.includes('run/main_scene="res://scenes/first_wake_game.tscn"') &&
  project.includes('window/size/resizable=true') &&
  project.includes('window/size/borderless=false'),
  'game candidate must boot from the real game and allow normal Windows maximize');
assert(entry.includes('KEY_F11') && entry.includes('event.alt_pressed') &&
  entry.includes('Window.MODE_FULLSCREEN'),
  'normal game window must offer an accessible fullscreen toggle');
assert(docs.includes('NOT YET PUBLISHED') && docs.includes('README'),
  'delivery docs must distinguish build proof from an actual download');
console.log('TSTSS_FIRST_WAKE_INSTALLER_CONTRACT_PASS release_authorized=false installer_link_published=false');
