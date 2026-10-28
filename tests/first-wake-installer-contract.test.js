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
const prepare = read('scripts/prepare-first-wake-windows-installer.ps1');
const publish = read('scripts/publish-first-wake-approved-windows-installer.ps1');

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
for (const marker of [
  "ExpectedSourceSha",
  "TSTSS_INSTALLER_SOURCE_SHA_MISMATCH",
  "TSTSS_INSTALLER_DEFENDER_REALTIME_REQUIRED",
  "build-first-wake-godot-installer.ps1",
  "verify-first-wake-installer-defender.ps1",
  "TSTSS_INSTALLER_PREP_INVALID_RECEIPT",
  "TSTSS_INSTALLER_LOCAL_PREP=PASS",
  "PUBLIC_RELEASE_AUTHORIZED=NO",
]) {
  assert(prepare.includes(marker), 'single-command trusted Windows preparation cannot skip provenance, binary scan, or nonpublication: ' + marker);
}
assert(!/Set-MpPreference|Remove-MpPreference|gh release create|upload-artifact/.test(prepare),
  'trusted Windows prep must not weaken Defender or publish');
for (const marker of [
  "TSTSS_RELEASE_CREATOR_EXPLICIT_APPROVAL_REQUIRED",
  "TSTSS_RELEASE_SOURCE_SHA_MISMATCH",
  "TSTSS_RELEASE_EXACT_BINARY_DEFENDER_CUSTODY_NOT_VERIFIED",
  "TSTSS_RELEASE_PLAYER_ACCEPTANCE_INCOMPLETE",
  "TSTSS_RELEASE_UNSIGNED_PREVIEW_NEEDS_EXPLICIT_APPROVAL",
  "TSTSS_RELEASE_MANIFEST_DIGEST_MISMATCH",
  "TSTSS_RELEASE_DRAFT_ASSET_SHA256_MISMATCH",
  "TSTSS_FIRST_WAKE_DIRECT_DOWNLOAD_READY=PASS",
  "gh release create",
  "--draft --prerelease",
  "gh release download",
  "gh release edit",
  "DIRECT_WINDOWS_INSTALLER_URL.txt",
]) {
  assert(publish.includes(marker), 'publishing must be explicitly approved, binary-bound, scan-verified and remotely hash-matched: ' + marker);
}
assert(publish.indexOf('gh release create') < publish.indexOf('gh release download') &&
  publish.indexOf('gh release download') < publish.indexOf('gh release edit'),
  'draft upload and verified remote download must precede public promotion');
assert(!/Set-MpPreference|Remove-MpPreference|continue-on-error/.test(publish),
  'release path may not weaken host Defender or hide release failures');
console.log('TSTSS_FIRST_WAKE_INSTALLER_CONTRACT_PASS release_authorized=false installer_link_published=false');
