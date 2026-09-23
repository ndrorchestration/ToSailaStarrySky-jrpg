const fs = require('fs');
const path = require('path');
const packageJson = require('../package.json');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(packageJson.main === 'index-embedded.html',
  'development manifest must retain the embedded HTML entry point');
assert(packageJson.window && packageJson.window.width === 1440,
  'desktop package window width must default to 1440');
assert(packageJson.window && packageJson.window.height === 960,
  'desktop package window height must default to 960');
assert(packageJson.window && packageJson.window.resizable === true,
  'desktop package window must remain resizable');
assert(packageJson.window.min_width === 960 && packageJson.window.min_height === 640,
  'desktop package minimum window must preserve the logical 960x640 game surface');
assert(typeof packageJson.scripts['package:windows'] === 'string',
  'Windows packaging script is missing');
assert(packageJson.scripts['verify:packaged-title-audio'] === 'node scripts/verify-packaged-title-audio.js',
  'packaged title-audio verifier script must be registered');
assert(packageJson.scripts['write:release-evidence'] === 'node scripts/write-release-evidence.js',
  'release evidence writer script must be registered');
assert(packageJson.devDependencies && packageJson.devDependencies['nw-builder'],
  'nw-builder dependency is missing');

const stageScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'stage-memories-desktop.js'),
  'utf8'
);
assert(stageScript.includes("main: 'www/index-embedded.html'"),
  'production desktop manifest must use the RPG Maker MV-style www entrypoint');
assert(stageScript.includes("path.join(stage, 'package.json')"),
  'production desktop manifest must live at the launcher root');
assert(stageScript.includes("path.join(stage, 'www')"),
  'production game payload must live under www');
assert(stageScript.includes("path.join(repo, 'assets')") &&
       stageScript.includes("path.join(www, 'assets')") &&
       stageScript.includes('fs.cpSync(assetsSrc, assetsDst, { recursive: true })'),
  'production desktop staging must preserve governed runtime assets under www/assets');
assert(packageJson.scripts['package:windows'].includes('.desktop-runtime'),
  'Windows packaging must consume only the staged production runtime');

const workflow = fs.readFileSync(
  path.join(__dirname, '..', '.github', 'workflows', 'desktop-package.yml'),
  'utf8'
);

assert(!workflow.includes('actions/upload-artifact@v4'),
  'release-critical path must not depend on GitHub Actions artifact storage');
assert(!workflow.includes('actions/download-artifact@v4'),
  'release-critical path must not depend on GitHub Actions artifact transfer');
assert(workflow.includes('npm ci'),
  'desktop workflow must use the lockfile');
assert(workflow.includes('npm run test:desktop-package'),
  'desktop workflow must run the packaging contract before building');
assert(workflow.includes('npm run test:m0-title-audio-ready'),
  'desktop workflow must require strict M0 title-audio readiness before packaging');
assert(workflow.includes('npm run package:windows'),
  'desktop workflow must build the Windows NW.js package');
assert(workflow.includes('Verify packaged title audio') &&
       workflow.includes('npm run verify:packaged-title-audio'),
  'hosted Windows workflow must verify the governed MP3 inside the packaged payload');
assert(workflow.includes('makensis'),
  'desktop workflow must compile a conventional NSIS installer');
assert(workflow.includes('RequestExecutionLevel user'),
  'player installer must not require administrator elevation');
assert(workflow.includes('InstallDir "$LOCALAPPDATA'),
  'player installer must default to a per-user location');
assert(workflow.includes('Aetherwake-Setup.exe'),
  'desktop workflow must preserve the Windows installer');
assert(workflow.includes('Aetherwake-Windows.zip'),
  'desktop workflow must preserve the portable ZIP fallback');
assert(workflow.includes('SHA256SUMS.txt'),
  'desktop workflow must publish artifact hashes');
assert(workflow.includes('Write release provenance evidence') &&
       workflow.includes('RELEASE_EVIDENCE.json'),
  'desktop workflow must publish source-bound release evidence');
assert(workflow.includes('verify-windows:'),
  'desktop workflow must have a Windows build-and-verification job');
assert(workflow.includes('runs-on: windows-2022'),
  'Windows verification must use a pinned runner image');
