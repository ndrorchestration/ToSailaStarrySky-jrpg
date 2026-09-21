const fs = require('fs');
const path = require('path');
const packageJson = require('../package.json');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(packageJson.main === 'aetherwake-themed.html',
  'desktop package must launch the themed HTML entry point');
assert(packageJson.window && packageJson.window.width === 960,
  'desktop package window width must remain 960');
assert(packageJson.window && packageJson.window.height === 640,
  'desktop package window height must remain 640');
assert(packageJson.window && packageJson.window.icon === 'icon.svg',
  'desktop package must reference the tracked application icon');
assert(fs.existsSync(path.join(__dirname, '..', 'icon.svg')),
  'desktop application icon is missing');
assert(fs.existsSync(path.join(__dirname, '..', 'aetherwake-themed.html')),
  'desktop themed launcher is missing');
assert(fs.existsSync(path.join(__dirname, '..', 'modules', 'title-music.js')),
  'desktop title music controller is missing');
assert(typeof packageJson.scripts['package:windows'] === 'string',
  'Windows packaging script is missing');
assert(typeof packageJson.scripts['stage:desktop-runtime'] === 'string',
  'desktop runtime staging script is missing');
assert(packageJson.scripts['stage:desktop-runtime'] === 'node scripts/stage-desktop-runtime.js',
  'desktop runtime staging command changed unexpectedly');
assert(packageJson.scripts['package:windows'].includes('npm run stage:desktop-runtime'),
  'Windows packaging must stage the minimal runtime before nw-builder');
assert(packageJson.scripts['package:windows'].includes('build/runtime-app'),
  'Windows packaging must target the staged runtime directory');
assert(packageJson.scripts['package:windows'].includes('--outDir=../aetherwake-dist'),
  'Windows build output must stay outside the source tree');
assert(packageJson.devDependencies && packageJson.devDependencies['nw-builder'] === '4.20.0',
  'nw-builder must be pinned to the verified packaging version');
assert(!packageJson.devDependencies.nw && !packageJson.devDependencies.nwjs,
  'unused legacy NW.js npm packages must not be reintroduced');

const stageScript = fs.readFileSync(
  path.join(__dirname, '..', 'scripts', 'stage-desktop-runtime.js'),
  'utf8'
);
assert(stageScript.includes("'aetherwake-themed.html'") &&
  stageScript.includes("'index-embedded.html'") &&
  stageScript.includes("'aetherwake.js'") &&
  stageScript.includes("'p5.min.js'") &&
  stageScript.includes("'embedded-fonts.css'") &&
  stageScript.includes("'icon.svg'") &&
  stageScript.includes("'modules'") &&
  stageScript.includes("'assets'"),
  'desktop runtime stage must explicitly include all required runtime assets');
assert(stageScript.includes('aetherwake-skyward-arpeggio-main-title.mp3'),
  'desktop runtime stage must require the canonical title theme');
for (const forbidden of ['node_modules', 'tests', 'docs', '.github', 'scripts']) {
  assert(stageScript.includes("'" + forbidden + "'"),
    'desktop runtime stage must explicitly forbid ' + forbidden);
}
assert(stageScript.includes('25 * 1024 * 1024'),
  'desktop runtime stage must fail closed on unexpected payload bloat');

const workflow = fs.readFileSync(
  path.join(__dirname, '..', '.github', 'workflows', 'desktop-package.yml'),
  'utf8'
);
assert(workflow.includes('npm run test:desktop-package'),
  'desktop workflow must run the packaging contract before building');
assert(workflow.includes('npm run package:windows'),
  'desktop workflow must build the Windows package');
assert(workflow.includes('node-version: 26.7.0'),
  'desktop workflow should match NW.js 0.116.0 host Node 26.7.0');
assert(workflow.includes('cancel-in-progress: true'),
  'desktop workflow should cancel superseded branch builds');
assert(workflow.includes('Aetherwake.exe'),
  'desktop workflow must verify the packaged executable');
assert(workflow.includes('package.nw'),
  'desktop workflow must verify the packaged NW.js application directory');
assert(workflow.includes('index-embedded.html'),
  'desktop workflow must verify the embedded entry point inside package.nw');
assert(workflow.includes('package.json'),
  'desktop workflow must verify the application manifest inside package.nw');
assert(workflow.includes('Resolve-Path ..\\aetherwake-dist'),
  'desktop workflow must treat the NW.js output directory itself as the package root');
assert(workflow.includes('name: Aetherwake-Windows'),
  'desktop workflow must publish a named Windows artifact');
assert(workflow.includes('Copy-Item -Path "..\\aetherwake-dist\\*"'),
  'desktop workflow must stage the verified external build after packaging');
assert(workflow.includes('path: artifact/Aetherwake-Windows/**'),
  'desktop workflow must upload the complete staged NW.js output root');
assert(!workflow.includes('Compress-Archive'),
  'desktop workflow should not create a redundant ZIP inside the GitHub artifact');

console.log('Aetherwake desktop package contract: PASS');
