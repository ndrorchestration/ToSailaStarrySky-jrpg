const assert = require('assert');
const fs = require('fs');

const mastery = require('../modules/mastery-defs.js');
const magicAccess = require('../modules/magic-access.js');
const effects = require('../modules/effect-vocabulary.js');
const combatPolicy = require('../modules/combat-system-policy.js');
const admission = require('../modules/foundation-spell-admission.js');
const contracts = require('../modules/foundation-spell-contracts.js');
const pulseEval = require('../modules/aether-pulse-synthetic-evaluation.js');
const pulseReference = require('../modules/aether-pulse-runtime-reference.js');

assert.strictEqual(admission.VERSION, '0.2.0');
assert.strictEqual(contracts.VERSION, '0.2.0');
assert.deepStrictEqual(
  Array.from(contracts.DRAFT_ORDER),
  ['aetherSense', 'aetherPulse']
);
assert.strictEqual(contracts.validateAgainstMastery(mastery), true);

const senseRecord = contracts.getContract('aetherSense');
assert(senseRecord, 'Aether Sense contract evidence must exist');
assert.strictEqual(
  senseRecord.status,
  contracts.STATUS.ESTABLISHED_RUNTIME
);
assert.strictEqual(senseRecord.cost.amount, 0);
assert.strictEqual(senseRecord.cost.resource, null);
assert.strictEqual(senseRecord.mutationPolicy, 'read-only');
assert.deepStrictEqual(senseRecord.startingCharacterIds, ['ender']);
assert.deepStrictEqual(senseRecord.blockers, []);
assert.deepStrictEqual(senseRecord.legacyEvidenceBlockers, []);

const senseCandidate = contracts.getAdmissionCandidate('aetherSense');
assert(senseCandidate, 'Aether Sense admission contract must be exposed');
assert(!Object.prototype.hasOwnProperty.call(senseCandidate, 'roll'),
  'Aether Sense target contract must not carry legacy roll fields');
assert(!Object.prototype.hasOwnProperty.call(senseCandidate, 'outcomes'),
  'Aether Sense target contract must not carry legacy outcome fields');

const senseAssessment = admission.assessSpell(
  'ender',
  'aetherSense',
  senseCandidate
);
assert.strictEqual(
  senseAssessment.status,
  admission.STATUS.RUNTIME_READY
);
assert.strictEqual(senseAssessment.contractComplete, true);
assert.strictEqual(senseAssessment.executionAuthorized, true);
assert.strictEqual(senseAssessment.reason, 'ok');

const lyraSense = admission.assessSpell(
  'lyra',
  'aetherSense',
  senseCandidate
);
assert.strictEqual(lyraSense.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  lyraSense.reason,
  admission.REASON.SCHOOL_ACCESS_UNAVAILABLE
);
assert.strictEqual(lyraSense.executionAuthorized, false);

const pulse = contracts.getContract('aetherPulse');
assert(pulse, 'Aether Pulse draft must exist');
assert.strictEqual(pulse.status, contracts.STATUS.DRAFT_UNRESOLVED);
assert.strictEqual(pulse.schoolId, 'aether');
assert.strictEqual(pulse.resourceBinding, 'aether');
assert.strictEqual(pulse.mode, 'combat-jrpg-formula');
assert.strictEqual(pulse.cost.resource, 'aether');
assert.strictEqual(pulse.cost.amount, null);
assert.strictEqual(pulse.cost.status, contracts.UNKNOWN);
assert.strictEqual(pulse.resolution.status, contracts.UNKNOWN);
assert.strictEqual(pulse.resolution.model, combatPolicy.TARGET.model);
assert.strictEqual(pulse.resolution.formulaId, 'aetherPulse');
assert.strictEqual(pulse.resolution.version, null);
assert.strictEqual(pulse.resolution.kind, null);
assert.strictEqual(pulse.resolution.parameters, null);
assert.strictEqual(pulse.resolution.rngUses, null);
assert.strictEqual(pulse.targeting.status, contracts.UNKNOWN);
assert.strictEqual(pulse.targeting.mode, null);
assert.strictEqual(pulse.targeting.maxTargets, null);
assert.strictEqual(pulse.targeting.requiresExplicitTarget, null);
assert.deepStrictEqual(pulse.requiredEffectKinds, ['damage']);
assert.strictEqual(pulse.effects, null);
assert.deepStrictEqual(pulse.startingCharacterIds, []);
assert.strictEqual(contracts.getAdmissionCandidate('aetherPulse'), null);

