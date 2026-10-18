'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..', 'modules', 'preview-world-presentation.js'), 'utf8');

// Dialogue may change composition and position, never the physical stature of an actor.
const actorBlock = source.match(/actors\.push\(\{[\s\S]*?id: 'ender',[\s\S]*?questMarker: false,[\s\S]*?\}\);/);
assert(actorBlock, 'Ender projected actor definition missing');
assert.match(actorBlock[0], /scale:\s*2\.55\s*,/, 'Ender must retain exploration scale during dialogue');
assert.doesNotMatch(actorBlock[0], /scale:\s*dialogueActive\s*\?/, 'Dialogue must not resize Ender');

const npcBlock = source.match(/for \(const npc of npcs\) \{[\s\S]*?actors\.push\(\{[\s\S]*?questMarker:[\s\S]*?\}\);/);
assert(npcBlock, 'NPC projected actor definition missing');
assert.match(npcBlock[0], /scale:\s*2\.45\s*,/, 'NPCs must retain exploration scale during dialogue');
assert.doesNotMatch(npcBlock[0], /scale:\s*dialogueActive/, 'Dialogue must not resize NPCs');

console.log('Aetherwake Chapter 1 dialogue stature consistency: PASS');
