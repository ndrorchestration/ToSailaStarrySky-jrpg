/* ============================================================
   Aetherwake JRPG — Target Combat System Policy v0.1
   modules/combat-system-policy.js

   This module describes the approved production combat direction.
   It does NOT replace the current legacy runtime by itself.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherCombatSystemPolicy = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  const TARGET = Object.freeze({
    model: 'jrpg-stat-formula',
    turnStructure: 'turn-based',
    visibleDice: false,
    outcomeBands: false,
    primaryResolution: 'stats+ability-formulas',
    rngRole: 'secondary-bounded',
  });

  const ALLOWED_RNG_USES = Object.freeze([
    'accuracy-evasion',
    'critical-hit',
    'status-application',
    'bounded-damage-variance',
    'enemy-ai-choice',
  ]);

  const MIGRATION = Object.freeze({
    legacyModel: '2d6-pbta-outcome-bands',
    legacyStatus: 'compatibility-only',
    preserveGameplayIntent: true,
    preserveExplicitResourceEvidence: true,
    preserveLegacyRollSemanticsAsTarget: false,
    requireNewFormulaContractBeforeAuthorization: true,
  });

  const TARGET_ABILITY_METADATA = Object.freeze([
    'targeting',
    'costs',
    'power',
    'scaling',
    'defenseInteraction',
    'elementOrType',
    'accuracyPolicy',
    'criticalPolicy',
    'variancePolicy',
    'effects',
  ]);

  function validate() {
    if (TARGET.visibleDice !== false) throw new Error('VISIBLE_DICE_MUST_BE_DISABLED');
    if (TARGET.outcomeBands !== false) throw new Error('OUTCOME_BANDS_MUST_BE_DISABLED');
    if (TARGET.primaryResolution !== 'stats+ability-formulas') {
      throw new Error('PRIMARY_RESOLUTION_POLICY_DRIFT');
    }
    if (MIGRATION.preserveLegacyRollSemanticsAsTarget !== false) {
      throw new Error('LEGACY_ROLL_SEMANTICS_MUST_NOT_BECOME_TARGET');
    }
    if (!MIGRATION.requireNewFormulaContractBeforeAuthorization) {
      throw new Error('FORMULA_CONTRACT_GATE_REQUIRED');
    }
    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    TARGET,
    ALLOWED_RNG_USES,
    MIGRATION,
    TARGET_ABILITY_METADATA,
    validate,
  });
});