assert.strictEqual(
  pulse.legacyResolutionEvidence.status,
  'historical-2d6-prototype-only'
);
assert.deepStrictEqual(pulse.legacyResolutionEvidence.roll, {
  system: '2d6',
  stat: contracts.UNKNOWN,
  successMin: 10,
  partialMin: 7,
  source: 'superseded-global-combat-rule',
});
for (const phase of ['common', 'success', 'partial', 'failure']) {
  assert.strictEqual(
    pulse.legacyResolutionEvidence.outcomes[phase],
    null,
    'legacy Aether Pulse outcome evidence must remain unresolved: ' + phase
  );
}

const pulseReadiness = contracts.getReadiness('aetherPulse');
assert.strictEqual(pulseReadiness.known, true);
assert.strictEqual(pulseReadiness.designComplete, false);
assert.strictEqual(pulseReadiness.runtimeEstablished, false);
assert.strictEqual(
  pulseReadiness.reason,
  'formula_contract_not_established'
);
for (const blocker of [
  contracts.BLOCKER.DESIGN_NOT_ESTABLISHED,
  contracts.BLOCKER.STARTING_OWNERSHIP_NOT_ESTABLISHED,
  contracts.BLOCKER.FORMULA_CONTRACT_NOT_SPECIFIED,
  contracts.BLOCKER.TARGETING_NOT_SPECIFIED,
  contracts.BLOCKER.EFFECT_CONTRACT_NOT_ESTABLISHED,
  contracts.BLOCKER.COST_NOT_SPECIFIED,
  contracts.BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
  contracts.BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
]) {
  assert(
    pulseReadiness.blockers.includes(blocker),
    'missing target Aether Pulse blocker: ' + blocker
  );
}
for (const blocker of [
  contracts.BLOCKER.ROLL_STAT_NOT_SPECIFIED,
  contracts.BLOCKER.COMMON_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
  contracts.BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
]) {
  assert(
    pulseReadiness.legacyEvidenceBlockers.includes(blocker),
    'missing legacy Aether Pulse evidence blocker: ' + blocker
  );
}

const missingPulseContract = admission.assessSpell(
  'ender',
  'aetherPulse',
  contracts.getAdmissionCandidate('aetherPulse')
);
assert.strictEqual(missingPulseContract.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  missingPulseContract.reason,
  admission.REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
);
assert.strictEqual(missingPulseContract.executionAuthorized, false);

function implemented(kind, target, operation, key) {
  return {
    kind,
    target,
    operation,
    key,
    runtimeStatus: effects.RUNTIME_STATUS.IMPLEMENTED,
    note: 'synthetic admission fixture only',
  };
}

// Synthetic completeness fixture: these numbers/stat choices are deliberately
// test-only. Passing structural validation must not promote Aether Pulse while
// its code-owned design/runtime status remains a proposal.
const syntheticPulseContract = {
  spellId: 'aetherPulse',
  schoolId: 'aether',
  mode: admission.MODE.COMBAT_JRPG,
  cost: {
    resource: effects.RESOURCE.AETHER,
    amount: 1,
  },
  resolution: {
    model: combatPolicy.TARGET.model,
    formulaId: 'aetherPulse',
    version: '0.0.0-test',
    kind: 'damage',
    parameters: {
      power: 1,
      scalingStat: 'wits',
      scalingCoefficient: 1,
      defenseStat: 'aetherDefense',
    },
    rngUses: [],
  },
  targeting: {
    mode: 'single-enemy',
    maxTargets: 1,
    requiresExplicitTarget: true,
  },
  effects: [
    implemented(
      effects.EFFECT_KIND.DAMAGE,
      effects.TARGET.ENEMY,
      effects.OPERATION.APPLY,
      'syntheticAetherPulse'
    ),
  ],
  mutationPolicy: 'effect-resolver',
  execution: {
    adapterId: 'synthetic-test-only',
    version: '0.0.0-test',
  },
  persistence: {
    mode: 'combat-local',
    fields: [],
  },
};

