'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const statModel = require('../modules/jrpg-stat-model.js');
const formula = require('../modules/combat-formula.js');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

const chapter1Hazards = [
  { id: 'skyPredator', expectedAbility: 'diveBomb' },
  { id: 'windShear', expectedAbility: 'galeForce' },
  { id: 'aetherLeak', expectedAbility: 'drain' },
  { id: 'corporateSalvager', expectedAbility: 'contractClause' },
];

function enemyBlock(id) {
  const re = new RegExp('\\n    ' + id + ': \\{([\\s\\S]*?)\\n    \\},');
  const match = runtime.match(re);
  assert(match, 'missing Chapter 1 enemy block: ' + id);
  return match[1];
}

function numberField(block, field) {
  const match = block.match(new RegExp('(?:^|,\\s*)' + field + ':\\s*(-?\\d+)'));
  assert(match, 'missing numeric field ' + field);
  return Number(match[1]);
}

function stringField(block, field) {
  const match = block.match(new RegExp(field + ":\\s*'([^']+)'")); 
  assert(match, 'missing string field ' + field);
  return match[1];
}

function sequence(values) {
  let i = 0;
  return () => values[Math.min(i++, values.length - 1)];
}

const enderStats = statModel.getPrimaryStats('ender', 1);
assert.strictEqual(enderStats.spirit, 12, 'Chapter 1 Ender Spirit baseline must remain 12');
assert.strictEqual(enderStats.wits, 8, 'Chapter 1 Ender Wits baseline drifted');
const actor = {
  productionStats: enderStats,
  productionDerivedStats: statModel.derive(enderStats, 1),
  staffCharges: 2,
  maxStaffCharges: 2,
  heat: { current: 1, max: 3 },
  vit: 13,
  maxVit: 13,
};

const report = [];

for (const hazard of chapter1Hazards) {
  const block = enemyBlock(hazard.id);
  const hp = numberField(block, 'hp');
  const might = numberField(block, 'might');
  const presence = numberField(block, 'presence');
  const grace = numberField(block, 'grace');
  const wits = numberField(block, 'wits');
  const ability = stringField(block, 'ability');

  assert.strictEqual(ability, hazard.expectedAbility,
    hazard.id + ' lost its distinct pressure mechanic');
  assert(hp >= 8 && hp <= 18,
    hazard.id + ' HP fell outside the Chapter 1 short-encounter budget');

  const productionStats = {
    might: Math.max(1, might || 1),
    grace: Math.max(1, grace || 1),
    wits: Math.max(1, wits || 1),
    spirit: Math.max(1, presence || 1),
    presence: Math.max(1, presence || 1),
  };
  const target = {
    weakness: stringField(block, 'weakness'),
    productionDerivedStats: statModel.derive(productionStats, 1),
  };

  const normal = formula.resolveAction(
    'staffStrike', actor, target, sequence([0.5, 0.99])
  );
  const analyzedTarget = {
    ...target,
    analysis: { nextDamageMultiplier: 1.15, charges: 1 },
  };
  const analyzed = formula.resolveAction(
    'staffStrike', actor, analyzedTarget, sequence([0.5, 0.99])
  );

  assert(normal.damage >= 1, hazard.id + ' must remain damageable');
  assert(analyzed.damage >= normal.damage,
    hazard.id + ' analysis must not reduce damage');

  const normalStrikes = Math.ceil(hp / normal.damage);
  const analyzedStrikes = Math.ceil(hp / analyzed.damage);
  assert(normalStrikes >= 1 && normalStrikes <= 3,
    hazard.id + ' exceeds the Chapter 1 baseline 1-3 strike budget');
  assert(analyzedStrikes <= normalStrikes,
    hazard.id + ' analysis must not make time-to-clear worse');

  report.push({
    id: hazard.id,
    hp,
    normalDamage: normal.damage,
    analyzedDamage: analyzed.damage,
    normalStrikes,
    analyzedStrikes,
    ability,
  });
}

assert.strictEqual(new Set(report.map(entry => entry.ability)).size, 4,
  'Chapter 1 hazards must retain four distinct pressure mechanics');

console.log('Aetherwake Chapter 1 combat balance contract: PASS');
console.log(JSON.stringify(report));
