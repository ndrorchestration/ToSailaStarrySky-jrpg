const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const statModelSource = fs.readFileSync(
  path.resolve(__dirname, '..', 'modules', 'jrpg-stat-model.js'),
  'utf8'
);
const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'modules', 'party-state.js'),
  'utf8'
);

const window = {};
vm.runInNewContext(statModelSource, { window, console });
vm.runInNewContext(source, { window, console });

const state = window.AetherPartyState;
assert(state, 'party-state API missing');
assert.strictEqual(state.balanceProfileVersion, 1);
assert.strictEqual(state.balanceStatus, 'PROVISIONAL_NOT_CANON');
assert.strictEqual(state.productionStatModelVersion, '0.1.0');

const defs = state.definitions;
assert.strictEqual(defs.length, 5);

const expected = {
  ender: { age:22, vit:13, wits:2, presence:1, spirit:1, might:-1, grace:0, role:'analyst-controller' },
  lyra: { age:24, vit:10, wits:1, presence:0, spirit:2, might:-1, grace:1, role:'perceptive-support' },
  ionia: { age:28, vit:12, wits:1, presence:2, spirit:0, might:0, grace:0, role:'captain-support' },
  reson: { age:25, vit:15, wits:0, presence:0, spirit:1, might:2, grace:0, role:'durable-weapon-specialist' },
  aepex: { age:27, vit:11, wits:2, presence:1, spirit:0, might:0, grace:0, role:'technical-specialist' },
};

for (const def of defs) {
  const e = expected[def.id];
  assert(e, 'unexpected protagonist definition: ' + def.id);
  assert.strictEqual(def.age, e.age, def.id + ' age drift');
  assert.strictEqual(def.base.vit, e.vit, def.id + ' Vit drift');
  for (const stat of ['wits','presence','spirit','might','grace']) {
    assert.strictEqual(def.base[stat], e[stat], def.id + ' ' + stat + ' drift');
  }
  const budget = def.base.wits + def.base.presence + def.base.spirit + def.base.might + def.base.grace;
  assert.strictEqual(budget, 3, def.id + ' should use the shared rank-1 attribute budget');
  assert.strictEqual(def.combatRole, e.role);
}

const ender = {
  name:'Young Ender',
  age:28,
  class:'Rift Scholar + Dreamwright',
  level:1, xp:0, xpToNext:50,
  unlockedAbilities:['uncoverTruth','sharedDream','mycelialLedger'],
  equipment:{staff:null,backpack:null},
};
state.bootstrap(ender);

assert.strictEqual(ender.name, 'Ender');
assert.strictEqual(ender.age, 22);
assert.strictEqual(ender.class, 'Rift Scholar');
assert.strictEqual(ender.nativeJob, 'Rift Scholar');
assert.strictEqual(ender.balanceStatus, 'PROVISIONAL_NOT_CANON');

for (const member of state.roster) {
  const e = expected[member.id];
  assert.strictEqual(member.canonicalName, member.name, member.id + ' canonical name must own roster identity');
  assert.strictEqual(member.age, e.age);
  assert.strictEqual(member.maxVit, e.vit);
  assert.strictEqual(member.combatRole, e.role);
  assert.strictEqual(member.balanceProfileVersion, 1);
  assert.strictEqual(member.productionStatModelVersion, '0.1.0');
  assert(member.productionStats, member.id + ' production stats missing');
}

assert.strictEqual(state.roster[0].productionStats.spirit, 12,
  'Ender production Spirit must reflect creator-directed value 12');
assert.strictEqual(state.roster[2].productionStats.presence, 9,
  'Ionia production Presence must reflect creator-directed value 9');
// Legacy compatibility fields remain intentionally unchanged until their
// remaining 2D6 actions migrate to the production formula path.
assert.strictEqual(state.roster[0].spirit, 1,
  'Ender legacy Spirit must remain compatibility-safe during migration');
assert.strictEqual(state.roster[2].presence, 2,
  'Ionia legacy Presence must remain compatibility-safe during migration');

const prototypeParty = [
  Object.assign({}, ender, {name:'Wrong Ender',age:99,class:'Rift Scholar + Dreamwright'}),
  {
    name:'Custom Companion A',age:22,class:'Engine-Wright',jobId:'engineWright',
    vit:12,maxVit:12,echoes:{current:2,max:3},wits:0,presence:2,spirit:0,might:2,grace:-1,
    scrap:5,aether:{current:3,max:6},heat:{current:0,max:3},staffCharges:1,maxStaffCharges:2,
    level:1,xp:0,xpToNext:50,unlockedAbilities:['overdriveStrike'],equipment:{staff:null,backpack:null}
  },
  {
    name:'Custom Companion B',age:22,class:'Sky-Sailor',jobId:'skySailor',
    vit:10,maxVit:10,echoes:{current:2,max:3},wits:1,presence:0,spirit:1,might:-1,grace:2,
    scrap:5,aether:{current:3,max:6},heat:{current:0,max:3},staffCharges:1,maxStaffCharges:2,
    level:1,xp:0,xpToNext:50,unlockedAbilities:['windShearDance'],equipment:{staff:null,backpack:null}
  }
];

state.commitPrototypeParty(prototypeParty);

assert.strictEqual(state.roster[0].name,'Ender');
assert.strictEqual(state.roster[0].age,22);
assert.strictEqual(state.roster[0].class,'Rift Scholar');

assert.strictEqual(state.roster[1].name,'Lyra');
assert.strictEqual(state.roster[1].age,24);
assert.strictEqual(state.roster[1].class,null);
assert.strictEqual(state.roster[1].spirit,2);
assert.strictEqual(state.roster[1].grace,1);

assert.strictEqual(state.roster[2].name,'Ionia');
assert.strictEqual(state.roster[2].age,28);
assert.strictEqual(state.roster[2].class,null);
assert.strictEqual(state.roster[2].presence,2);
assert.strictEqual(state.roster[2].vit,12);

assert.strictEqual(state.roster[3].runtimeImplemented,false,
  'Reson must remain unavailable until his action kit is implemented');
assert.strictEqual(state.roster[4].runtimeImplemented,false,
  'Aepex must remain unavailable until his action kit is implemented');

console.log('Aetherwake authored protagonist stat profiles: PASS');
