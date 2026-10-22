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
assert(packageJson.window && packageJson.window.title === 'AETHERWAKE',
  'player-facing desktop title must use the canonical Aetherwake name without the retired subtitle');
assert(packageJson.window && packageJson.window.resizable === true,
  'desktop package window must remain resizable');
assert(packageJson.window.min_width === 960 && packageJson.window.min_height === 640,
  'desktop package minimum window must preserve the logical 960x640 game surface');
assert(typeof packageJson.scripts['package:windows'] === 'string',
  'Windows packaging script is missing');
assert(packageJson.devDependencies && packageJson.devDependencies['nw-builder'],
  'nw-builder dependency is missing');

const stageScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'stage-memories-desktop.js'),
  'utf8'
);
assert(stageScript.includes("main: 'www/index-embedded.html'"),
  'production desktop manifest must use the RPG Maker MV-style www entrypoint');
assert(stageScript.includes("'icon.ico'"),
  'production desktop runtime must stage a Windows ICO asset');
assert(stageScript.includes('version: rootPackage.version'),
  'production desktop manifest must carry the project version for Windows metadata');
assert(packageJson.scripts['package:windows'].includes('--app.icon=.desktop-runtime/www/icon.ico'),
  'Windows packaging must pass the staged ICO through nw-builder app icon metadata');
assert(stageScript.includes("path.join(stage, 'package.json')"),
  'production desktop manifest must live at the launcher root');
assert(stageScript.includes("path.join(stage, 'www')"),
  'production game payload must live under www');
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
assert(workflow.includes('npm run package:windows'),
  'desktop workflow must build the Windows NW.js package');
assert(workflow.includes('Get-ChildItem -LiteralPath $dist -Filter "Aetherwake.exe" -File -Recurse'),
  'desktop workflow must locate the emitted executable at any supported package depth');
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
assert(localReleaseScript.includes('Get-ChildItem -LiteralPath $dist -Filter "Aetherwake.exe" -File -Recurse'),
  'local Windows release fallback must locate direct or nested nw-builder output');
assert(localReleaseScript.includes('LOCAL_WINDOWS_RELEASE=PASS'),
  'local Windows release fallback must emit an explicit success marker');
assert(localReleaseScript.includes('Start-Process -FilePath $installer'),
  'local Windows release fallback must install-smoke the generated installer');
assert(localReleaseScript.includes('Start-Process -FilePath $installedExe'),
  'local Windows release fallback must launch-smoke the installed game');
assert(localReleaseScript.includes('AETHERWAKE_DESKTOP_SMOKE_MARKER'),
  'local Windows release fallback must require application-level render readiness');
assert(localReleaseScript.includes('DESKTOP_RENDER_READINESS=PASS'),
  'local Windows release fallback must verify a rendered first frame');

console.log('Aetherwake desktop package contract: PASS');

const runtimeSource = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
assert(!runtimeSource.includes('THE LAST SOLARPUNK AIRSHIP'),
  'runtime must not render the retired subtitle');
assert(!stageScript.includes('THE LAST SOLARPUNK AIRSHIP'),
  'staged desktop manifest must not restore the retired subtitle');
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


const safePlayerScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'build-safe-player-package.ps1'),
  'utf8'
);
assert(typeof packageJson.scripts['package:windows:safe-player'] === 'string',
  'safe player package script is missing');
assert(!safePlayerScript.includes('makensis') && !safePlayerScript.includes('WriteUninstaller'),
  'safe player package must not invoke NSIS or generate its uninstaller');
assert(!safePlayerScript.includes('ExecutionPolicy Bypass'),
  'safe player package must not bypass PowerShell execution policy');
assert(safePlayerScript.includes('Install-Aetherwake.cmd') && safePlayerScript.includes('Uninstall-Aetherwake.cmd'),
  'safe player package must provide explicit install/uninstall wrappers');
assert(safePlayerScript.includes("GetFolderPath('Desktop')"),
  'uninstall wrapper must resolve the actual Windows Desktop known folder');
assert(safePlayerScript.includes('cd /d "%TEMP%"'),
  'uninstall wrapper must leave its own install directory before delayed deletion');
