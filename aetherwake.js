Warning: truncated output (original token count: 85630)
Total output lines: 9691

// === modules/core.js ===
// ============================================================
// Aetherwake JRPG — Main p5.js Sketch (GLOBAL MODE)
// ============================================================
// Single-file HTML: index.html loads p5.js CDN then this script.
// All modules use bare p5 globals — this sketch does too.
// ============================================================

// ── Palette ──
const C = {
  teal:     [42, 255, 181],
  scioto:   [124, 200, 232],
  navy:     [26, 16, 46],
  parchment:[232, 220, 198],
  dusttan:  [210, 180, 140],
  rust:     [180, 90, 50],
  soil:     [120, 90, 60],
  biolum:   [80, 240, 160],
  rose:     [220, 120, 160],
  shad:     [60, 50, 60],   // dark gray-violet for shadow fills (char-create module expects this)
  dim:      [80, 70, 90],   // muted blue-gray for labels/indicators (char-create module expects this)
};

// ── State ──
const STATE = {
  BOOT: 'boot', MENU: 'menu', WORLD: 'world', COMBAT: 'combat',
  DIALOGUE: 'dialogue', SHOP: 'shop', LEDGER: 'ledger',
  QUESTLOG: 'questlog', CHARSHEET: 'charsheet', AIRSHIP: 'airship',
  SAVELOAD: 'saveload', OPENING: 'opening', CHARCREATE: 'charcreate', PREVIEW_END: 'preview-end',
};
let gameState = STATE.BOOT;
window.gameState = gameState;  // expose for debug
let prevState = null;
// Overlay states need their own return target. `prevState` is updated every
// frame for transition effects, so it cannot safely carry the state beneath
// an overlay.
let overlayReturnState = null;

// Boot sequence timing
let bootTime = 0;
const BOOT_LOAD_MS = 1200;   // loading-only motion may advance autonomously
const PREAMBLE_PAGE_MIN_MS = 650; // prevents accidental double-tap skips between story pages
let preambleStart = 0;
let preamblePage = 0;
let preamblePageShownAt = 0;
const PREAMBLE_PAGES = Object.freeze([
  Object.freeze([
    'A ship above a broken world.',
    'A core that has begun to sing wrong.',
  ]),
  Object.freeze([
    'Below, the copper ground is tired — rusted, cracked,',
    'choking on its own dust.',
    'Above, the sky-lanes are still open.',
  ]),
  Object.freeze([
    'For three hundred years, the aether-cores',
    'kept the arcologies aloft.',
    'Now the cores are failing.',
  ]),
  Object.freeze([
    'You are Ender.',
    'Deckhand. Engineer-in-training.',
    'You carry a wrench, a passport, and a decision',
    'you have not yet admitted you have to make.',
  ]),
  Object.freeze([
    "The Aureate Wake's core is singing wrong.",
    'Something has to be done about that.',
  ]),
]);
let titleVisible = 0;        // 0..1 fade-in for title
let titleFlash = 0;          // flash effect on title

// ── Screen shake (combat / impact) ──
let shake = { intensity: 0, duration: 0, startTime: 0 };

// ── Hit stop / freeze frames (critical hits) ──
let hitStop = { active: false, remaining: 0 };

// ── Screen fade transitions ──
let fade = { active: false, from: null, to: null, startTime: 0, duration: 400, alpha: 0 };

// ── UI polish state (Memories adaptation patterns) ──
// panelOpenness: window slide-open animation progress (0-255)
let panelOpenness = 0;
// uiWindowTone: panel ambiance tint accumulator for scene-state shifts
let uiWindowTone = 0;
// lastCmdIdx: last-chosen menu command index for last-command memory
let lastCmdIdx = -1;

// ── Dialogue type-in ──
let dialogueTypeIn = { active: false, fullText: '', displayText: '', charIndex: 0, speed: 22, lastCharTime: 0 };

// ── Global visual settings ──
const VIS = {
  screenShake: true,
  hitStop: true,
  fadeTransitions: true,
  dialogueTypeIn: true,
  vignette: true,
  particles: true,
  hudAnimations: true,
};

// ── Toast messages ──
window.toasts = [];

// Floating islands for title parallax (recreated for boot seq)
const titleIslands = [];
for (let i = 0; i < 14; i++) {
  titleIslands.push({
    x: (i * 23 + 7) % 60,
    y: 30 + (i * 17) % 200,
    size: 18 + (i % 5) * 4,
    speed: 0.3 + (i % 3) * 0.2,
    drift: (i % 7) * 0.7 - 3.5,
  });
}

// Module references (set after loading)
let world = null;
let combat = null;
let airNavigationState = null;
let combatReturnState = STATE.WORLD;
let pendingHazardIndex = null;

// Preview 0.1 is intentionally bounded: authored opening -> Ionia -> one combat -> end card.
let previewEncounterArmed = false;
let previewEncounterStarted = false;
let previewEncounterFinished = false;
let previewEndAt = 0;
let saveMenuMode = 'save';
let saveMenuIndex = 0;
let saveMenuReturnState = STATE.WORLD;
let pendingAutosaveReason = null;

// Expose state for debugging
window.gameState = gameState;

// Timing
let lastTime = 0;
let dt = 0;
let loadedPlaytimeMs = 0;
let playSessionStartMs = 0;

// Input
const keys = {};
const keysPressed = {};
const keyRepeat = {};
const keyRepeatFirst = {};

// ── setup() ──
function setup() {
  window._setupOrder = window._setupOrder ? window._setupOrder + '→setup-start' : 'setup-start';
  const canvas = createCanvas(960, 640);
  window._setupOrder = window._setupOrder + '→canvas-done';
  // Now proceed with normal setup
  frameRate(60);
  pixelDensity(1);
  colorMode(RGB, 255);
  textFont('Segoe UI');
  textSize(16);
  textLeading(20);
  if (typeof document !== 'undefined' && document.fonts) {
    document.fonts.ready.then(function() {
      var ok = document.fonts.check('16px VT323');
      if (!ok) console.warn('FONT FALLBACK: VT323 not loaded; text will render in system default.');
    });
  }
  randomSeed(42);
  noiseSeed(42);

  window._setupOrder = window._setupOrder + '→world-start';
  if (typeof window.AetherWorld !== 'undefined') {
    world = window.AetherWorld(p5, C);
    window._world = world;
    if (world && typeof world.init === 'function') world.init();
  }
  if (!world || !world.player) {
    throw new Error('WORLD_PLAYER_UNAVAILABLE_FOR_PARTY_STATE');
  }
  if (!window.AetherPartyState || typeof window.AetherPartyState.bootstrap !== 'function') {
    throw new Error('AETHER_PARTY_STATE_UNAVAILABLE');
  }
  window.AetherPartyState.bootstrap(world.player);
  if (!window.AetherFirstWakeOpening ||
      typeof window.AetherFirstWakeOpening.createState !== 'function' ||
      typeof window.AetherFirstWakeOpening.validate !== 'function') {
    throw new Error('AETHER_FIRST_WAKE_OPENING_UNAVAILABLE');
  }
  window.AetherFirstWakeOpening.validate();
  window._firstWakeOpeningState = window.AetherFirstWakeOpening.createState();
  if (!window.AetherCombatSystemPolicy ||
      typeof window.AetherCombatSystemPolicy.validate !== 'function') {
    throw new Error('AETHER_COMBAT_SYSTEM_POLICY_UNAVAILABLE');
  }
  window.AetherCombatSystemPolicy.validate();
  if (!window.AetherCombatFormula ||
      typeof window.AetherCombatFormula.resolveAction !== 'function' ||
      typeof window.AetherCombatFormula.validateAgainstAbilityDefs !== 'function') {
    throw new Error('AETHER_COMBAT_FORMULA_UNAVAILABLE');
  }
  window.AetherCombatFormula.validateAgainstAbilityDefs(window.AetherAbilityDefs);
  window._combatSystemPolicy = window.AetherCombatSystemPolicy;
  window._combatFormula = window.AetherCombatFormula;
  if (!window.AetherCommonsLedger ||
      typeof window.AetherCommonsLedger.createLedgerEntry !== 'function' ||
      typeof window.AetherCommonsLedger.validate !== 'function') {
    throw new Error('AETHER_COMMONS_LEDGER_UNAVAILABLE');
  }
  window.AetherCommonsLedger.validate();
  window._commonsLedger = window.AetherCommonsLedger;
  if (!window.AetherSealContract ||
      typeof window.AetherSealContract.evaluateTarget !== 'function' ||
      typeof window.AetherSealContract.validate !== 'function') {
    throw new Error('AETHER_SEAL_CONTRACT_UNAVAILABLE');
  }
  window.AetherSealContract.validate();
  window._aetherSealContract = window.AetherSealContract;
  if (!window.AetherAirNavigation || typeof window.AetherAirNavigation.createState !== 'function') {
    throw new Error('AETHER_AIR_NAVIGATION_UNAVAILABLE');
  }
  airNavigationState = window.AetherAirNavigation.createState({
    mooredLandmarkId: 'wake-dock',
    speed: 0,
  });
  window._airNavigation = window.AetherAirNavigation;
  window._airNavigationState = airNavigationState;
  if (!window.AetherSaveSystem ||
      typeof window.AetherSaveSystem.save !== 'function' ||
      typeof window.AetherSaveSystem.load !== 'function') {
    throw new Error('AETHER_SAVE_SYSTEM_UNAVAILABLE');
  }
  if (!window.AetherSavePayloadValidator ||
      typeof window.AetherSavePayloadValidator.validatePayload !== 'function') {
    throw new Error('AETHER_SAVE_PAYLOAD_VALIDATOR_UNAVAILABLE');
  }
  // Foundation-only exposure. Live snapshot/restore hooks are intentionally
  // added in a later bounded tranche after this module seam is verified.
  window._saveSystem = window.AetherSaveSystem;
  window._savePayloadValidator = window.AetherSavePayloadValidator;
  window._setupOrder = window._setupOrder + '→party-state-done';
  window._setupOrder = window._setupOrder + '→combat-start';
  if (typeof window.AetherCombat !== 'undefined') {
    combat = new window.AetherCombat(window, C);
    window._combat = combat;
    if (combat && typeof combat.init === 'function') combat.init();
  }
  window._setupOrder = window._setupOrder + '→combat-done';
  // Character creation module (if present — loaded via index-embedded.html <script>)
  if (typeof window.AetherCharCreate !== 'undefined') {
    window._charcreate = window.AetherCharCreate;
    if (window._charcreate && typeof window._charcreate.init === 'function') window._charcreate.init();
    window._setupOrder = window._setupOrder + '→charcreate-done';
  }
  window._setupOrder = window._setupOrder + '→setup-done';
  lastTime = millis();
  playSessionStartMs = lastTime;
  window.__awRuntimeReady = true;
}

