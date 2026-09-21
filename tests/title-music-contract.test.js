const assert = require('assert');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const controllerPath = path.join(ROOT, 'modules', 'title-music.js');
const launcherPath = path.join(ROOT, 'aetherwake-themed.html');
const packagePath = path.join(ROOT, 'package.json');

assert(fs.existsSync(controllerPath), 'title music controller is missing');
assert(fs.existsSync(launcherPath), 'themed launcher is missing');

const controller = fs.readFileSync(controllerPath, 'utf8');
const launcher = fs.readFileSync(launcherPath, 'utf8');
const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));

assert(controller.includes('AetherwakeTitleMusic'),
  'controller does not expose its runtime contract');
assert(controller.includes('assets/audio/aetherwake-skyward-arpeggio-main-title.mp3'),
  'controller does not bind the canonical theme asset');
assert(controller.includes("addEventListener('keydown'"),
  'controller does not retry playback after keyboard interaction');
assert(controller.includes("addEventListener('pointerdown'"),
  'controller does not retry playback after pointer interaction');
assert(controller.includes('result.catch'),
  'controller does not handle autoplay rejection non-fatally');
assert(controller.includes('fadeOut'),
  'controller does not fade the title theme out when gameplay begins');
assert(launcher.includes('index-embedded.html'),
  'launcher does not host the canonical runtime');
assert(launcher.includes('modules/title-music.js'),
  'launcher does not load the title music controller');
assert.strictEqual(pkg.main, 'aetherwake-themed.html',
  'desktop package does not launch the themed entrypoint');

console.log('TITLE_MUSIC_CONTRACT=PASS');
