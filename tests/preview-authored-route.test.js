'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const smokePath = path.join(__dirname, 'smoke-playwright.js');
const smoke = fs.readFileSync(smokePath, 'utf8');

assert.match(smoke, /async function walkToTile\(page, targetX, targetY\)/,
  'Preview smoke must navigate with player movement input');
assert.doesNotMatch(smoke, /p\.tileX\s*=\s*7;\s*p\.tileY\s*=\s*7/,
  'Preview smoke must not teleport directly onto Ionia');
assert.doesNotMatch(smoke, /keyboard\.press\(['"]KeyC['"]\)/,
  'Preview smoke must not start the encounter with the debug combat shortcut');
assert.match(smoke, /npcId === 'elder_farmer'.*Captain Ionia/s,
  'Preview smoke must verify first contact with Captain Ionia');
assert.match(smoke,
  /for \(let lineIndex = 0; lineIndex < firstDialogue\.lines\.length; lineIndex\+\+\)/,
  'Preview smoke must advance every line of Ionia’s first conversation');
assert.match(smoke, /enemy\.name === 'Sky-Predator'/,
  'Preview smoke must verify Ionia starts the authored Sky-Predator encounter');

console.log('Aetherwake Preview authored route contract: PASS');