function cloneSaveJson(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function currentPlaytimeMs() {
  const now = typeof millis === 'function' ? millis() : 0;
  return Math.max(0, loadedPlaytimeMs + Math.max(0, now - playSessionStartMs));
}

function canSnapshotPersistentState() {
  if (gameState !== STATE.WORLD && gameState !== STATE.AIRSHIP) return false;
  if (!world || typeof world.getQuestState !== 'function') return false;
  const questState = world.getQuestState();
  return Boolean(
    questState &&
    ['signal', 'crossing', 'contact', 'choice'].includes(questState.state)
  );
}

function buildSavePayload() {
  if (!canSnapshotPersistentState()) {
    throw new Error('SAVE_NOT_ALLOWED_IN_CURRENT_STATE');
  }
  if (!world || typeof world.snapshotPersistentState !== 'function') {
    throw new Error('WORLD_PERSISTENCE_SNAPSHOT_UNAVAILABLE');
  }
  const worldSnapshot = world.snapshotPersistentState();
  const payload = {
    runtime: {
      scene: gameState === STATE.AIRSHIP ? STATE.AIRSHIP : STATE.WORLD,
      dayTime: worldSnapshot.runtime.dayTime,
      skyLayerVisible: worldSnapshot.runtime.skyLayerVisible,
      playtimeMs: currentPlaytimeMs(),
    },
    world: worldSnapshot.world,
    quest: worldSnapshot.quest,
    party: {
      roster: Array.isArray(window.ROSTER)
        ? window.ROSTER.map(character => cloneSaveJson(character))
        : [],
      activeIds: Array.isArray(window.ACTIVE_PARTY)
        ? window.ACTIVE_PARTY.map(character => character.id)
        : [],
    },
    airNavigation: window.AetherAirNavigation && airNavigationState
      ? window.AetherAirNavigation.exportPersistentState(airNavigationState)
      : null,
  };

  window.AetherSavePayloadValidator.validatePayload(payload, {
    validateAirNavigation(candidate) {
      return window.AetherAirNavigation.validatePersistentState(candidate);
    },
  });
  return payload;
}

function prepareSaveEnvelopeForApply(envelope) {
  if (!envelope || !envelope.payload) {
    throw new Error('SAVE_ENVELOPE_PAYLOAD_MISSING');
  }
  const payload = cloneSaveJson(envelope.payload);

  window.AetherSavePayloadValidator.validatePayload(payload, {
    validateAirNavigation(candidate) {
      return window.AetherAirNavigation.validatePersistentState(candidate);
    },
  });

  if (!world || typeof world.preparePersistentState !== 'function') {
    throw new Error('WORLD_PERSISTENCE_PREPARE_UNAVAILABLE');
  }
  const preparedWorld = world.preparePersistentState(payload.world, payload.quest);

  if (!window.ROSTER || window.ROSTER.length !== 5 ||
      !window.AetherPartyState || typeof window.AetherPartyState.setActivePartyIds !== 'function') {
    throw new Error('PARTY_PERSISTENCE_RUNTIME_UNAVAILABLE');
  }
  const preparedRoster = payload.party.roster.map((record, index) => {
    const target = window.ROSTER[index];
    if (!target || record.id !== target.id) {
      throw new Error('SAVE_PARTY_IDENTITY_MISMATCH');
    }
    return cloneSaveJson(record);
  });

  const preparedAirNavigation = payload.airNavigation
    ? window.AetherAirNavigation.restorePersistentState(payload.airNavigation)
    : null;

  return Object.freeze({
    payload,
    preparedWorld,
    preparedRoster,
    preparedActiveIds: payload.party.activeIds.slice(),
    preparedAirNavigation,
  });
}

function applySaveEnvelope(envelope) {
  // No canonical live state changes before this preflight completes.
  const prepared = prepareSaveEnvelopeForApply(envelope);
  const payload = prepared.payload;

  prepared.preparedRoster.forEach((record, index) => {
    Object.assign(window.ROSTER[index], cloneSaveJson(record));
  });
  window.AetherPartyState.setActivePartyIds(prepared.preparedActiveIds);
  window.AetherPartyState.validate();

  world.restorePersistentState(prepared.preparedWorld, payload.runtime);

  airNavigationState = prepared.preparedAirNavigation;
  window._airNavigationState = airNavigationState;

  loadedPlaytimeMs = payload.runtime.playtimeMs;
  playSessionStartMs = typeof millis === 'function' ? millis() : 0;

  pendingHazardIndex = null;
  combatReturnState = STATE.WORLD;
  pendingAutosaveReason = null;
  previewEncounterStarted = false;
  previewEncounterFinished = false;
  previewEndAt = 0;
  gameState = payload.runtime.scene === STATE.AIRSHIP ? STATE.AIRSHIP : STATE.WORLD;
  window.gameState = gameState;
  prevState = null;
  return true;
}

window._persistenceRuntime = Object.freeze({
  buildSavePayload,
  prepareSaveEnvelopeForApply,
  applySaveEnvelope,
  currentPlaytimeMs,
});

function buildLoadableSaveIndex() {
  if (!window.AetherSaveSystem) return [];
  return window.AetherSaveSystem.list().map(meta => {
    if (!meta.exists || meta.valid === false) return meta;
    try {
      const loaded = window.AetherSaveSystem.load(meta.slot);
      if (!loaded || !loaded.envelope) {
        return { ...meta, valid: false, semanticValid: false, error: 'SAVE_ENVELOPE_MISSING' };
      }
      prepareSaveEnvelopeForApply(loaded.envelope);
      return { ...meta, semanticValid: true };
    } catch (error) {
      return { ...meta, valid: false, semanticValid: false, error: error.message };
    }
  });
}

function latestLoadableSave() {
  const classified = buildLoadableSaveIndex();
  const latest = classified
    .filter(entry => entry.exists && entry.valid !== false && entry.semanticValid === true && entry.savedAt)
    .sort((a, b) => String(b.savedAt).localeCompare(String(a.savedAt)))[0] || null;
  window._latestSaveMeta = latest;
  return latest;
}

function continueLatestSave() {
  const latest = latestLoadableSave();
  if (!latest) {
    showToast('NO VALID SAVE FOUND', C.rust, 1400);
    return false;
  }
  return loadFromSlot(latest.slot);
}

function requestAutosave(reason) {
  pendingAutosaveReason = reason || 'checkpoint';
}

function flushPendingAutosaveIfStable() {
  if (!pendingAutosaveReason) return false;
  if (gameState !== STATE.WORLD && gameState !== STATE.AIRSHIP) return false;
  if (!canSnapshotPersistentState()) {
    pendingAutosaveReason = null;
    return false;
  }

  const reason = pendingAutosaveReason;
  pendingAutosaveReason = null;
  try {
    const result = window.AetherSaveSystem.rotateAutosave(buildSavePayload(), saveMetadata());
    window._lastSaveResult = result;
    window._lastAutosaveReason = reason;
    window._saveSlotIndex = buildLoadableSaveIndex();
    showToast('AUTOSAVED // ' + reason.toUpperCase(), C.teal, 900);
    return true;
  } catch (error) {
    window._lastSaveError = error.message;
    console.error('AUTOSAVE_FAILED', error);
    return false;
  }
}

function saveMetadata() {
  return {
    gameVersion: '0.1.0-chapter1',
    playtimeMs: currentPlaytimeMs(),
    chapter: 'Chapter I — First Wake',
    location: gameState === STATE.AIRSHIP ? 'Open Sky' : 'Aureate Wake',
    partySummary: Array.isArray(window.ACTIVE_PARTY)
      ? window.ACTIVE_PARTY.map(character => character.name || character.id)
      : ['Ender'],
  };
}

function saveToSlot(slot) {
  if (!canSnapshotPersistentState()) {
    showToast('CANNOT SAVE HERE', C.rust, 1400);
    return false;
  }
  try {
    const result = window.AetherSaveSystem.save(slot, buildSavePayload(), saveMetadata());
    window._lastSaveResult = result;
    window._saveSlotIndex = buildLoadableSaveIndex();
    showToast('GAME SAVED // ' + slot.toUpperCase(), C.teal, 1300);
    return true;
  } catch (error) {
    window._lastSaveError = error.message;
    console.error('SAVE_FAILED', error);
    showToast('SAVE FAILED // ' + error.message, C.rust, 2200);
    return false;
  }
}

function loadFromSlot(slot) {
  try {
    const loaded = window.AetherSaveSystem.load(slot);
    if (!loaded) {
      showToast('NO SAVE IN ' + slot.toUpperCase(), C.rust, 1400);
      return false;
    }
    prepareSaveEnvelopeForApply(loaded.envelope);
    window._lastLoadResult = loaded;
    applySaveEnvelope(loaded.envelope);
    window._saveSlotIndex = buildLoadableSaveIndex();
    showToast('GAME LOADED // ' + slot.toUpperCase(), C.teal, 1500);
    return true;
  } catch (error) {
    window._lastLoadError = error.message;
    console.error('LOAD_FAILED', error);
    showToast('LOAD FAILED // ' + error.message, C.rust, 2200);
    return false;
  }
}

function openSaveLoadMenu(mode) {
  if (mode === 'save' && !canSnapshotPersistentState()) {
    showToast('CANNOT SAVE HERE', C.rust, 1400);
    return false;
  }
  if (gameState !== STATE.WORLD && gameState !== STATE.AIRSHIP) return false;
  saveMenuReturnState = gameState;
  saveMenuMode = mode === 'load' ? 'load' : 'save';
  saveMenuIndex = 0;
  window._saveSlotIndex = buildLoadableSaveIndex();
  gameState = STATE.SAVELOAD;
  window.gameState = gameState;
  prevState = null;
  return true;
}

function handleSaveLoadInput() {
  const slots = window.AetherSaveSystem.MANUAL_SLOTS;
  if (keysPressed[27]) {
    gameState = saveMenuReturnState;
    window.gameState = gameState;
    prevState = null;
    return;
  }
  if (keysPressed[LEFT_ARROW] || keysPressed[RIGHT_ARROW]) {
    saveMenuMode = saveMenuMode === 'save' ? 'load' : 'save';
  }
  if (keysPressed[UP_ARROW]) saveMenuIndex = (saveMenuIndex + slots.length - 1) % slots.length;
  if (keysPressed[DOWN_ARROW]) saveMenuIndex = (saveMenuIndex + 1) % slots.length;
  if (keysPressed[13] || keysPressed[32]) {
    const slot = slots[saveMenuIndex];
    if (saveMenuMode === 'save') {
      const returnState = saveMenuReturnState;
      gameState = returnState;
      window.gameState = gameState;
      if (saveToSlot(slot)) {
        openSaveLoadMenu('save');
        saveMenuIndex = slots.indexOf(slot);
      } else {
        openSaveLoadMenu('save');
      }
    } else {
      loadFromSlot(slot);
    }
  }
}

function drawSaveLoadOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 238);
  rect(0, 0, width, height);
  const slots = window.AetherSaveSystem.MANUAL_SLOTS;
  const listing = buildLoadableSaveIndex();

  textAlign(LEFT, TOP);
  textFont('Press Start 2P');
  textSize(13);
  fill(C.teal[0], C.teal[1], C.teal[2]);
  text('SAVE / LOAD', 90, 56);

  textSize(9);
  fill(C.parchment[0], C.parchment[1], C.parchment[2]);
  text('MODE: ' + saveMenuMode.toUpperCase() + '   LEFT / RIGHT SWITCH', 90, 84);

  for (let i = 0; i < slots.length; i++) {
    const slot = slots[i];
    const meta = listing.find(entry => entry.slot === slot);
    const y = 120 + i * 62;
    if (i === saveMenuIndex) {
      fill(C.teal[0], C.teal[1], C.teal[2], 35);
      rect(80, y - 8, width - 160, 52);
    }

    fill(i === saveMenuIndex ? C.teal[0] : C.parchment[0],
         i === saveMenuIndex ? C.teal[1] : C.parchment[1],
         i === saveMenuIndex ? C.teal[2] : C.parchment[2]);
    textFont('Press Start 2P');
    textSize(9);
    text('SLOT ' + (i + 1), 100, y);

    textFont('Segoe UI');
    textSize(15);
    if (meta && meta.exists && meta.valid !== false && meta.semanticValid === true) {
      const mins = Math.floor((meta.playtimeMs || 0) / 60000);
      text((meta.chapter || 'Aetherwake') + ' // ' + mins + ' min', 220, y - 2);
      text((meta.partySummary || []).join(' + '), 220, y + 18);
    } else if (meta && meta.exists) {
      fill(C.rust[0], C.rust[1], C.rust[2]);
      const reason = meta.semanticValid === false ? 'INVALID SAVE STATE' : 'CORRUPT / UNREADABLE';
      text(reason + ' — ORIGINAL RETAINED', 220, y + 6);
    } else {
      text('EMPTY', 220, y + 6);
    }
  }

  textFont('Press Start 2P');
  textSize(8);
  fill(C.scioto[0], C.scioto[1], C.scioto[2]);
  text('UP / DOWN SLOT   ENTER CONFIRM   ESC RETURN   F5 SAVE   F9 LOAD', 90, height - 42);
}

function runChapter1PersistenceSmokeOnce() {
  if (window.__awChapter1PersistenceSmokeDone) return;
  try {
    if (typeof process === 'undefined' || !process.env) return;
    const mode = process.env.AETHERWAKE_CHAPTER1_PERSISTENCE_MODE;
    const markerPath = process.env.AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER;
    const isolatedRoot = process.env.AETHERWAKE_SAVE_ROOT_OVERRIDE;
    if (!mode || !markerPath || !isolatedRoot) return;
    if (!window.__awRuntimeReady || !window.__awFirstFrame) return;
    if (typeof require !== 'function') return;
    if (!window.AetherSaveSystem || !world || !world.player) {
      throw new Error('CHAPTER1_PERSISTENCE_SMOKE_RUNTIME_UNAVAILABLE');
    }

    const fs = require('fs');
    let payload = null;

    if (mode === 'create') {
      // Smoke-only mutation in an isolated save root. The distinctive position
      // proves the second process restored bytes written by the first process.
      gameState = STATE.WORLD;
      window.gameState = gameState;
      world.player.tileX = 17;
      world.player.tileY = 16;
      world.player.px = 17 * 16;
      world.player.py = 16 * 16;
      const saved = saveToSlot('manual-6');
      if (!saved) throw new Error('CHAPTER1_PERSISTENCE_SMOKE_SAVE_FAILED');
      const latest = latestLoadableSave();
      if (!latest || latest.slot !== 'manual-6') {
        throw new Error('CHAPTER1_PERSISTENCE_SMOKE_SAVE_NOT_LOADABLE');
      }
      const stored = window.AetherSaveSystem.load('manual-6');
      payload = {
        phase: 'create',
        result: 'PASS',
        storageType: stored && stored.storageType,
        savePath: stored && stored.path,
        slot: 'manual-6',
        tileX: world.player.tileX,
        tileY: world.player.tileY,
        questState: world.getQuestState().state,
      };
    } else if (mode === 'continue') {
      gameState = STATE.MENU;
      window.gameState = gameState;
      if (!continueLatestSave()) {
        throw new Error('CHAPTER1_PERSISTENCE_SMOKE_CONTINUE_FAILED');
      }
      const questState = world.getQuestState();
      if (gameState !== STATE.WORLD ||
          world.player.tileX !== 17 ||
          world.player.tileY !== 16 ||
          !questState || questState.state !== QUEST_STATES.SIGNAL) {
        throw new Error('CHAPTER1_PERSISTENCE_SMOKE_RESTORE_MISMATCH');
      }
      const latest = latestLoadableSave();
      payload = {
        phase: 'continue',
        result: 'PASS',
        gameState,
        slot: latest && latest.slot,
        tileX: world.player.tileX,
        tileY: world.player.tileY,
        questState: questState.state,
      };
    } else {
      throw new Error('CHAPTER1_PERSISTENCE_SMOKE_MODE_INVALID:' + mode);
    }

    fs.writeFileSync(markerPath, JSON.stringify(payload), 'utf8');
    window.__awChapter1PersistenceSmokeDone = true;
  } catch (error) {
    window.__awChapter1PersistenceSmokeDone = true;
    try {
      if (typeof require === 'function' &&
          typeof process !== 'undefined' && process.env &&
          process.env.AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER) {
        require('fs').writeFileSync(
          process.env.AETHERWAKE_CHAPTER1_PERSISTENCE_MARKER,
          JSON.stringify({ phase: process.env.AETHERWAKE_CHAPTER1_PERSISTENCE_MODE || null,
            result: 'FAIL', error: error.message }),
          'utf8'
        );
      }
    } catch (_) {}
    console.error('CHAPTER1_PERSISTENCE_SMOKE_FAILED', error);
  }
}

function writeDesktopSmokeMarkerOnce() {
  if (window.__awDesktopSmokeMarkerWritten) return;
  try {
    if (typeof process === 'undefined' || !process.env) return;
    const markerPath = process.env.AETHERWAKE_DESKTOP_SMOKE_MARKER;
    if (!markerPath) return;
    if (!window.__awRuntimeReady || !window.__awFirstFrame) return;
    if (typeof require !== 'function') return;

    const fs = require('fs');
    const payload = {
      runtimeReady: true,
      firstFrame: true,
      width: typeof width === 'number' ? width : null,
      height: typeof height === 'number' ? height : null,
      gameState: typeof gameState !== 'undefined' ? gameState : null,
      setupOrder: window._setupOrder || null,
      timestamp: new Date().toISOString(),
    };
    fs.writeFileSync(markerPath, JSON.stringify(payload), 'utf8');
    window.__awDesktopSmokeMarkerWritten = true;
  } catch (error) {
    console.error('DESKTOP_SMOKE_MARKER_WRITE_FAILED', error);
  }
}

