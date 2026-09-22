'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'title-music.js'), 'utf8');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const stage = fs.readFileSync(path.join(root, 'scripts', 'stage-memories-desktop.js'), 'utf8');

assert(source.includes("const VERSION = '0.2.0'"), 'direct title controller version missing');
assert(source.includes('assets/audio/aetherwake-skyward-arpeggio-main-title.mp3'),
  'canonical title-theme path missing');
assert(source.includes("new Set(['boot', 'menu'])"),
  'title theme must remain bounded to boot/menu states');
assert(source.includes("addEventListener('keydown'"),
  'title theme must retry after keyboard gesture');
assert(source.includes("addEventListener('pointerdown'"),
  'title theme must retry after pointer gesture');
assert(source.includes("addEventListener('error'"),
  'title theme must fail non-fatally on missing/invalid asset');
assert(source.includes('result.catch'),
  'title theme must absorb autoplay rejection');
assert(source.includes('fadeOut'),
  'title theme must fade when leaving title states');

assert(html.includes('modules/title-music.js'),
  'direct embedded runtime must load title-music controller');
assert(!html.includes('aetherwake-themed.html'),
  'embedded runtime must not depend on stale iframe wrapper');

assert(stage.includes("const assetsSrc = path.join(repo, 'assets')"),
  'desktop staging must include repository assets');
assert(stage.includes('fs.cpSync(assetsSrc, assetsDst'),
  'desktop staging must recursively copy assets');

console.log('Aetherwake direct title-theme contract: PASS');


const smoke = fs.readFileSync(path.join(root, 'tests', 'smoke-playwright.js'), 'utf8');
assert(smoke.includes('aetherwake-skyward-arpeggio-main-title\\.mp3'),
  'smoke must allow the documented pending binary to remain non-fatal');
assert(smoke.includes('verified/recoverable but its binary has not yet been'),
  'smoke title-media exception must preserve the explicit admission boundary');
