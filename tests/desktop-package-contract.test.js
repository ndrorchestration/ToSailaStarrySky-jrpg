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
assert(typeof packageJson.scripts['package:windows'] === 'string',
  'Windows packaging script is missing');
assert(packageJson.devDependencies && packageJson.devDependencies['nw-builder'],
  'nw-builder dependency is missing');

const workflow = fs.readFileSync(
  path.join(__dirname, '..', '.github', 'workflows', 'desktop-package.yml'),
  'utf8'
);
assert(workflow.includes('npm run test:desktop-package'),
  'desktop workflow must run the packaging contract before building');
assert(workflow.includes('npm run package:windows'),
  'desktop workflow must build the Windows package');
assert(workflow.includes('Inno Setup'),
  'desktop workflow must build the standard Windows installer');
assert(workflow.includes('Aetherwake-Setup.exe'),
  'desktop workflow must publish the standard Windows installer');
assert(workflow.includes('Aetherwake-Windows.zip'),
  'desktop workflow must publish a named Windows ZIP fallback');

console.log('Aetherwake desktop package contract: PASS');
