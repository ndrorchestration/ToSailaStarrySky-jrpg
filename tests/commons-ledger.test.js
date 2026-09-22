const assert = require('assert');
const ledger = require('../modules/commons-ledger.js');

assert.strictEqual(ledger.VERSION, '0.1.0');
assert.strictEqual(ledger.OWNER, 'ender');
assert.strictEqual(ledger.ACCESS_MODE, 'mycelial-commons');
assert.strictEqual(ledger.MUTATION_POLICY, 'read-only');
assert.strictEqual(ledger.validate(), true);

const target = {
  id: 'test_network',
  name: 'Test Network',
  type: 'distributed-system',
  ability: 'reroute',
  abilityDesc: 'Redirects a bounded flow.',
  weakness: 'isolated relay',
  relationships: ['relay-a -> relay-b'],
  dependencies: ['relay-a'],
  exchanges: ['aether-flow'],
  obligations: ['maintain-route'],
};

const before = JSON.stringify(target);
const entry = ledger.createLedgerEntry(target);

assert.strictEqual(entry.owner, 'ender');
assert.strictEqual(entry.readOnly, true);
assert.strictEqual(entry.targetId, 'test_network');
assert.strictEqual(entry.observedAbility, 'reroute');
assert.strictEqual(entry.dependencies[0], 'relay-a');
assert.strictEqual(entry.exchanges[0], 'aether-flow');
assert.strictEqual(entry.obligations[0], 'maintain-route');
assert.deepStrictEqual(entry.unknowns, []);
assert.strictEqual(JSON.stringify(target), before,
  'Commons Ledger must not mutate the inspected target');
assert(Object.isFrozen(entry), 'ledger entry must be immutable');
assert(Object.isFrozen(entry.dependencies), 'ledger nested arrays must be immutable');

const sparse = ledger.createLedgerEntry({name:'Unknown Node'});
assert(sparse.unknowns.includes('dependencies'));
assert(sparse.unknowns.includes('relationships'));
assert(sparse.unknowns.includes('exchanges'));
assert(sparse.unknowns.includes('obligations'));
assert(sparse.unknowns.includes('observedAbility'));
assert(!ledger.summarize(sparse).includes('undefined'));

assert.throws(() => ledger.createLedgerEntry(null), /COMMONS_LEDGER_TARGET_REQUIRED/);

console.log('Aetherwake Commons Ledger contract: PASS');
