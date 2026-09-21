'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

function functionBody(name) {
  const start = runtime.indexOf('function ' + name + '(');
  assert(start >= 0, name + ' is missing');
  const next = runtime.indexOf('\nfunction ', start + 1);
  return runtime.slice(start, next >= 0 ? next : runtime.length);
}

const ambient = functionBody('drawWorldAmbient');
assert(!ambient.includes('ellipse('),
  'world ambient atmosphere still uses procedural ellipse rendering');
assert(ambient.includes('Math.round'),
  'ambient particle placement is not pixel aligned');
assert(ambient.includes('rect(x, y, 2, 2)'),
  'ambient motes are not rendered as pixel clusters');
assert(ambient.includes('rect(x - 48, y, 96, 3)'),
  'ground mist is not rendered as pixel bands');

console.log('Aetherwake pixel ambient contract: PASS');
