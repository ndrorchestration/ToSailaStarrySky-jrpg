const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const scriptPath = path.resolve(
  __dirname,
  '..',
  'scripts',
  'verify-godot-chapter1-windows-preview.ps1'
);
const script = fs.readFileSync(scriptPath, 'utf8');

assert(script.includes('[string]$ExpectedSourceSha') &&
       script.includes('SOURCE_SHA_MISMATCH') &&
       script.includes('git rev-parse HEAD') &&
       script.includes('git status --porcelain --untracked-files=no') &&
       script.includes('TRACKED_WORKTREE_NOT_CLEAN') &&
       script.includes('git ls-files --others --exclude-standard -- godot') &&
       script.includes('UNTRACKED_GODOT_AUTHORITY_FILES'),
  'exact Windows QA must bind clean tracked source and an uncontaminated Godot project to an expected SHA');

assert(script.includes('build-godot-chapter1-windows-preview.ps1') &&
       script.includes('package-godot-chapter1-windows-preview.ps1'),
  'exact Windows QA must run the existing build and package gates');

assert(script.includes('Start-MpScan -ScanType CustomScan -ScanPath') &&
       script.includes('Get-MpThreatDetection') &&
       script.includes('DEFENDER_DETECTION_FOR_'),
  'exact Windows QA must run fail-closed Defender custom scans');

assert(script.includes('INSTALL_WRAPPER') &&
       script.includes('UNINSTALL_WRAPPER') &&
       script.includes('PACKAGED_EXE') &&
       script.includes('ZIP'),
  'Defender gate must cover wrappers, packaged EXE and ZIP');

assert(script.includes('PREEXISTING_NATIVE_PREVIEW_INSTALL') &&
       script.includes('Get-CimInstance Win32_Process') &&
       script.includes('ExecutablePath') &&
       script.includes('INSTALLED_EXE_HASH_MISMATCH') &&
       script.includes('INSTALLED_UNINSTALLER_HASH_MISMATCH') &&
       script.includes('INSTALLED_NATIVE_PREVIEW_WINDOW_NOT_READY'),
  'install gate must start clean, preserve packaged bytes and verify the exact installed native process/window');

assert(script.includes('Aetherwake Native Preview.lnk') &&
       script.includes('running-app native preview uninstaller') &&
       script.includes('UNINSTALL_LEFT_INSTALL_DIRECTORY') &&
       script.includes('UNINSTALL_LEFT_TEMP_CLEANUP_COPY'),
  'exact Windows QA must verify shortcuts and running-app uninstall cleanup');

assert(script.includes('WINDOWS_NATIVE_QA_RECEIPT.json') &&
       script.includes('installWrapperSha256') &&
       script.includes('uninstallWrapperSha256') &&
       script.includes('packageReadmeSha256') &&
       script.includes('packageManifestSha256') &&
       script.includes('TRACKED_SOURCE_CHANGED_DURING_QA') &&
       script.includes('publicReleaseAuthorized = $false') &&
       script.includes('AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS'),
  'exact Windows QA must emit complete artifact custody, preserve tracked source and avoid authorizing public release');

assert(!/Start-Process[^\n]*-Verb\s+RunAs/i.test(script),
  'exact Windows QA must not request elevation');
assert(!/Set-MpPreference|Add-MpPreference|Remove-MpPreference|DisableRealtimeMonitoring|ExclusionPath|ExecutionPolicy\s+Bypass/i.test(script),
  'exact Windows QA must not alter Defender protection/exclusions or bypass execution policy');

console.log('Aetherwake Godot exact Windows QA contract: PASS');