assert.strictEqual(
  admission.validateCompleteContract(
    mastery.getFoundationSpellDefinition('aetherPulse'),
    syntheticPulseContract
  ),
  true
);

const syntheticAssessment = admission.assessSpell(
  'ender',
  'aetherPulse',
  syntheticPulseContract
);
assert.strictEqual(
  syntheticAssessment.status,
  admission.STATUS.COMPLETE_NOT_AUTHORIZED
);
assert.strictEqual(syntheticAssessment.contractComplete, true);
assert.strictEqual(syntheticAssessment.executionAuthorized, false);
assert.strictEqual(
  syntheticAssessment.reason,
  'design_proposal_not_runtime_authorized'
);

const invalidCost = JSON.parse(JSON.stringify(syntheticPulseContract));
invalidCost.cost.amount = null;
const invalidAssessment = admission.assessSpell(
  'ender',
  'aetherPulse',
  invalidCost
);
assert.strictEqual(invalidAssessment.status, admission.STATUS.BLOCKED);
assert.strictEqual(
  invalidAssessment.reason,
  admission.REASON.CONTRACT_COST_INVALID
);

const legacyCandidate = JSON.parse(JSON.stringify(syntheticPulseContract));
legacyCandidate.roll = {
  system: '2d6',
  stat: 'wits',
  successMin: 10,
  partialMin: 7,
};
legacyCandidate.outcomes = {
  common: [],
  success: [],
  partial: [],
  failure: [],
};
assert.strictEqual(
  admission.assessSpell('ender', 'aetherPulse', legacyCandidate).reason,
  admission.REASON.CONTRACT_LEGACY_RESOLUTION_FORBIDDEN
);

const invalidRng = JSON.parse(JSON.stringify(syntheticPulseContract));
invalidRng.resolution.rngUses = ['success-partial-failure'];
assert.strictEqual(
  admission.assessSpell('ender', 'aetherPulse', invalidRng).reason,
  admission.REASON.CONTRACT_RESOLUTION_INVALID
);

const invalidTargeting = JSON.parse(JSON.stringify(syntheticPulseContract));
invalidTargeting.targeting.maxTargets = 0;
assert.strictEqual(
  admission.assessSpell('ender', 'aetherPulse', invalidTargeting).reason,
  admission.REASON.CONTRACT_TARGETING_INVALID
);

const missingEffects = JSON.parse(JSON.stringify(syntheticPulseContract));
missingEffects.effects = [];
assert.strictEqual(
  admission.assessSpell('ender', 'aetherPulse', missingEffects).reason,
  admission.REASON.CONTRACT_EFFECTS_INVALID
);

assert.strictEqual(
  contracts.getReadiness('notASpell').reason,
  'unknown_foundation_spell_contract'
);


// Everything below is an explicit historical/synthetic 2D6 reference suite.
// It is retained to prevent provenance drift and has no target-design authority.
assert.strictEqual(pulseEval.VERSION, '0.1.0');
assert.strictEqual(pulseEval.STATUS, 'synthetic-test-only');
assert.strictEqual(pulseEval.SPELL_ID, 'aetherPulse');
assert.strictEqual(pulseEval.SCHOOL_ID, 'aether');
assert.strictEqual(pulseEval.RESOURCE, 'aether');

function syntheticBalanceCandidate(candidateId, resourceCost, rollStat, enemyDamage, selfDamage) {
  return {
    status: pulseEval.STATUS,
    synthetic: true,
    spellId: 'aetherPulse',
    schoolId: 'aether',
    candidateId,
    resource: 'aether',
    resourceCost,
    rollStat,
    enemyDamage,
    selfDamage,
  };
}

