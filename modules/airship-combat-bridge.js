/*
 * Aetherwake — Dragonfly combat handoff
 *
 * Converts one-shot airship systems into a small, deterministic combat
 * modifier object. It is renderer-free so the contract can be tested in Node.
 */
(function attachAirshipCombatBridge(root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.AetherAirshipCombatBridge = factory();
  }
}(typeof window !== 'undefined' ? window : globalThis, function createAirshipCombatBridge() {
  'use strict';

  const VERSION = '0.1.0';
  const VALID_MODES = ['guard', 'slip', 'resonance'];

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
  }

  function normalizeMode(mode) {
    return VALID_MODES.includes(mode) ? mode : 'guard';
  }

  function numeric(value, fallback) {
    return Number.isFinite(Number(value)) ? Number(value) : fallback;
  }

  function createTransfer(inputState) {
    const state = inputState || {};
    const pending = state.pendingCombat || {};

    return {
      shipId: state.shipId || null,
      classId: state.classId || null,
      shieldMode: normalizeMode(state.shieldMode),
      phaseSlipReady: Boolean(pending.phaseSlip),
      resonanceLanceDamage: clamp(
        numeric(pending.resonanceLanceDamage, 0),
        0,
        30
      ),
    };
  }

  function consumeTransfer(inputState) {
    const state = clone(inputState || {});
    const transfer = createTransfer(inputState);

    state.pendingCombat = Object.assign(
      { phaseSlip: false, resonanceLanceDamage: 0 },
      state.pendingCombat || {}
    );
    state.pendingCombat.phaseSlip = false;
    state.pendingCombat.resonanceLanceDamage = 0;

    return { state, transfer };
  }

  function createCombatModifiers(inputTransfer) {
    const transfer = inputTransfer || {};
    const shieldMode = normalizeMode(transfer.shieldMode);
    const phaseSlipReady = Boolean(transfer.phaseSlipReady);

    return {
      shipId: transfer.shipId || null,
      classId: transfer.classId || null,
      shieldMode,
      phaseSlipReady,
      // A Slip veil is a second, weaker phase window when the drive was not
      // explicitly fired before the encounter.
      slipVeilReady: shieldMode === 'slip',
      guardAbsorption: shieldMode === 'guard' ? 1 : 0,
      firstRollBonus: shieldMode === 'resonance' ? 1 : 0,
      // Integrity damage is intentionally compressed into the combat scale:
      // 24-30 ship points becomes a bounded 3-4 opening strike.
      openingLanceDamage: clamp(
        Math.ceil(numeric(transfer.resonanceLanceDamage, 0) / 8),
        0,
        4
      ),
    };
  }

  function mitigateIncomingDamage(inputModifiers, requestedDamage) {
    const modifiers = Object.assign({}, inputModifiers || {});
    const requested = Math.max(0, Math.floor(numeric(requestedDamage, 0)));
    let damage = requested;
    let event = null;

    if (requested > 0 && modifiers.phaseSlipReady) {
      damage = 0;
      modifiers.phaseSlipReady = false;
      event = 'phaseSlip';
    } else if (requested > 0 && modifiers.slipVeilReady) {
      damage = 0;
      modifiers.slipVeilReady = false;
      event = 'slip';
    } else if (requested > 0 && modifiers.guardAbsorption > 0) {
      const absorbed = Math.min(requested, modifiers.guardAbsorption);
      damage = requested - absorbed;
      modifiers.guardAbsorption = 0;
      event = 'guard';
    }

    return {
      modifiers,
      requested,
      damage,
      event,
    };
  }

  return {
    VERSION,
    createTransfer,
    consumeTransfer,
    createCombatModifiers,
    mitigateIncomingDamage,
  };
}));
