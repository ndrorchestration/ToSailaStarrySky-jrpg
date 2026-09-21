const assert = require('assert');
const defs = require('../modules/mastery-defs.js');

assert.strictEqual(defs.VERSION, '0.1.0');
assert.deepStrictEqual(
  defs.DOMAIN_FAMILY_IDS,
  ['elemental', 'arcane', 'psychic', 'spirit'],
  'major domain-family IDs changed'
);
assert.deepStrictEqual(
  defs.ENDER_SPECIAL_AFFINITY_IDS,
  ['aether', 'resonance', 'correspondence', 'lumen'],
  'Ender authored special affinities changed'
);

const enderAffinities = defs.getAuthoredAffinities('ender');
assert.strictEqual(enderAffinities.status, 'established');
assert.deepStrictEqual(
  enderAffinities.ids,
  ['aether', 'resonance', 'correspondence', 'lumen']
);

for (const id of ['lyra', 'ionia', 'reson', 'aepex']) {
  const affinity = defs.getAuthoredAffinities(id);
  assert.strictEqual(affinity.status, 'unknown',
    id + ' affinities must remain explicitly unknown');
  assert.deepStrictEqual(affinity.ids, []);

  const job = defs.getNativeJobStatus(id);
  assert.strictEqual(job.status, 'unknown',
    id + ' native job must remain explicitly unknown');
  assert.strictEqual(job.id, null);
  assert.strictEqual(job.label, null);
}

const enderJob = defs.getNativeJobStatus('ender');
assert.deepStrictEqual(enderJob, {
  status: 'established',
  id: 'rift-scholar',
  label: 'Rift Scholar',
});

assert.throws(
  () => defs.validateIdList('TEST', ['valid-id', 'valid-id']),
  /TEST_ID_DUPLICATE:valid-id/
);
assert.throws(
  () => defs.validateIdList('TEST', ['Not Valid']),
  /TEST_ID_INVALID:Not Valid/
);
assert.throws(
  () => defs.validateIdList('TEST', []),
  /TEST_MUST_BE_NONEMPTY_ARRAY/
);

assert.strictEqual(defs.validate(), true);

console.log('Aetherwake mastery definitions contract: PASS');
