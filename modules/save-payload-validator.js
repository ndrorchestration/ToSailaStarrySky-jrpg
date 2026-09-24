/*
 * Aetherwake — Save Payload Validator v1
 * Pure semantic preflight for gameplay payloads.
 * No live runtime state is mutated by this module.
 */
(function attach(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.AetherSavePayloadValidator = api;
}(typeof window !== 'undefined' ? window : globalThis, function createValidator() {
  'use strict';

  const VERSION = '1.0.0';
  const MAP_SIZE = 32;
  const ROSTER_IDS = Object.freeze(['ender','lyra','ionia','reson','aepex']);
  const QUEST_STATES = Object.freeze(['signal','crossing','contact','choice','wake','done']);
  const PERSISTABLE_QUEST_STATES = Object.freeze(['signal','crossing','contact','choice']);
  const CONTACT_NPC_IDS = Object.freeze(['elder_farmer','engine_spirit','child_prophet','corporate_salvager']);
  const STABLE_SCENES = Object.freeze(['world','airship']);

  function assert(condition, code) {
    if (!condition) throw new Error(code);
  }

  function isPlainObject(value) {
    return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
  }

  function finite(value, code) {
    assert(Number.isFinite(value), code);
    return value;
  }

  function integer(value, code) {
    assert(Number.isInteger(value), code);
    return value;
  }

  function validateRuntime(runtime) {
    assert(isPlainObject(runtime), 'SAVE_RUNTIME_INVALID');
    assert(STABLE_SCENES.includes(runtime.scene), 'SAVE_RUNTIME_SCENE_INVALID');
    finite(runtime.dayTime, 'SAVE_RUNTIME_DAYTIME_INVALID');
    assert(runtime.dayTime >= 0, 'SAVE_RUNTIME_DAYTIME_NEGATIVE');
    assert(typeof runtime.skyLayerVisible === 'boolean', 'SAVE_RUNTIME_SKY_LAYER_INVALID');
    finite(runtime.playtimeMs, 'SAVE_RUNTIME_PLAYTIME_INVALID');
    assert(runtime.playtimeMs >= 0, 'SAVE_RUNTIME_PLAYTIME_NEGATIVE');
    return true;
  }

  function validateWorld(world) {
    assert(isPlainObject(world), 'SAVE_WORLD_INVALID');
    const pos = world.playerPosition;
    assert(isPlainObject(pos), 'SAVE_WORLD_POSITION_INVALID');
    integer(pos.tileX, 'SAVE_WORLD_TILE_X_INVALID');
    integer(pos.tileY, 'SAVE_WORLD_TILE_Y_INVALID');
    finite(pos.px, 'SAVE_WORLD_PX_INVALID');
    finite(pos.py, 'SAVE_WORLD_PY_INVALID');
    assert(pos.tileX >= 0 && pos.tileX < MAP_SIZE, 'SAVE_WORLD_TILE_X_RANGE');
    assert(pos.tileY >= 0 && pos.tileY < MAP_SIZE, 'SAVE_WORLD_TILE_Y_RANGE');
    assert(Math.abs(pos.px - pos.tileX * 16) <= 0.001, 'SAVE_WORLD_PX_MISMATCH');
    assert(Math.abs(pos.py - pos.tileY * 16) <= 0.001, 'SAVE_WORLD_PY_MISMATCH');

    if (world.covenantField != null) {
      assert(isPlainObject(world.covenantField), 'SAVE_COVENANT_FIELD_INVALID');
      if (world.covenantField.x != null) finite(world.covenantField.x, 'SAVE_COVENANT_X_INVALID');
      if (world.covenantField.y != null) finite(world.covenantField.y, 'SAVE_COVENANT_Y_INVALID');
      if (world.covenantField.life != null) {
        finite(world.covenantField.life, 'SAVE_COVENANT_LIFE_INVALID');
        assert(world.covenantField.life >= 0, 'SAVE_COVENANT_LIFE_NEGATIVE');
      }
      if (world.covenantField.planted != null) {
        assert(typeof world.covenantField.planted === 'boolean', 'SAVE_COVENANT_PLANTED_INVALID');
      }
    }
    assert(Array.isArray(world.ledgerEntries), 'SAVE_LEDGER_INVALID');
    return true;
  }

  function validateQuest(quest) {
    assert(isPlainObject(quest), 'SAVE_QUEST_INVALID');
    assert(QUEST_STATES.includes(quest.state), 'SAVE_QUEST_STATE_INVALID');
    assert(PERSISTABLE_QUEST_STATES.includes(quest.state), 'SAVE_QUEST_STATE_NOT_PERSISTABLE');
    assert(typeof quest.act === 'string' && quest.act.length > 0, 'SAVE_QUEST_ACT_INVALID');
    integer(quest.hooksCompleted, 'SAVE_QUEST_HOOK_COUNT_INVALID');
    integer(quest.hazardsCompleted, 'SAVE_QUEST_HAZARD_COUNT_INVALID');
    assert(quest.hooksCompleted >= 0 && quest.hooksCompleted <= 3, 'SAVE_QUEST_HOOK_COUNT_RANGE');
    assert(quest.hazardsCompleted >= 0 && quest.hazardsCompleted <= 4, 'SAVE_QUEST_HAZARD_COUNT_RANGE');

    assert(Array.isArray(quest.npcsMet), 'SAVE_QUEST_NPCS_INVALID');
    assert(quest.npcsMet.length <= CONTACT_NPC_IDS.length, 'SAVE_QUEST_NPC_COUNT_RANGE');
    assert(quest.npcsMet.every(x => typeof x === 'string'), 'SAVE_QUEST_NPC_ID_INVALID');
    assert(quest.npcsMet.every(id => CONTACT_NPC_IDS.includes(id)), 'SAVE_QUEST_NPC_UNKNOWN');
    assert(new Set(quest.npcsMet).size === quest.npcsMet.length, 'SAVE_QUEST_NPC_DUPLICATE');

    for (const [key, min, max] of [
      ['hullIntegrity',0,100],
      ['morale',0,100],
      ['heatLevel',0,100],
      ['engineIntegration',0,100],
    ]) {
      finite(quest[key], 'SAVE_QUEST_' + key.toUpperCase() + '_INVALID');
      assert(quest[key] >= min && quest[key] <= max, 'SAVE_QUEST_' + key.toUpperCase() + '_RANGE');
    }

    assert(Array.isArray(quest.discoveries), 'SAVE_QUEST_DISCOVERIES_INVALID');
    assert(Array.isArray(quest.journal), 'SAVE_QUEST_JOURNAL_INVALID');
    assert(Array.isArray(quest.signalHooks), 'SAVE_QUEST_SIGNAL_HOOKS_INVALID');
    assert(Array.isArray(quest.crossingHazards), 'SAVE_QUEST_CROSSING_HAZARDS_INVALID');
    assert(quest.signalHooks.length === 3, 'SAVE_QUEST_SIGNAL_HOOK_COUNT_DRIFT');
    assert(quest.crossingHazards.length === 4, 'SAVE_QUEST_CROSSING_HAZARD_COUNT_DRIFT');

    const doneHooks = quest.signalHooks.filter(x => x && x.done === true).length;
    const doneHazards = quest.crossingHazards.filter(x => x && x.done === true).length;
    assert(doneHooks === quest.hooksCompleted, 'SAVE_QUEST_HOOK_COUNTER_MISMATCH');
    assert(doneHazards === quest.hazardsCompleted, 'SAVE_QUEST_HAZARD_COUNTER_MISMATCH');

    if (quest.choiceMade != null) assert(typeof quest.choiceMade === 'string', 'SAVE_QUEST_CHOICE_INVALID');
    if (quest.choicePath != null) assert(['path_a','path_b','path_c'].includes(quest.choicePath), 'SAVE_QUEST_CHOICE_PATH_INVALID');
    if (quest.wakeEpilogueId != null) assert(typeof quest.wakeEpilogueId === 'string', 'SAVE_QUEST_EPILOGUE_INVALID');
    return true;
  }

  function validateCharacter(record, expectedId) {
    assert(isPlainObject(record), 'SAVE_PARTY_RECORD_INVALID');
    assert(record.id === expectedId, 'SAVE_PARTY_IDENTITY_MISMATCH');
    if (record.level != null) {
      integer(record.level, 'SAVE_PARTY_LEVEL_INVALID:' + expectedId);
      assert(record.level >= 1 && record.level <= 200, 'SAVE_PARTY_LEVEL_RANGE:' + expectedId);
    }
    for (const key of ['vit','maxVit','aether','aetherMax','heat','heatMax','echoes','echoesMax','scrap']) {
      if (record[key] != null) {
        finite(record[key], 'SAVE_PARTY_RESOURCE_INVALID:' + expectedId + ':' + key);
        assert(record[key] >= 0, 'SAVE_PARTY_RESOURCE_NEGATIVE:' + expectedId + ':' + key);
      }
    }
    if (record.vit != null && record.maxVit != null) assert(record.vit <= record.maxVit, 'SAVE_PARTY_VIT_OVER_MAX:' + expectedId);
    if (record.aether != null && record.aetherMax != null) assert(record.aether <= record.aetherMax, 'SAVE_PARTY_AETHER_OVER_MAX:' + expectedId);
    if (record.heat != null && record.heatMax != null) assert(record.heat <= record.heatMax, 'SAVE_PARTY_HEAT_OVER_MAX:' + expectedId);
    if (record.echoes != null && record.echoesMax != null) assert(record.echoes <= record.echoesMax, 'SAVE_PARTY_ECHOES_OVER_MAX:' + expectedId);
    return true;
  }

  function validateParty(party) {
    assert(isPlainObject(party), 'SAVE_PARTY_INVALID');
    assert(Array.isArray(party.roster), 'SAVE_PARTY_ROSTER_INVALID');
    assert(party.roster.length === ROSTER_IDS.length, 'SAVE_PARTY_ROSTER_COUNT_INVALID');
    party.roster.forEach((record, index) => validateCharacter(record, ROSTER_IDS[index]));

    assert(Array.isArray(party.activeIds), 'SAVE_PARTY_ACTIVE_IDS_INVALID');
    assert(party.activeIds.length >= 1 && party.activeIds.length <= 5, 'SAVE_PARTY_ACTIVE_COUNT_INVALID');
    assert(new Set(party.activeIds).size === party.activeIds.length, 'SAVE_PARTY_ACTIVE_DUPLICATE');
    assert(party.activeIds.every(id => ROSTER_IDS.includes(id)), 'SAVE_PARTY_ACTIVE_UNKNOWN');

    party.roster.forEach(record => {
      assert(typeof record.playable === 'boolean', 'SAVE_PARTY_PLAYABLE_FLAG_INVALID:' + record.id);
    });
    for (const id of party.activeIds) {
      const record = party.roster.find(entry => entry.id === id);
      assert(record && record.playable === true, 'SAVE_PARTY_ACTIVE_NOT_PLAYABLE:' + id);
    }
    return true;
  }

  function validateAirNavigation(airNavigation, context) {
    if (airNavigation == null) return true;
    assert(isPlainObject(airNavigation), 'SAVE_AIR_NAV_INVALID');
    assert(context && typeof context.validateAirNavigation === 'function', 'SAVE_AIR_NAV_VALIDATOR_REQUIRED');
    context.validateAirNavigation(airNavigation);
    return true;
  }

  function validatePayload(payload, context) {
    assert(isPlainObject(payload), 'SAVE_PAYLOAD_SEMANTIC_INVALID');
    validateRuntime(payload.runtime);
    validateWorld(payload.world);
    validateQuest(payload.quest);
    validateParty(payload.party);
    validateAirNavigation(payload.airNavigation, context || null);
    if (payload.runtime.scene === 'airship') {
      assert(payload.airNavigation != null, 'SAVE_AIRSHIP_STATE_MISSING');
    }
    return true;
  }

  return Object.freeze({
    VERSION,
    MAP_SIZE,
    ROSTER_IDS: ROSTER_IDS.slice(),
    QUEST_STATES: QUEST_STATES.slice(),
    PERSISTABLE_QUEST_STATES: PERSISTABLE_QUEST_STATES.slice(),
    CONTACT_NPC_IDS: CONTACT_NPC_IDS.slice(),
    STABLE_SCENES: STABLE_SCENES.slice(),
    validatePayload,
    validateRuntime,
    validateWorld,
    validateQuest,
    validateParty,
    validateAirNavigation,
  });
}));