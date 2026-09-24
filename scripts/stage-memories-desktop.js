const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const stage = path.join(repo, '.desktop-runtime');
const www = path.join(stage, 'www');

function writeWindowsIcon(filePath) {
  const size = 32;
  const xorBytes = size * size * 4;
  const andRowBytes = 4;
  const andBytes = andRowBytes * size;
  const bitmapBytes = 40 + xorBytes + andBytes;
  const out = Buffer.alloc(6 + 16 + bitmapBytes);

  // ICONDIR + one ICONDIRENTRY.
  out.writeUInt16LE(0, 0);
  out.writeUInt16LE(1, 2);
  out.writeUInt16LE(1, 4);
  out.writeUInt8(size, 6);
  out.writeUInt8(size, 7);
  out.writeUInt8(0, 8);
  out.writeUInt8(0, 9);
  out.writeUInt16LE(1, 10);
  out.writeUInt16LE(32, 12);
  out.writeUInt32LE(bitmapBytes, 14);
  out.writeUInt32LE(22, 18);

  // BITMAPINFOHEADER. ICO height includes XOR + AND masks.
  const dib = 22;
  out.writeUInt32LE(40, dib);
  out.writeInt32LE(size, dib + 4);
  out.writeInt32LE(size * 2, dib + 8);
  out.writeUInt16LE(1, dib + 12);
  out.writeUInt16LE(32, dib + 14);
  out.writeUInt32LE(0, dib + 16);
  out.writeUInt32LE(xorBytes, dib + 20);

  const pixelOffset = dib + 40;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const displayY = size - 1 - y;
      const dx = Math.abs(x - 15.5);
      const outer = displayY >= 4 && displayY <= 27 && dx <= (displayY - 3) * 0.55;
      const inner = displayY >= 10 && displayY <= 23 && dx <= (displayY - 8) * 0.34;
      const core = (x - 15.5) ** 2 + (displayY - 18) ** 2 <= 5;
      let r = 7, g = 21, b = 31, a = 255;
      if (outer) { r = 110; g = 231; b = 200; }
      if (inner) { r = 16; g = 47; b = 58; }
      if (core) { r = 245; g = 199; b = 107; }
      const i = pixelOffset + (y * size + x) * 4;
      out[i] = b;
      out[i + 1] = g;
      out[i + 2] = r;
      out[i + 3] = a;
    }
  }

  fs.writeFileSync(filePath, out);
}

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

writeWindowsIcon(path.join(www, 'icon.ico'));

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
  version: '0.1.0',
  description: 'Aetherwake Chapter 1 — First Wake',
  author: 'NDR Orchestration',
  main: 'www/index-embedded.html',
  'js-flags': '--expose-gc',
  nwbuild: {
    app: {
      icon: '.desktop-runtime/www/icon.ico'
    }
  },
  window: {
    title: 'AETHERWAKE — THE LAST SOLARPUNK AIRSHIP',
    width: 1440,
    height: 960,
    min_width: 960,
    min_height: 640,
    toolbar: false,
    resizable: true,
    icon: 'www/icon.ico',
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
