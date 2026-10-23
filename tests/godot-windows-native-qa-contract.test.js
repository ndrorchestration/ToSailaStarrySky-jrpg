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
const buildScript = fs.readFileSync(
  path.resolve(__dirname, '..', 'scripts', 'build-godot-chapter1-windows-preview.ps1'),
  'utf8'
);
const captureScript = fs.readFileSync(
  path.resolve(__dirname, '..', 'godot', 'tests', 'capture_first_wake_chapter1_review.gd'),
  'utf8'
);
const gitignore = fs.readFileSync(
  path.resolve(__dirname, '..', '.gitignore'),
  'utf8'
);

assert(script.includes('[string]$ExpectedSourceSha') &&
       script.includes('EXPECTED_SOURCE_SHA_INVALID') &&
       script.includes('SOURCE_SHA_MISMATCH') &&
       script.includes('git rev-parse HEAD') &&
       script.includes('git status --porcelain --untracked-files=no') &&
       script.includes('TRACKED_WORKTREE_NOT_CLEAN') &&
       script.includes('git ls-files --others --exclude-standard -- godot') &&
       script.includes('UNTRACKED_GODOT_AUTHORITY_FILES'),
  'exact Windows QA must validate and bind clean tracked source plus an uncontaminated Godot project to an expected SHA');

assert((script.match(/EXPECTED_SOURCE_SHA_INVALID/g) || []).length === 1 &&
       (script.match(/git rev-parse HEAD/g) || []).length === 1 &&
       (script.match(/AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS/g) || []).length === 1,
  'exact Windows QA control flow must contain one source validator, one HEAD binding and one terminal PASS marker');

assert(/(^|\n)\.godot\/\s*(\n|$)/.test(gitignore),
  'Godot generated .godot cache must stay ignored so exact QA remains rerunnable without weakening authority-file checks');

assert(script.includes('build-godot-chapter1-windows-preview.ps1') &&
       script.includes('package-godot-chapter1-windows-preview.ps1'),
  'exact Windows QA must run the existing build and package gates');

assert(script.includes('4.7.2.stable.official.ed1daf0bf') &&
       script.includes('GODOT_VERSION_MISMATCH') &&
       script.includes('Assert-AuthenticodePublisher') &&
       script.includes('Prehensile Tales B.V.') &&
       script.includes('AUTHENTICODE_INVALID_') &&
       script.includes('AUTHENTICODE_PUBLISHER_MISMATCH_') &&
       script.includes('godotAuthenticode') &&
       script.includes('windowsReleaseTemplateAuthenticode') &&
       script.includes('godotExeSha256') &&
       script.includes('windowsReleaseTemplateSha256') &&
       script.includes('templateVersionText'),
  'exact Windows QA must authenticate and custody-bind the official Godot 4.7.2 Windows toolchain');

assert(script.includes('--rendering-method') &&
       script.includes('gl_compatibility') &&
       script.includes('capture_first_wake_chapter1_review.gd') &&
       script.includes('AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS') &&
       script.includes('AETHERWAKE_GODOT_CHAPTER1_ARTISTIC_ACCEPTANCE=PENDING') &&
       script.includes('chapter1-wind-shear-combat-native-960x640.png') &&
       script.includes('frameSha256 = $RenderHashes'),
  'exact Windows QA must execute and hash-bind the real native Chapter I render gate');

assert(captureScript.includes('AETHERWAKE_CAPTURE_OUTPUT_DIR') &&
       captureScript.includes('ProjectSettings.globalize_path(DEFAULT_OUTPUT)'),
  'native capture must support isolated verifier output without breaking default workflow output');

assert(buildScript.includes('PSNativeCommandUseErrorActionPreference') &&
       buildScript.includes('$GodotExitCode = $LASTEXITCODE') &&
       buildScript.includes('$ErrorActionPreference = "Continue"'),
  'Windows build wrapper must preserve Godot exit-code authority under PowerShell native stderr behavior');

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
       script.includes('PREEXISTING_NATIVE_PREVIEW_RESIDUE') &&
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
       script.includes('WINDOWS_NATIVE_QA_RECEIPT.md') &&
       script.includes('AETHERWAKE_GODOT_EXACT_QA_RECEIPT_MD=') &&
       script.includes('EXPORTED_TO_PACKAGED_EXE_HASH_MISMATCH') &&
       script.includes('exportedExeSha256') &&
       script.includes('installWrapperSha256') &&
       script.includes('uninstallWrapperSha256') &&
       script.includes('packageReadmeSha256') &&
       script.includes('packageManifestSha256') &&
       script.includes('TRACKED_SOURCE_CHANGED_DURING_QA') &&
       script.includes('publicReleaseAuthorized = $false') &&
       script.includes('Public release authorized: NO') &&
       script.includes('AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS'),
  'exact Windows QA must emit machine and human-readable custody, preserve tracked source and avoid authorizing public release');

assert(!/Start-Process[^\n]*-Verb\s+RunAs/i.test(script),
  'exact Windows QA must not request elevation');
assert(!/Set-MpPreference|Add-MpPreference|Remove-MpPreference|DisableRealtimeMonitoring|ExclusionPath|ExecutionPolicy\s+Bypass/i.test(script),
  'exact Windows QA must not alter Defender protection/exclusions or bypass execution policy');

console.log('Aetherwake Godot exact Windows QA contract: PASS');
