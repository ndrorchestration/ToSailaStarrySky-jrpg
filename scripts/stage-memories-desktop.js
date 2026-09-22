const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const stage = path.join(repo, '.desktop-runtime');
const www = path.join(stage, 'www');

fs.rmSync(stage, { recursive: true, force: true });
fs.mkdirSync(www, { recursive: true });

const runtimeFiles = [
  'index-embedded.html',
  'aetherwake.js',
  'p5.min.js',
  'embedded-fonts.css',
  'icon.svg'
];

for (const file of runtimeFiles) {
  const src = path.join(repo, file);
  if (!fs.existsSync(src)) {
    throw new Error(`Required desktop runtime file missing: ${file}`);
  }
  fs.copyFileSync(src, path.join(www, file));
}

const modulesSrc = path.join(repo, 'modules');
const modulesDst = path.join(www, 'modules');
if (!fs.existsSync(modulesSrc)) {
  throw new Error('Required desktop runtime directory missing: modules');
}
fs.cpSync(modulesSrc, modulesDst, { recursive: true });

const assetsSrc = path.join(repo, 'assets');
const assetsDst = path.join(www, 'assets');
if (fs.existsSync(assetsSrc)) {
  fs.cpSync(assetsSrc, assetsDst, { recursive: true });
}

const manifest = {
  name: 'Aetherwake',
  main: 'www/index-embedded.html',
  'js-flags': '--expose-gc',
  window: {
    title: 'AETHERWAKE — THE LAST SOLARPUNK AIRSHIP',
    width: 1440,
    height: 960,
    min_width: 960,
    min_height: 640,
    toolbar: false,
    resizable: true,
    position: 'center',
    show: true,
    frame: true,
    fullscreen: false,
    kiosk: false,
    focus: true
  }
};

fs.writeFileSync(
  path.join(stage, 'package.json'),
  JSON.stringify(manifest, null, 2) + '\n',
  'utf8'
);

const forbidden = [
  'tests',
  'docs',
  '.github',
  'node_modules',
  'package-lock.json'
];

for (const entry of forbidden) {
  if (fs.existsSync(path.join(stage, entry)) || fs.existsSync(path.join(www, entry))) {
    throw new Error(`Development-only content leaked into desktop runtime: ${entry}`);
  }
}

console.log('MEMORIES_STYLE_DESKTOP_LAYOUT=PASS');
console.log(`DESKTOP_MAIN=${manifest.main}`);
console.log(`DESKTOP_STAGE=${stage}`);