// ── draw() ──
function draw() {
  dt = millis() - lastTime;
  lastTime = millis();

  // Boot sequence timer — only set once when entering BOOT
  if (gameState === STATE.BOOT && bootTime === 0) {
    bootTime = millis();
  }
  if (preambleStart === 0 && bootTime > 0) {
    preambleStart = bootTime;
  }

  background(C.navy[0], C.navy[1], C.navy[2]);

  // ── Hit stop: freeze the frame if active ──
  if (hitStop.active) {
    hitStop.remaining -= dt;
    if (hitStop.remaining <= 0) {
      hitStop.active = false;
      hitStop.remaining = 0;
    } else {
      // Skip the rest of draw (still advance time for shake/fade so they don't desync)
      // We still need to render freeze-frame content, so continue below but skip updates.
      // The world/combat update calls are gated by hitStop below.
    }
  }

  // Only run world/combat updates if hit stop is NOT active
  const updatesEnabled = !hitStop.active;

  flushPendingAutosaveIfStable();

  // Subtle corner brackets — confirm canvas is live without distracting
  noFill();
  stroke(C.teal[0], C.teal[1], C.teal[2], 50);
  strokeWeight(2);
  const cb = 16;
  noFill();
  rect(2, 2, cb, 2); rect(2, 2, 2, cb);
  rect(width - cb - 2, 2, cb, 2); rect(width - 2, 2, 2, cb);
  rect(2, height - 4, cb, 2); rect(2, height - cb - 2, 2, cb);
  rect(width - cb - 2, height - 4, cb, 2); rect(width - 2, height - cb - 2, 2, cb);

  // Screen shake offset
  let shakeX = 0, shakeY = 0;
  if (shake.intensity > 0 && shake.startTime > 0) {
    const age = millis() - shake.startTime;
    if (age < shake.duration) {
      const decay = 1 - (age / shake.duration);
      const mag = shake.intensity * 0.6 * decay;
      shakeX = (Math.random() - 0.5) * mag;
      shakeY = (Math.random() - 0.5) * mag;
    } else {
      shake.intensity = 0;
    }
  }
  if (shakeX !== 0 || shakeY !== 0) translate(shakeX, shakeY);

  drawBackgroundGrid();

  // Boot sequence state dispatch
  if (gameState === STATE.BOOT) {
    drawBootSequence();
  }
  else if (gameState === STATE.MENU) {
    drawTitleScreen();
  }
  else if (gameState === STATE.OPENING) {
    drawFirstWakeOpening();
  }
  else if (gameState === STATE.CHARCREATE) {
    if (window._charcreate && typeof window._charcreate.draw === 'function') {
      window._charcreate.draw();
    }
    // When char-create signals completion, transition to WORLD and init combat
    if (window._charcreate && window._charcreate.phase === 'done') {
      // Commit the preservation character-creation draft into persistent
      // roster records. The lead record is the original World player object,
      // mutated in place so World, ROSTER[0], and ACTIVE_PARTY[0] share identity.
      if (!window.AetherPartyState ||
          typeof window.AetherPartyState.commitPrototypeParty !== 'function') {
        throw new Error('AETHER_PARTY_STATE_UNAVAILABLE_DURING_HANDOFF');
      }
      const activeParty = window.AetherPartyState.commitPrototypeParty(window._charcreate.party);
      if (!activeParty || activeParty[0] !== world.player ||
          !window.ROSTER || window.ROSTER[0] !== world.player) {
        throw new Error('PERSISTENT_PARTY_IDENTITY_INVARIANT_FAILED');
      }
      // Re-init combat with the new player data
      if (combat && typeof combat.init === 'function') {
        combat.init({
          vit: world.player.vit,
          scrap: world.player.scrap,
          aether: { current: world.player.aether, max: world.player.aetherMax },
          heat: { current: world.player.heat, max: world.player.heatMax },
          echoes: { current: world.player.echoes, max: world.player.echoesMax },
          charges: world.player.staffCharges,
          staffMax: world.player.maxStaffCharges || 2,
          aetherMax: world.player.aetherMax,
          heatMax: world.player.heatMax,
          echoesMax: world.player.echoesMax,
          level: world.player.level,
          xp: world.player.xp,
          xpToNext: world.player.xpToNext,
          unlockedAbilities: world.player.unlockedAbilities,
          equipment: world.player.equipment,
          productionStats: world.player.productionStats,
          productionDerivedStats: world.player.productionDerivedStats,
          productionStatModelVersion: world.player.productionStatModelVersion,
        });
      }
      gameState = STATE.WORLD;
      window.gameState = gameState;
    }
  }
  else if (gameState === STATE.PREVIEW_END) {
    drawPreviewEndScreen();
  }
  else if (gameState === STATE.WORLD) {
    if (world && typeof world.update === 'function') world.update(dt / 1000);
    if (world && typeof world.render === 'function') world.render();
  }
  else if (gameState === STATE.AIRSHIP) {
    drawAirNavigationScene();
  }
  else if (gameState === STATE.COMBAT) {
    if (combat && typeof combat.render === 'function') combat.render();
    if (combat && typeof combat.drawCombatScene === 'function') {
      const px = world ? world.player.px : 160;
      const py = world ? world.player.py : 380;
      const aetherInfo = combat.getAether ? combat.getAether() : { max: 6 };
      const chargeInfo = combat.getCharges ? combat.getCharges() : { max: 2 };
      const skyCombat = combatReturnState === STATE.AIRSHIP;
      const skyTravel = skyCombat && airNavigationState && window.AetherAirNavigation &&
        typeof window.AetherAirNavigation.travelProfile === 'function'
        ? window.AetherAirNavigation.travelProfile(airNavigationState)
        : null;
      combat.drawCombatScene(
        px,
        py,
        aetherInfo.max,
        chargeInfo.max,
        {
          domain: skyCombat ? 'sky' : 'ground',
          weatherId: skyTravel && skyTravel.weather ? skyTravel.weather.id : 'clear',
          altitude: skyCombat && airNavigationState ? airNavigationState.altitude : null,
          encounterPressure: skyTravel ? skyTravel.encounterPressure : 0,
        }
      );
    }
    // Shared UI layout preserves the encounter stage instead of reserving two
    // full-height opaque sidebars. An empty combat log consumes no panel space.
    const uiVisual = window.AetherUIVisualSystem;
    const hasCombatLog = Boolean(window.UI && Array.isArray(window.UI.combatLog) && window.UI.combatLog.length);
    const combatLayout = uiVisual && typeof uiVisual.layoutCombat === 'function'
      ? uiVisual.layoutCombat(width, height, hasCombatLog)
      : null;
    if (typeof drawCombatPanel === 'function' && combat && typeof combat.getState === 'function') {
      drawCombatPanel(combat.getState(), combatLayout && combatLayout.statusPanel);
    }
    if (hasCombatLog && typeof drawCombatLog === 'function') {
      const logBox = combatLayout && combatLayout.logPanel;
      if (logBox) drawCombatLog(logBox.x, logBox.y, logBox.w, logBox.h);
    }
  }
  else if (gameState === STATE.DIALOGUE) {
    if (world && typeof world.render === 'function') world.render();
    drawDialogueOverlay();
  }
  else if (gameState === STATE.SHOP) {
    if (world && typeof world.render === 'function') world.render();
    drawShopOverlay();
  }
  else if (gameState === STATE.LEDGER) {
    if (world && typeof world.render === 'function') world.render();
    drawLedgerOverlay();
  }
  else if (gameState === STATE.QUESTLOG) {
    if (world && typeof world.render === 'function') world.render();
    drawQuestLogOverlay();
  }
  else if (gameState === STATE.CHARSHEET) {
    if (world && typeof world.render === 'function') world.render();
    drawCharSheetOverlay();
  }
  else if (gameState === STATE.SAVELOAD) {
    if (saveMenuReturnState === STATE.WORLD && world && typeof world.render === 'function') world.render();
    else if (saveMenuReturnState === STATE.AIRSHIP) drawAirNavigationScene();
    drawSaveLoadOverlay();
  }

  // ── Vignette (intensifies at night) ──
  if (VIS.vignette) {
    drawVignette();
  }

  // ── Toast messages ──
  drawToasts();

  // ── Screen flash ──
  drawScreenFlash();

  // ── Fade transition overlay ──
  drawFadeOverlay();

  // ── Dialogue type-in effect ──
  updateDialogueTypeIn();
  if (dialogueTypeIn.active && gameState === STATE.DIALOGUE) {
    // Override the dialogue text with the type-in version
    if (window.UI.dialogueText) {
      window.UI.dialogueText = dialogueTypeIn.displayText;
    }
  }

  // Preview 0.1 intentionally omits CRT scanlines; they obscure pixel art on native Windows rendering.

  // ── Scene fade: track previous state for next-frame detection ──
  prevState = gameState;

  // ── Window openness animation (Memories §1.2) ──
  if (window.UI.opening) {
    window.UI.openness = Math.min(255, window.UI.openness + 32);
    if (window.UI.openness >= 255) window.UI.opening = false;
  }
  if (window.UI.closing) {
    window.UI.openness = Math.max(0, window.UI.openness - 32);
    if (window.UI.openness <= 0) {
      window.UI.openness = 0;
      window.UI.closing = false;
    }
  }

  // The embedded loader waits for a completed frame, not merely a canvas node.
  window.__awFirstFrame = true;
  runChapter1PersistenceSmokeOnce();
  writeDesktopSmokeMarkerOnce();
}

// ── Input ──
// Interaction key for world module (set by keyPressed, read by world.interact)
let interactionKey = null;

function keyPressed() {
  keys[keyCode] = true;
  keysPressed[keyCode] = true;

  if (gameOver && keyCode === 82) { // R — begin Chapter I again.
    if (window.location && typeof window.location.reload === 'function') {
      window.location.reload();
    }
    delete keysPressed[keyCode];
    return false;
  }

  if ((gameState === STATE.WORLD || gameState === STATE.AIRSHIP) && keyCode === 116) { // F5
    openSaveLoadMenu('save');
    delete keysPressed[keyCode];
    return false;
  }
  if ((gameState === STATE.WORLD || gameState === STATE.AIRSHIP) && keyCode === 120) { // F9
    openSaveLoadMenu('load');
    delete keysPressed[keyCode];
    return false;
  }

  // Story-bearing boot presentation is fully player-paced after loading.
  // Each preamble page is held until explicit input; the final page then hands
  // control to the title. A small minimum dwell prevents accidental double taps.
  if (gameState === STATE.BOOT) {
    const now = millis();
    const elapsed = bootTime > 0 ? now - bootTime : 0;
    if (elapsed >= BOOT_LOAD_MS) {
      if (preamblePageShownAt === 0) preamblePageShownAt = now;
      if (now - preamblePageShownAt >= PREAMBLE_PAGE_MIN_MS) {
        if (preamblePage < PREAMBLE_PAGES.length - 1) {
          preamblePage += 1;
          preamblePageShownAt = now;
        } else {
          gameState = STATE.MENU;
          window.gameState = gameState;
          titleVisible = 0;
          titleFlash = 0;
        }
      }
      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return false;
    }
  }

  if (gameState === STATE.OPENING) {
    const opening = window.AetherFirstWakeOpening;
    const openingState = window._firstWakeOpeningState;
    const openingScene = opening && openingState ? opening.currentScene(openingState) : null;

    if (openingScene && openingScene.id === 'dock_walk' &&
        (keyCode === LEFT_ARROW || keyCode === 65 || keyCode === RIGHT_ARROW || keyCode === 68)) {
      const delta = (keyCode === LEFT_ARROW || keyCode === 65) ? -1 : 1;
      const movement = opening.moveDock(openingState, delta);
      if (movement.ready && !window.__awDockWalkReadyToastShown) {
        showToast('AUREATE WAKE REACHED // ENTER TO BOARD', C.teal, 1400);
        window.__awDockWalkReadyToastShown = true;
      }
      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }

    if (openingScene && openingScene.id === 'berth_task' && keyCode === 69) {
      const berth = opening.interactBerth(openingState);
      const berthSteps = ['BERTH CLEARED', 'PANEL ALIGNED', 'BAG PLACED // A PLACE ABOARD'];
      if (berth.advanced) {
        showToast(berthSteps[Math.max(0, berth.step - 1)], berth.ready ? C.teal : C.scioto, 1100);
      }
      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }

    if (openingScene && openingScene.id === 'talen_staying' && keyCode === 69) {
      const talen = opening.interactTalen(openingState);
      const talenSteps = ['TALEN: ARE YOU STAYING HERE NOW?', 'A SMALL WAKE IS LEFT ON YOUR DESK'];
      if (talen.advanced) {
        showToast(talenSteps[Math.max(0, talen.step - 1)], talen.ready ? C.teal : C.scioto, 1200);
      }
      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }

    const wakeExplorationScene = openingScene && openingScene.sequence >= 5 && openingScene.sequence <= 8;
    if (wakeExplorationScene &&
        (keyCode === LEFT_ARROW || keyCode === 65 ||
         keyCode === RIGHT_ARROW || keyCode === 68 ||
         keyCode === UP_ARROW || keyCode === 87 ||
         keyCode === DOWN_ARROW || keyCode === 83)) {
      let dx = 0;
      let dy = 0;
      if (keyCode === LEFT_ARROW || keyCode === 65) dx = -1;
      else if (keyCode === RIGHT_ARROW || keyCode === 68) dx = 1;
      else if (keyCode === UP_ARROW || keyCode === 87) dy = -1;
      else if (keyCode === DOWN_ARROW || keyCode === 83) dy = 1;

      const movement = opening.moveWake(openingState, dx, dy);
      if (movement.event && movement.event.type === 'wrong-song-triggered') {
        showToast('THE WAKE FALLS OUT OF RHYTHM', C.scioto, 1500);
        advanceFirstWakeOpening();
      }

      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }

    if (wakeExplorationScene && keyCode === 69) {
      const interaction = opening.interactWake(openingState);
      const view = opening.wakeExplorationView(openingState);
      if (view.lastMessage) {
        showToast(view.lastMessage.toUpperCase(), C.scioto, 1500);
      }

      if (interaction.event && (
        interaction.event.type === 'wrong-song-triggered' ||
        interaction.event.type === 'wrong-song-acknowledged' ||
        interaction.event.type === 'ionia-found' ||
        interaction.event.type === 'core-threshold'
      )) {
        advanceFirstWakeOpening();
      } else if (interaction.event && interaction.event.type === 'investigation-clue') {
        const count = interaction.event.count;
        showToast(
          'ANOMALY EVIDENCE // ' + count + ' FOUND' +
          (interaction.event.coreUnlocked ? ' // CORE ROUTE OPEN' : ''),
          interaction.event.coreUnlocked ? C.teal : C.parchment,
          1700
        );
      }

      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }

    if (keyCode === 13 || keyCode === 32) {
      const beforeScene = openingScene;
      const beforeIndex = openingState && openingState.sceneIndex;
      advanceFirstWakeOpening();
      if (beforeScene && openingState && openingState.sceneIndex === beforeIndex) {
        if (beforeScene.cinematic && typeof opening.presentationReady === 'function' &&
            !opening.presentationReady(openingState)) {
          // Minimum cinematic dwell is still active; no warning toast needed.
        } else if (beforeScene.id === 'dock_walk') {
          showToast('MOVE RIGHT TOWARD THE AUREATE WAKE', C.scioto, 1100);
        } else if (beforeScene.id === 'berth_task') {
          showToast('PRESS E TO WORK ON THE BERTH', C.scioto, 1100);
        } else if (beforeScene.id === 'talen_staying') {
          showToast('PRESS E TO RESPOND TO TALEN', C.scioto, 1100);
        } else if (beforeScene.id === 'lyra_family') {
          showToast('EXPLORE THE WAKE // E TO INSPECT', C.scioto, 1200);
        } else if (beforeScene.id === 'wrong_song') {
          showToast('FIND LYRA // E TO SPEAK', C.scioto, 1200);
        } else if (beforeScene.id === 'ionia_practical') {
          showToast('FIND IONIA // E TO SPEAK', C.scioto, 1200);
        } else if (beforeScene.id === 'core_walk') {
          const view = opening.wakeExplorationView(openingState);
          showToast(
            view.coreUnlocked ? 'FIND THE CORE DOOR' : 'INVESTIGATE // ' + view.clues.length + ' / 2 CLUES',
            C.scioto,
            1200
          );
        }
      }
      delete keysPressed[keyCode];
      if (typeof ensureAudio === 'function') ensureAudio();
      if (typeof resumeAudio === 'function') resumeAudio();
      return;
    }
  }

  // Publish interaction intent before dispatch; world.interact() reads this value synchronously.
  if (gameState === STATE.WORLD) {
    if (keyCode === 69) window.interactionKey = 'e';
    else if (keyCode === 81) window.interactionKey = 'q';
    else if (keyCode === 70) window.interactionKey = 'f';
    else if (keyCode === 9) window.interactionKey = 'tab';
    else if (keyCode === 76) window.interactionKey = 'l';
    else if (keyCode === 77) window.interactionKey = 'm';
  }

  handleInput();

  // keysPressed is an edge-triggered event map consumed synchronously above.
  // Clear this key immediately so it cannot leak into a later key event.
  delete keysPressed[keyCode];

  // Audio context must be resumed from user gesture on first interaction
  if (typeof ensureAudio === 'function') ensureAudio();
  if (typeof resumeAudio === 'function') resumeAudio();

  // Footstep sound on first move key repeat (tile crossing)
  if (gameState === STATE.WORLD && (keyCode === UP_ARROW || keyCode === DOWN_ARROW ||
      keyCode === LEFT_ARROW || keyCode === RIGHT_ARROW)) {
    if (typeof window.playFootstep === 'function') window.playFootstep();
  }

  // Menu select sound
  if (gameState === STATE.MENU) {
    if (keyCode === 13 || keyCode === 32 || keyCode === 78 || keyCode === 110) {
      if (typeof window.playMenuSelect === 'function') window.playMenuSelect();
    }
  }

  // Set interaction key for world module — write to window so world.interact()
  // and drawInteractionHints() can read the same source.
  // E = 69, Q = 81, F = 70, Tab = 9, L = 76, M = 77
  if (gameState === STATE.WORLD) {
    if (keyCode === 69) window.interactionKey = 'e';
    else if (keyCode === 81) window.interactionKey = 'q';
    else if (keyCode === 70) window.interactionKey = 'f';
    else if (keyCode === 9) window.interactionKey = 'tab';
    else if (keyCode === 76) window.interactionKey = 'l';
    else if (keyCode === 77) window.interactionKey = 'm';

  }
  // Shop buy-by-number (1-8 only; 9 is reserved for debug)
  if (gameState === STATE.SHOP) {
    if (typeof key === 'string' && key >= '1' && key <= '8') {
      if (window.UI.shopBuyHandler) window.UI.shopBuyHandler(key);
    }
  }

  // DEBUG
  window._lastKeyEvent = { type: 'keyPressed', keyCode: keyCode, key: (typeof key !== 'undefined' ? key : null), gameState: gameState };
}

function keyReleased() {
  keys[keyCode] = false;
  if (keyCode === 69 || keyCode === 81 || keyCode === 70 || keyCode === 9 || keyCode === 76 || keyCode === 77) {
    window.interactionKey = null;
  }
}

function keyTyped() {
  // p5 fires keyTyped for character keys; keyPressed already handled keyCode input.
  // Here we handle character-driven game flow changes.
  if (gameState === STATE.OPENING) {
    return;
  }
  if (gameState === STATE.CHARCREATE) {
    if (window._charcreate && typeof window._charcreate.handleTypedChar === 'function') {
      window._charcreate.handleTypedChar(key);
    }
    return;
  }
  if (gameState === STATE.MENU) {
    if (key === 'c' || key === 'C') {
      continueLatestSave();
      return;
    }
    if (key === 'n' || key === 'N' || key === 'Enter' || key === ' ') {
      startGame();
    }
    // Remove return; to allow fall-through from BOOT→MENU→WORLD in same key event
  }
  if (gameState === STATE.WORLD) {
    // Disembark ship: L or Esc
    if ((key === 'l' || key === 'L' || key === 'escape') && world && player && player.shipBoarded) {
      player.shipBoarded = false;
    }
    // Choice path selection: 1/2/3
    handleChoiceInput();
  }
  if (gameState === STATE.BOOT) {
    // Also allow character keys to skip boot
    if (key === 'n' || key === 'N' || key === 'Enter' || key === ' ') {
      gameState = STATE.MENU;
      titleVisible = 0;
      titleFlash = 0;
    }
  }
}