assert(workflow.includes('Install and launch exact candidate'),
  'desktop workflow must install-smoke the exact candidate installer');
assert(workflow.includes('AETHERWAKE_DESKTOP_SMOKE_MARKER'),
  'desktop workflow must require an application-level readiness marker');
assert(workflow.includes('DESKTOP_RENDER_READINESS=PASS'),
  'desktop workflow must require live rendered-frame readiness before publication');
assert(workflow.includes('Verify packaged save survives restart'),
  'desktop workflow must verify persistence across an installed NW.js restart');
assert(workflow.includes('AETHERWAKE_SAVE_PERSISTENCE_PHASE') &&
       workflow.includes('AETHERWAKE_SAVE_PERSISTENCE_MARKER'),
  'desktop workflow must drive the packaged save persistence smoke mode');
assert(workflow.includes('DESKTOP_SAVE_RESTART=PASS'),
  'desktop workflow must require packaged save restart success before publication');
assert(workflow.includes('Verify portable package layout'),
  'desktop workflow must verify the portable package shape');

assert(workflow.includes('Publish verified Windows release'),
  'desktop workflow must publish only after build and Windows verification in the same job');
assert(workflow.indexOf('Install and launch exact candidate') < workflow.indexOf('Publish verified Windows release'),
  'publication must occur after exact-candidate install/launch verification');

const readme = fs.readFileSync(path.join(__dirname, '..', 'README.md'), 'utf8');
const desktopGuide = fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'DESKTOP_BUILD.md'),
  'utf8'
);
const localReleaseScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'build-windows-release.ps1'),
  'utf8'
);
assert(readme.includes('Aetherwake-Setup.exe'),
  'README must advertise the standard installer');
assert(readme.includes('Aetherwake-Windows.zip'),
  'README must advertise the portable fallback');
assert(!readme.includes('Aetherwake-OneClick.exe'),
  'README must not advertise superseded self-extracting artifacts');
assert(desktopGuide.includes('Aetherwake-Setup.exe'),
  'desktop guide must advertise the standard installer');
assert(!desktopGuide.includes('Aetherwake-OneClick.exe'),
  'desktop guide must not advertise superseded self-extracting artifacts');
assert(localReleaseScript.includes('LOCAL_WINDOWS_RELEASE=PASS'),
  'local Windows release fallback must emit an explicit success marker');
assert(localReleaseScript.includes('Local Windows release requires readable Git HEAD provenance') &&
       localReleaseScript.includes('Local Windows release requires a clean working tree'),
  'local Windows release must require a clean working tree and exact source provenance');
assert(localReleaseScript.includes('Start-Process -FilePath $installer'),
  'local Windows release fallback must install-smoke the generated installer');
assert(localReleaseScript.includes('Start-Process -FilePath $installedExe'),
  'local Windows release fallback must launch-smoke the installed game');
assert(localReleaseScript.includes('AETHERWAKE_DESKTOP_SMOKE_MARKER'),
  'local Windows release fallback must require application-level render readiness');
assert(localReleaseScript.includes('DESKTOP_RENDER_READINESS=PASS'),
  'local Windows release fallback must verify a rendered first frame');
assert(localReleaseScript.includes('AETHERWAKE_SAVE_PERSISTENCE_PHASE') &&
       localReleaseScript.includes('AETHERWAKE_SAVE_PERSISTENCE_MARKER'),
  'local Windows release fallback must run packaged save persistence smoke');
assert(localReleaseScript.includes('DESKTOP_SAVE_RESTART=PASS'),
  'local Windows release fallback must prove save/load across process restart');
assert(localReleaseScript.includes('restored the wrong quest state'),
  'local Windows release fallback must verify quest-state restoration after restart');
assert(localReleaseScript.includes('restored the wrong active-party membership/order'),
  'local Windows release fallback must verify full active-party restoration after restart');
assert(localReleaseScript.includes('did not use the same isolated NW.js data path'),
  'local Windows release fallback must verify both processes use the same isolated NW.js data path');
assert(localReleaseScript.includes('npm run verify:packaged-title-audio') &&
       localReleaseScript.includes('PACKAGED_TITLE_AUDIO=PASS'),
  'local Windows release must verify the governed MP3 inside the packaged payload');
