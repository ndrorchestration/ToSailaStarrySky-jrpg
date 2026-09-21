'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

function functionBody(name) {
  const start = runtime.indexOf('function ' + name + '(');
  assert(start >= 0, name + ' is missing');
  const next = runtime.indexOf('\nfunction ', start + 1);
  return runtime.slice(start, next >= 0 ? next : runtime.length);
}

const falling = functionBody('drawFallingIslands');
assert(falling.includes("drawPixelWorldTile('float'"),
  'falling islands are not bound to the shared pixel tile authority');
assert(!falling.includes('ellipse('),
  'falling islands still use procedural ellipse rendering');
assert(falling.includes('Math.round((dayTime * 8) % 4)'),
  'falling-island drift is not pixel-aligned');

const astro = functionBody('drawSkyAstro');
assert(astro.includes("drawPixelWorldTile('astro', px, py, 0)"),
  'astro tile is not explicitly bound to its authored frame');
assert(!astro.includes('% 1'),
  'astro renderer retains meaningless modulo-1 pseudo-animation');

console.log('Aetherwake pixel world ambient contract: PASS');