function windowResized() {
  resizeCanvas(960, 640);
}

function handleInput() {
  // ── Scene fade transition on state change ──
  if (prevState !== null && prevState !== gameState && VIS.fadeTransitions) {
    fade.active = true;
    fade.from = prevState;
    fade.to = gameState;
    fade.startTime = millis() - 1;
    fade.duration = 250;
  }

  // ── Debug logging for key events ──
  window._lastStateTransition = {
    from: prevState,
    to: gameState,
    time: millis(),
    keyCode: (typeof keyCode !== 'undefined' ? keyCode : null),
  };

  // Handle state transitions keyed by physical key events.
  // This runs from keyPressed() for keyCode-based checks.

  const anyEnter = keysPressed[13] || keysPressed[32] ||          // Enter, Space
                   (typeof key !== 'undefined' && (key === 'Enter' || key === ' ' || key === 'n' || key === 'N'));

  if (gameState === STATE.PREVIEW_END) {
    if (anyEnter && window.location && typeof window.location.reload === 'function') {
      window.location.reload();
    }
    return;
  }

  if (gameState === STATE.BOOT) {
    // Any key skips the boot sequence, goes straight to menu.
    // The same key press also triggers MENU→WORLD in the same frame so a
    // single keypress (or test) gets the player into the world.
    if (keysPressed[13] || keysPressed[32] || keysPressed[78] || keysPressed[110] ||
        (typeof key !== 'undefined' && (key === 'Enter' || key === ' ' || key === 'n' || key === 'N'))) {
      gameState = STATE.MENU;
      titleVisible = 0;
      titleFlash = 0;
      // Fall through to MENU handler in the same handleInput() call.
      // Do NOT return — let the MENU branch below also run.
    }
    // (intentionally fall through — MENU handler below also runs)
  }
  if (gameState === STATE.MENU) {
    if (keysPressed[67] || keysPressed[99] ||
        (typeof key !== 'undefined' && (key === 'c' || key === 'C'))) {
      if (continueLatestSave()) return;
    }
    // Start game on Enter/Space/N (from both keyPressed path and character path).
    // For headless Chromium (Playwright testing): keyTyped may not fire reliably
    // for letter keys, so also handle keyPressed keyCode path explicitly.
    if (keysPressed[13] || keysPressed[32] || keysPressed[78] || keysPressed[110] ||
        (typeof key !== 'undefined' && (key === 'Enter' || key === ' ' || key === 'n' || key === 'N'))) {
      startGame();
    }
    // If startGame() routed us into CHARCREATE, run the char-create handler
    // for this same key press so the title→name transition works on first Enter.
    if (gameState === STATE.CHARCREATE &&
        window._charcreate && typeof window._charcreate.handleInput === 'function') {
      window._charcreate.handleInput(keys, keysPressed);
    }
    return;
  }

  if (gameState === STATE.CHARCREATE) {
    if (window._charcreate && typeof window._charcreate.handleInput === 'function') {
      window._charcreate.handleInput(keys, keysPressed);
    }
    return;
  }

  if (gameState === STATE.SAVELOAD) {
    handleSaveLoadInput();
  }
  else if (gameState === STATE.WORLD) {
    handleWorldInput();
  }
  else if (gameState === STATE.DIALOGUE) {
    // Dialogue is a real overlay state, so its confirm key must be handled
    // here instead of falling through to the generic close-only overlay path.
    if (keysPressed[69] || keysPressed[13] || keysPressed[32]) {
      if (world && typeof world.nextDialogueLine === 'function') {
        world.nextDialogueLine();
      }
    }
    if (keysPressed[27]) closeOverlay();
  }
  else if (gameState === STATE.AIRSHIP) {
    handleAirNavigationInput();
  }
  else if (gameState === STATE.COMBAT) {
    if (combat && typeof combat.handleInput === 'function') {
      combat.handleInput(keys, keysPressed);
    }

    // Once an encounter is over, Enter / Space / Esc returns to WORLD and
    // writes persistent combat results back to world.player.
    if (combat && typeof combat.getState === 'function') {
      const combatState = combat.getState();
      if (combatState && combatState.encounterOver &&
          (keysPressed[13] || keysPressed[32] || keysPressed[27])) {
        finishCombat();
        return;
      }
    }

    // Number keys 1-8 trigger combat actions
    if (typeof key === 'string' && key >= '1' && key <= '8' && combat && typeof combat.resolveTurn === 'function') {
      const actionIds = ['staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold', 'windWard', 'aetherSeal', 'rest'];
      const idx = key.charCodeAt(0) - 49;
      if (idx >= 0 && idx < actionIds.length) {
        combat.resolveTurn(actionIds[idx], null);
      }
    }
    // S key: secondary action. Secondary state belongs to AetherCombat;
    // core must not reach into the combat module's private state.
    if (typeof key === 'string' && key.toLowerCase() === 's' &&
        combat && typeof combat.resolveSecondaryAction === 'function') {
      combat.resolveSecondaryAction();
    }
  }
  else {
    // Overlay states — ESC or Enter to close
    if (keysPressed[ENTER] || keysPressed[27]) {
      closeOverlay();
    }
  }
}

function handleWorldInput() {
  if (world && typeof world.getQuestState === 'function') {
    const currentQuest = world.getQuestState();
    if (currentQuest && currentQuest.state === 'wake') {
      if (keysPressed[13] || keysPressed[32]) {
        if (typeof world.advanceQuest === 'function') {
          world.advanceQuest();
        }
      }
      return;
    }
  }

  // WASD movement with key repeat
  const now = millis();
  const delay = 200, rate = 60;

  const movementCodes = [UP_ARROW, DOWN_ARROW, LEFT_ARROW, RIGHT_ARROW, 87, 83, 65, 68];
  for (const code of movementCodes) {
    if (keys[code]) {
      if (!keyRepeat[code]) {
        keyRepeat[code] = now;
        keyRepeatFirst[code] = true;
        doMove(code);
      } else if (now - keyRepeat[code] >= (keyRepeatFirst[code] ? delay : rate)) {
        keyRepeat[code] = now;
        keyRepeatFirst[code] = false;
        doMove(code);
      }
    } else {
      delete keyRepeat[code];
      delete keyRepeatFirst[code];
    }
  }

  // Edge-triggered actions
  if (keysPressed[81]) {   // Q
    if (world && typeof world.plantField === 'function') world.plantField();
  }
  if (keysPressed[69]) {   // E
    if (gameState === STATE.DIALOGUE) {
      // Advance dialogue
      if (world && typeof world.nextDialogueLine === 'function') {
        world.nextDialogueLine();
      }
    } else {
      if (world && typeof world.interact === 'function') world.interact();
    }
  }
  if (keysPressed[70]) {   // F
    if (world && typeof world.boardShip === 'function') {
      world.boardShip();
      if (world.player && world.player.shipBoarded) enterAirNavigation();
    }
  }
  if (keysPressed[9]) {    // Tab
    if (world && typeof world.toggleLayer === 'function') world.toggleLayer();
  }
  if (keysPressed[76]) {   // L
    openState(STATE.LEDGER);
  }
  if (keysPressed[77]) {   // M
    const shopOpened = world && typeof world.openShop === 'function'
      ? world.openShop()
      : true;
    if (shopOpened !== false) openState(STATE.SHOP);
  }
  if (keysPressed[82]) {   // R
    openState(STATE.CHARSHEET);
  }
  if (keysPressed[84]) {   // T
    openState(STATE.QUESTLOG);
  }
  if (keysPressed[27]) {   // ESC
    closeOverlay();
  }
}

function doMove(code) {
  if (!world || typeof world.movePlayer !== 'function') return;
  if (code === UP_ARROW || code === 87)    world.movePlayer(0, -1);
  if (code === DOWN_ARROW || code === 83)  world.movePlayer(0, 1);
  if (code === LEFT_ARROW || code === 65)  world.movePlayer(-1, 0);
  if (code === RIGHT_ARROW || code === 68) world.movePlayer(1, 0);
}

function startGame() {
  startFirstWakeOpening();
}

function startFirstWakeOpening() {
  if (!window.AetherFirstWakeOpening || !window.AetherPartyState) {
    throw new Error('FIRST_WAKE_OPENING_RUNTIME_UNAVAILABLE');
  }
  previewEncounterArmed = false;
  previewEncounterStarted = false;
  previewEncounterFinished = false;
  previewEndAt = 0;
  window._firstWakeOpeningState = window.AetherFirstWakeOpening.createState();
  window.AetherPartyState.setActivePartyIds(['ender']);
  gameState = STATE.OPENING;
  window.gameState = gameState;
  prevState = null;
}

function advanceFirstWakeOpening() {
  const opening = window.AetherFirstWakeOpening;
  const state = window._firstWakeOpeningState;
  if (!opening || !state) throw new Error('FIRST_WAKE_OPENING_STATE_UNAVAILABLE');

  const beforeScene = opening.currentScene(state);
  const result = opening.advance(state);
  if (result.event && result.event.type === 'party-join') {
    window.AetherPartyState.recruitCharacter(result.event.characterId);
    showToast(
      result.event.characterId.toUpperCase() + ' joined Ender\'s active party.',
      C.teal,
      1600
    );
  }

  if (!state.complete && beforeScene && state.sceneIndex !== beforeScene.sequence) {
    const nextScene = opening.currentScene(state);
    if (nextScene.id === 'lyra_family') {
      showToast('THE WAKE IS YOURS TO EXPLORE // E TO INSPECT', C.teal, 2000);
    } else if (nextScene.id === 'wrong_song') {
      showToast('SOMETHING IS WRONG // FIND LYRA', C.scioto, 1800);
    } else if (nextScene.id === 'ionia_practical') {
      showToast('FIND IONIA', C.teal, 1400);
    } else if (nextScene.id === 'core_walk') {
      showToast('INVESTIGATE THE ANOMALY // ANY 2 OF 3 CLUES', C.teal, 2200);
    }
  }

  if (state.complete) {
    gameState = STATE.WORLD;
    window.gameState = gameState;
    prevState = null;
    showToast('CHAPTER I // FIRST WAKE', C.scioto, 1800);
    showToast('WASD / ARROWS // MOVE   E // TALK   T // QUEST LOG', C.teal, 3200);
    showToast('OBJECTIVE // FOLLOW THE SIGNAL CONTACTS', C.parchment, 4800);
    requestAutosave('chapter-handoff');
  }
}

function drawPreviewEndScreen() {
  push();
  noSmooth();
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 248);
  rect(0, 0, width, height);

  const pulse = 0.72 + Math.sin(millis() * 0.003) * 0.12;
  const centerX = Math.round(width / 2);
  const signalY = Math.round(height / 2 - 78);

  // The aether signal resolves into stepped scan lines instead of a soft glow.
  const signalBands = [92, 144, 196, 144, 92];
  for (let i = 0; i < signalBands.length; i++) {
    fill(C.teal[0], C.teal[1], C.teal[2], Math.round(13 + pulse * 11));
    rect(centerX - signalBands[i] / 2, signalY + i * 4, signalBands[i], 2);
  }

  // Sparse sky pixels keep the end card in the same crisp visual language.
  const stars = [
    [0.07,0.12,2],[0.18,0.24,3],[0.29,0.10,2],[0.39,0.19,2],[0.52,0.10,3],
    [0.64,0.18,2],[0.78,0.11,2],[0.92,0.24,3],[0.04,0.52,2],[0.12,0.69,3],
    [0.89,0.58,2],[0.96,0.73,3],[0.13,0.88,2],[0.25,0.94,3],[0.42,0.86,2],
    [0.59,0.93,3],[0.76,0.87,2],[0.91,0.91,3],[0.33,0.34,2],[0.67,0.32,2],
  ];
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 115);
  for (const [nx, ny, size] of stars) {
    rect(Math.round(width * nx), Math.round(height * ny), size, size);
  }

  // Two small floating-island silhouettes frame the copy without crossing it.
  const islandY = Math.round(height * 0.37);
  for (const islandX of [Math.round(width * 0.07), Math.round(width * 0.82)]) {
    fill(55, 187, 111, 185);
    rect(islandX + 20, islandY, 62, 4);
    rect(islandX + 8, islandY + 4, 86, 5);
    fill(46, 47, 54, 235);
    rect(islandX + 14, islandY + 9, 74, 7);
    rect(islandX + 25, islandY + 16, 52, 6);
    rect(islandX + 39, islandY + 22, 24, 6);
    fill(C.teal[0], C.teal[1], C.teal[2], 205);
    rect(islandX + 28, islandY + 11, 4, 4);
  }

  // A low floating ledge anchors the replay prompt in the sky setting.
  const ledgeY = height - 72;
  fill(55, 187, 111, 190);
  rect(centerX - 112, ledgeY, 72, 4);
  rect(centerX - 40, ledgeY - 4, 80, 4);
  rect(centerX + 40, ledgeY, 72, 4);
  fill(46, 47, 54, 235);
  rect(centerX - 104, ledgeY + 4, 208, 7);
  rect(centerX - 78, ledgeY + 11, 156, 6);
  rect(centerX - 50, ledgeY + 17, 100, 6);
  rect(centerX - 25, ledgeY + 23, 50, 5);
  fill(C.teal[0], C.teal[1], C.teal[2], 205);
  rect(centerX - 78, ledgeY + 6, 4, 4);
  rect(centerX + 66, ledgeY + 6, 4, 4);

  textAlign(CENTER, CENTER);
  textFont('Press Start 2P');
  textSize(11);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 220);
  text('AETHERWAKE // PREVIEW 0.1', width / 2, height / 2 - 112);

  textSize(24);
  fill(C.teal[0], C.teal[1], C.teal[2], 235);
  text('END OF PREVIEW', width / 2, height / 2 - 48);

  textFont('Segoe UI');
  textSize(20);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 220);
  text(
    'Ender has heard the first warning and survived the first thing in the sky that answered it.\n\nThe rest of Aetherwake is still being built.',
    width / 2,
    height / 2 + 26,
    width - 230,
    150
  );

  textFont('Press Start 2P');
  textSize(9);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 190);
  text('ENTER / SPACE — PLAY AGAIN', width / 2, height / 2 + 150);
  pop();
}
function drawFirstWakeOpening() {
  const opening = window.AetherFirstWakeOpening;
  const state = window._firstWakeOpeningState;
  const visual = window.AetherFirstWakeVisual;
  if (!opening || !state) return;
  const scene = opening.currentScene(state);
  if (typeof opening.tickPresentation === 'function') opening.tickPresentation(state, 1);

  if (visual && typeof visual.draw === 'function') {
    push();
    visual.draw(scene, state, { now: millis(), width, height });
    pop…55630 tokens truncated…d,
      vy: Math.sin(angle) * spd * spread - (upward ? spd * 0.5 : 0),
      life: life * (0.5 + Math.random() * 0.5),
      maxLife: life,
      size: size * (0.5 + Math.random() * 0.5),
      color: color,
      decay: 0.97 + Math.random() * 0.02,
    });
  }
}

/**
 * Emit a ring expansion (for covenant field activation, ability effects).
 * @param {number} cx, cy
 * @param {number} maxRadius — ring start radius
 * @param {number} expandDist — how far it expands
 * @param {number} life — frames to live
 * @param {array} color
 */
function emitRing(cx, cy, maxRadius, expandDist, life, color) {
  if (!VIS.particles) return;
  for (let i = 0; i < 32; i++) {
    const a = (i / 32) * TWO_PI;
    const inner = maxRadius;
    const outer = maxRadius + expandDist;
    const r = inner + Math.random() * (outer - inner);
    window.particles.push({
      x: cx + Math.cos(a) * r,
      y: cy + Math.sin(a) * r,
      vx: Math.cos(a) * 0.3,
      vy: Math.sin(a) * 0.3,
      life: life * (0.6 + Math.random() * 0.4),
      maxLife: life,
      size: 2 + Math.random() * 2,
      color: color || [42, 255, 181],
      decay: 0.97,
      ring: true,
    });
  }
}

/** Update and cull particles. Call once per frame in drawHUDFrame. */
function updateParticles() {
  for (let i = window.particles.length - 1; i >= 0; i--) {
    const p = window.particles[i];
    p.x += p.vx;
    p.y += p.vy;
    p.vy += 0.04; // slight gravity
    p.vx *= p.decay || 0.98;
    p.vy *= p.decay || 0.98;
    p.life--;
    if (p.life <= 0) {
      window.particles.splice(i, 1);
    }
  }
  // Cap total particles for performance
  if (window.particles.length > 200) {
    window.particles.splice(0, window.particles.length - 200);
  }
}

