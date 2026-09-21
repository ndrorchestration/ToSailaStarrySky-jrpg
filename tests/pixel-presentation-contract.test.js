'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

function section(startMarker, endMarker) {
  const start = runtime.indexOf(startMarker);
  const end = runtime.indexOf(endMarker, start);
  assert(start >= 0 && end > start, 'missing runtime section: ' + startMarker);
  return runtime.slice(start, end);
}

const title = section('function drawTitleScreen()', 'function drawAirshipOverlay()');
assert(title.includes('Pixel-built title islands'), 'title pixel-island contract missing');
assert(!title.includes('ellipse(px, py, island.size'), 'title islands regressed to procedural ellipses');

const covenant = section('function drawCovenantField()', '// --- Player');
assert(covenant.includes('Pixel-conscious covenant glyph'), 'covenant pixel-glyph contract missing');
assert(!covenant.includes('ellipse('), 'covenant field regressed to procedural ellipse geometry');
assert(covenant.includes('beginShape()'), 'covenant diamond geometry missing');

console.log('Aetherwake pixel presentation contract: PASS');
