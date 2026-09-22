const assert = require('assert');
const defs = require('../modules/magic-defs.js');
const catalog = require('../modules/non-elemental-spell-trees.js');

assert.strictEqual(
  catalog.runtimeStatus,
  'STATUS_PRESERVING_DESIGN_CATALOG_NOT_EXECUTABLE'
);

const expectedIds = Object.keys(defs.NON_ELEMENTAL_DOMAINS).sort();
const actualIds = Object.keys(catalog.TREES).sort();
assert.deepStrictEqual(actualIds, expectedIds,
  'catalog must cover every registered non-elemental domain exactly once');

const spellIds = new Set();

for (const [domainId, tree] of Object.entries(catalog.TREES)) {
  const def = defs.NON_ELEMENTAL_DOMAINS[domainId];

  assert.strictEqual(tree.domainId, domainId);
  assert.strictEqual(tree.status, def.status,
    `${domainId} must preserve canonical status`);
  assert.strictEqual(tree.access, def.access,
    `${domainId} must preserve canonical access`);
  assert.strictEqual(tree.boundary, def.boundary,
    `${domainId} must preserve canonical boundary`);
  assert.ok(tree.fantasy && tree.signature);

  assert.deepStrictEqual(Object.keys(tree.ranks), ['1','2','3','4','5']);

  const roles = new Set();

  for (let rank=1; rank<=5; rank+=1) {
    const node = tree.ranks[rank];
    assert.ok(node.label);
    assert.ok(Array.isArray(node.spells) && node.spells.length >= 2,
      `${domainId} rank ${rank} must have at least two design seeds`);

    for (const spell of node.spells) {
      assert.ok(spell.id.startsWith(domainId + '.'),
        `spell/domain id mismatch: ${spell.id}`);
      assert.ok(!spellIds.has(spell.id), `duplicate spell id: ${spell.id}`);
      spellIds.add(spell.id);

      assert.ok(spell.name && spell.intent);
      assert.ok(Array.isArray(spell.roles) && spell.roles.length > 0);
      spell.roles.forEach(role => roles.add(role));

      for (const req of spell.requiresMastery || []) {
        if (req.tree) {
          assert.ok(defs.ELEMENTAL_TREES[req.tree],
            `${spell.id} references unknown elemental tree`);
        } else if (req.domain) {
          assert.ok(defs.NON_ELEMENTAL_DOMAINS[req.domain],
            `${spell.id} references unknown non-elemental domain`);
        } else {
          assert.fail(`${spell.id} has invalid mastery requirement`);
        }
        assert.ok(Number.isInteger(req.rank) && req.rank >= 1 && req.rank <= 5);
      }
    }
  }

  assert.ok(roles.size >= 4,
    `${domainId} must support broad JRPG utility; roles=${[...roles].join(',')}`);
  assert.ok(tree.ranks[5].spells.some(s => s.roles.includes('grand-art')),
    `${domainId} must contain a rank-5 Grand Art seed`);
}

assert.strictEqual(catalog.allSpells().length, spellIds.size);
assert.strictEqual(catalog.allSpells().length, expectedIds.length * 10,
  'v0.1 should contain exactly two seeds per rank across all domains');

// Status preservation: proposed domains are mapped, not promoted.
assert.strictEqual(catalog.getTree('vital').status, 'proposed');
assert.strictEqual(catalog.getTree('umbral').status, 'proposed');
assert.strictEqual(catalog.getTree('time').status, 'proposed-high-order');
assert.strictEqual(catalog.getTree('fate').status, 'proposed-high-order');
assert.strictEqual(catalog.getTree('aether').status, 'established');

// Critical conceptual boundaries.
assert.match(catalog.getTree('lumen').boundary, /not Holy/i);
assert.match(catalog.getTree('umbral').boundary, /morally neutral/i);
assert.match(catalog.getTree('time').boundary, /no casual history rewrite/i);
assert.match(catalog.getTree('fate').boundary, /not temporal flow/i);
assert.match(catalog.getTree('psychic').boundary, /not soul or fate/i);
assert.match(catalog.getTree('spirit').boundary, /not generic life energy/i);

// Dreaming remains exceptional and outside ordinary mastery.
assert.strictEqual(catalog.getTree('dreaming'), null);
assert.strictEqual(defs.EXCEPTIONAL_POWERS.dreaming.ordinaryLearnable, false);

// Specific synthesis gates.
const timeGrand = catalog.getTree('time').ranks[5].spells
  .find(s => s.id === 'time.moment_of_many_roads');
assert.ok(timeGrand.requiresMastery.some(r => r.domain === 'fate' && r.rank === 5));

const umbralGrand = catalog.getTree('umbral').ranks[5].spells
  .find(s => s.id === 'umbral.penumbra_meridian');
assert.ok(umbralGrand.requiresMastery.some(r => r.domain === 'correspondence' && r.rank === 5));

const vitalGrand = catalog.getTree('vital').ranks[5].spells
  .find(s => s.id === 'vital.phoenix_garden');
assert.ok(vitalGrand.requiresMastery.some(r => r.tree === 'fire' && r.rank === 5));

console.log('non-elemental-spell-trees contract: PASS');
console.log(JSON.stringify({
  domainCount: actualIds.length,
  spellCount: catalog.allSpells().length,
  established: actualIds.filter(id => /established/.test(catalog.getTree(id).status)).length,
  proposed: actualIds.filter(id => /proposed/.test(catalog.getTree(id).status)).length
}, null, 2));