/** Draw all active particles. Call after world/combat but before scanlines. */
function drawParticles() {
  if (!window.particles.length) return;
  noStroke();
  for (const p of window.particles) {
    const t = p.life / p.maxLife;
    const alpha = t * 200;
    const col = p.color;
    fill(col[0], col[1], col[2], alpha * 0.6);
    ellipse(p.x, p.y, p.size * t, p.size * t);
    // Core highlight
    fill(col[0], col[1], col[2], alpha * 0.3);
    ellipse(p.x, p.y, p.size * t * 2.2, p.size * t * 2.2);
  }
}

// ─────────────────────────────────────────────
// HUD IMPROVEMENTS
// ─────────────────────────────────────────────

/** Pulses when vit is low (< 5). */
let _lowVitPulse = 0;

/**
 * Draw animated HP bar — smooth transition, color shifts with health.
 * @param {number} x, y, w, h — bar rect
 * @param {number} current — current HP
 * @param {number} max — max HP
 * @param {string} label — optional label text above
 * @param {string} lowColor
 * @param {string} highColor
 */
function drawAnimatedHPBar(x, y, w, h, current, max, label,
                            lowColor, highColor) {
  lowColor = lowColor || PAL.RED;
  highColor = highColor || PAL.GREEN;
  push();
  const ratio = max > 0 ? constrain(current / max, 0, 1) : 0;
  // Smoothed ratio for animation
  const animKey = 'hp_' + label + '_' + current;
  const smoothRatio = animBar(animKey, ratio, 0.15);

  // Background
  noStroke();
  fill(PAL.NAVY);
  rect(x, y, w, h, 2);
  drawPixelBorder(x, y, w, h, 1, PAL.SHADOW, PAL.DIM);

  // Fill bar — color blends from low to high
  const fillW = max(0, (w - 2) * smoothRatio);
  if (fillW > 0) {
    // Blend color based on ratio
    const lc = color(lowColor);
    const hc = color(highColor);
    const blend = lerpColor(lc, hc, smoothRatio);
    blend.setAlpha(200);
    fill(blend);
    noStroke();
    rect(x + 1, y + 1, fillW, h - 2, 1.5);
    // Glow
    blend.setAlpha(60);
    fill(blend);
    rect(x + 1, y + 1, fillW, h - 2, 1.5);
  }

  // Low HP pulse — red flash overlay
  if (current > 0 && current < 5) {
    _lowVitPulse = (millis() * 0.005) % 1;
    const pulseAlpha = sin(_lowVitPulse * TWO_PI) * 0.4 + 0.4;
    fill(color(PAL.RED), pulseAlpha * 80);
    noStroke();
    rect(x, y, w, h, 2);
  }

  // Label
  if (label) {
    textFont(FONT_UI);
    textSize(8);
    textAlign(LEFT, TOP);
    fill(PAL.PARCHMENT, 180);
    noStroke();
    text(label.toUpperCase(), x, y - 11);
  }
  pop();
}

/**
 * Draw echo diamonds — small diamond icons showing current/max echoes.
 * @param {number} x, y — position
 * @param {number} current
 * @param {number} max
 * @param {number} size
 */
function drawEchoDiamonds(x, y, current, max, size) {
  size = size || 8;
  push();
  const totalDiamonds = max || 1;
  const diaW = size * 1.6;
  const diaH = size * 1.6;
  const gap = 3;
  const startX = x;
  for (let i = 0; i < totalDiamonds; i++) {
    const dx = startX + i * (diaW + gap);
    const filled = i < current;
    const col = filled ? PAL.BIO : PAL.SHADOW;
    const alpha = filled ? 220 : 60;
    // Diamond shape
    push();
    translate(dx + diaW / 2, y + diaH / 2);
    noStroke();
    fill(color(col), alpha);
    beginShape();
    vertex(0, -diaH / 2);
    vertex(diaW / 2, 0);
    vertex(0, diaH / 2);
    vertex(-diaW / 2, 0);
    endShape(CLOSE);
    // Glow on filled
    if (filled) {
      fill(color(PAL.BIO), 50);
      beginShape();
      vertex(0, -diaH / 2);
      vertex(diaW / 2, 0);
      vertex(0, diaH / 2);
      vertex(-diaW / 2, 0);
      endShape(CLOSE);
    }
    pop();
  }
  pop();
}

/**
 * Draw heat warning indicator — orange glow when heat > 2.
 * @param {number} x, y
 * @param {number} current
 * @param {number} max
 */
function drawHeatWarning(x, y, current, max) {
  push();
  const ratio = max > 0 ? current / max : 0;
  const warning = ratio > 0.67; // heat > 2/3
  const pulse = warning ? (millis() * 0.006) % 1 : 0;
  const glowAlpha = warning ? (sin(pulse * TWO_PI) * 0.3 + 0.5) * 160 : 0;

  // Warning glow bg
  if (glowAlpha > 5) {
    noStroke();
    fill(PAL.AMBER, glowAlpha * 0.3);
    ellipse(x, y, 24, 24);
  }

  // Icon — warning diamond/exclamation
  textFont(FONT_UI);
  textSize(10);
  textAlign(CENTER, CENTER);
  fill(warning ? PAL.AMBER : PAL.DIM, warning ? 220 : 100);
  noStroke();
  text('⚠', x, y);

  // Heat bar to the right
  const barW = 30, barH = 4;
  const bx = x + 10, by = y + 8;
  noStroke();
  fill(PAL.NAVY);
  rect(bx, by, barW, barH, 1);
  drawPixelBorder(bx, by, barW, barH, 1, PAL.SHADOW, PAL.DIM);
  const fillW = max(0, (barW - 2) * ratio);
  if (fillW > 0) {
    const hc = color(PAL.AMBER);
    hc.setAlpha(180);
    fill(hc);
    noStroke();
    rect(bx + 1, by + 1, fillW, barH - 2, 1);
  }
  // Label
  textFont(FONT_BODY);
  textSize(9);
  textAlign(LEFT, CENTER);
  fill(PAL.PARCHMENT, 160);
  noStroke();
  text('HEAT', bx + barW + 4, by + barH / 2);
  pop();
}

/**
 * Draw aether crystal visual — glowing crystal when aether > 0.
 * @param {number} x, y — center
 * @param {number} current
 * @param {number} max
 */
function drawAetherCrystal(x, y, current, max) {
  push();
  translate(x, y);
  const ratio = max > 0 ? current / max : 0;
  const hasAether = current > 0;
  const pulse = hasAether ? (millis() * 0.004) % 1 : 0;
  const glowAlpha = hasAether ? (sin(pulse * TWO_PI) * 0.3 + 0.5) * 180 : 30;

  // Outer glow
  noStroke();
  fill(PAL.SCIOTO, glowAlpha * 0.3);
  ellipse(0, 0, 22 + glowAlpha * 0.05, 22 + glowAlpha * 0.05);

  // Crystal shape — diamond/hex
  const s = 7;
  noStroke();
  fill(hasAether ? PAL.SCIOTO : PAL.DIM, hasAether ? 220 : 80);
  beginShape();
  vertex(0, -s);
  vertex(s * 0.6, -s * 0.3);
  vertex(s * 0.6, s * 0.3);
  vertex(0, s);
  vertex(-s * 0.6, s * 0.3);
  vertex(-s * 0.6, -s * 0.3);
  endShape(CLOSE);

  // Inner bright core when charged
  if (hasAether && ratio > 0.3) {
    fill(PAL.TEAL, 160);
    beginShape();
    vertex(0, -s * 0.5);
    vertex(s * 0.3, -s * 0.15);
    vertex(s * 0.3, s * 0.15);
    vertex(0, s * 0.5);
    vertex(-s * 0.3, s * 0.15);
    vertex(-s * 0.3, -s * 0.15);
    endShape(CLOSE);
  }

  // Label
  textFont(FONT_UI);
  textSize(7);
  textAlign(CENTER, TOP);
  fill(PAL.PARCHMENT, 140);
  noStroke();
  text('AETHER', 0, s + 5);
  pop();
}

/**
 * Draw solar charge meter with sun/moon icon.
 * @param {number} x, y — top-left of meter
 * @param {number} current kWh
 * @param {number} max kWh
 * @param {number} dayNightPhase 0..1 (0=noon day, 0.5=night)
 */
function drawSolarMeterHUD(x, y, current, max, dayNightPhase) {
  push();
  const ratio = max > 0 ? constrain(current / max, 0, 1) : 0;

  // Background panel
  noStroke();
  fill(PAL.NAVY);
  rect(x, y, 120, 22, 3);
  drawPixelBorder(x, y, 120, 22, 2, PAL.SHADOW, PAL.TEAL);

  // Sun/moon icon on left
  const iconX = x + 14, iconY = y + 11;
  const isDay = dayNightPhase != null ? dayNightPhase < 0.5 : ratio > 0.2;
  noStroke();
  if (isDay) {
    // Sun — circle with rays
    fill(PAL.SCIOTO, 200);
    ellipse(iconX, iconY, 8, 8);
    fill(PAL.SCIOTO, 80);
    ellipse(iconX, iconY, 14, 14);
    // Rays
    stroke(PAL.SCIOTO, 100);
    strokeWeight(1);
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TWO_PI + millis() * 0.001;
      const r1 = 7, r2 = 11;
      line(iconX + cos(a) * r1, iconY + sin(a) * r1,
           iconX + cos(a) * r2, iconY + sin(a) * r2);
    }
    noStroke();
  } else {
    // Moon — crescent
    fill(PAL.TEAL, 200);
    ellipse(iconX, iconY, 8, 8);
    fill(PAL.NAVY, 200);
    ellipse(iconX + 2, iconY - 2, 6, 6);
    fill(PAL.TEAL, 60);
    ellipse(iconX, iconY, 12, 12);
    noStroke();
  }

  // Charge bar
  const barX = x + 24, barY = y + 5, barW = 82, barH = 12;
  noStroke();
  fill(PAL.NAVY);
  rect(barX, barY, barW, barH, 2);
  drawPixelBorder(barX, barY, barW, barH, 1, PAL.SHADOW, PAL.DIM);

  const fillW = max(0, (barW - 2) * ratio);
  if (fillW > 0) {
    const sc = color(PAL.TEAL);
    sc.setAlpha(200);
    fill(sc);
    noStroke();
    rect(barX + 1, barY + 1, fillW, barH - 2, 1.5);
    // Glow
    sc.setAlpha(50);
    fill(sc);
    rect(barX + 1, barY + 1, fillW, barH - 2, 1.5);
  }

  // Label
  textFont(FONT_BODY);
  textSize(10);
  textAlign(LEFT, CENTER);
  fill(PAL.PARCHMENT, 170);
  noStroke();
  const label = isDay ? '☀ SOLAR' : '☽ SOLAR';
  text(label, barX + barW + 6, barY + barH / 2);

  textFont(FONT_UI);
  textSize(7);
  textAlign(RIGHT, CENTER);
  fill(PAL.DIM, 140);
  noStroke();
  text(current.toFixed(1) + 'kWh', x + 116, y + 17);
  pop();
}

/**
 * Draw quest progress indicator — dots for each stage.
 * @param {number} x, y — position
 * @param {string} currentState — 'signal' | 'crossing' | 'contact' | 'choice' | 'wake'
 */
function drawQuestProgress(x, y, currentState) {
  push();
  const stages = [
    { key: 'signal',   label: 'SIG', color: PAL.TEAL },
    { key: 'crossing', label: 'CROSS', color: PAL.AMBER },
    { key: 'contact',  label: 'CONTACT', color: PAL.SCIOTO },
    { key: 'choice',   label: 'CHOICE', color: PAL.RUST },
    { key: 'wake',     label: 'WAKE', color: PAL.BIO },
  ];
  const dotSize = 6;
  const gap = 4;
  const totalW = stages.length * (dotSize + gap) - gap;
  const startX = x;

  // Background pill
  noStroke();
  fill(PAL.NAVY);
  rect(x - 6, y - dotSize - 4, totalW + 12, dotSize * 2 + 12, 4);
  drawPixelBorder(x - 6, y - dotSize - 4, totalW + 12, dotSize * 2 + 12, 1, PAL.SHADOW, PAL.DIM);

  stages.forEach((s, i) => {
    const dx = startX + i * (dotSize + gap);
    const dy = y;
    const done = i < stages.findIndex(st => st.key === currentState);
    const active = s.key === currentState;
    const col = done ? PAL.TEAL : (active ? s.color : PAL.DIM);
    const alpha = done ? 220 : (active ? 220 : 80);

    // Dot
    noStroke();
    fill(color(col), alpha);
    ellipse(dx + dotSize / 2, dy + dotSize / 2, dotSize, dotSize);
    // Glow on active
    if (active) {
      fill(color(col), 50);
      ellipse(dx + dotSize / 2, dy + dotSize / 2, dotSize * 2, dotSize * 2);
    }

    // Label below
    textFont(FONT_UI);
    textSize(6);
    textAlign(CENTER, TOP);
    fill(PAL.PARCHMENT, done ? 160 : 90);
    noStroke();
    text(s.label, dx + dotSize / 2, dy + dotSize + 3);
  });
  pop();
}

/**
 * Draw day-night indicator. 0 = noon (bright), 0.5 = night (dark), 1 = noon again.
 * Phase maps to angle: 0 = top (noon), PI = bottom (night).
 * arc / ellipse with scioto-blue → dark navy gradient.
 */
function drawDayNightIndicatorHUD(cx, cy, r = 28) {
  push();
  const phase = window.UI.dayNightPhase; // 0..1
  const angle = phase * TWO_PI;

  // Outer ring — pixel border
  drawPixelBorder(cx - r - 6, cy - r - 6, (r + 6) * 2, (r + 6) * 2, 2,
                   PAL.SHADOW, PAL.TEAL);

  // Background circle
  noStroke();
  fill(PAL.NAVY);
  ellipse(cx, cy, r * 2);

  // Day arc (top half, scioto blue) — drawn from -PI/2 to PI/2 based on phase
  const dayStart = -HALF_PI;
  const dayEnd = dayStart + TWO_PI * phase;
  stroke(PAL.SCIOTO);
  strokeWeight(4);
  noFill();
  // Day arc: from -PI/2 clockwise by phase*2PI
  const startA = -HALF_PI;
  const endA = startA + phase * TWO_PI;
  // When phase > 0.5 the day arc overlaps; we draw a "night" wedge instead
  if (phase <= 0.5) {
    arc(cx, cy, r * 2, r * 2, startA, endA);
  } else {
    // Night: draw full circle dark, then day arc for remaining
    fill(PAL.NAVY);
    noStroke();
    ellipse(cx, cy, r * 2 - 4);
    arc(cx, cy, r * 2, r * 2, startA, endA);
  }

  // Sun/moon indicator at the leading edge
  const indicatorAngle = endA;
  const ix = cx + cos(indicatorAngle) * (r - 6);
  const iy = cy + sin(indicatorAngle) * (r - 6);
  noStroke();
  if (phase < 0.5) {
    // Sun
    fill(PAL.SCIOTO);
    ellipse(ix, iy, 8, 8);
    // Glow
    fill(color(PAL.SCIOTO), 80);
    ellipse(ix, iy, 14, 14);
  } else {
    // Moon
    fill(PAL.TEAL);
    ellipse(ix, iy, 7, 7);
    fill(color(PAL.TEAL), 60);
    ellipse(ix, iy, 12, 12);
  }

  // Label
  fill(PAL.PARCHMENT);
  noStroke();
  textFont(FONT_UI);
  textSize(9);
  textAlign(CENTER, CENTER);
  const label = phase < 0.25 ? 'DAWN' : phase < 0.5 ? 'DAY' :
                phase < 0.75 ? 'DUSK' : 'NIGHT';
  text(label, cx, cy + r + 14);
  pop();
}

// ─────────────────────────────────────────────
// COVENANT FIELD (teal circle)
// ─────────────────────────────────────────────

/**
 * Draw a Covenant Field — a teal circle with glow, pulsing ring, and mycelial accents.
 * @param {number} x, y — center
 * @param {number} radius — field radius (pixels)
 * @param {number} pulse — 0..1 pulse phase for animation
 */
