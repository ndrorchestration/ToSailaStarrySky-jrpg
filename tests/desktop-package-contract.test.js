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


assert(workflow.includes('Uninstallable=yes'),
  'standard installer must support normal uninstall');
assert(workflow.includes('DefaultDirName={localappdata}\\\\Programs\\\\Aetherwake'),
  'player installer must default to a per-user location');
assert(workflow.includes('PrivilegesRequired=lowest'),
  'player installer must not require administrator elevation');
assert(workflow.includes('DisableStartupPrompt=yes'),
  'player installer must not present the pre-install startup confirmation');
assert(workflow.includes('Install and launch packaged app'),
  'desktop workflow must install-smoke the compiled installer');

const readme = fs.readFileSync(path.join(__dirname, '..', 'README.md'), 'utf8');
const desktopGuide = fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'DESKTOP_BUILD.md'),
  'utf8'
);
assert(readme.includes('Aetherwake-Setup.exe'),
  'README must advertise the standard installer');
assert(!readme.includes('Aetherwake-OneClick.exe'),
  'README must not advertise superseded self-extracting artifacts');
assert(desktopGuide.includes('Aetherwake-Setup.exe'),
  'desktop guide must advertise the standard installer');
assert(!desktopGuide.includes('Aetherwake-OneClick.exe'),
  'desktop guide must not advertise superseded self-extracting artifacts');
console.log('Aetherwake desktop package contract: PASS');
