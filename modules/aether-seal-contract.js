/* ============================================================
   Aetherwake — Aether Seal Contract v0.1
   Design substrate for Ender's Aether / Ward technique.

   SSOT boundary:
   - Ender owns Aether affinity.
   - Aether Seal closes/suppresses unstable Aether phenomena and weakens
     explicitly Aether-dependent enemies/devices.
   - This module does not execute live combat mutations yet.
   - It must fail closed when Aether dependence is unknown.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherSealContract = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const OWNER = 'ender';
  const DOMAIN = 'aether';
  const BRANCH = 'ward';
  const STATUS = 'design-substrate-not-live';

  const DEFAULTS = Object.freeze({
    suppressionTurns: 2,
    aetherDamageTakenMultiplier: 1.15,
    aetherOutputMultiplier: 0.80,
  });

  function hasExplicitAetherDependency(target) {
    if (!target || typeof target !== 'object') return null;
    if (target.aetherDependent === true) return true;
    if (target.aetherDependent === false) return false;
    if (Array.isArray(target.tags)) {
      if (target.tags.includes('aether-dependent')) return true;
      if (target.tags.includes('not-aether-dependent')) return false;
    }
    return null;
  }

  function evaluateTarget(target) {
    if (!target || typeof target !== 'object') {
      throw new Error('AETHER_SEAL_TARGET_REQUIRED');
    }

    const dependency = hasExplicitAetherDependency(target);

    if (dependency !== true) {
      return Object.freeze({
        applicable: false,
        reason: dependency === false
          ? 'target-explicitly-not-aether-dependent'
          : 'aether-dependence-unknown',
        owner: OWNER,
        domain: DOMAIN,
        branch: BRANCH,
      });
    }

    return Object.freeze({
      applicable: true,
      reason: 'explicit-aether-dependence',
      owner: OWNER,
      domain: DOMAIN,
      branch: BRANCH,
      effect: Object.freeze({
        status: 'aether-suppressed',
        durationTurns: DEFAULTS.suppressionTurns,
        incomingAetherDamageMultiplier: DEFAULTS.aetherDamageTakenMultiplier,
        outgoingAetherEffectMultiplier: DEFAULTS.aetherOutputMultiplier,
      }),
    });
  }

  function validate() {
    if (OWNER !== 'ender') throw new Error('AETHER_SEAL_OWNER_DRIFT');
    if (DOMAIN !== 'aether') throw new Error('AETHER_SEAL_DOMAIN_DRIFT');
    if (BRANCH !== 'ward') throw new Error('AETHER_SEAL_BRANCH_DRIFT');
    if (DEFAULTS.suppressionTurns < 1 || DEFAULTS.suppressionTurns > 5) {
      throw new Error('AETHER_SEAL_DURATION_OUT_OF_BOUNDS');
    }
    if (DEFAULTS.aetherDamageTakenMultiplier <= 1 ||
        DEFAULTS.aetherDamageTakenMultiplier > 1.5) {
      throw new Error('AETHER_SEAL_INCOMING_MULTIPLIER_OUT_OF_BOUNDS');
    }
    if (DEFAULTS.aetherOutputMultiplier < 0.5 ||
        DEFAULTS.aetherOutputMultiplier >= 1) {
      throw new Error('AETHER_SEAL_OUTPUT_MULTIPLIER_OUT_OF_BOUNDS');
    }
    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    OWNER,
    DOMAIN,
    BRANCH,
    STATUS,
    DEFAULTS,
    hasExplicitAetherDependency,
    evaluateTarget,
    validate,
  });
});
