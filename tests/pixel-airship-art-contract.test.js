'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const start = runtime.indexOf('function drawShipInterior()');
const end = runtime.indexOf('// --- Ground Layer', start);
assert(start >= 0 && end > start, 'live ship interior renderer missing');
const ship = runtime.slice(start, end);

assert(!ship.includes('ellipse('), 'ship interior must not regress to procedural ellipse glow');
assert(ship.includes('Dragonfly wing spars'), 'dragonfly-derived silhouette contract missing');
assert(ship.includes('Multiphasic aether core'), 'aether core visual contract missing');
assert(ship.includes('hydroponic repair beds'), 'solarpunk interior storytelling contract missing');
assert(ship.includes("AetherPixelSprites.draw('ender'"), 'Ender sprite authority missing from ship interior');

console.log('Aetherwake pixel airship interior contract: PASS');
