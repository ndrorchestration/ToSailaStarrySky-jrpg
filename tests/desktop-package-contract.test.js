const fs = require('fs');
const path = require('path');
const packageJson = require('../package.json');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(packageJson.main === 'index-embedded.html',
  'desktop package must launch the embedded HTML entry point');
assert(packageJson.window && packageJson.window.width === 960,
  'desktop package window width must remain 960');
assert(packageJson.window && packageJson.window.height === 640,
  'desktop package window height must remain 640');
assert(packageJson.window && packageJson.window.icon === 'icon.svg',
  'desktop package must reference the tracked application icon');
assert(fs.existsSync(path.join(__dirname, '..', 'icon.svg')),
  'desktop application icon is missing');
assert(typeof packageJson.scripts['package:windows'] === 'string',
  'Windows packaging script is missing');
assert(packageJson.scripts['package:windows'].includes('--outDir=../aetherwake-dist'),
  'Windows build output must stay outside the source tree');
assert(packageJson.devDependencies && packageJson.devDependencies['nw-builder'] === '4.20.0',
  'nw-builder must be pinned to the verified packaging version');
assert(!packageJson.devDependencies.nw && !packageJson.devDependencies.nwjs,
  'unused legacy NW.js npm packages must not be reintroduced');

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
assert(workflow.includes('path: ../aetherwake-dist/**'),
  'desktop workflow must upload the complete verified NW.js output root');
assert(!workflow.includes('Compress-Archive'),
  'desktop workflow should not create a redundant ZIP inside the GitHub artifact');

console.log('Aetherwake desktop package contract: PASS');
