'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const title = fs.readFileSync(path.join(root, 'modules', 'title-visual-stage.js'), 'utf8');
const opening = require('../modules/first-wake-opening.js');
const visual = fs.readFileSync(path.join(root, 'modules', 'first-wake-visual-stage.js'), 'utf8');
const authored = fs.readFileSync(path.join(root, 'modules', 'authored-character-art.js'), 'utf8');

assert(title.includes("text('AETHERWAKE', cx, logoY)"), 'title logo must be key-art-first');
assert(title.includes("text('NEW GAME', cx, menuY)"), 'title must expose a minimal New Game command');
assert(!title.includes('WASD / ARROWS') && !title.includes('A small ship. A broken world.'),
  'title must not begin with tutorial or pitch copy');

assert.strictEqual(opening.SCENES[0].id, 'arrival_horizon');
assert(opening.SCENES[0].minimumTicks >= 240,
  'world reveal must have sustained cinematic dwell before handoff');

assert(visual.includes('function drawHorizonEstablishing'),
  'opening must have a dedicated establishing composition');
assert(visual.includes("sceneTicks >= 90 && sceneTicks < 160"),
  'location reveal timing drifted');
assert(visual.includes("sceneTicks >= 142"),
  'narration must not appear before the world has time to breathe');
assert(!visual.includes("FIRST WAKE // ' + String(scene.sequence)"),
  'player-facing transition must not show sequence metadata');

assert(authored.includes('drawProvisionalFieldCharacter'),
  'opening must have an authored pixel fallback ahead of procedural figures');
assert(visual.includes('drawProvisionalFieldCharacter'),
  'opening must actually use the provisional pixel fallback');

console.log('Aetherwake first-minute JRPG genre-read contract: PASS');
