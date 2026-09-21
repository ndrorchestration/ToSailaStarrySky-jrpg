const assert = require('assert');
const roles = require('../modules/field-role-defs.js');

assert.strictEqual(roles.VERSION, '0.1.0');
assert.strictEqual(roles.PROVENANCE, 'preservation-era-prototype-mechanics');
assert.deepStrictEqual(
  roles.ORDER,
  ['skySailor', 'engineWright', 'aetherWeaver'],
  'field-role order changed'
);

const defs = roles.list();
assert.strictEqual(defs.length, 3, 'expected exactly three preservation field roles');

const sky = roles.getById('skySailor');
assert(sky && sky.name === 'Sky-Sailor');
assert.strictEqual(sky.vit, 10);
assert.strictEqual(sky.grace, 2);
assert.deepStrictEqual(
  sky.abilities.map(ability => ability.id),
  ['windShearDance', 'aetherCompass']
);

const engine = roles.getById('engineWright');
assert(engine && engine.name === 'Engine-Wright');
assert.strictEqual(engine.vit, 12);
assert.strictEqual(engine.might, 2);
assert.deepStrictEqual(
  engine.abilities.map(ability => ability.id),
  ['overdriveStrike', 'patchworkShield']
);

const weave = roles.getById('aetherWeaver');
assert(weave && weave.name === 'Aether-Weaver');
assert.strictEqual(weave.vit, 9);
assert.strictEqual(weave.spirit, 2);
assert.deepStrictEqual(
  weave.abilities.map(ability => ability.id),
  ['spiritThread', 'aetherWeave']
);

assert.strictEqual(roles.getById('unknown-role'), null);
assert.strictEqual(roles.validate(), true);

const duplicateOrder = ['skySailor', 'skySailor'];
assert.throws(
  () => roles.validateCandidate(duplicateOrder, { skySailor: sky }),
  /FIELD_ROLE_ORDER_DUPLICATE/
);

const malformed = {
  skySailor: Object.assign({}, sky, { abilities: [sky.abilities[0]] }),
};
assert.throws(
  () => roles.validateCandidate(['skySailor'], malformed),
  /FIELD_ROLE_ABILITIES_INVALID:skySailor/
);

const cloned = roles.getById('skySailor');
cloned.name = 'Changed';
assert.strictEqual(
  roles.getById('skySailor').name,
  'Sky-Sailor',
  'registry callers must not mutate frozen authority through returned objects'
);

console.log('Aetherwake preservation field-role definitions contract: PASS');