const pulseCandidateA = syntheticBalanceCandidate(
  'TEST_ONLY_A',
  1,
  'wits',
  { success: 2, partial: 1, failure: 0 },
  { success: 0, partial: 0, failure: 1 }
);
const pulseCandidateB = syntheticBalanceCandidate(
  'TEST_ONLY_B',
  2,
  'wits',
  { success: 4, partial: 2, failure: 0 },
  { success: 0, partial: 0, failure: 0 }
);

const neutralCounts = pulseEval.getOutcomeCounts(0);
assert.deepStrictEqual(neutralCounts, {
  success: 6,
  partial: 15,
  failure: 15,
  total: 36,
});
const plusTwoCounts = pulseEval.getOutcomeCounts(2);
assert.deepStrictEqual(plusTwoCounts, {
  success: 15,
  partial: 15,
  failure: 6,
  total: 36,
});

const neutralA = pulseEval.evaluateCandidate(pulseCandidateA, 0);
assert.strictEqual(neutralA.synthetic, true);
assert.strictEqual(neutralA.designEstablished, false);
assert.strictEqual(neutralA.runtimeAuthorized, false);
assert.strictEqual(neutralA.expectedEnemyDamageNumerator, 27);
assert.strictEqual(neutralA.expectedEnemyDamage, 27 / 36);
assert.strictEqual(neutralA.expectedSelfDamageNumerator, 15);
assert.strictEqual(neutralA.expectedSelfDamage, 15 / 36);
assert.strictEqual(neutralA.expectedEnemyDamagePerAether, 27 / 36);

const plusTwoA = pulseEval.evaluateCandidate(pulseCandidateA, 2);
assert.strictEqual(plusTwoA.expectedEnemyDamageNumerator, 45);
assert.strictEqual(plusTwoA.expectedEnemyDamage, 45 / 36);
assert.strictEqual(plusTwoA.expectedSelfDamageNumerator, 6);

const neutralB = pulseEval.evaluateCandidate(pulseCandidateB, 0);
assert.strictEqual(neutralB.expectedEnemyDamageNumerator, 54);
assert.strictEqual(neutralB.expectedEnemyDamage, 54 / 36);
assert.strictEqual(neutralB.expectedEnemyDamagePerAether, 27 / 36);

const modifierSweep = pulseEval.evaluateAcrossModifiers(
  pulseCandidateA,
  [-1, 0, 1, 2, 3]
);
assert.strictEqual(modifierSweep.length, 5);
modifierSweep.forEach(result => {
  const counts = result.probabilities.counts;
  assert.strictEqual(
    counts.success + counts.partial + counts.failure,
    36,
    'every 2D6 modifier sweep must preserve the 36 exact dice outcomes'
  );
  assert.strictEqual(result.runtimeAuthorized, false);
  assert.strictEqual(result.designEstablished, false);
});

assert.throws(
  () => pulseEval.validateCandidate(Object.assign({}, pulseCandidateA, {
    synthetic: false,
  })),
  /SYNTHETIC_CANDIDATE_BOUNDARY_REQUIRED/
);
assert.throws(
  () => pulseEval.evaluateAcrossModifiers(pulseCandidateA, [0, 0]),
  /SYNTHETIC_MODIFIER_SET_DUPLICATE/
);


assert.strictEqual(pulseReference.VERSION, '0.1.0');
assert.strictEqual(pulseReference.STATUS, 'legacy-2d6-reference');

// modules/combat.js has been retired in favor of the integrated
// aetherwake.js runtime. The legacy 2D6 reference values are now
// inlined in aether-pulse-runtime-reference.js REFERENCE object.
// Verify the referentially intact values rather than the retired source.
const legacyRef = pulseReference.REFERENCE;
const enderRef = legacyRef.ender;
const enemyHpRef = legacyRef.enemyHp;
const staffStrikeRef = legacyRef.staffStrike;

assert.deepStrictEqual(enderRef, {
  wits: 2,
  might: -1,
  aetherCurrent: 4,
  aetherMax: 6,
  staffCharges: 2,
}, 'legacy ender 2D6 reference drifted');

assert.deepStrictEqual(enemyHpRef, {
  aetherLeak: 8,
  corporateSalvager: 10,
  skyPredator: 12,
  windShear: 14,
}, 'legacy enemy HP reference drifted');