assert(localReleaseScript.includes('npm run write:release-evidence') &&
       localReleaseScript.includes('RELEASE_EVIDENCE.json'),
  'local Windows release must emit machine-readable source-bound evidence');

console.log('Aetherwake desktop package contract: PASS');

const runtimeSource = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
assert(runtimeSource.includes('function writeDesktopSmokeMarkerOnce()'),
  'runtime must expose a guarded desktop readiness marker writer');
assert(runtimeSource.includes('window.__awRuntimeReady') &&
       runtimeSource.includes('window.__awFirstFrame'),
  'desktop readiness marker must be bound to runtime-ready and completed-first-frame signals');

const embeddedHtmlForCanvas = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');
const runtimeSourceForCanvas = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
assert(runtimeSourceForCanvas.includes('createCanvas(960, 640)'),
  'logical game canvas must remain 960x640 to preserve authored layout coordinates');
assert(embeddedHtmlForCanvas.includes('width: min(100vw, calc(100vh * 1.5))'),
  'desktop presentation must scale the 3:2 canvas to the largest fitting window area');

const embeddedDesktopControls = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');
assert(embeddedDesktopControls.includes('win.toggleFullscreen()'),
  'desktop entrypoint must expose a native fullscreen toggle');
assert(embeddedDesktopControls.includes("event.altKey && event.key === 'Enter'"),
  'desktop entrypoint must support Alt+Enter fullscreen');
assert(embeddedDesktopControls.includes("event.key === 'F11'"),
  'desktop entrypoint must support F11 fullscreen');
assert(embeddedDesktopControls.includes('win.leaveFullscreen()'),
  'desktop entrypoint must support leaving fullscreen with Escape');

assert(runtimeSource.includes('function runDesktopSavePersistenceSmokeIfRequested()'),
  'runtime must expose environment-gated packaged save persistence smoke');
assert(runtimeSource.includes("saveToSlot('manual-6', false)"),
  'packaged save smoke must exercise the production save path');
assert(runtimeSource.includes("loadFromSlot('manual-6')"),
  'packaged save smoke must exercise the production load path');
assert(runtimeSource.includes("window.ACTIVE_PARTY.splice(0, window.ACTIVE_PARTY.length)"),
  'packaged save smoke must invalidate live party state before loading');
assert(runtimeSource.includes("quest.state === expectedQuestState"),
  'packaged save smoke must require quest-state restoration from the persisted payload');
assert(runtimeSource.includes("expectedActiveIds.every((id, index) => id === restoredActiveIds[index])"),
  'packaged save smoke must require exact active-party membership/order restoration');

const windowsRelease = fs.readFileSync(path.join(__dirname, '..', 'scripts', 'build-windows-release.ps1'), 'utf8');
assert(windowsRelease.includes('npm run test:m0-title-audio-ready'),
  'Windows release build must require strict M0 title-audio readiness before packaging');

const packagedAudioVerifier = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'verify-packaged-title-audio.js'),
  'utf8'
);
assert(packagedAudioVerifier.includes("path.join(packageDir, 'www', title.canonicalPath)"),
  'packaged title-audio verifier must inspect the staged www payload');
assert(packagedAudioVerifier.includes("assert.deepStrictEqual(\n  packaged,\n  source"),
  'packaged title-audio verifier must compare the staged file to governed source authority');

const releaseEvidenceWriter = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'write-release-evidence.js'),
  'utf8'
);
assert(releaseEvidenceWriter.includes("git', ['rev-parse', 'HEAD']"),
  'release evidence must bind artifacts to exact source commit');
assert(releaseEvidenceWriter.includes("git', ['status', '--porcelain=v1']"),
  'release evidence must reject dirty working-tree provenance');
assert(releaseEvidenceWriter.includes('governedTitleAudio') &&
       releaseEvidenceWriter.includes('sourceVerification.sha256'),
  'release evidence must retain governed title-audio identity');
assert(releaseEvidenceWriter.includes('installer') &&
       releaseEvidenceWriter.includes('portableZip'),
  'release evidence must fingerprint installer and portable ZIP');
