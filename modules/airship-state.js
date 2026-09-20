/*
 * Aetherwake — Dragonfly-class airship state
 *
 * The module is deliberately independent of p5.js so the ship's resource
 * rules can be verified without booting the renderer. Browser builds receive
 * window.AetherAirshipState; Node contract tests receive module.exports.
 */
(function attachAirshipState(root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.AetherAirshipState = factory();
  }
}(typeof window !== 'undefined' ? window : globalThis, function createAirshipApi() {
  'use strict';

  const VERSION = '0.1.0';
  const SHIELD_MODES = ['guard', 'slip', 'resonance'];

  const SHIELD_PROFILES = {
    guard: {
      id: 'guard',
      label: 'GUARD',
      description: 'Dampens incoming force around the three-container hull.',
      phaseSlipCost: 3,
      lanceDamage: 24,
    },
    slip: {
      id: 'slip',
      label: 'SLIP',
      description: 'Thins the veil to let the Wake shear through hostile space.',
      phaseSlipCost: 2,
      lanceDamage: 24,
    },
    resonance: {
      id: 'resonance',
      label: 'RESONANCE',
      description: 'Turns the veil into a listening array for precise strikes.',
      phaseSlipCost: 3,
      lanceDamage: 30,
    },
  };

  const SYSTEM_DEFINITIONS = [
    {
      id: 'phaseSlip',
      label: 'PHASE-SLIP WAKE DRIVE',
      shortLabel: 'PHASE-SLIP',
      description: 'Fold the Wake across a short broken sky-lane.',
      powerCost: 3,
      chargeKey: 'driveCharges',
      cooldown: 2,
    },
    {
      id: 'harmonicVeil',
      label: 'HARMONIC PHASE VEIL',
      shortLabel: 'VEIL MODE',
      description: 'Cycle the multiphasic defense profile around the hull.',
      powerCost: 0,
      chargeKey: null,
      cooldown: 0,
    },
    {
      id: 'resonanceLance',
      label: 'RESONANCE LANCE',
      shortLabel: 'LANCE',
      description: 'Focus the Wakeheart into a narrow aetheric strike.',
      powerCost: 2,
      chargeKey: 'lanceCharges',
      cooldown: 1,
    },
    {
      id: 'rootlineTether',
      label: 'ROOTLINE TETHER',
      shortLabel: 'TETHER',
      description: 'Anchor the ship to a stable frequency and restore phase integrity.',
      powerCost: 1,
      chargeKey: 'tetherCharges',
      cooldown: 2,
    },
    {
      id: 'patternForge',
      label: 'PATTERN FORGE',
      shortLabel: 'FORGE',
      description: 'Reweave damaged hull plating from stored matter-patterns.',
      powerCost: 2,
      chargeKey: 'forgeCharges',
      cooldown: 3,
    },
  ];

  const DEFAULT_STATE = {
    shipId: 'aureate-wake',
    classId: 'dragonfly-wake',
    hullVolumeContainers: 3,
    power: 6,
    maxPower: 6,
    hull: 100,
    maxHull: 100,
    phaseIntegrity: 100,
    maxPhaseIntegrity: 100,
    shieldMode: 'guard',
    driveCharges: 3,
    lanceCharges: 2,
    tetherCharges: 2,
    forgeCharges: 2,
    heat: 0,
    maxHeat: 4,
    targetIntegrity: 100,
    cooldowns: {
      phaseSlip: 0,
      resonanceLance: 0,
      rootlineTether: 0,
      patternForge: 0,
    },
    lastAction: null,
    lastMessage: 'Wakeheart online. Dragonfly frame holding.',
    log: ['Wakeheart online. Dragonfly frame holding.'],
  };

  function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
  }

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function appendLog(state, message) {
    state.lastMessage = message;
    state.log = state.log.concat(message).slice(-12);
  }

  function createState(overrides) {
    const input = overrides || {};
    const state = Object.assign({}, clone(DEFAULT_STATE), clone(input));
    state.cooldowns = Object.assign(
      {},
      clone(DEFAULT_STATE.cooldowns),
      clone(input.cooldowns || {})
    );
    state.log = Array.isArray(input.log)
      ? input.log.slice()
      : clone(DEFAULT_STATE.log);
    state.power = clamp(state.power, 0, state.maxPower);
    state.hull = clamp(state.hull, 0, state.maxHull);
    state.phaseIntegrity = clamp(state.phaseIntegrity, 0, state.maxPhaseIntegrity);
    state.heat = clamp(state.heat, 0, state.maxHeat);
    return state;
  }

  function getSystemDefinitions() {
    return SYSTEM_DEFINITIONS.map(system => Object.assign({}, system));
  }

  function getShieldProfile(mode) {
    const profile = SHIELD_PROFILES[mode] || SHIELD_PROFILES.guard;
    return Object.assign({}, profile);
  }

  function cycleShieldMode(inputState) {
    const state = createState(inputState);
    const currentIndex = SHIELD_MODES.indexOf(state.shieldMode);
    const nextMode = SHIELD_MODES[(currentIndex + 1) % SHIELD_MODES.length];
    state.shieldMode = nextMode;
    appendLog(state, 'Harmonic veil shifted to ' + getShieldProfile(nextMode).label + '.');
    return {
      ok: true,
      state,
      mode: nextMode,
      message: state.lastMessage,
    };
  }

  function reject(state, message) {
    appendLog(state, message);
    return { ok: false, state, message };
  }

  function resolveAction(inputState, actionId) {
    const state = createState(inputState);

    if (actionId === 'ventWake') {
      Object.keys(state.cooldowns).forEach(key => {
        state.cooldowns[key] = Math.max(0, state.cooldowns[key] - 1);
      });
      state.power = clamp(state.power + 1, 0, state.maxPower);
      state.heat = Math.max(0, state.heat - 2);
      state.lastAction = actionId;
      appendLog(state, 'Wakeheart vented. One power cell returned; cooldowns advanced.');
      return { ok: true, state, message: state.lastMessage };
    }

    const system = SYSTEM_DEFINITIONS.find(entry => entry.id === actionId);
    if (!system || system.id === 'harmonicVeil') {
      return reject(state, 'Unknown or non-actionable airship system: ' + actionId + '.');
    }

    const cooldown = state.cooldowns[actionId] || 0;
    if (cooldown > 0) {
      return reject(state, system.shortLabel + ' is cooling for ' + cooldown + ' cycle(s).');
    }

    const profile = getShieldProfile(state.shieldMode);
    const powerCost = actionId === 'phaseSlip' ? profile.phaseSlipCost : system.powerCost;
    if (state.power < powerCost) {
      return reject(state, system.shortLabel + ' rejected: insufficient Wakeheart power.');
    }

    if (system.chargeKey && state[system.chargeKey] <= 0) {
      return reject(state, system.shortLabel + ' rejected: no charges remain.');
    }

    state.power -= powerCost;
    if (system.chargeKey) state[system.chargeKey] -= 1;
    state.cooldowns[actionId] = system.cooldown;
    state.lastAction = actionId;

    if (actionId === 'phaseSlip') {
      state.phaseIntegrity = clamp(state.phaseIntegrity - 8, 0, state.maxPhaseIntegrity);
      appendLog(state, 'Phase-slip wake engaged. The Dragonfly crossed a broken sky-lane.');
    } else if (actionId === 'resonanceLance') {
      state.heat = clamp(state.heat + 2, 0, state.maxHeat);
      state.targetIntegrity = clamp(
        state.targetIntegrity - profile.lanceDamage,
        0,
        100
      );
      appendLog(state, 'Resonance Lance fired through the ' + profile.label + ' veil.');
    } else if (actionId === 'rootlineTether') {
      state.phaseIntegrity = clamp(state.phaseIntegrity + 22, 0, state.maxPhaseIntegrity);
      appendLog(state, 'Rootline Tether found a stable note and restored phase integrity.');
    } else if (actionId === 'patternForge') {
      state.hull = clamp(state.hull + 16, 0, state.maxHull);
      appendLog(state, 'Pattern Forge reknit the Dragonfly hull from stored matter.');
    }

    return { ok: true, state, message: state.lastMessage };
  }

  return {
    VERSION,
    SHIELD_MODES: SHIELD_MODES.slice(),
    createState,
    getSystemDefinitions,
    getShieldProfile,
    cycleShieldMode,
    resolveAction,
  };
}));
