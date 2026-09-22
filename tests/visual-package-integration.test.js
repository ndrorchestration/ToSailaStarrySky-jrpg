'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const smoke = fs.readFileSync(path.join(root, '.github', 'workflows', 'smoke.yml'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const stage = fs.readFileSync(path.join(root, 'scripts', 'stage-memories-desktop.js'), 'utf8');

const smokeScripts = Array.from(
  smoke.matchAll(/run:\s+npm run ([^\s]+)/g),
  (match) => match[1]
);
for (const script of smokeScripts) {
  assert(pkg.scripts && pkg.scripts[script],
    'smoke workflow references missing package script: ' + script);
}

const moduleRefs = Array.from(
  html.matchAll(/<script src="modules\/([^"]+)"/g),
  (match) => match[1]
);
for (const file of moduleRefs) {
  assert(fs.existsSync(path.join(root, 'modules', file)),
    'embedded runtime references missing module: ' + file);
}

for (const required of [
  'pixel-sprites.js',
  'pixel-tiles.js',
  'dragonfly-visual.js',
  'title-visual-stage.js',
  'first-wake-visual-stage.js',
  'visual-benchmark.js',
  'combat-visual-stage.js',
  'flight-visual-stage.js',
  'cinematic-player.js',
  'title-music.js',
]) {
  assert(moduleRefs.includes(required),
    'Visual Package v1 module is not loaded by embedded runtime: ' + required);
}

assert(stage.includes("main: 'www/index-embedded.html'"),
  'desktop package must preserve direct embedded entrypoint');
assert(stage.includes("const assetsSrc = path.join(repo, 'assets')"),
  'desktop staging must include governed assets');
assert(stage.includes('fs.cpSync(assetsSrc, assetsDst'),
  'desktop staging must recursively copy assets');
assert(!html.includes('aetherwake-themed.html'),
  'consolidated runtime must not depend on retired iframe wrapper');

assert(pkg.scripts['capture:visual-evidence'],
  'visual evidence capture script missing');
assert(pkg.scripts['test:visual-evidence-contract'],
  'visual evidence contract script missing');
assert(pkg.scripts['test:cinematic-player'],
  'cinematic player contract script missing');
assert(pkg.scripts['test:title-music'],
  'title music contract script missing');

console.log(
  'Aetherwake Visual Package v1 integration contract: PASS ' +
  '(' + smokeScripts.length + ' smoke scripts, ' + moduleRefs.length + ' runtime modules)'
);