assert.strictEqual(staffStrikeRef.rollSystem, '2d6');
assert.strictEqual(staffStrikeRef.stat, 'might');
assert.strictEqual(staffStrikeRef.modifier, -1);
assert.strictEqual(staffStrikeRef.registryCost, 0);
assert.strictEqual(staffStrikeRef.dedicatedResource, 'staffCharges');

const abilitySource = fs.readFileSync(
  require.resolve('../modules/ability-defs.js'),
  'utf8'
);
assert(
  abilitySource.includes("id: 'staffStrike'") &&
  abilitySource.includes("stat: 'might'") &&
  abilitySource.includes("cost: 0") &&
  abilitySource.includes("tier: 0"),
  'Staff Strike registry reference drifted'
);

assert.deepStrictEqual(pulseReference.REFERENCE.ender, {
  wits: 2,
  might: -1,
  aetherCurrent: 4,
  aetherMax: 6,
  staffCharges: 2,
});
assert.deepStrictEqual(pulseReference.REFERENCE.enemyHp, {
  aetherLeak: 8,
  corporateSalvager: 10,
  skyPredator: 12,
  windShear: 14,
});

const staffReference = pulseReference.evaluateStaffStrike();
assert.deepStrictEqual(staffReference.probabilities.counts, {
  success: 3,
  partial: 12,
  failure: 21,
  total: 36,
});
assert.strictEqual(staffReference.expectedEnemyDamage, 70.5 / 36);
assert.strictEqual(staffReference.expectedSelfDamage, 75 / 36);
assert.strictEqual(staffReference.expectedChargeConsumption, 15 / 36);
assert(
  Math.abs(staffReference.expectedEnemyDamagePerExpectedCharge - 4.7) < 1e-12,
  'charged Staff Strike expected damage-per-charge reference drifted'
);

const pulseRuntimeComparison = pulseReference.compareSyntheticPulse(
  pulseCandidateA,
  pulseReference.REFERENCE.ender.wits
);
assert.strictEqual(pulseRuntimeComparison.synthetic, true);
assert.strictEqual(pulseRuntimeComparison.designEstablished, false);
assert.strictEqual(pulseRuntimeComparison.runtimeAuthorized, false);
assert.strictEqual(
  pulseRuntimeComparison.pulse.expectedEnemyDamage,
  45 / 36
);
assert.strictEqual(
  pulseRuntimeComparison.pulse.expectedSelfDamage,
  6 / 36
);
assert.strictEqual(
  pulseRuntimeComparison.resourceEnvelope.castCapacityAtCurrentAether,
  4
);
assert.strictEqual(
  pulseRuntimeComparison.resourceEnvelope.castCapacityAtMaxAether,
  6
);
assert.strictEqual(
  pulseRuntimeComparison.resourceEnvelope.expectedDamageAtCurrentAether,
  5
);
assert.strictEqual(
  pulseRuntimeComparison.resourceEnvelope.expectedDamageAtMaxAether,
  7.5
);
assert.strictEqual(
  pulseRuntimeComparison.ratios.enemyDamageVsChargedStaff,
  (45 / 36) / (70.5 / 36)
);
assert.strictEqual(
  pulseRuntimeComparison.enemyCoverage.aetherLeak.expectedHpFractionPerCast,
  (45 / 36) / 8
);
assert.strictEqual(
  pulseRuntimeComparison.enemyCoverage.windShear.expectedHpFractionPerCast,
  (45 / 36) / 14
);
assert.strictEqual(
  pulseRuntimeComparison.boundary,
  'comparison against preservation-era 2D6 prototype only; no target design or runtime authority'
);

console.log('Aetherwake foundation spell admission gate: PASS');
console.log(JSON.stringify({
  sense: senseAssessment,
  pulse: pulseReadiness,
  syntheticPulse: syntheticAssessment,
  syntheticBalanceEvaluation: {
    neutralA,
    plusTwoA,
    neutralB,
  },
  currentRuntimeReference: {
    staffReference,
    pulseRuntimeComparison,
  },
  boundary: 'structural completeness and synthetic balance evidence never override design/runtime authorization',
}, null, 2));