function drawCovenantFieldHUD(x, y, radius = 60, pulse = 0) {
  push();
  translate(x, y);

  // Outer glow — large soft teal ellipse
  noStroke();
  for (let g = 5; g >= 0; g--) {
    const alpha = map(g, 0, 5, 5, 40);
    fill(color(PAL.TEAL), alpha);
    ellipse(0, 0, radius * 2 + g * 12, radius * 2 + g * 12);
  }

  // Main field circle
  stroke(PAL.TEAL);
  strokeWeight(2);
  fill(color(PAL.TEAL), 18); // very low opacity fill
  ellipse(0, 0, radius * 2);

  // Inner ring — pulsing
  const pulseRadius = radius * (0.85 + 0.15 * sin(pulse * TWO_PI));
  noFill();
  stroke(PAL.TEAL);
  strokeWeight(1);
  ellipse(0, 0, pulseRadius * 2);

  // Mycelial accent lines (radial, teal)
  stroke(PAL.TEAL);
  strokeWeight(1);
  const segments = 8;
  for (let i = 0; i < segments; i++) {
    const a = (TWO_PI / segments) * i + pulse * 0.3;
    const r1 = radius * 0.2;
    const r2 = radius * (0.7 + 0.2 * sin(pulse * TWO_PI + i));
    line(cos(a) * r1, sin(a) * r1, cos(a) * r2, sin(a) * r2);
  }

  // Center glyph — diamond / hex
  push();
  rotate(pulse * TWO_PI * 0.5);
  stroke(PAL.TEAL);
  strokeWeight(2);
  noFill();
  // Diamond
  const d = radius * 0.18;
  beginShape();
  vertex(0, -d);
  vertex(d, 0);
  vertex(0, d);
  vertex(-d, 0);
  endShape(CLOSE);
  pop();

  pop();
}

// ─────────────────────────────────────────────
// CHARACTER SHEET HUD
// ─────────────────────────────────────────────

/**
 * Draw the full character sheet HUD: portrait, class/level, stats, abilities, gear, resources.
 * Layout: top-left portrait + vitals, right column stats, bottom abilities/gear/resources.
 */
function drawCharSheet(px, py, pw, ph) {
  push();
  const sheet = {
    portraitX: px + 16,
    portraitY: py + 16,
    portraitW: 120,
    portraitH: 140,
    classX: px + 160,
    classY: py + 16,
    levelX: px + 160,
    levelY: py + 48,
    statsX: px + 160,
    statsY: py + 80,
    abilitiesX: px + 16,
    abilitiesY: py + 220,
    gearX: px + 300,
    gearY: py + 220,
    resourcesX: px + 16,
    resourcesY: py + 360,
    panelW: pw - 32,
    panelH: ph - 32,
  };

  // Panel background with pixel border
  noStroke();
  fill(PAL.NAVY);
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  // ── Portrait Area ──
  const portX = sheet.portraitX;
  const portY = sheet.portraitY;
  const portW = sheet.portraitW;
  const portH = sheet.portraitH;

  // Portrait frame — pixel border
  drawPixelBorder(portX, portY, portW, portH, 3, PAL.SHADOW, PAL.TEAL);

  // Portrait bg
  noStroke();
  fill(PAL.SHADOW);
  rect(portX + 4, portY + 4, portW - 8, portH - 8);

  // Portrait fallback: Ender — copper hair, brass goggles, practical fieldwear
  const cx = portX + portW / 2;
  const cy = portY + portH / 2 - 10;
  const headR = 32;

  // Head silhouette
  fill(PAL.DUST);
  noStroke();
  ellipse(cx, cy, headR * 2, headR * 2.1);

  // Freckles / fieldwear detail.
  noStroke();
  fill(PAL.RUST);
  rect(cx - 19, cy + 4, 2, 2);
  rect(cx - 14, cy + 6, 2, 2);
  rect(cx + 12, cy + 6, 2, 2);
  rect(cx + 17, cy + 4, 2, 2);

  // Brass goggles with pale lenses.
  fill(PAL.DUST);
  ellipse(cx - 12, cy - 4, 14, 10);
  ellipse(cx + 12, cy - 4, 14, 10);
  fill(PAL.SCIOTO);
  ellipse(cx - 12, cy - 4, 8, 6);
  ellipse(cx + 12, cy - 4, 8, 6);

  // Eyes
  fill(PAL.NAVY);
  noStroke();
  ellipse(cx - 12, cy - 4, 4, 4);
  ellipse(cx + 12, cy - 4, 4, 4);

  // Short copper hair.
  fill(PAL.RUST);
  noStroke();
  beginShape();
  vertex(cx - 22, cy - 22);
  vertex(cx - 26, cy - 14);
  vertex(cx - 24, cy - 8);
  vertex(cx - 18, cy - 14);
  vertex(cx - 14, cy - 20);
  endShape();
  beginShape();
  vertex(cx + 22, cy - 22);
  vertex(cx + 26, cy - 14);
  vertex(cx + 24, cy - 8);
  vertex(cx + 18, cy - 14);
  vertex(cx + 14, cy - 20);
  endShape();

  // Armor collar hint
  fill(PAL.RUST);
  noStroke();
  rect(cx - 18, cy + 22, 36, 8);

  const livePlayer = world && world.player ? world.player : null;
  const production = livePlayer && livePlayer.productionStats ? livePlayer.productionStats : null;
  const liveClass = livePlayer
    ? (livePlayer.nativeJob || livePlayer.class || 'Rift Scholar')
    : 'Rift Scholar';
  const liveLevel = livePlayer && Number.isFinite(livePlayer.level) ? livePlayer.level : 1;

  // ── Class + Level ──
  textFont(FONT_UI);
  textSize(10);
  textAlign(LEFT, TOP);
  drawGlowText('CLASS', sheet.classX, sheet.classY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  text(liveClass, sheet.classX + 44, sheet.classY);

  drawGlowText('LEVEL', sheet.levelX, sheet.levelY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  text('Lv. ' + liveLevel, sheet.levelX + 44, sheet.levelY);

  // ── Stats ──
  textFont(FONT_BODY);
  textSize(14);
  const statsY = sheet.statsY;
  const statAccent = PAL.TEAL;
  const stats = [
    { label: 'Vit', value: String(livePlayer ? livePlayer.vit : 13), accent: PAL.RUST },
    { label: 'Echoes', value: String(livePlayer ? livePlayer.echoes : 3) + '/' +
        String(livePlayer ? (livePlayer.echoesMax || 3) : 3), accent: PAL.BIO },
    { label: 'Wits', value: String(production ? production.wits : 8), accent: PAL.SCIOTO },
    { label: 'Presence', value: String(production ? production.presence : 4), accent: PAL.TEAL },
    { label: 'Spirit', value: String(production ? production.spirit : 12), accent: PAL.TEAL },
    { label: 'Might', value: String(production ? production.might : 3), accent: PAL.RUST },
    { label: 'Grace', value: String(production ? production.grace : 4), accent: PAL.SCIOTO },
  ];
  stats.forEach((s, i) => {
    const sy = statsY + i * 18;
    drawGlowText(s.label, sheet.statsX, sy, statAccent, 14);
    fill(s.accent);
    noStroke();
    textSize(16);
    text(s.value, sheet.statsX + textWidth(s.label) + 8, sy - 2);
  });

  // ── Abilities ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('ABILITIES', sheet.abilitiesX, sheet.abilitiesY,
               PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(13);
  const abils = [
    'Resonator Staff: Formula EMP strike',
    'Uncover Truth: Analyze weakness',
    'Mycelial Ledger: Read commons network',
    'Hold: Recharge Resonator Staff',
  ];
  abils.forEach((a, i) => {
    const ay = sheet.abilitiesY + 22 + i * 18;
    fill(PAL.PARCHMENT);
    noStroke();
    // Ability name in teal
    const parts = a.split(':');
    if (parts.length === 2) {
      drawGlowText(parts[0] + ':', sheet.abilitiesX + 10, ay,
                   PAL.TEAL, 13);
      fill(PAL.PARCHMENT);
      text(parts[1].trim(), sheet.abilitiesX + 10 + textWidth(parts[0] + ':') + 8, ay);
    } else {
      drawGlowText(a, sheet.abilitiesX + 10, ay, PAL.TEAL, 13);
    }
  });

  // ── Gear ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('GEAR', sheet.gearX, sheet.gearY, PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(13);
  const gear = [
    { name: 'Loom Backpack', desc: 'Solar green tubes / 2.0kWh / 400W' },
    { name: 'Resonator Staff', desc: 'Gunmetal shaft, claw mount, cyan crystal' },
  ];
  gear.forEach((g, i) => {
    const gy = sheet.gearY + 22 + i * 42;
    drawGlowText(g.name, sheet.gearX + 10, gy, PAL.BIO, 13);
    fill(PAL.DIM);
    noStroke();
    textSize(12);
    text(g.desc, sheet.gearX + 10, gy + 16);
  });

  // ── Resources ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('RESOURCES', sheet.resourcesX, sheet.resourcesY,
               PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(14);
  const resY = sheet.resourcesY + 22;
  const liveAether = livePlayer && typeof livePlayer.aether === 'object'
    ? livePlayer.aether.current
    : (livePlayer ? livePlayer.aether : 4);
  const liveAetherMax = livePlayer && typeof livePlayer.aether === 'object'
    ? livePlayer.aether.max
    : (livePlayer ? (livePlayer.aetherMax || 6) : 6);
  const liveHeat = livePlayer && typeof livePlayer.heat === 'object'
    ? livePlayer.heat.current
    : (livePlayer ? livePlayer.heat : 1);
  const liveHeatMax = livePlayer && typeof livePlayer.heat === 'object'
    ? livePlayer.heat.max
    : (livePlayer ? (livePlayer.heatMax || 3) : 3);
  const liveCharge = livePlayer && Number.isFinite(livePlayer.solarCharge)
    ? livePlayer.solarCharge
    : 1.0;
  const res = [
    { label: 'Scrap', value: String(livePlayer ? livePlayer.scrap : 7), unit: '' },
    { label: 'Aether', value: String(liveAether), unit: '/' + liveAetherMax },
    { label: 'Heat', value: String(liveHeat), unit: '/' + liveHeatMax },
    { label: 'Charge', value: Number(liveCharge).toFixed(1), unit: 'kWh / 400W' },
  ];
  res.forEach((r, i) => {
    const ry = resY + i * 20;
    drawGlowText(r.label, sheet.resourcesX + 10, ry, PAL.SCIOTO, 14);
    fill(PAL.PARCHMENT);
    noStroke();
    textSize(15);
    text(r.value + r.unit, sheet.resourcesX + 10 + textWidth(r.label) + 10, ry - 1);
  });

  pop();
}

/**
 * Minimal HUD version — smaller, top-bar style.
 */
function drawWorldHUD() {
  push();
  const hudX = 8, hudY = 8, hudW = width - 512, hudH = 52;
  const livePlayer = world && world.player ? world.player : null;
  const qs = world && typeof world.getQuestState === 'function'
    ? world.getQuestState()
    : null;

  noStroke();
  fill(PAL.NAVY);
  rect(hudX, hudY, hudW, hudH);
  drawPixelBorder(hudX, hudY, hudW, hudH, 2, PAL.SHADOW, PAL.TEAL);

  const liveName = livePlayer && (livePlayer.canonicalName || livePlayer.name)
    ? (livePlayer.canonicalName || livePlayer.name)
    : 'Ender';
  const liveClass = livePlayer
    ? (livePlayer.nativeJob || livePlayer.class || 'Rift Scholar')
    : 'Rift Scholar';
  const liveLevel = livePlayer && Number.isFinite(livePlayer.level)
    ? livePlayer.level
    : 1;

  textFont(FONT_UI);
  textSize(9);
  drawGlowText(String(liveName).toUpperCase(), hudX + 12, hudY + 8, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(9);
  text(liveClass + '  Lv.' + liveLevel, hudX + 64, hudY + 8);

  const liveEchoes = livePlayer && typeof livePlayer.echoes === 'object'
    ? livePlayer.echoes.current
    : (livePlayer ? livePlayer.echoes : 3);
  const liveEchoesMax = livePlayer && typeof livePlayer.echoes === 'object'
    ? livePlayer.echoes.max
    : (livePlayer ? (livePlayer.echoesMax || 3) : 3);
  const liveAether = livePlayer && typeof livePlayer.aether === 'object'
    ? livePlayer.aether.current
    : (livePlayer ? livePlayer.aether : 4);
  const liveAetherMax = livePlayer && typeof livePlayer.aether === 'object'
    ? livePlayer.aether.max
    : (livePlayer ? (livePlayer.aetherMax || 6) : 6);
  const liveHeat = livePlayer && typeof livePlayer.heat === 'object'
    ? livePlayer.heat.current
    : (livePlayer ? livePlayer.heat : 1);
  const liveHeatMax = livePlayer && typeof livePlayer.heat === 'object'
    ? livePlayer.heat.max
    : (livePlayer ? (livePlayer.heatMax || 3) : 3);

  textFont(FONT_BODY);
  textSize(12);
  const vY = hudY + 28;
  drawStatLabel('Vit', hudX + 12, vY,
    String(livePlayer ? livePlayer.vit : 13), PAL.RUST);
  drawStatLabel('Echoes', hudX + 80, vY,
    String(liveEchoes) + '/' + String(liveEchoesMax), PAL.BIO);
  drawStatLabel('Scrap', hudX + 160, vY,
    String(livePlayer ? livePlayer.scrap : 7), PAL.DUST);
  drawStatLabel('Aether', hudX + 220, vY,
    String(liveAether) + '/' + String(liveAetherMax), PAL.SCIOTO);
  drawStatLabel('Heat', hudX + 290, vY,
    String(liveHeat) + '/' + String(liveHeatMax), PAL.AMBER);

  const qX = hudX + hudW - 150;
  const qY = hudY + 8;
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('QUEST', qX, qY, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(10);
  const phase = qs && qs.state ? String(qs.state).toUpperCase() : 'SIGNAL';
  let progress = '';
  if (qs) {
    if (qs.state === 'signal') progress = ' ' + qs.hooksCompleted + '/3';
    else if (qs.state === 'crossing') progress = ' ' + qs.hazardsCompleted + '/4';
    else if (qs.state === 'contact') progress = ' ' + qs.npcsMet.length + '/4';
  }
  text(phase + progress, qX + 44, qY);

  drawDayNightIndicatorHUD(hudX + hudW - 36, hudY + 32, 20);
  pop();
}

// ─────────────────────────────────────────────
// COMBAT UI PANEL
// ─────────────────────────────────────────────

/** Action icon glyphs — simple p5 shapes for each action type */
function drawActionIcon(cx, cy, size, actionId) {
  push();
  translate(cx, cy);
  const s = size * 0.5;
  textFont(FONT_UI);
  textSize(s * 0.7);
  textAlign(CENTER, CENTER);
  let glyph = '?';
  let col = PAL.TEAL;
  switch (actionId) {
    case 'staffStrike':
      glyph = '\u2605'; // star
      col = PAL.AMBER;
      break;
    case 'uncoverTruth':
      glyph = '\u2726'; // four pointed star
      col = PAL.SCIOTO;
      break;
    case 'sharedDream':
      glyph = '\u2665'; // heart
      col = PAL.BIO;
      break;
    case 'mycelialLedger':
      glyph = '\u25A0'; // square
      col = PAL.GREEN;
      break;
    case 'hold':
      glyph = '\u25CF'; // circle
      col = PAL.DIM;
      break;
  }
  fill(col);
  noStroke();
  text(glyph, 0, 0);
  pop();
}

/** Draw the full combat UI panel — left side of screen */
function drawCombatPanel(combatState, layoutBox) {
  if (!combatState) return;
  push();
  const uiVisual = window.AetherUIVisualSystem;
  const fallback = { x: 24, y: 24, w: 184, h: 400 };
  const box = layoutBox || fallback;
  const px = box.x, py = box.y, pw = box.w, ph = box.h;

  // Panel background follows the shared translucent instrument-panel token.
  const panelColor = uiVisual && typeof uiVisual.panelRGBA === 'function'
    ? uiVisual.panelRGBA()
    : [11, 16, 33, 214];
  fill(...panelColor);
  noStroke();
  rect(px, py, pw, ph, 8);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT', px + 12, py + 8, PAL.TEAL, 9);

  // Enemy section
  if (combatState.enemy) {
    const ey = py + 36;
    drawPixelBorder(px + 8, ey, pw - 16, 44, 2, PAL.SHADOW, PAL.RUST);
    textFont(FONT_UI);
    textSize(8);
    drawGlowText(combatState.enemy.name.toUpperCase(), px + 14, ey + 4, PAL.RUST, 8);
    textFont(FONT_BODY);
    textSize(11);
    fill(PAL.PARCHMENT);
    noStroke();
    const eNameW = textWidth(combatState.enemy.name);
    text('HP ' + combatState.enemy.hp + '/' + combatState.enemy.maxHp, px + pw - 64, ey + 6);
    // HP bar
    const hpRatio = combatState.enemy.hp / combatState.enemy.maxHp;
    const barW = pw - 32;
    noStroke();
    fill(PAL.SHADOW);
    rect(px + 14, ey + 24, barW, 5);
    const hpCol = hpRatio > 0.5 ? PAL.SCIOTO : (hpRatio > 0.25 ? PAL.AMBER : PAL.RED);
    fill(hpCol);
    rect(px + 14, ey + 24, barW * hpRatio, 5);
    // Weakness hint
    textFont(FONT_UI);
    textSize(7);
    fill(PAL.DIM);
    const weakness = String(combatState.enemy.weakness || 'unknown');
    const weaknessShort = weakness.length > 18 ? weakness.substring(0, 17).trimEnd() + '..' : weakness;
    text('WEAK: ' + weaknessShort, px + 14, ey + 32);
  }

  // Player status section
  const sY = py + 90;
  drawPixelBorder(px + 8, sY, pw - 16, 76, 2, PAL.SHADOW, PAL.TEAL);
  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ENDER', px + 14, sY + 6, PAL.TEAL, 8);

  // Player resources use a fixed compact grid; values never compete for the
  // same horizontal lane when the shared UI system narrows the panel.
  textFont(FONT_BODY);
  textSize(10);
  const col1 = px + 14;
  const col2 = px + Math.round(pw * 0.53);
  const row1 = sY + 22;
  const row2 = sY + 41;
  const row3 = sY + 60;
  fill(PAL.RUST); text('HP', col1, row1);
  fill(PAL.PARCHMENT); text(combatState.player.vit + '/' + combatState.player.maxVit, col1 + 23, row1);
  fill(PAL.SCIOTO); text('AETHER', col2, row1);
  fill(PAL.PARCHMENT); text(combatState.player.aether.current + '/' + combatState.player.aether.max, col2 + 45, row1);
  fill(PAL.BIO); text('ECHO', col1, row2);
  fill(PAL.PARCHMENT); text(combatState.player.echoes.current + '/' + combatState.player.echoes.max, col1 + 33, row2);
  fill(PAL.TEAL); text('STAFF', col2, row2);
  fill(PAL.PARCHMENT); text(combatState.player.staffCharges + '/' + combatState.player.maxStaffCharges, col2 + 38, row2);
  fill(PAL.DUST); text('SCRAP', col1, row3);
  fill(PAL.PARCHMENT); text(String(combatState.player.scrap), col1 + 38, row3);

  // Actions grid — eight stable number-key slots. Locked actions stay visible
  // so progression is legible without making key bindings move.
  const aX = px + 8;
  const aY = sY + 86;
  const aW = pw - 16;
  const aH = 132;
  drawPixelBorder(aX, aY, aW, aH, 2, PAL.SHADOW, PAL.TEAL);

  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ACTIONS [1-8]', aX + 12, aY + 6, PAL.TEAL, 8);

  const actions = combatState.actions || [];
  const eligibleActionIds = new Set(
    combatState.eligibleActionIds || actions.map(action => action.id)
  );
  const actH = 14;
  const actStartY = aY + 20;
  actions.forEach((action, idx) => {
    const ay = actStartY + idx * actH;
    const unlocked = eligibleActionIds.has(action.id);
    const useEligibility = combatState.actionUseEligibility
      ? combatState.actionUseEligibility[action.id]
      : null;
    const usable = unlocked && (!useEligibility || useEligibility.canUse);
    // Number circle
    fill(usable ? PAL.TEAL : PAL.DIM);
    noStroke();
    ellipse(aX + 12, ay + 6, 8, 8);
    fill(PAL.NAVY);
    textFont(FONT_UI);
    textSize(7);
    textAlign(CENTER, CENTER);
    text(String(idx + 1), aX + 12, ay + 6);
    // Action label
    textFont(FONT_BODY);
    textSize(9);
    textAlign(LEFT, CENTER);
    const label = action.label || action.id;
    const compactLabel = label.split(/\s+[^A-Za-z0-9]+\s+/)[0].trim();
    fill(usable ? PAL.PARCHMENT : PAL.DIM);
    noStroke();
    const statePrefix = !unlocked
      ? 'LOCK ? '
      : (useEligibility && useEligibility.reason === 'ssot_blocked'
        ? 'N/A ? '
        : (usable ? '' : 'NO RES ? '));
    const maxLabelChars = statePrefix ? 13 : 17;
    text(statePrefix + compactLabel.substring(0, maxLabelChars), aX + 23, ay);
    // Cost indicator uses the exact same centralized legacy cost function as
    // runtime admission/payment.
    const totalCost = window.AetherAbilityDefs.getActionResourceCost(action);
    if (unlocked && totalCost > 0) {
      textFont(FONT_UI);
      textSize(7);
      fill(usable ? PAL.AMBER : PAL.DIM);
      text('COST ' + totalCost, aX + aW - 48, ay + 1);
    }
    // Icon
    if (usable) drawActionIcon(aX + aW - 13, ay + 6, 11, action.id);
  });

  // Enemy special ability hint
  if (combatState.enemy && combatState.enemy.abilityDesc) {
    const abY = aY + aH + 10;
    drawPixelBorder(px + 8, abY, pw - 16, 26, 1, PAL.SHADOW, PAL.RUST);
    textFont(FONT_UI);
    textSize(7);
    fill(PAL.RUST);
    text('ENEMY ABILITY', px + 14, abY + 4);
    textFont(FONT_BODY);
    textSize(9);
    fill(PAL.PARCHMENT);
    const abText = combatState.enemy.abilityDesc;
    const maxW = pw - 40;
    const words = abText.split(' ');
    let line = '';
    let lines = [];
    for (const w of words) {
      if (textWidth(line + ' ' + w) > maxW && line) {
        lines.push(line);
        line = w;
      } else {
        line = line ? line + ' ' + w : w;
      }
    }
    if (line) lines.push(line);
    lines.forEach((l, i) => {
      text(l, px + 14, abY + 13 + i * 9);
    });
  }

  pop();
}

// ─────────────────────────────────────────────
// COMBAT TURN LOG
// ─────────────────────────────────────────────

/**
 * Draw the combat turn log — right-side panel, scrollable last-N entries.
 */
function drawCombatLog(lx, ly, lw, lh) {
  push();
  const uiVisual = window.AetherUIVisualSystem;
  const panelColor = uiVisual && typeof uiVisual.panelRGBA === 'function'
    ? uiVisual.panelRGBA()
    : [11, 16, 33, 214];
  fill(...panelColor);
  noStroke();
  rect(lx, ly, lw, lh, 8);
  drawPixelBorder(lx, ly, lw, lh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT LOG', lx + 12, ly + 10, PAL.TEAL, 9);

  // Divider line
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  // Entries
  textFont(FONT_BODY);
  textSize(12);
  const log = window.UI.combatLog;
  const entryH = 16;
  const maxEntries = Math.floor((lh - 40) / entryH);
  const start = Math.max(0, log.length - maxEntries);
  for (let i = start; i < log.length; i++) {
    const eY = ly + 32 + (i - start) * entryH;
    const entry = log[i];
    // Timestamp / turn number — dim
    fill(PAL.DIM);
    noStroke();
    text('[' + i +']', lx + 12, eY);
    // Message — parchment with teal glow on key words
    const msgX = lx + 36;
    // Color-code by content
    if (entry.includes('FAIL') || entry.includes('miss')) {
      drawGlowText(entry, msgX, eY, PAL.RED, 12);
    } else if (entry.includes('PARTIAL') || entry.includes('partial') ||
               entry.includes('cost')) {
      drawGlowText(entry, msgX, eY, PAL.AMBER, 12);
    } else if (entry.includes('SUCCESS') || entry.includes('success') ||
               entry.includes('hit')) {
      drawGlowText(entry, msgX, eY, PAL.GREEN, 12);
    } else {
      drawGlowText(entry, msgX, eY, PAL.PARCHMENT, 12);
    }
  }

  // Footer hint
  textFont(FONT_UI);
  textSize(8);
  fill(PAL.DIM);
  noStroke();
  text('Tab: toggle log', lx + lw - 90, ly + lh - 14);

  pop();
}

// ─────────────────────────────────────────────
// DICE ROLL DISPLAY (2D6)
// ─────────────────────────────────────────────

/**
 * Draw a 2D6 dice roll result with PbtA framing.
 * @param {number} result — sum of 2D6 (2..12)
 * @param {string} description — what was rolled (e.g. 'Uncover Truth + Wits')
 * @param {number} cx, cy — center position
 * @param {number} size — die size in pixels
 */
function drawDiceRoll(result, description, cx, cy, size = 64) {
  push();
  translate(cx, cy);

  // Background panel
  const panelW = size * 2 + 40;
  const panelH = size + 90;
  fill(PAL.NAVY);
  noStroke();
  rect(-panelW / 2, -panelH / 2, panelW, panelH);
  drawPixelBorder(-panelW / 2, -panelH / 2, panelW, panelH, 3,
                   PAL.SHADOW, PAL.TEAL);

  // Two dice — left and right
  const dieOff = size / 2 + 6;
  drawDie(size, -dieOff, 0, result >= 6 ? 6 : result - 6);
  drawDie(size, dieOff, 0, result >= 6 ? 6 : result);

  // Result sum — big glow text
  const sumColor = result >= 10 ? PAL.GREEN :
                   result >= 7  ? PAL.AMBER : PAL.RED;
  textFont(FONT_UI);
  textSize(22);
  textAlign(CENTER, CENTER);
  drawGlowTextCenter(String(result), 0, -size / 2 - 16, sumColor, 22);

  // Framing label
  textFont(FONT_UI);
  textSize(9);
  let frame = '';
  let frameColor = PAL.PARCHMENT;
  if (result >= 10) {
    frame = '10+  FULL SUCCESS';
    frameColor = PAL.GREEN;
  } else if (result >= 7) {
    frame = '7-9  PARTIAL — COST';
    frameColor = PAL.AMBER;
  } else {
    frame = '6-  FAILURE — GM MOVE';
    frameColor = PAL.RED;
  }
  drawGlowTextCenter(frame, 0, size / 2 + 10, frameColor, 9);

  // Description
  textFont(FONT_BODY);
  textSize(12);
  fill(PAL.PARCHMENT);
  noStroke();
  textAlign(CENTER, CENTER);
  const descY = size / 2 + 24;
  drawGlowTextCenter(description, 0, descY, PAL.TEAL, 12);

  pop();
}

/**
 * Draw a single D6 die face with pips.
 * @param {number} size — side length in pixels
 * @param {number} dx, dy — position
 * @param {number} value — 1..6
 */
function drawDie(size, dx, dy, value) {
  push();
  translate(dx, dy);

  // Die body — rounded rect with pixel border
  const r = 4; // corner radius
  fill(PAL.WHITE);
  noStroke();
  rect(-size / 2, -size / 2, size, size, r);
  drawPixelBorder(-size / 2, -size / 2, size, size, 2, PAL.SHADOW, PAL.SCIOTO);

  // Pip pattern
  const pipR = size * 0.08;
  const pipColor = PAL.NAVY;
  fill(pipColor);
  noStroke();

  const cx = 0;
  const cy = 0;
  const off = size * 0.28;

  // All 6 patterns
  if (value === 1) {
    ellipse(cx, cy, pipR * 2, pipR * 2);
  } else if (value === 2) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 3) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx, cy, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 4) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 5) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx, cy, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 6) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx - off, cy, pipR * 2, pipR * 2);
    ellipse(cx + off, cy, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  }

  // Subtle shadow under die
  pop();
}

