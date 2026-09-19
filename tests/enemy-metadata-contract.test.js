const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const start = source.indexOf('  this.beginEncounter = function(enemyId) {');
const end = source.indexOf('  this.resolveTurn = function(actionId, resources) {', start);
assert(start >= 0 && end > start, 'beginEncounter source boundaries not found');

const body = source.slice(start, end);
[
  'type: template.type || enemyId',
  'ability: template.ability || null',
  'abilities: template.ability ? [template.ability] : []',
  'abilityDesc: template.abilityDesc || null',
  'color: template.color || null',
  'bodyShape: template.bodyShape || null',
].forEach(fragment => {
  assert(body.includes(fragment), 'encounter metadata propagation missing: ' + fragment);
});

assert(source.includes("const eType = state.enemy.type || 'generic';"),
  'enemy-turn type dispatch is missing');
assert(source.includes('const normalizedAbilityId = String(abilityId).replace'),
  'legacy enemy ability ID normalization is missing');

console.log('Aetherwake enemy metadata contract: PASS');
