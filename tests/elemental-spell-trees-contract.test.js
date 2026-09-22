const assert = require('assert');
const defs = require('../modules/magic-defs.js');
const catalog = require('../modules/elemental-spell-trees.js');

assert.strictEqual(catalog.runtimeStatus, 'DESIGN_CATALOG_NOT_EXECUTABLE');

const expectedTreeIds = Object.keys(defs.ELEMENTAL_TREES).sort();
const actualTreeIds = Object.keys(catalog.TREES).sort();
assert.deepStrictEqual(actualTreeIds, expectedTreeIds, 'spell-tree catalog must cover every admitted elemental tree');

const seenIds = new Set();

for (const [treeId, tree] of Object.entries(catalog.TREES)) {
  assert.strictEqual(tree.treeId, treeId);
  assert.ok(tree.fantasy && tree.signature, `${treeId} missing fantasy/signature`);

  const rankKeys = Object.keys(tree.ranks);
  assert.deepStrictEqual(rankKeys, ['1','2','3','4','5'], `${treeId} must define ranks 1–5`);

  const roleSet = new Set();

  for (let rank = 1; rank <= 5; rank += 1) {
    const node = tree.ranks[rank];
    assert.ok(node.label, `${treeId} rank ${rank} missing label`);
    assert.ok(Array.isArray(node.spells) && node.spells.length >= 2,
      `${treeId} rank ${rank} should have at least two learnable seeds`);

    for (const spell of node.spells) {
      assert.ok(spell.id.startsWith(treeId + '.'), `spell id/tree mismatch: ${spell.id}`);
      assert.ok(!seenIds.has(spell.id), `duplicate spell id: ${spell.id}`);
      seenIds.add(spell.id);

      assert.ok(spell.name && spell.intent, `${spell.id} missing name/intent`);
      assert.ok(Array.isArray(spell.roles) && spell.roles.length > 0, `${spell.id} missing roles`);
      spell.roles.forEach(role => roleSet.add(role));

      for (const requirement of spell.requiresMastery || []) {
        if (requirement.tree) {
          assert.ok(defs.ELEMENTAL_TREES[requirement.tree], `${spell.id} references unknown tree`);
        } else if (requirement.domain) {
          assert.ok(defs.NON_ELEMENTAL_DOMAINS[requirement.domain], `${spell.id} references unknown domain`);
        } else {
          assert.fail(`${spell.id} has invalid mastery requirement`);
        }
        assert.ok(Number.isInteger(requirement.rank) && requirement.rank >= 1 && requirement.rank <= 5,
          `${spell.id} has invalid prerequisite rank`);
      }
    }
  }

  assert.ok(roleSet.size >= 4, `${treeId} needs broad JRPG utility, got roles: ${[...roleSet].join(',')}`);
  assert.ok(tree.ranks[5].spells.some(spell => spell.roles.includes('grand-art')),
    `${treeId} rank 5 must contain a Grand Art`);
}

const allSpells = catalog.allSpells();
assert.strictEqual(allSpells.length, seenIds.size);
assert.ok(allSpells.length >= 110, 'catalog should establish at least two abilities per rank across 11 trees');

const earth = catalog.getTree('earth');
assert.ok(
  earth.ranks[4].spells.some(spell => spell.id === 'earth.magma_vein' &&
    spell.requiresMastery.some(req => req.tree === 'fire')),
  'Magma must remain Earth with Fire prerequisite/synergy'
);
assert.ok(
  earth.ranks[4].spells.some(spell => spell.id === 'earth.vitrify'),
  'Glass/Vitrification must remain an Earth application'
);

const water = catalog.getTree('water');
assert.ok(water.ranks[4].spells.some(spell => spell.id === 'water.steam_sheath'),
  'Steam must remain a Water application');

const sonic = catalog.getTree('sonic');
assert.ok(sonic.ranks[3].spells.some(spell => spell.id === 'sonic.silence_field' &&
  /not a metaphysical anti-magic/i.test(spell.intent)),
  'Sonic must remain physically bounded rather than replacing Resonance');

const storm = catalog.getTree('storm');
assert.ok(storm.ranks[5].spells.some(spell => spell.id === 'storm.heavenbreak_tempest' &&
  spell.requiresMastery.some(req => req.tree === 'lightning' && req.rank === 5)),
  'Storm + Lightning grand synthesis must require master Lightning');

console.log('elemental-spell-trees contract: PASS');
console.log(JSON.stringify({ treeCount:actualTreeIds.length, spellCount:allSpells.length }, null, 2));