// ─────────────────────────────────────────────
// MENU SYSTEM
// ─────────────────────────────────────────────

/**
 * Draw a menu popup: title + option list + callback.
 * When menuOpen is true, this draws over the game view.
 * Callback signature: callback(optionIndex) or callback(optionText).
 */
function drawMenu() {
  if (!window.UI.menuOpen) return;

  push();
  const title = window.UI.menuTitle;
  const options = window.UI.menuOptions;
  if (!title || !options || options.length === 0) {
    pop();
    return;
  }

  // Measure (approximate with a dummy text pass)
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const titleW = textWidth(title) + 24;
  const optionH = 20;
  const padX = 16;
  const padY = 14;
  const headerH = 28;
  const totalW = Math.max(titleW, 220);
  const totalH = headerH + options.length * optionH + padY * 2;

  // Position: center screen
  const mx = (width - totalW) / 2;
  const my = (height - totalH) / 2;

  // Backdrop (dim the game)
  fill(color(PAL.NAVY), 220);
  noStroke();
  rect(0, 0, width, height);

  // Menu panel
  fill(PAL.SHADOW);
  noStroke();
  rect(mx, my, totalW, totalH);
  drawPixelBorder(mx, my, totalW, totalH, 3, PAL.SHADOW, PAL.TEAL);

  // Title bar at top
  noStroke();
  fill(PAL.NAVY);
  rect(mx, my, totalW, headerH);
  // Title glow
  textAlign(CENTER, CENTER);
  textFont(FONT_UI);
  textSize(10);
  drawGlowTextCenter(title.toUpperCase(), mx + totalW / 2, my + headerH / 2,
                      PAL.TEAL, 10);

  // Options
  textFont(FONT_BODY);
  textSize(13);
  textAlign(LEFT, TOP);
  options.forEach((opt, i) => {
    const oy = my + headerH + padY + i * optionH;
    const isSelected = i === 0; // highlight first (or implement selection later)
    // Option row bg
    noStroke();
    if (isSelected) {
      fill(color(PAL.TEAL), 18);
    } else {
      fill(PAL.NAVY);
    }
    rect(mx + padX, oy, totalW - padX * 2, optionH);
    // Pixel border on each option
    drawPixelBorder(mx + padX, oy, totalW - padX * 2, optionH, 1,
                     PAL.SHADOW, isSelected ? PAL.TEAL : PAL.DIM);

    // Option number circle
    noStroke();
    fill(isSelected ? PAL.TEAL : PAL.DIM);
    ellipse(mx + padX + 12, oy + optionH / 2, 10, 10);
    fill(PAL.NAVY);
    textSize(10);
    textAlign(CENTER, CENTER);
    textFont(FONT_UI);
    text(String(i + 1), mx + padX + 12, oy + optionH / 2);

    // Option text with glow
    textFont(FONT_BODY);
    textSize(13);
    textAlign(LEFT, CENTER);
    const txtX = mx + padX + 28;
    if (isSelected) {
      drawGlowText(opt, txtX, oy + 2, PAL.TEAL, 13);
    } else {
      fill(PAL.PARCHMENT);
      noStroke();
      text(opt, txtX, oy + 2);
    }
  });

  // Footer hint
  textFont(FONT_UI);
  textSize(8);
  textAlign(CENTER, CENTER);
  fill(PAL.DIM);
  noStroke();
  text('ENTER to select  ESC to close', mx + totalW / 2, my + totalH - 10);

  pop();
}

/**
 * Open a menu.
 * @param {string} title
 * @param {string[]} options
 * @param {function} callback — called with option text when selected
 */
function openMenu(title, options, callback) {
  window.UI.menuOpen = true;
  window.UI.menuTitle = title;
  window.UI.menuOptions = options;
  window.UI.menuCallback = callback;
}

/**
 * Close the menu.
 */
function closeMenu() {
  window.UI.menuOpen = false;
  window.UI.menuTitle = '';
  window.UI.menuOptions = [];
  window.UI.menuCallback = null;
}

/**
 * Handle menu input — to be called from core.js on keypress.
 * Returns the selected option text, or null.
 */
function handleMenuInput() {
  if (!window.UI.menuOpen) return null;
  // Simple: ENTER selects first option, ESC closes.
  // In core.js, bind these to keys and call selectMenuOption / closeMenu.
  return null;
}

/**
 * Select the currently highlighted menu option (first by default).
 */
