const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const start = source.indexOf('  this.resolveTurn = function(actionId, resources) {');
const end = source.indexOf('  this.ability = function(name, target) {', start);

assert(start >= 0 && end > start, 'resolveTurn source boundaries not found');

const body = source.slice(start, end);

[
  /state\.enemy\.hp\s*[-+]?=/,
  /state\.player\.scrap\s*[-+]?=/,
  /state\.player\.staffCharges\s*(?:\+\+|--|[-+]?=)/,
  /state\.player\.(?:aether|heat|echoes)\.current\s*(?:\+\+|--|[-+]?=)/,
].forEach(pattern => {
  assert(!pattern.test(body), 'ordinary direct mutation bypasses resolver: ' + pattern);
});

const directVitAssignments = body.match(/state\.player\.vit\s*=/g) || [];
assert.strictEqual(directVitAssignments.length, 1,
  'only the explicit defeat-floor vitality assignment may remain direct');
assert(body.includes('state.player.vit = 1;'),
  'explicit defeat-floor vitality assignment missing');

assert(body.includes('applyDamage(effectVocabulary.TARGET.ENEMY'),
  'enemy damage is not routed through resolver');
assert(body.includes('applyDamage(effectVocabulary.TARGET.SELF'),
  'player damage is not routed through resolver');
assert(body.includes('applyRestore(effectVocabulary.TARGET.SELF'),
  'restoration is not routed through resolver');
assert(body.includes('changeResource(effectVocabulary.RESOURCE.'),
  'resource changes are not routed through resolver');
assert(body.includes("changeModifier('nextRoll', -pendingRollBonus);"),
  'next-roll modifier consumption is not routed through resolver');
assert(body.includes("changeModifier('nextRoll', 1);"),
  'Uncover Truth modifier grant is not routed through resolver');
assert(!/state\.player\.nextRollBonus\s*=/.test(body),
  'resolveTurn directly mutates nextRollBonus outside the resolver');

console.log('Aetherwake live resolver integration contract: PASS');
