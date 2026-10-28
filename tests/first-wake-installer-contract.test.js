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
const custody = read('scripts/verify-first-wake-installer-defender.ps1');

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
assert(nsi.includes('MUI_PAGE_WELCOME') && nsi.includes('MUI_PAGE_FINISH') &&
  nsi.includes('MUI_FINISHPAGE_RUN'),
  'installer must present a normal welcome/finish flow and optional first launch');
assert(nsi.includes('Function CheckInstallDestination') &&
  nsi.includes('Call CheckInstallDestination') &&
  nsi.includes('IfFileExists "$INSTDIR\\*"') &&
  nsi.includes('IfFileExists "$DESKTOP\\To Sail the Starry Sky (First Wake).lnk"'),
  'do not overwrite a populated installation path or pre-existing player shortcut');
assert(nsi.includes('WriteRegStr HKCU') &&
  nsi.includes('DeleteRegKey HKCU') &&
  nsi.includes('QuietUninstallString'),
  'Windows Apps & Features should offer a per-user uninstall that also cleans registry metadata');
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
  qa.includes('TSTSS_INSTALLER_DEFENDER_QA=NOT_ESTABLISHED') &&
  qa.includes('TSTSS_INSTALLER_NATIVE_WINDOW_MAXIMIZE_RESTORE=PASS') &&
  qa.includes('TSTSS_INSTALLER_APPS_AND_FEATURES_REGISTRY=PASS') &&
  qa.includes('TSTSS_INSTALLER_EXISTING_INSTALL_PROTECTED=PASS') &&
  qa.includes('TSTSS_INSTALLER_UNINSTALL_SHORTCUTS_AND_REGISTRY=PASS'),
  'functional Windows install/window/maximize/shortcut/uninstall checks and separate Defender boundary required');
assert(qa.includes('Preflight unchanged Defender custody requirements') &&
  qa.includes('WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED'),
  'existing Defender custody preflight may not be removed or bypassed');

assert(project.includes('run/main_scene="res://scenes/first_wake_game.tscn"') &&
  project.includes('window/size/resizable=true') &&
  project.includes('window/size/borderless=false'),
  'game candidate must boot from the real game and allow normal Windows maximize');
assert(entry.includes('KEY_F11') && entry.includes('event.alt_pressed') &&
  entry.includes('Window.MODE_FULLSCREEN') && entry.includes('pre_fullscreen_mode'),
  'normal game window must offer an accessible fullscreen toggle');
assert(docs.includes('NOT YET PUBLISHED') && docs.includes('README'),
  'delivery docs must distinguish build proof from an actual download');
assert(qa.includes('trusted-installer-defender-qa:') &&
  qa.includes('runs-on: [self-hosted, Windows, X64, defender-on]') &&
  qa.includes("contains(github.event.pull_request.labels.*.name, 'trusted-defender-on')") &&
  qa.includes('github.event.pull_request.user.login') &&
  qa.includes('verify-first-wake-installer-defender.ps1'),
  'trusted scan must require deliberate maintainer opt-in, private runner, exact installer scan');
for (const marker of [
  'TSTSS_DEFENDER_REALTIME_NOT_ENABLED',
  'TSTSS_DEFENDER_WHOLE_DRIVE_EXCLUDED',
  'Start-MpScan -ScanType CustomScan',
  'TSTSS_DEFENDER_SCAN_COMPLETION_NOT_ATTESTED',
  'TSTSS_DEFENDER_DETECTION',
  'TSTSS_DEFENDER_CUSTODY=PASS',
  'TSTSS_DEFENDER_EXE_EXTENSION_EXCLUDED',
  'TSTSS_DEFENDER_TARGET_PROCESS_EXCLUDED',
  'TSTSS_DEFENDER_TARGET_PATH_EXCLUDED',
  'TSTSS_DEFENDER_AMBIGUOUS_PATH_EXCLUSION',
  'Assert-NoTargetExclusions @($GameExe, $SetupExe)',
  'publicReleaseAuthorized = $false',
]) {
  assert(custody.includes(marker), 'trusted scan fail-closed/security marker missing: ' + marker);
}
console.log('TSTSS_FIRST_WAKE_INSTALLER_CONTRACT_PASS release_authorized=false installer_link_published=false');