function selectMenuOption(index = 0) {
  if (!window.UI.menuOpen) return;
  const options = window.UI.menuOptions;
  if (index < 0 || index >= options.length) return;
  const cb = window.UI.menuCallback;
  if (cb) cb(options[index]);
  closeMenu();
}

// ─────────────────────────────────────────────
// QUEST LOG
// ─────────────────────────────────────────────

/**
 * Draw the quest log panel — left or right side, scrollable.
 */
function drawQuestLog(lx, ly, lw, lh) {
  push();
  fill(PAL.NAVY);
  noStroke();
  rect(lx, ly, lw, lh);
  drawPixelBorder(lx, ly, lw, lh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('QUEST LOG', lx + 12, ly + 10, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  // Stages / entries
  textFont(FONT_BODY);
  textSize(12);
  const log = window.UI.questLog;
  const entryH = 18;
  const maxEntries = Math.floor((lh - 40) / entryH);
  const start = Math.max(0, log.length - maxEntries);
  for (let i = start; i < log.length; i++) {
    const eY = ly + 32 + (i - start) * entryH;
    const entry = log[i];
    // Numbered
    fill(PAL.TEAL);
    noStroke();
    textSize(10);
    textFont(FONT_UI);
    text('[' + (i + 1) + ']', lx + 14, eY - 1);
    // Message
    textFont(FONT_BODY);
    textSize(12);
    fill(PAL.PARCHMENT);
    noStroke();
    const msgX = lx + 50;
    drawGlowText(entry, msgX, eY, PAL.PARCHMENT, 12);
  }

  // Quest stages summary (hardcoded from SPEC)
  const stagesY = ly + lh - 36;
  textFont(FONT_UI);
  textSize(8);
  fill(PAL.DIM);
  noStroke();
  const stages = [
    'SIGNAL: distress / bounty / dream',
    'CROSSING: Wind Shear / Aether Leak / Sky-Predator',
    'CONTACT: elder / engine spirit / child / salvager',
    'CHOICE: Save / Preserve / Allow Ascent',
    'WAKE: 6 epilogues'
  ];
  stages.forEach((s, i) => {
    const sx = lx + 14 + (i % 2) * (lw / 2);
    const sy = stagesY + Math.floor(i / 2) * 14;
    fill(PAL.DIM);
    noStroke();
    text(s, sx, sy);
  });

  pop();
}

// ─────────────────────────────────────────────
// INVENTORY DISPLAY
// ─────────────────────────────────────────────

/**
 * Draw the inventory panel — grid of item slots.
 */
function drawInventory(ix, iy, iw, ih) {
  push();
  fill(PAL.NAVY);
  noStroke();
  rect(ix, iy, iw, ih);
  drawPixelBorder(ix, iy, iw, ih, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('INVENTORY', ix + 12, iy + 10, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(ix + 12, iy + 24, ix + iw - 12, iy + 24);

  // Items grid
  const slotSize = 48;
  const gap = 6;
  const cols = Math.floor((iw - 24) / (slotSize + gap));
  const items = window.UI.inventory;
  const startX = ix + 12;
  const startY = iy + 34;

  textFont(FONT_BODY);
  textSize(11);

  items.forEach((item, idx) => {
    const col = idx % cols;
    const row = Math.floor(idx / cols);
    const sx = startX + col * (slotSize + gap);
    const sy = startY + row * (slotSize + gap);

    // Slot bg
    noStroke();
    fill(PAL.SHADOW);
    rect(sx, sy, slotSize, slotSize);
    drawPixelBorder(sx, sy, slotSize, slotSize, 1, PAL.SHADOW, PAL.DIM);

    // Item name (truncated)
    fill(PAL.PARCHMENT);
    noStroke();
    textAlign(CENTER, CENTER);
    textFont(FONT_UI);
    textSize(8);
    const name = item.name || item;
    text(name.substring(0, 10), sx + slotSize / 2, sy + slotSize / 2 - 4);
    textFont(FONT_BODY);
    textSize(9);
    fill(PAL.DIM);
    text('x' + (item.qty || 1), sx + slotSize / 2, sy + slotSize / 2 + 10);
  });

  if (items.length === 0) {
    textFont(FONT_BODY);
    textSize(12);
    textAlign(CENTER, CENTER);
    fill(PAL.DIM);
    noStroke();
    text('Empty', ix + iw / 2, iy + ih / 2);
  }

  pop();
}

// ─────────────────────────────────────────────
// NPC DIALOGUE BOX
// ─────────────────────────────────────────────

/**
 * Draw an NPC dialogue box at the bottom of the screen.
 * @param {object} npc — { name, title? }
 * @param {string} text — dialogue text (wraps)
 */
function drawNPCDialogue(npc, text) {
  push();
  window.UI.dialogueOpen = true;
  window.UI.dialogueNPC = npc;
  window.UI.dialogueText = text;

  const bw = Math.min(width * 0.7, 600);
  const bh = 90;
  const bx = (width - bw) / 2;
  const by = height - bh - 20;

  // Backdrop
  fill(color(PAL.NAVY), 200);
  noStroke();
  rect(0, height - bh - 40, width, bh + 40);

  // Box
  fill(PAL.SHADOW);
  noStroke();
  rect(bx, by, bw, bh);
  drawPixelBorder(bx, by, bw, bh, 3, PAL.SHADOW, PAL.TEAL);

  // NPC name header
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const npcName = npc.name || 'UNKNOWN';
  const npcTitle = npc.title ? ' — ' + npc.title : '';
  drawGlowText(npcName + npcTitle, bx + 12, by + 8, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(bx + 12, by + 22, bx + bw - 12, by + 22);

  // Dialogue text — wrap manually
  textFont(FONT_BODY);
  textSize(13);
  textAlign(LEFT, TOP);
  textLeading(16);

  const maxTextW = bw - 24;
  const words = text.split(' ');
  let line = '';
  let ly = by + 30;
  let lineCount = 0;
  const maxLines = 3;

  for (let i = 0; i < words.length && lineCount < maxLines; i++) {
    const test = line ? line + ' ' + words[i] : words[i];
    if (textWidth(test) > maxTextW && line) {
      // Draw line
      drawGlowText(line, bx + 12, ly, PAL.PARCHMENT, 13);
      line = words[i];
      ly += 16;
      lineCount++;
    } else {
      line = test;
    }
  }
  // Draw last line
  if (line && lineCount < maxLines) {
    drawGlowText(line, bx + 12, ly, PAL.PARCHMENT, 13);
    lineCount++;
  }

  // Continue prompt
  if (lineCount > 0) {
    textFont(FONT_UI);
    textSize(8);
    textAlign(CENTER, CENTER);
    fill(PAL.DIM);
    noStroke();
    const promptY = by + bh - 12;
    drawGlowTextCenter('[E] continue', bx + bw / 2, promptY,
                        PAL.DIM, 8);
  }

  pop();
}

/**
 * Close dialogue.
 */
function clearDialogueOverlay() {
  window.UI.dialogueOpen = false;
  window.UI.dialogueNPC = null;
  window.UI.dialogueText = '';
}

// ─────────────────────────────────────────────
// SHOP INTERFACE (Repair Cafe)
// ─────────────────────────────────────────────

/**
 * Draw the Repair Cafe shop interface.
 * @param {Array} items — [{ name, desc, cost, repair?, buy? }]
 */
function drawShop(items) {
  push();
  window.UI.shopOpen = true;
  window.UI.shopItems = items || [];

  const sw = Math.min(width * 0.75, 640);
  const sh = Math.min(height * 0.7, 420);
  const sx = (width - sw) / 2;
  const sy = (height - sh) / 2;

  // Backdrop
  fill(color(PAL.NAVY), 220);
  noStroke();
  rect(0, 0, width, height);

  // Shop panel
  fill(PAL.SHADOW);
  noStroke();
  rect(sx, sy, sw, sh);
  drawPixelBorder(sx, sy, sw, sh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(10);
  textAlign(CENTER, CENTER);
  drawGlowTextCenter('REPAIR CAFE', sx + sw / 2, sy + 18, PAL.TEAL, 10);

  textFont(FONT_BODY);
  textSize(11);
  fill(PAL.DIM);
  noStroke();
  textAlign(CENTER, CENTER);
  text('— Salvager\'s Row —', sx + sw / 2, sy + 34);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(sx + 16, sy + 44, sx + sw - 16, sy + 44);

  // Money/resource display
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const resX = sx + 16;
  const resY = sy + 52;
  drawGlowText('SCRAP: 7', resX, resY, PAL.DUST, 9);
  drawGlowText('AETHER: 4/6', resX + 110, resY, PAL.SCIOTO, 9);
  drawGlowText('CHARGE: 2.0kWh', resX + 230, resY, PAL.BIO, 9);

  // Items grid
  const itemsData = window.UI.shopItems;
  const itemW = 180;
  const itemH = 100;
  const itemGap = 12;
  const cols = Math.floor((sw - 32) / (itemW + itemGap));
  const startX = sx + 16;
  const startY = sy + 74;

  textFont(FONT_BODY);
  textSize(12);

  itemsData.forEach((item, idx) => {
    const col = idx % cols;
    const row = Math.floor(idx / cols);
    const ix = startX + col * (itemW + itemGap);
    const iy = startY + row * (itemH + itemGap);

    // Item card
    fill(PAL.NAVY);
    noStroke();
    rect(ix, iy, itemW, itemH);
    drawPixelBorder(ix, iy, itemW, itemH, 2, PAL.SHADOW, PAL.TEAL);

    // Item icon placeholder — colored square
    noStroke();
    fill(PAL.BIO);
    rect(ix + 10, iy + 10, 30, 30);
    drawPixelBorder(ix + 10, iy + 10, 30, 30, 1, PAL.SHADOW, PAL.TEAL);

    // Item name
    fill(PAL.PARCHMENT);
    noStroke();
    textAlign(LEFT, TOP);
    textFont(FONT_UI);
    textSize(9);
    const name = item.name || 'Unknown';
    drawGlowText(name.substring(0, 20), ix + 48, iy + 10, PAL.TEAL, 9);

    // Description
    textFont(FONT_BODY);
    textSize(11);
    fill(PAL.DIM);
    noStroke();
    const desc = item.desc || '';
    const descLines = desc.split(' ').slice(0, 8).join(' ');
    text(descLines.substring(0, 40), ix + 12, iy + 48);

    // Cost
    textFont(FONT_UI);
    textSize(9);
    textAlign(LEFT, TOP);
    const costStr = item.cost ? `SCRAP ${item.cost}` : '—';
    drawGlowText(costStr, ix + 12, iy + 74, item.cost ? PAL.DUST : PAL.DIM, 9);

    // Action hint
    textFont(FONT_UI);
    textSize(8);
    fill(PAL.DIM);
    noStroke();
    const action = item.repair ? '[R] Repair' :
                  item.buy ? '[B] Buy' : '[X] Back';
    text(action, ix + itemW - 60, iy + itemH - 12);
  });

  // Footer
  textFont(FONT_UI);
  textSize(8);
  textAlign(CENTER, CENTER);
  fill(PAL.DIM);
  noStroke();
  text('M: close shop  ESC: back', sx + sw / 2, sy + sh - 10);

  pop();
}

/**
 * Close shop.
 */
function clearShopOverlay() {
  window.UI.shopOpen = false;
  window.UI.shopItems = [];
}

// ─────────────────────────────────────────────
// TURN OVERLAY
// ─────────────────────────────────────────────

/**
 * Draw a turn overlay — full-screen announcement of whose turn it is.
 * @param {string} actor — actor name
 * @param {string} phase — 'INITIATIVE' | 'ACTION' | 'RESOLUTION' | 'END'
 */
function drawTurnOverlay(actor, phase) {
  push();
  window.UI.turnOverlay = true;

  const overlayMsg = phase + ' — ' + actor;

  // Dim backdrop
  fill(color(PAL.NAVY), 200);
  noStroke();
  rect(0, 0, width, height);

  // Central text
  textFont(FONT_UI);
  textSize(14);
  textAlign(CENTER, CENTER);
  let color = PAL.TEAL;
  if (phase === 'END') color = PAL.DIM;
  else if (phase === 'RESOLUTION') color = PAL.SCIOTO;
  drawGlowTextCenter(overlayMsg, width / 2, height / 2, color, 14);

  // Sub-text
  textFont(FONT_BODY);
  textSize(11);
  fill(PAL.PARCHMENT);
  noStroke();
  textAlign(CENTER, CENTER);
  const sub = phase === 'INITIATIVE' ? 'Grace + Wits determine turn order' :
              phase === 'ACTION' ? 'Choose action — main or secondary' :
              phase === 'RESOLUTION' ? 'Stats + ability formula resolve the action' :
              phase === 'END' ? 'Press SPACE for next turn' : '';
  if (sub) {
    drawGlowTextCenter(sub, width / 2, height / 2 + 40, PAL.PARCHMENT, 11);
  }

  pop();
}

/**
 * Clear turn overlay.
 */
function clearTurnOverlay() {
  window.UI.turnOverlay = false;
}

// ─────────────────────────────────────────────
// DRAW HUD (main entry — composites all HUD layers)
// ─────────────────────────────────────────────

/**
 * Main HUD draw — called each frame. Composites background, HUD, day-night, scanlines.
 * @param {object} gameState — { showCharSheet, showCombatLog, showQuestLog, showInventory, showDice, diceResult, diceDesc, showMenu, menuArgs, showDialogue, npc, dialogueText, showShop, shopItems, showTurnOverlay, turnActor, turnPhase }
 */
function drawHUDFrame(gameState) {
  push();
  // Background + grid
  drawBackground();

  const mode = gameState || {};

  // Day-night in corner
  drawDayNightIndicatorHUD(width - 56, 44, 28);

  // HUD bar
  if (mode.showHUD !== false) {
    drawHUD(16, 16, 440, 72);
  }

  // Character sheet
  if (mode.showCharSheet) {
    drawCharSheet(16, 100, 440, 360);
  }

  // Combat log
  if (mode.showCombatLog) {
    drawCombatLog(width - 240, 100, 224, 260);
  }

  // Quest log
  if (mode.showQuestLog) {
    drawQuestLog(16, 100, 280, 340);
  }

  // Inventory
  if (mode.showInventory) {
    drawInventory(width - 260, 380, 244, 200);
  }

  // Dice roll
  if (mode.showDice && mode.diceResult != null) {
    drawDiceRoll(mode.diceResult, mode.diceDesc || '',
                 width / 2, height / 2 - 20, 56);
  }

  // Dialogue
  if (mode.showDialogue && mode.npc) {
    drawNPCDialogue(mode.npc, mode.dialogueText || '');
  }

  // Shop
  if (mode.showShop) {
    drawShop(mode.shopItems || [
      { name: 'Resonator Tuning', desc: 'Realign cyan crystal, +1 EMP', cost: 3, repair: true },
      { name: 'Loom Patch Kit', desc: 'Solar tube repair — restore 0.5kWh', cost: 2, repair: true },
      { name: 'Mycelial Ink', desc: 'Tattoo refresh — +1 Presence temp', cost: 4, buy: true },
      { name: 'Goggle Lens', desc: 'Green filter — +1 Wits in aether', cost: 5, buy: true },
    ]);
  }

  // Menu
  if (mode.showMenu) {
    // Re-open menu if not already open (compatibility)
    if (!window.UI.menuOpen && mode.menuArgs) {
      const ma = mode.menuArgs;
      openMenu(ma.title || 'MENU', ma.options || [], ma.callback || null);
    }
    drawMenu();
  }

  // Turn overlay
  if (mode.showTurnOverlay) {
    drawTurnOverlay(mode.turnActor || 'ENDER',
                     mode.turnPhase || 'ACTION');
  }

  // Particles
  if (VIS.particles) {
    updateParticles();
    drawParticles();
  }

  // Screen flash
  drawScreenFlashLegacy();

  pop();
}

// ─────────────────────────────────────────────
// MODULE INIT
// ─────────────────────────────────────────────
console.log('[UI] Aetherwake UI module loaded —',
            Object.keys(window.UI).join(', '));

function drawScreenFlashLegacy() {
  if (!window.screenFlash || !window.screenFlash.active) return;
  const age = millis() - window.screenFlash.startTime;
  if (age > window.screenFlash.duration) {
    window.screenFlash.active = false;
    return;
  }
  const t = 1 - age / window.screenFlash.duration;
  const alpha = t * window.screenFlash.alpha;
  noStroke();
  fill(color(255, 255, 255, alpha));
  rect(0, 0, width, height);
}

