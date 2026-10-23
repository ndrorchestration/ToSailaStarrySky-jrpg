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
       script.includes('git ls-files --others -- godot') &&
       !script.includes('git ls-files --others --exclude-standard -- godot') &&
       script.includes('UNTRACKED_GODOT_AUTHORITY_FILES'),
  'exact Windows QA must validate and bind clean tracked source plus all ignored/nonignored Godot project files to an expected SHA');

assert((script.match(/EXPECTED_SOURCE_SHA_INVALID/g) || []).length === 1 &&
       (script.match(/git rev-parse HEAD/g) || []).length === 1 &&
       (script.match(/AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS/g) || []).length === 1,
  'exact Windows QA control flow must contain one source validator, one HEAD binding and one terminal PASS marker');

assert(/(^|\n)\.godot\/\s*(\n|$)/.test(gitignore),
  'Godot generated .godot cache must stay ignored in normal repository status');

assert(script.includes('$GodotCacheDir = Join-Path $GodotDir ".godot"') &&
       script.includes('Remove-Item -LiteralPath $GodotCacheDir -Recurse -Force'),
  'exact Windows QA must delete stale .godot cache before source binding and clean generated cache before final integrity proof');

assert(script.includes('$GeneratedGodotMetadataSha = [ordered]@{}') &&
       script.includes('EndsWith(".import"') &&
       script.includes('EndsWith(".uid"') &&
       script.includes('git ls-files -- $SourceRelativePath') &&
       script.includes('GENERATED_GODOT_UID_METADATA_INVALID') &&
       script.includes('GENERATED_GODOT_IMPORT_METADATA_INVALID') &&
       script.includes('$GeneratedGodotMetadataSha[$RelativeMetadataPath] = Get-Sha256Hex $MetadataPath') &&
       script.includes('Remove-Item -LiteralPath (Join-Path $RepoRoot $RelativeMetadataPath) -Force') &&
       script.includes('GENERATED_GODOT_METADATA_CLEANUP_FAILED'),
  'Godot-generated sidecars must be limited to tracked sources, validated, hash-bound, cleaned and followed by a zero-untracked proof');

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
       script.includes('godotExeSha256'),
  'exact Windows QA must authenticate and custody-bind the official Godot 4.7.2 Windows editor');

assert(script.includes('$ExpectedTemplateVersion = "4.7.2.stable"') &&
       script.includes('EXPORT_TEMPLATE_VERSION_MISMATCH') &&
       script.includes('windowsReleaseTemplateSha256') &&
       script.includes('templateVersionText') &&
       !script.includes('windowsReleaseTemplateAuthenticode'),
  'export template custody must use exact-version identity plus SHA-256 without inventing an upstream Authenticode guarantee');

assert(script.includes('--rendering-method') &&
       script.includes('gl_compatibility') &&
       script.includes('capture_first_wake_chapter1_review.gd') &&
       script.includes('AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS') &&
       script.includes('AETHERWAKE_GODOT_CHAPTER1_ARTISTIC_ACCEPTANCE=PENDING') &&
       script.includes('chapter1-wind-shear-combat-native-960x640.png') &&
       script.includes('logSha256 = $RenderLogSha') &&
       script.includes('frameSha256 = $RenderHashes'),
  'exact Windows QA must execute and hash-bind the real native Chapter I render gate, including its log and frames');

assert(captureScript.includes('AETHERWAKE_CAPTURE_OUTPUT_DIR') &&
       captureScript.includes('ProjectSettings.globalize_path(DEFAULT_OUTPUT)'),
  'native capture must support isolated verifier output without breaking default workflow output');

assert(buildScript.includes('PSNativeCommandUseErrorActionPreference') &&
       buildScript.includes('$GodotExitCode = $LASTEXITCODE') &&
       buildScript.includes('$ErrorActionPreference = "Continue"'),
  'Windows build wrapper must preserve Godot exit-code authority under PowerShell native stderr behavior');

assert(buildScript.includes('res://tests/first_wake_chapter1_review_test.gd') &&
       buildScript.includes('res://tests/ionia_four_direction_test.gd'),
  'Windows package gate must exercise the Chapter I actor-presentation boundary and Ionia directional art contract');

assert(script.includes('Get-DefenderCustody') &&
       script.includes('Get-MpComputerStatus') &&
       script.includes('DEFENDER_ANTIVIRUS_NOT_ENABLED') &&
       script.includes('DEFENDER_REALTIME_NOT_ENABLED') &&
       script.includes('AMProductVersion') &&
       script.includes('AMEngineVersion') &&
       script.includes('AntivirusSignatureVersion') &&
       script.includes('Start-MpScan -ScanType CustomScan -ScanPath') &&
       script.includes('Get-MpThreatDetection') &&
       script.includes('DEFENDER_DETECTION_FOR_'),
  'exact Windows QA must verify active Defender state, custody-bind engine/signature metadata, and run fail-closed custom scans');

