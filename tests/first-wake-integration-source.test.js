const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');
const handoffStart = source.indexOf('else if (gameState === STATE.CHARCREATE)');
const worldStart = source.indexOf('else if (gameState === STATE.WORLD)', handoffStart);
const handoff = source.slice(handoffStart, worldStart);
const startGameStart = source.indexOf('function startGame()');
const startCombatStart = source.indexOf('// ── Combat launcher', startGameStart);
const startGame = source.slice(startGameStart, startCombatStart);

assert.match(handoff, /commitFirstWakeParty/);
assert.doesNotMatch(handoff, /commitPrototypeParty/);
assert.match(handoff, /partyCommit\s*&&\s*partyCommit\.activeParty/);
assert.match(startGame, /start\(\{\s*mode:\s*['"]authored['"]\s*\}\)/);
assert.match(source, /AetherPartyCombat\.createController/);
assert.match(source, /activeActor\.id !== ['"]ender['"]/);
assert.match(source, /window\.__awTestEnabled/);

console.log('First Wake integration source contract: 7/7 passed');
