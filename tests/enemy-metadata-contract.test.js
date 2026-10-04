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
  'type: scaledTemplate.type || enemyId',
  'ability: scaledTemplate.ability || null',
  'abilities: scaledTemplate.ability ? [scaledTemplate.ability] : []',
  'abilityDesc: scaledTemplate.abilityDesc || null',
  'color: scaledTemplate.color || null',
  'bodyShape: scaledTemplate.bodyShape || null',
  'aetherDependent: scaledTemplate.aetherDependent === true',
].forEach(fragment => {
  assert(body.includes(fragment), 'encounter metadata propagation missing: ' + fragment);
});

assert(source.includes("const eType = state.enemy.type || 'generic';"),
  'enemy-turn type dispatch is missing');
assert(source.includes('const normalizedAbilityId = String(abilityId).replace'),
  'legacy enemy ability ID normalization is missing');

assert(body.includes('scaling: scaledTemplate.scaling || null'),
  'encounter scaling metadata is not exposed');

console.log('Aetherwake enemy metadata contract: PASS');

assert(source.includes("aetherDependent: true"),
  'Aether Leak Wraith template must establish explicit Aether dependence');
assert(!source.includes("engine_spirit: {\n      aetherDependent: true"),
  'Wakeheart Echo must not be inferred Aether-dependent');
