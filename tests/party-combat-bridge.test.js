const assert = require('assert');
const bridge = require('../modules/party-combat-bridge.js');
const fieldRoles = require('../modules/field-role-defs.js');

function member(id, name, templateId, overrides) {
  return Object.assign({
    id,
    canonicalName: name,
    name,
    runtimeImplemented: true,
    mechanicsTemplateId: templateId || null,
    mechanicsTemplateName: templateId
      ? fieldRoles.getById(templateId).name
      : null,
    implementationSource: id === 'ender'
      ? 'canonical-lead'
      : 'authored-identity+prototype-mechanics',
    vit: id === 'ender' ? 13 : 10,
    maxVit: id === 'ender' ? 13 : 10,
    echoes: id === 'ender' ? 3 : 2,
    echoesMax: id === 'ender' ? 3 : 2,
    aether: id === 'ender' ? 4 : 3,
    aetherMax: 6,
    heat: id === 'ender' ? 1 : 0,
    heatMax: 3,
  }, overrides || {});
}

const party = [
  member('ender', 'Ender', null),
  member('lyra', 'Lyra', 'skySailor'),
  member('ionia', 'Ionia', 'aetherWeaver'),
];

const snapshot = bridge.createSnapshot(party, fieldRoles);
assert.strictEqual(snapshot.version, '0.1.0');
assert.strictEqual(snapshot.mode, 'read-only-three-character-context');
assert.strictEqual(snapshot.leadActorId, 'ender');
assert.deepStrictEqual(snapshot.executableActorIds, ['ender']);
assert.deepStrictEqual(snapshot.members.map(x => x.id), ['ender', 'lyra', 'ionia']);

assert.strictEqual(snapshot.members[0].execution.status, 'executable-lead');
assert.deepStrictEqual(snapshot.members[0].declaredActions, []);

for (const companion of snapshot.members.slice(1)) {
  assert.strictEqual(companion.execution.status, 'declared-non-executable');
  assert.strictEqual(companion.execution.reason, 'OUTCOME_CONTRACT_NOT_ESTABLISHED');
  assert.strictEqual(companion.declaredActions.length, 2);
  assert(companion.declaredActions.every(action =>
    action.executable === false &&
    action.reason === 'OUTCOME_CONTRACT_NOT_ESTABLISHED'
  ));
}

assert.deepStrictEqual(
  snapshot.members[1].declaredActions.map(x => x.id),
  ['windShearDance', 'aetherCompass']
);
assert.deepStrictEqual(
  snapshot.members[2].declaredActions.map(x => x.id),
  ['spiritThread', 'aetherWeave']
);
assert.strictEqual(snapshot.members[1].fieldRole.provenance,
  'preservation-era-prototype-mechanics');
assert.strictEqual(bridge.validateSnapshot(snapshot), true);

// Snapshot must be detached from canonical records.
snapshot.members[1].vit = 0;
assert.strictEqual(party[1].vit, 10);

assert.throws(
  () => bridge.createSnapshot(party.slice(0, 2), fieldRoles),
  /PARTY_COMBAT_ACTIVE_PARTY_LENGTH_MUST_BE_3/
);
assert.throws(
  () => bridge.createSnapshot([party[1], party[0], party[2]], fieldRoles),
  /PARTY_COMBAT_PHASE_A_LEAD_MUST_BE_ENDER/
);
assert.throws(
  () => bridge.createSnapshot([
    party[0],
    member('reson', 'Reson', 'skySailor', { runtimeImplemented: false }),
    party[2],
  ], fieldRoles),
  /PARTY_COMBAT_ACTIVE_MEMBER_NOT_IMPLEMENTED/
);
assert.throws(
  () => bridge.createSnapshot([
    party[0],
    member('lyra', 'Lyra', 'unknownTemplate'),
    party[2],
  ], fieldRoles),
  /PARTY_COMBAT_UNKNOWN_FIELD_ROLE:lyra:unknownTemplate/
);

console.log('Aetherwake read-only party combat bridge contract: PASS');