assert(script.includes('Get-WinEvent -ListLog "Microsoft-Windows-Windows Defender/Operational"') &&
       script.includes('Get-DefenderLatestRecordId') &&
       script.includes('-MaxEvents 1') &&
       script.includes('$PreScanRecordId = Get-DefenderLatestRecordId') &&
       script.includes('[long]$Candidate.RecordId -le $PreScanRecordId') &&
       script.includes('Id = @(1000, 1001, 1002)') &&
       script.includes('"Scan Resources"') &&
       script.includes('"Scan ID"') &&
       script.includes('DEFENDER_SCAN_START_EVENT_MISSING_') &&
       script.includes('DEFENDER_SCAN_COMPLETION_EVENT_MISSING_') &&
       script.includes('DEFENDER_SCAN_CANCELLED_') &&
       script.includes('preScanRecordId = $PreScanRecordId') &&
       script.includes('startEventRecordId = [long]$StartEvent.RecordId') &&
       script.includes('completionEventRecordId = [long]$CompletionEvent.RecordId') &&
       script.includes('threatDetectionCount = $Detections.Count') &&
       script.includes('pre-scan RecordId watermark') &&
       script.includes('Defender scan watermark/event/Scan-ID custody: recorded in JSON receipt') &&
       !script.includes('Start-Sleep -Milliseconds 750'),
  'each Defender artifact scan must be record-watermarked, bound to exact-path event 1000, same-ID event 1001, fail on 1002, and custody-bind event records plus threat result');

assert(script.includes('INSTALL_WRAPPER') &&
       script.includes('UNINSTALL_WRAPPER') &&
       script.includes('PACKAGED_EXE') &&
       script.includes('ZIP'),
  'Defender gate must cover wrappers, packaged EXE and ZIP');

assert(script.includes('PREEXISTING_NATIVE_PREVIEW_INSTALL') &&
       script.includes('PREEXISTING_NATIVE_PREVIEW_RESIDUE') &&
       script.includes('Get-CimInstance Win32_Process') &&
       script.includes('ExecutablePath') &&
       script.includes('AuditedInstallCmd') &&
       script.includes('audited extracted ZIP native preview installer') &&
       script.includes('source = "audited-extracted-zip"') &&
       script.includes('$ExpectedInstallMarker = "AETHERWAKE_GODOT_NATIVE_PREVIEW_INSTALL_V1"') &&
       script.includes('$InstalledMarker = Join-Path $InstallDir "Aetherwake-Native-Preview.install"') &&
       script.includes('INSTALLED_OWNERSHIP_MARKER_MISMATCH') &&
       script.includes('ownershipMarker = [ordered]@{') &&
       script.includes('INSTALLED_EXE_HASH_MISMATCH') &&
       script.includes('INSTALLED_UNINSTALLER_HASH_MISMATCH') &&
       script.includes('INSTALLED_NATIVE_PREVIEW_WINDOW_NOT_READY') &&
       script.includes('Assert-ShortcutTarget') &&
       script.includes('SHORTCUT_TARGET_MISMATCH_') &&
       script.includes('SHORTCUT_WORKDIR_MISMATCH_'),
  'install gate must exercise the audited extracted ZIP, prove install ownership, preserve packaged bytes and verify exact process/window plus shortcut targets');

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
       script.includes('packageManifest = $ManifestValues') &&
       script.includes('PACKAGE_MANIFEST_KEY_COUNT_MISMATCH') &&
       script.includes('PACKAGE_MANIFEST_VALUE_MISMATCH') &&
       script.includes('Expand-Archive') &&
       script.includes('ZIP_CONTENT_SET_MISMATCH') &&
       script.includes('ZIP_PAYLOAD_HASH_MISMATCH') &&
       script.includes('zipContentAudit') &&
       script.includes('generatedGodotMetadata') &&
       script.includes('AETHERWAKE_GODOT_EXACT_QA_GENERATED_METADATA=') &&
       script.includes('TRACKED_SOURCE_CHANGED_DURING_QA') &&
       script.includes('FINAL_GIT_UNTRACKED_GODOT_SCAN_FAILED') &&
       script.includes('UNTRACKED_GODOT_AUTHORITY_FILES_CREATED_DURING_QA') &&
       script.includes('Final tracked/untracked Godot source integrity: PASS') &&
       script.includes('publicReleaseAuthorized = $false') &&
       script.includes('Public release authorized: NO') &&
       script.includes('AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS'),
  'exact Windows QA must verify manifest/ZIP/install custody, preserve Godot source integrity, and avoid authorizing public release');

assert(!/Start-Process[^\n]*-Verb\s+RunAs/i.test(script),
  'exact Windows QA must not request elevation');
assert(!/Set-MpPreference|Add-MpPreference|Remove-MpPreference|DisableRealtimeMonitoring|ExclusionPath|ExecutionPolicy\s+Bypass/i.test(script),
  'exact Windows QA must not alter Defender protection/exclusions or bypass execution policy');

console.log('Aetherwake Godot exact Windows QA contract: PASS');
