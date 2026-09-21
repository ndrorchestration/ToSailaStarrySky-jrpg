const assert = require('assert');
const mastery = require('../modules/mastery-defs.js');
const magicAccess = require('../modules/magic-access.js');
const sense = require('../modules/aether-sense.js');

assert.strictEqual(sense.VERSION, '0.1.0');
assert.strictEqual(sense.SPELL_ID, 'aetherSense');
assert.strictEqual(sense.CHARACTER_ID, 'ender');
assert.strictEqual(sense.RESOURCE_COST, 0);

const spell = mastery.getFoundationSpellDefinition('aetherSense');
assert.strictEqual(spell.designStatus, 'established');
assert.strictEqual(spell.runtimeStatus, 'integrated');
assert.deepStrictEqual(spell.startingCharacterIds, ['ender']);

const admission = magicAccess.getFoundationSpellStudyAdmission(
  'ender',
  'aetherSense'
);
assert.strictEqual(admission.canUse, true);
assert.strictEqual(admission.reason, 'ok');

const result = sense.scan(
  'ender',
  { x: 10, y: 10 },
  [
    {
      id: 'wake-core',
      label: 'Wake Core',
      kind: sense.SIGNATURE_KIND.CORE,
      intensity: sense.INTENSITY.STRONG,
      x: 23,
      y: 10,
      note: 'Engineered Aether circulation.',
    },
    {
      id: 'aether-leak',
      label: 'Aether Leak',
      kind: sense.SIGNATURE_KIND.LEAK,
      intensity: sense.INTENSITY.UNSTABLE,
      x: 14,
      y: 11,
    },
    {
      id: 'inactive-field',
      label: 'Inactive field',
      kind: sense.SIGNATURE_KIND.FIELD,
      intensity: sense.INTENSITY.FAINT,
      x: 10,
      y: 10,
      active: false,
    },
  ]
);

assert.strictEqual(result.ok, true);
assert.strictEqual(result.resourceCost, 0);
assert.strictEqual(result.detections.length, 2);
assert.deepStrictEqual(
  result.detections.map(item => item.id),
  ['aether-leak', 'wake-core'],
  'detections should be ordered nearest-first'
);
assert.strictEqual(result.detections[0].distance, 5);
assert.strictEqual(result.detections[0].direction, 'east');
assert.strictEqual(result.detections[1].distance, 13);
assert.strictEqual(result.detections[1].direction, 'east');

const summary = sense.summarize(result);
assert(summary.includes('Aether Leak'));
assert(summary.includes('Wake Core'));
assert(summary.includes('unstable'));
assert(summary.includes('strong'));

const denied = sense.scan(
  'lyra',
  { x: 0, y: 0 },
  []
);
assert.strictEqual(denied.ok, false);
assert.strictEqual(denied.reason, 'school_access_unknown');
assert.deepStrictEqual(denied.detections, []);

assert.throws(
  () => sense.scan('ender', null, []),
  /AETHER_SENSE_ORIGIN_REQUIRED/
);
assert.throws(
  () => sense.scan('ender', { x: 0, y: 0 }, [{}]),
  /AETHER_SENSE_SIGNATURE_ID_INVALID/
);
assert.throws(
  () => sense.scan('ender', { x: 0, y: 0 }, [
    {
      id: 'duplicate',
      label: 'One',
      kind: sense.SIGNATURE_KIND.DEVICE,
      intensity: sense.INTENSITY.FAINT,
      x: 1,
      y: 1,
    },
    {
      id: 'duplicate',
      label: 'Two',
      kind: sense.SIGNATURE_KIND.DEVICE,
      intensity: sense.INTENSITY.MODERATE,
      x: 2,
      y: 2,
    },
  ]),
  /AETHER_SENSE_SIGNATURE_DUPLICATE:duplicate/
);

assert.strictEqual(sense.validate(), true);

console.log('Aetherwake Aether Sense runtime contract: PASS');
console.log(JSON.stringify({
  version: sense.VERSION,
  spellId: sense.SPELL_ID,
  resourceCost: sense.RESOURCE_COST,
  sampleDetections: result.detections.map(item => ({
    id: item.id,
    distance: item.distance,
    direction: item.direction,
  })),
  boundary: 'read-only exploration sensing; no quest/combat mutation',
}, null, 2));
