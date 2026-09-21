// PLAYABLE_RUNTIME_AUTHORITY
// This file is the integrated Aetherwake gameplay runtime loaded by both
// index.html and index-embedded.html.
//
// Do not infer playable behavior from modules/core.js, modules/combat.js,
// modules/world.js, modules/ui.js, or modules/ui-adapter.js. Those files are
// NON_RUNTIME_MIRROR sources unless an entrypoint explicitly loads them.
//
// Runtime authority contract: docs/RUNTIME_AUTHORITY.md
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
  shad:     [60, 50, 60],   // dark gray-violet for shadow fills (char-create module expects this)
  dim:      [80, 70, 90],   // muted blue-gray for labels/indicators (char-create module expects this)
};

// ── State ──
const STATE = {
  BOOT: 'boot', MENU: 'menu', WORLD: 'world', COMBAT: 'combat',
  DIALOGUE: 'dialogue', SHOP: 'shop', LEDGER: 'ledger',
  QUESTLOG: 'questlog', CHARSHEET: 'charsheet', AIRSHIP: 'airship',
  SYSTEMMENU: 'systemmenu', CHARCREATE: 'charcreate',
};
let gameState = STATE.BOOT;
window.gameState = gameState;  // expose for debug
let prevState = null;       // compatibility projection of the current overlay return target
let overlayStateStack = [];  // nested JRPG menus: WORLD → SYSTEMMENU → STATUS, etc.
let lastFrameState = null;  // render/fade tracking only
let menuAutoStartTimer = 0;  // one-shot: auto-start from MENU after 3s idle (prevents single-press hang)

// Boot sequence timing
let bootTime = 0;
const BOOT_LOAD_MS = 1200;   // how long loading text shows
const PREAMBLE_DURATION = 9000; // preamble text scroll duration
let preambleStart = 0;
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
let charSheetRosterIndex = 0; // read-only roster browser selection; never changes formation
let titleMenuCursor = 0;
let systemMenuCursor = 0;
let combatCursor = 0;
let shopCursor = 0;
let airshipCursor = 0;
let choiceCursor = 0;

// ── Dialogue type-in ──
let dialogueTypeIn = { active: false, fullText: '', displayText: '', charIndex: 0, speed: 22, lastCharTime: 0 };

// ── Global visual settings ──
const VIS = {
  screenShake: true,
  hitStop: true,
  fadeTransitions: true,
  dialogueTypeIn: true,
  // Disabled in the integrated runtime until the vignette compositor is
  // rewritten. The current concentric navy-ellipse implementation repeatedly
  // darkens the center and can bury otherwise valid title/world rendering.
  vignette: false,
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
let airshipState = null;

// Expose state for debugging
window.gameState = gameState;

// Timing
let lastTime = 0;
let dt = 0;

// Input
const keys = {};
const keysPressed = {};
const keyRepeat = {};
const keyRepeatFirst = {};

// ── setup() ──
let initializationFailed = false;

function showInitializationFailure(message) {
  initializationFailed = true;
  window.__aetherwakeInitFailed = true;
  const text = 'AETHERWAKE INITIALIZATION FAILED: ' + message;
  if (typeof document !== 'undefined') {
    const node = document.getElementById('aetherwake-init-error');
    if (node) {
      node.textContent = text;
      node.hidden = false;
      node.classList.add('aetherwake-init-failed');
    }
  }
  if (typeof noLoop === 'function') noLoop();
}

window.showInitializationFailure = showInitializationFailure;

function setup() {
  window._setupOrder = window._setupOrder ? window._setupOrder + '→setup-start' : 'setup-start';
  const canvas = createCanvas(960, 640);
  // #jrpg-container is the full-viewport game host. Without an explicit
  // parent, p5 appends the canvas after that 100%-height element, placing the
  // real game below an overflow:hidden viewport.
  if (canvas && typeof canvas.parent === 'function') {
    canvas.parent('jrpg-container');
  }
  window._setupOrder = window._setupOrder + '→canvas-done';
  // Now proceed with normal setup
  frameRate(60);
  pixelDensity(1);
  colorMode(RGB, 255);
  textFont('VT323');
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
  if (typeof window.AetherWorld === 'undefined') {
    showInitializationFailure('WORLD_MODULE_MISSING');
    return;
  }
  world = window.AetherWorld(p5, C);
  window._world = world;
  if (world && typeof world.init === 'function') world.init();
  if (!world || !world.player) {
    showInitializationFailure('WORLD_PLAYER_UNAVAILABLE_FOR_PARTY_STATE');
    return;
  }

  if (!window.AetherCombatSystemPolicy ||
      typeof window.AetherCombatSystemPolicy.validate !== 'function') {
    showInitializationFailure('AETHER_COMBAT_SYSTEM_POLICY_UNAVAILABLE');
    return;
  }
  try {
    window.AetherCombatSystemPolicy.validate();
  } catch (error) {
    showInitializationFailure('AETHER_COMBAT_SYSTEM_POLICY_INVALID');
    return;
  }
  window._combatSystemPolicy = window.AetherCombatSystemPolicy;

  if (!window.AetherCombatFormula ||
      typeof window.AetherCombatFormula.resolveAction !== 'function' ||
      typeof window.AetherCombatFormula.validateAgainstAbilityDefs !== 'function') {
    showInitializationFailure('AETHER_COMBAT_FORMULA_UNAVAILABLE');
    return;
  }
  try {
    window.AetherCombatFormula.validateAgainstAbilityDefs(window.AetherAbilityDefs);
  } catch (error) {
    showInitializationFailure('AETHER_COMBAT_FORMULA_INVALID');
    return;
  }
  window._combatFormula = window.AetherCombatFormula;

  if (!window.AetherMasteryDefs ||
      typeof window.AetherMasteryDefs.validate !== 'function') {
    showInitializationFailure('AETHER_MASTERY_DEFS_UNAVAILABLE');
    return;
  }
  try {
    window.AetherMasteryDefs.validate();
  } catch (error) {
    showInitializationFailure('AETHER_MASTERY_DEFS_INVALID');
    return;
  }
  window._masteryDefs = window.AetherMasteryDefs;

  if (!window.AetherMagicAccess ||
      typeof window.AetherMagicAccess.validate !== 'function') {
    showInitializationFailure('AETHER_MAGIC_ACCESS_UNAVAILABLE');
    return;
  }
  try {
    window.AetherMagicAccess.validate();
  } catch (error) {
    showInitializationFailure('AETHER_MAGIC_ACCESS_INVALID');
    return;
  }
  window._magicAccess = window.AetherMagicAccess;

  if (!window.AetherSense ||
      typeof window.AetherSense.validate !== 'function' ||
      typeof window.AetherSense.scan !== 'function') {
    showInitializationFailure('AETHER_SENSE_UNAVAILABLE');
    return;
  }
  try {
    window.AetherSense.validate();
  } catch (error) {
    showInitializationFailure('AETHER_SENSE_INVALID');
    return;
  }
  window._aetherSense = window.AetherSense;

  if (!window.AetherFieldRoleDefs ||
      typeof window.AetherFieldRoleDefs.validate !== 'function' ||
      typeof window.AetherFieldRoleDefs.list !== 'function') {
    showInitializationFailure('AETHER_FIELD_ROLE_DEFS_UNAVAILABLE');
    return;
  }
  try {
    window.AetherFieldRoleDefs.validate();
  } catch (error) {
    showInitializationFailure('AETHER_FIELD_ROLE_DEFS_INVALID');
    return;
  }
  window._fieldRoleDefs = window.AetherFieldRoleDefs;

  if (!window.AetherPartyCombatBridge ||
      typeof window.AetherPartyCombatBridge.createSnapshot !== 'function' ||
      typeof window.AetherPartyCombatBridge.validateSnapshot !== 'function') {
    showInitializationFailure('AETHER_PARTY_COMBAT_BRIDGE_UNAVAILABLE');
    return;
  }
  window._partyCombatBridge = window.AetherPartyCombatBridge;

  if (!window.AetherPartyState || typeof window.AetherPartyState.bootstrap !== 'function') {
    showInitializationFailure('AETHER_PARTY_STATE_UNAVAILABLE');
    return;
  }
  window.AetherPartyState.bootstrap(world.player);
  if (!window.AetherSaveState ||
      window.AetherSaveState.schemaVersion !== 2 ||
      typeof window.AetherSaveState.createDocument !== 'function' ||
      typeof window.AetherSaveState.loadFromStorage !== 'function') {
    showInitializationFailure('AETHER_SAVE_STATE_UNAVAILABLE');
    return;
  }
  window._saveState = window.AetherSaveState;
  if (!window.AetherAirshipState ||
      typeof window.AetherAirshipState.createState !== 'function') {
    showInitializationFailure('AETHER_AIRSHIP_STATE_UNAVAILABLE');
    return;
  }
  airshipState = window.AetherAirshipState.createState(world.player.airship);
  world.player.airship = airshipState;
  window._airshipState = airshipState;
  installRuntimePersistenceAdapter();
  window._setupOrder = window._setupOrder + '→party-state-done';
  window._setupOrder = window._setupOrder + '→combat-start';
  if (typeof window.AetherCombat === 'undefined') {
    showInitializationFailure('AETHER_COMBAT_MODULE_MISSING');
    return;
  }
  combat = new window.AetherCombat(window, C);
  window._combat = combat;
  if (!combat || typeof combat.init !== 'function') {
    showInitializationFailure('AETHER_COMBAT_UNAVAILABLE');
    return;
  }
  combat.init();
  window._setupOrder = window._setupOrder + '→combat-done';
  // Character creation is required for the playable entrypoint.
  if (typeof window.AetherCharCreate === 'undefined') {
    showInitializationFailure('AETHER_CHAR_CREATE_MODULE_MISSING');
    return;
  }
  window._charcreate = window.AetherCharCreate;
  if (window._charcreate && typeof window._charcreate.init === 'function') window._charcreate.init();
  window._setupOrder = window._setupOrder + '→charcreate-done';
  window._setupOrder = window._setupOrder + '→setup-done';
  lastTime = millis();
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

  // MENU is an explicit JRPG command surface. Do not auto-start a game;
  // the player confirms NEW GAME or CONTINUE.
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
      // Re-init combat from the canonical lead + validated three-member context.
      if (combat && typeof combat.init === 'function') {
        combat.init(buildCombatPlayerSnapshot());
      }
      gameState = STATE.WORLD;
      window.gameState = gameState;
    }
  }
  else if (gameState === STATE.WORLD) {
    if (world && typeof world.update === 'function') world.update(dt / 1000);
    if (world && typeof world.render === 'function') world.render();
  }
  else if (gameState === STATE.AIRSHIP) {
    drawAirshipOverlay();
  }
  else if (gameState === STATE.COMBAT) {
    if (combat && typeof combat.render === 'function') combat.render();
    if (combat && typeof combat.drawCombatScene === 'function') {
      const px = world ? world.player.px : 160;
      const py = world ? world.player.py : 380;
      const aetherInfo = combat.getAether ? combat.getAether() : { max: 6 };
      const chargeInfo = combat.getCharges ? combat.getCharges() : { max: 2 };
      combat.drawCombatScene(px, py, aetherInfo.max, chargeInfo.max);
    }
    // Draw combat UI panel
    if (typeof drawCombatPanel === 'function' && combat && typeof combat.getState === 'function') {
      drawCombatPanel(combat.getState());
    }
    // Draw combat log on the right
    if (typeof drawCombatLog === 'function') {
      drawCombatLog(width - 240, 100, 224, 280);
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
  else if (gameState === STATE.SYSTEMMENU) {
    if (world && typeof world.render === 'function') world.render();
    drawSystemMenuOverlay();
  }

  // ── Vignette (intensifies at night) ──
  if (VIS.vignette) {
    drawVignette();
  }

  // ── Toast messages ──
  drawToasts();

  // ── Fade transition overlay ──
  drawFadeOverlay();

  // ── Dialogue type-in effect ──
  updateDialogueTypeIn();
  if (dialogueTypeIn.active && gameState === STATE.DIALOGUE) {
    // The animation owns the displayed string while active. Do not gate this
    // on the current text being truthy: the first type-in frame may
    // intentionally be empty before the first character is revealed.
    window.UI.dialogueText = dialogueTypeIn.displayText;
  }

  drawScanlines();

  // ── Scene fade: track the last rendered state without clobbering overlay return state ──
  lastFrameState = gameState;

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
}

// ── Input ──
// Interaction key for world module (set by keyPressed, read by world.interact)
let interactionKey = null;

function jrpgInputApi() {
  return window.AetherJrpgInput || null;
}

function inputPressed(action) {
  const api = jrpgInputApi();
  return Boolean(api && typeof api.isPressed === 'function' &&
    api.isPressed(keysPressed, action));
}

function inputHeld(action) {
  const api = jrpgInputApi();
  return Boolean(api && typeof api.isHeld === 'function' &&
    api.isHeld(keys, action));
}

function normalizedLegacyPressed() {
  const out = Object.assign({}, keysPressed);
  const api = jrpgInputApi();
  if (!api || !api.ACTION) return out;
  if (inputPressed(api.ACTION.OK)) out[13] = true;
  if (inputPressed(api.ACTION.CANCEL)) out[27] = true;
  if (inputPressed(api.ACTION.LEFT)) out[37] = true;
  if (inputPressed(api.ACTION.UP)) out[38] = true;
  if (inputPressed(api.ACTION.RIGHT)) out[39] = true;
  if (inputPressed(api.ACTION.DOWN)) out[40] = true;
  return out;
}

function keyPressed() {
  keys[keyCode] = true;
  keysPressed[keyCode] = true;

  // F2 / F3 are player-facing persistence shortcuts. Handle them before
  // ordinary state dispatch so they remain one-shot and cannot leak into
  // overlay/combat controls.
  if (keyCode === 113) { // F2
    quickSaveGame();
    delete keysPressed[keyCode];
    return false;
  }
  if (keyCode === 114) { // F3
    quickLoadGame();
    delete keysPressed[keyCode];
    return false;
  }

  // Set interaction key BEFORE calling handleInput so that
  // world.interact()/handleWorldInput() see the current key.
  // Standard JRPG OK is contextual; legacy Aetherwake hotkeys remain aliases.
  if (gameState === STATE.WORLD) {
    const inputApi = jrpgInputApi();
    if (inputApi && inputPressed(inputApi.ACTION.OK)) window.interactionKey = 'ok';
    else if (keyCode === 69) window.interactionKey = 'e';
    else if (keyCode === 81) window.interactionKey = 'q';
    else if (keyCode === 70) window.interactionKey = 'f';
    else if (keyCode === 9) window.interactionKey = 'tab';
    else if (keyCode === 76) window.interactionKey = 'l';
    else if (keyCode === 77) window.interactionKey = 'm';
    // C = 67: start combat encounter (dev/testing)
    else if (keyCode === 67) {
      if (combat && typeof combat.beginEncounter === 'function') {
        startCombat('skyPredator');
      }
    }
  }

  handleInput();

  // Numeric choices use keydown so browser layouts cannot drop the selection.
  if ((gameState === STATE.WORLD || gameState === STATE.DIALOGUE) &&
      keyCode >= 49 && keyCode <= 51) {
    handleChoiceInput(String(keyCode - 48));
  }

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
    const inputApi = jrpgInputApi();
    const menuOk = Boolean(inputApi && inputPressed(inputApi.ACTION.OK));
    if (menuOk || keyCode === 78 || keyCode === 110) {
      if (typeof window.playMenuSelect === 'function') window.playMenuSelect();
    }
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
  const inputApi = jrpgInputApi();
  const releasesOk = Boolean(inputApi &&
    inputApi.actionsForKeyCode(keyCode).includes(inputApi.ACTION.OK));
  if (releasesOk || keyCode === 69 || keyCode === 81 || keyCode === 70 ||
      keyCode === 9 || keyCode === 76 || keyCode === 77) {
    window.interactionKey = null;
  }
}

function keyTyped() {
  // Text entry is the only responsibility of keyTyped. All game-state actions
  // are edge-triggered from keyPressed through the JRPG semantic input layer.
  // This prevents one physical Enter/Space/Z press from advancing two states.
  if (gameState === STATE.CHARCREATE &&
      window._charcreate &&
      typeof window._charcreate.handleTypedChar === 'function') {
    window._charcreate.handleTypedChar(key);
  }
}

function windowResized() {
  resizeCanvas(960, 640);
}

function handleInput() {
  if (lastFrameState !== null && lastFrameState !== gameState && VIS.fadeTransitions) {
    fade.active = true;
    fade.from = lastFrameState;
    fade.to = gameState;
    fade.startTime = millis() - 1;
    fade.duration = 250;
  }

  window._lastStateTransition = {
    from: lastFrameState,
    to: gameState,
    time: millis(),
    keyCode: (typeof keyCode !== 'undefined' ? keyCode : null),
  };

  const api = jrpgInputApi();
  const A = api ? api.ACTION : {};
  const ok = api ? inputPressed(A.OK) : Boolean(keysPressed[13] || keysPressed[32]);
  const cancel = api ? inputPressed(A.CANCEL) : Boolean(keysPressed[27]);
  const up = api ? inputPressed(A.UP) : Boolean(keysPressed[38]);
  const down = api ? inputPressed(A.DOWN) : Boolean(keysPressed[40]);
  const left = api ? inputPressed(A.LEFT) : Boolean(keysPressed[37]);
  const right = api ? inputPressed(A.RIGHT) : Boolean(keysPressed[39]);
  const pageUp = api ? inputPressed(A.PAGEUP) : Boolean(keysPressed[33]);
  const pageDown = api ? inputPressed(A.PAGEDOWN) : Boolean(keysPressed[34]);
  const shift = api ? inputPressed(A.SHIFT) : Boolean(keysPressed[16]);

  if (gameState === STATE.BOOT) {
    if (ok || keysPressed[78] || keysPressed[110]) {
      gameState = STATE.MENU;
      window.gameState = gameState;
      titleVisible = 0;
      titleFlash = 0;
      titleMenuCursor = 0;
    }
    return;
  }

  if (gameState === STATE.MENU) {
    handleTitleMenuInput({ ok, up, down });
    return;
  }

  if (gameState === STATE.CHARCREATE) {
    if (window._charcreate && typeof window._charcreate.handleInput === 'function') {
      window._charcreate.handleInput(keys, normalizedLegacyPressed());
    }
    return;
  }

  if (gameState === STATE.WORLD) {
    handleWorldInput();
    return;
  }

  if (gameState === STATE.SYSTEMMENU) {
    handleSystemMenuInput({ ok, cancel, up, down });
    return;
  }

  if (gameState === STATE.AIRSHIP) {
    handleAirshipInput({ ok, cancel, up, down, left, right });
    return;
  }

  if (gameState === STATE.COMBAT) {
    if (combat && typeof combat.handleInput === 'function') {
      combat.handleInput(keys, normalizedLegacyPressed());
    }
    const combatState = combat && typeof combat.getState === 'function'
      ? combat.getState()
      : null;

    if (combatState && combatState.encounterOver && (ok || cancel)) {
      finishCombat();
      return;
    }

    const actions = combatState && Array.isArray(combatState.actions)
      ? combatState.actions
      : [];
    if (actions.length > 0) {
      if (up || left) combatCursor = (combatCursor - 1 + actions.length) % actions.length;
      else if (down || right) combatCursor = (combatCursor + 1) % actions.length;

      if (ok && combat && typeof combat.resolveTurn === 'function') {
        const selected = actions[combatCursor];
        if (selected) combat.resolveTurn(selected.id, null);
      }
    }

    if (typeof key === 'string' && key >= '1' && key <= '8' &&
        combat && typeof combat.resolveTurn === 'function') {
      const actionIds = ['staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger',
        'hold', 'windWard', 'aetherSeal', 'rest'];
      const idx = key.charCodeAt(0) - 49;
      if (idx >= 0 && idx < actionIds.length) {
        combatCursor = idx;
        combat.resolveTurn(actionIds[idx], null);
      }
    }

    if ((shift || (typeof key === 'string' && key.toLowerCase() === 's')) &&
        combat && typeof combat.resolveSecondaryAction === 'function') {
      combat.resolveSecondaryAction();
    }
    return;
  }

  if (gameState === STATE.DIALOGUE) {
    if (cancel) {
      if (world && typeof world.closeDialogue === 'function') world.closeDialogue();
      closeOverlay();
      return;
    }
    if (ok || keysPressed[69]) {
      if (world && typeof world.nextDialogueLine === 'function') {
        world.nextDialogueLine();
        if (!window.UI.dialogueOpen) closeOverlay();
      }
    }
    return;
  }

  if (gameState === STATE.SHOP) {
    handleShopInput({ ok, cancel, up, down });
    return;
  }

  if (gameState === STATE.CHARSHEET) {
    if (pageUp || left) {
      charSheetRosterIndex = (charSheetRosterIndex + 4) % 5;
      return;
    }
    if (pageDown || right) {
      charSheetRosterIndex = (charSheetRosterIndex + 1) % 5;
      return;
    }
    if (keysPressed[49] || keysPressed[50] || keysPressed[51] ||
        keysPressed[52] || keysPressed[53]) {
      const selectedCode = [49, 50, 51, 52, 53].find(code => keysPressed[code]);
      if (selectedCode != null) charSheetRosterIndex = selectedCode - 49;
      return;
    }
    if (cancel || keysPressed[82]) closeOverlay();
    return;
  }

  if (gameState === STATE.LEDGER || gameState === STATE.QUESTLOG) {
    if (cancel || ok ||
        (gameState === STATE.LEDGER && keysPressed[76]) ||
        (gameState === STATE.QUESTLOG && keysPressed[84])) {
      closeOverlay();
    }
    return;
  }

  if (cancel || ok) closeOverlay();
}

function handleWorldInput() {
  // Arrow-key movement follows the Memories/RPG Maker convention.
  // WASD remains a compatibility alias through the key map below.
  const now = millis();
  const api = jrpgInputApi();
  const ok = api ? inputPressed(api.ACTION.OK) : Boolean(keysPressed[13] || keysPressed[32]);
  const menu = api ? inputPressed(api.ACTION.MENU) : Boolean(keysPressed[27] || keysPressed[88]);
  const up = api ? inputPressed(api.ACTION.UP) : Boolean(keysPressed[38]);
  const down = api ? inputPressed(api.ACTION.DOWN) : Boolean(keysPressed[40]);
  const left = api ? inputPressed(api.ACTION.LEFT) : Boolean(keysPressed[37]);
  const right = api ? inputPressed(api.ACTION.RIGHT) : Boolean(keysPressed[39]);
  const fast = api ? inputHeld(api.ACTION.SHIFT) : Boolean(keys[16]);

  const questState = world && typeof world.getQuestState === 'function'
    ? world.getQuestState()
    : null;
  if (questState && questState.state === 'choice' && !questState.choiceMade) {
    const count = Array.isArray(questState.choicePaths) ? questState.choicePaths.length : 0;
    if (count > 0) {
      choiceCursor = Math.max(0, Math.min(choiceCursor, count - 1));
      if (up || left) choiceCursor = (choiceCursor - 1 + count) % count;
      else if (down || right) choiceCursor = (choiceCursor + 1) % count;
      else if (ok && typeof world.selectChoicePath === 'function') {
        world.selectChoicePath(choiceCursor);
      }
    }
    return;
  }
  const delay = fast ? 110 : 200;
  const rate = fast ? 35 : 60;

  const directions = [
    { primary: UP_ARROW, aliases: [87], dx: 0, dy: -1 },
    { primary: DOWN_ARROW, aliases: [83], dx: 0, dy: 1 },
    { primary: LEFT_ARROW, aliases: [65], dx: -1, dy: 0 },
    { primary: RIGHT_ARROW, aliases: [68], dx: 1, dy: 0 },
  ];

  for (const dir of directions) {
    const heldCode = [dir.primary].concat(dir.aliases).find(code => keys[code]);
    const repeatCode = heldCode || dir.primary;
    if (heldCode) {
      if (!keyRepeat[repeatCode]) {
        keyRepeat[repeatCode] = now;
        keyRepeatFirst[repeatCode] = true;
        world.movePlayer(dir.dx, dir.dy);
      } else if (now - keyRepeat[repeatCode] >=
                 (keyRepeatFirst[repeatCode] ? delay : rate)) {
        keyRepeat[repeatCode] = now;
        keyRepeatFirst[repeatCode] = false;
        world.movePlayer(dir.dx, dir.dy);
      }
    } else {
      [dir.primary].concat(dir.aliases).forEach(code => {
        delete keyRepeat[code];
        delete keyRepeatFirst[code];
      });
    }
  }

  if (ok && world && typeof world.interact === 'function') {
    window.interactionKey = 'ok';
    const result = world.interact();
    if (result && result.ok) {
      if (result.kind === 'dialogue') openState(STATE.DIALOGUE);
      else if (result.kind === 'airship') openState(STATE.AIRSHIP);
      else if (result.kind === 'shop') openState(STATE.SHOP);
      else if (result.kind === 'ledger') openState(STATE.LEDGER);
    }
  }

  if (menu) {
    systemMenuCursor = Math.max(0,
      Math.min(systemMenuCursor, getSystemMenuCommands().length - 1));
    openState(STATE.SYSTEMMENU);
    return;
  }

  // Compatibility aliases retained during migration.
  if (keysPressed[81] && world && typeof world.plantField === 'function') {
    world.plantField();
  }
  if (keysPressed[69] && world && typeof world.interact === 'function') {
    window.interactionKey = 'e';
    const result = world.interact();
    if (result && result.ok && result.kind === 'dialogue') openState(STATE.DIALOGUE);
  }
  if (keysPressed[70] && world && typeof world.interact === 'function') {
    window.interactionKey = 'f';
    const result = world.interact();
    if (result && result.ok && result.kind === 'airship') openState(STATE.AIRSHIP);
  }
  if (keysPressed[9] && world && typeof world.toggleLayer === 'function') world.toggleLayer();
  if (keysPressed[76]) openState(STATE.LEDGER);
  if (keysPressed[77] && world && typeof world.openShop === 'function') {
    const result = world.openShop();
    if (result && result.ok) openState(STATE.SHOP);
    else if (result && result.reason) addLedgerEntry('shop', result.reason);
  }
  if (keysPressed[86] && world && typeof world.senseAether === 'function') {
    const result = world.senseAether();
    if (result && !result.ok && result.reason) {
      addLedgerEntry('aether-sense',
        'Aether Sense unavailable: ' + result.reason + '.');
    }
  }
  if (keysPressed[82]) openState(STATE.CHARSHEET);
  if (keysPressed[84]) openState(STATE.QUESTLOG);

  if (keysPressed[67] && combat && typeof combat.beginEncounter === 'function') {
    startCombat('skyPredator');
  }
}


function getTitleMenuCommands() {
  const commands = [{ id: 'new', label: 'NEW GAME' }];
  if (hasStoredSave()) commands.push({ id: 'continue', label: 'CONTINUE' });
  return commands;
}

function activateTitleMenuCommand(command) {
  if (!command) return;
  if (command.id === 'continue') {
    quickLoadGame();
  } else if (command.id === 'new') {
    startGame();
  }
}

function handleTitleMenuInput(input) {
  const commands = getTitleMenuCommands();
  if (!commands.length) return;
  titleMenuCursor = Math.max(0, Math.min(titleMenuCursor, commands.length - 1));
  if (input.up) {
    titleMenuCursor = (titleMenuCursor - 1 + commands.length) % commands.length;
    return;
  }
  if (input.down) {
    titleMenuCursor = (titleMenuCursor + 1) % commands.length;
    return;
  }
  if (input.ok) activateTitleMenuCommand(commands[titleMenuCursor]);
}

function getSystemMenuCommands() {
  return [
    { id: 'status', label: 'STATUS' },
    { id: 'quest', label: 'QUEST' },
    { id: 'ledger', label: 'MYCELIAL LEDGER' },
    { id: 'sense', label: 'AETHER SENSE' },
    { id: 'field', label: 'COVENANT FIELD' },
    { id: 'layer', label: 'SKY / GROUND LAYER' },
    { id: 'save', label: 'SAVE' },
    { id: 'load', label: 'LOAD' },
  ];
}

function activateSystemMenuCommand(command) {
  if (!command) return;
  if (command.id === 'status') {
    openState(STATE.CHARSHEET);
  } else if (command.id === 'quest') {
    openState(STATE.QUESTLOG);
  } else if (command.id === 'ledger') {
    openState(STATE.LEDGER);
  } else if (command.id === 'sense') {
    const returnState = prevState || STATE.WORLD;
    closeOverlay();
    if (returnState === STATE.WORLD && world && typeof world.senseAether === 'function') {
      world.senseAether();
    }
  } else if (command.id === 'field') {
    const returnState = prevState || STATE.WORLD;
    closeOverlay();
    if (returnState === STATE.WORLD && world && typeof world.plantField === 'function') {
      world.plantField();
    }
  } else if (command.id === 'layer') {
    const returnState = prevState || STATE.WORLD;
    closeOverlay();
    if (returnState === STATE.WORLD && world && typeof world.toggleLayer === 'function') {
      world.toggleLayer();
    }
  } else if (command.id === 'save') {
    const returnState = prevState || STATE.WORLD;
    closeOverlay();
    if (returnState === STATE.WORLD) quickSaveGame();
  } else if (command.id === 'load') {
    const returnState = prevState || STATE.WORLD;
    closeOverlay();
    if (returnState === STATE.WORLD) quickLoadGame();
  }
}

function handleSystemMenuInput(input) {
  const commands = getSystemMenuCommands();
  if (!commands.length) return;
  if (input.cancel) {
    closeOverlay();
    return;
  }
  if (input.up) {
    systemMenuCursor = (systemMenuCursor - 1 + commands.length) % commands.length;
    return;
  }
  if (input.down) {
    systemMenuCursor = (systemMenuCursor + 1) % commands.length;
    return;
  }
  if (input.ok) activateSystemMenuCommand(commands[systemMenuCursor]);
}

function handleShopInput(input) {
  const items = window.UI && Array.isArray(window.UI.shopItems)
    ? window.UI.shopItems
    : [];
  if (input.cancel) {
    closeOverlay();
    return;
  }
  if (!items.length) return;
  shopCursor = Math.max(0, Math.min(shopCursor, items.length - 1));
  if (input.up) {
    shopCursor = (shopCursor - 1 + items.length) % items.length;
    return;
  }
  if (input.down) {
    shopCursor = (shopCursor + 1) % items.length;
    return;
  }
  if (input.ok && window.UI.shopBuyHandler) {
    window.UI.shopBuyHandler(String(shopCursor + 1));
  }
}

function commitAirshipState(nextState) {
  airshipState = nextState;
  window._airshipState = nextState;
  if (world && world.player) world.player.airship = nextState;
}

function installRuntimePersistenceAdapter() {
  function requireWorldPersistence(method) {
    if (!world || typeof world[method] !== 'function') {
      throw new Error('RUNTIME_WORLD_PERSISTENCE_API_UNAVAILABLE');
    }
    return world[method].bind(world);
  }

  function requireAirshipPersistence(method) {
    if (!window.AetherAirshipState ||
        typeof window.AetherAirshipState[method] !== 'function') {
      throw new Error('RUNTIME_AIRSHIP_PERSISTENCE_API_UNAVAILABLE');
    }
    return window.AetherAirshipState[method].bind(window.AetherAirshipState);
  }

  window.AetherRuntimePersistence = Object.freeze({
    exportWorldState: function() {
      return requireWorldPersistence('exportPersistentState')();
    },
    validateWorldState: function(payload) {
      return requireWorldPersistence('validatePersistentState')(payload);
    },
    restoreWorldState: function(payload) {
      return requireWorldPersistence('restorePersistentState')(payload);
    },
    exportAirshipState: function() {
      if (!ensureAirshipState()) {
        throw new Error('RUNTIME_AIRSHIP_STATE_UNAVAILABLE');
      }
      return requireAirshipPersistence('exportPersistentState')(airshipState);
    },
    validateAirshipState: function(payload) {
      return requireAirshipPersistence('validatePersistentState')(payload);
    },
    restoreAirshipState: function(payload) {
      const nextState = requireAirshipPersistence('restorePersistentState')(payload);
      commitAirshipState(nextState);
      return requireAirshipPersistence('exportPersistentState')(airshipState);
    },
  });
}

function ensureAirshipState() {
  if (!window.AetherAirshipState ||
      typeof window.AetherAirshipState.createState !== 'function') {
    return false;
  }
  if (!airshipState) {
    airshipState = window.AetherAirshipState.createState(
      world && world.player ? world.player.airship : null
    );
  }
  window._airshipState = airshipState;
  if (world && world.player) world.player.airship = airshipState;
  return true;
}

function resolveAirshipCommand(actionId) {
  if (!ensureAirshipState()) return;
  const result = window.AetherAirshipState.resolveAction(airshipState, actionId);
  commitAirshipState(result.state);
  showToast(result.message, result.ok ? C.teal : C.rust, 1600);
  if (result.ok && actionId === 'resonanceLance') {
    triggerShake(3, 120);
  }
}

function cycleAirshipShieldMode() {
  if (!ensureAirshipState()) return;
  const result = window.AetherAirshipState.cycleShieldMode(airshipState);
  commitAirshipState(result.state);
  showToast(result.message, C.scioto, 1400);
}

function leaveAirship() {
  if (world && world.player) world.player.shipBoarded = false;
  if (gameState === STATE.AIRSHIP) {
    // AIRSHIP is a full-screen ship state rather than a normal overlay.
    // Return directly to WORLD instead of relying on overlay history.
    gameState = STATE.WORLD;
    window.gameState = gameState;
    prevState = null;
    overlayStateStack.length = 0;
    if (VIS.fadeTransitions) startFade(100);
  }
}

function getAirshipCommands() {
  return [
    { id: 'phaseSlip', label: 'PHASE-SLIP' },
    { id: 'harmonicVeil', label: 'VEIL MODE' },
    { id: 'resonanceLance', label: 'LANCE' },
    { id: 'rootlineTether', label: 'TETHER' },
    { id: 'patternForge', label: 'FORGE' },
    { id: 'ventWake', label: 'VENT WAKE' },
  ];
}

function activateAirshipCommand(command) {
  if (!command) return;
  if (command.id === 'harmonicVeil') cycleAirshipShieldMode();
  else resolveAirshipCommand(command.id);
}

function handleAirshipInput(input) {
  const commands = getAirshipCommands();
  airshipCursor = Math.max(0, Math.min(airshipCursor, commands.length - 1));

  if (input && input.cancel) {
    leaveAirship();
    return;
  }
  if (input && (input.up || input.left)) {
    airshipCursor = (airshipCursor - 1 + commands.length) % commands.length;
    return;
  }
  if (input && (input.down || input.right)) {
    airshipCursor = (airshipCursor + 1) % commands.length;
    return;
  }
  if (input && input.ok) {
    activateAirshipCommand(commands[airshipCursor]);
    return;
  }

  // Compatibility aliases retained during migration.
  if (keysPressed[27] || keysPressed[76]) {
    leaveAirship();
  } else if (keysPressed[50] || keysPressed[72]) {
    airshipCursor = 1;
    cycleAirshipShieldMode();
  } else if (keysPressed[49]) {
    airshipCursor = 0;
    resolveAirshipCommand('phaseSlip');
  } else if (keysPressed[51]) {
    airshipCursor = 2;
    resolveAirshipCommand('resonanceLance');
  } else if (keysPressed[52]) {
    airshipCursor = 3;
    resolveAirshipCommand('rootlineTether');
  } else if (keysPressed[53]) {
    airshipCursor = 4;
    resolveAirshipCommand('patternForge');
  } else if (keysPressed[82]) {
    airshipCursor = 5;
    resolveAirshipCommand('ventWake');
  }
}

function doMove(code) {
  if (!world || typeof world.movePlayer !== 'function') return;
  if (code === UP_ARROW)    world.movePlayer(0, -1);
  if (code === DOWN_ARROW)  world.movePlayer(0, 1);
  if (code === LEFT_ARROW)  world.movePlayer(-1, 0);
  if (code === RIGHT_ARROW) world.movePlayer(1, 0);
}

function buildPartyCombatContext() {
  if (!window._partyCombatBridge ||
      typeof window._partyCombatBridge.createSnapshot !== 'function') {
    throw new Error('PARTY_COMBAT_BRIDGE_UNAVAILABLE');
  }
  if (!Array.isArray(window.ACTIVE_PARTY)) {
    throw new Error('PARTY_COMBAT_ACTIVE_PARTY_UNAVAILABLE');
  }
  const snapshot = window._partyCombatBridge.createSnapshot(
    window.ACTIVE_PARTY,
    window._fieldRoleDefs || window.AetherFieldRoleDefs
  );
  window._partyCombatBridge.validateSnapshot(snapshot);
  return snapshot;
}

window.buildPartyCombatContext = buildPartyCombatContext;

function buildCombatPlayerSnapshot() {
  if (!world || !world.player) throw new Error('COMBAT_SYNC_WORLD_PLAYER_REQUIRED');
  return {
    name: world.player.name,
    age: world.player.age,
    class: world.player.class,
    wits: world.player.wits,
    presence: world.player.presence,
    spirit: world.player.spirit,
    might: world.player.might,
    grace: world.player.grace,
    maxVit: world.player.maxVit,
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
    unlockedAbilities: Array.isArray(world.player.unlockedAbilities)
      ? world.player.unlockedAbilities.slice()
      : [],
    equipment: world.player.equipment
      ? JSON.parse(JSON.stringify(world.player.equipment))
      : { staff: null, backpack: null },
    partyContext: buildPartyCombatContext(),
  };
}

function syncCombatFromWorldPlayer() {
  if (!combat || typeof combat.init !== 'function') {
    throw new Error('COMBAT_SYNC_API_UNAVAILABLE');
  }
  combat.init(buildCombatPlayerSnapshot());
  return true;
}

function hasStoredSave() {
  if (!window._saveState) return false;
  try {
    const storage = window.localStorage;
    if (!storage || typeof storage.getItem !== 'function') return false;
    const keys = [window._saveState.storageKey]
      .concat(Array.isArray(window._saveState.legacyStorageKeys)
        ? window._saveState.legacyStorageKeys
        : []);
    return keys.some(key => typeof key === 'string' && storage.getItem(key) != null);
  } catch (error) {
    return false;
  }
}

window.hasStoredSave = hasStoredSave;

function quickSaveGame() {
  if (gameState !== STATE.WORLD) {
    showToast('SAVE AVAILABLE IN WORLD ONLY', C.rust, 1800);
    return { ok: false, reason: 'SAVE_REQUIRES_WORLD' };
  }
  if (!window._saveState || typeof window._saveState.saveToStorage !== 'function') {
    showToast('SAVE SYSTEM UNAVAILABLE', C.rust, 1800);
    return { ok: false, reason: 'SAVE_API_UNAVAILABLE' };
  }

  try {
    const result = window._saveState.saveToStorage(window.localStorage);
    addLedgerEntry('system', 'Game saved.');
    showToast('GAME SAVED', C.teal, 1500);
    return result;
  } catch (error) {
    console.error('AETHER_QUICK_SAVE_FAILED', error);
    showToast('SAVE FAILED', C.rust, 1800);
    return { ok: false, reason: error && error.message ? error.message : 'SAVE_FAILED' };
  }
}

function quickLoadGame() {
  const allowed = gameState === STATE.MENU ||
    gameState === STATE.CHARCREATE ||
    gameState === STATE.WORLD;
  if (!allowed) {
    showToast('LOAD UNAVAILABLE IN CURRENT STATE', C.rust, 1800);
    return { ok: false, reason: 'LOAD_REQUIRES_SAFE_STATE' };
  }
  if (!window._saveState || typeof window._saveState.loadFromStorage !== 'function') {
    showToast('SAVE SYSTEM UNAVAILABLE', C.rust, 1800);
    return { ok: false, reason: 'SAVE_API_UNAVAILABLE' };
  }

  try {
    const result = window._saveState.loadFromStorage(window.localStorage);
    if (!result || !result.ok) {
      showToast('NO SAVE FOUND', C.rust, 1600);
      return result || { ok: false, reason: 'SAVE_NOT_FOUND' };
    }

    syncCombatFromWorldPlayer();
    gameState = STATE.WORLD;
    window.gameState = gameState;
    prevState = null;
    overlayStateStack.length = 0;
    if (window.UI) {
      window.UI.dialogueOpen = false;
      window.UI.shopOpen = false;
      window.UI.opening = false;
    }
    addLedgerEntry('system', result.migrated ? 'Legacy save migrated and loaded.' : 'Game loaded.');
    showToast(result.migrated ? 'SAVE MIGRATED + LOADED' : 'GAME LOADED', C.teal, 1800);
    if (VIS.fadeTransitions) startFade(120);
    return result;
  } catch (error) {
    console.error('AETHER_QUICK_LOAD_FAILED', error);
    showToast('LOAD FAILED', C.rust, 1800);
    return { ok: false, reason: error && error.message ? error.message : 'LOAD_FAILED' };
  }
}

window.quickSaveGame = quickSaveGame;
window.quickLoadGame = quickLoadGame;

function startGame() {
  // DO NOT call world.init() again — it was called in setup() and resets
  // the player, NPCs, quest, shop, and ledger to initial state. We only
  // transition to CHARCREATE state so the character creation flow can run.
  // When char-create signals completion (phase === 'done'), it will transition
  // to WORLD. If char-create is not loaded, fall through to WORLD directly.
  if (typeof window.AetherCharCreate !== 'undefined' && window._charcreate) {
    gameState = STATE.CHARCREATE;
    window.gameState = gameState;
    if (typeof window._charcreate.start === 'function') window._charcreate.start();
  } else {
    gameState = STATE.WORLD;
    window.gameState = gameState;
    prevState = null;
  }
}

// ── Combat launcher: triggers an encounter ──
function startCombat(enemyId) {
  if (!combat || !world) return;
  combatCursor = 0;

  const resolvedEnemyId = enemyId || 'skyPredator';
  // Preflight encounter identity before mutating combat or consuming one-shot
  // airship state. Invalid encounter requests must be completely fail-closed.
  if (typeof combat.canBeginEncounter === 'function' &&
      !combat.canBeginEncounter(resolvedEnemyId)) {
    addLedgerEntry('combat', 'Combat failed: Unknown enemy: ' + resolvedEnemyId);
    return { ok: false, reason: 'Unknown enemy: ' + resolvedEnemyId };
  }

  // Only consume airship transfer when player is eligible
  let airshipTransfer = null;
  if (airshipState &&
      window.AetherAirshipCombatBridge &&
      typeof window.AetherAirshipCombatBridge.consumeTransfer === 'function') {
    // Check if player is eligible: boarded OR has one-shot armed
    const isEligible = world.player.shipBoarded || 
      (airshipState && airshipState.pendingCombat && 
       (airshipState.pendingCombat.phaseSlip || 
        airshipState.pendingCombat.resonanceLanceDamage));
    
    if (isEligible) {
      const prepared = window.AetherAirshipCombatBridge.consumeTransfer(airshipState);
      commitAirshipState(prepared.state);
      airshipTransfer = prepared.transfer;
    }
  }

  // Build one canonical Ender snapshot plus validated read-only party context.
  const playerSnapshot = buildCombatPlayerSnapshot();
  playerSnapshot.airshipTransfer = airshipTransfer;

  combat.init(playerSnapshot);
  const result = combat.beginEncounter(resolvedEnemyId);
  if (!result || !result.ok) {
    // Fail closed — don't enter combat state for invalid enemy IDs
    if (result && result.reason) {
      addLedgerEntry('combat', 'Combat failed: ' + result.reason);
    }
    return;
  }
  gameState = STATE.COMBAT;
  window.gameState = gameState;
}

function finishCombat() {
  if (!combat || !world || !world.player || typeof combat.getState !== 'function') return;

  const combatState = combat.getState();
  const p = combatState && combatState.player ? combatState.player : null;

  if (p) {
    const persistentFields = [
      'name', 'age', 'class', 'wits', 'presence', 'spirit',
      'might', 'grace', 'maxVit', 'level', 'xp', 'xpToNext',
    ];
    persistentFields.forEach(field => {
      if (p[field] !== undefined) world.player[field] = p[field];
    });
    world.player.unlockedAbilities = Array.isArray(p.unlockedAbilities)
      ? p.unlockedAbilities.slice()
      : world.player.unlockedAbilities;
    world.player.equipment = p.equipment
      ? JSON.parse(JSON.stringify(p.equipment))
      : world.player.equipment;

    world.player.vit = p.vit;
    world.player.scrap = p.scrap;

    if (p.aether) {
      world.player.aether = p.aether.current;
      world.player.aetherMax = p.aether.max;
    }
    if (p.heat) {
      world.player.heat = p.heat.current;
      world.player.heatMax = p.heat.max;
    }
    if (p.echoes) {
      world.player.echoes = p.echoes.current;
      world.player.echoesMax = p.echoes.max;
    }

    world.player.staffCharges = p.staffCharges;
    if (p.maxStaffCharges !== undefined) {
      world.player.maxStaffCharges = p.maxStaffCharges;
    } else if (combat.getCharges) {
      const chargeInfo = combat.getCharges();
      if (chargeInfo && chargeInfo.max != null) {
        world.player.maxStaffCharges = chargeInfo.max;
      }
    }
  }

  gameState = STATE.WORLD;
  window.gameState = gameState;
  prevState = null;
  if (VIS.fadeTransitions) startFade(150);
}

function openState(s) {
  overlayStateStack.push(gameState);
  prevState = overlayStateStack[overlayStateStack.length - 1] || null;
  gameState = s;
  if (s === STATE.SHOP) {
    const count = window.UI && Array.isArray(window.UI.shopItems)
      ? window.UI.shopItems.length
      : 0;
    shopCursor = count > 0
      ? Math.max(0, Math.min(Number(window.UI.lastShopSelection) || 0, count - 1))
      : 0;
  }
  if (s === STATE.AIRSHIP) airshipCursor = 0;
  window.gameState = gameState;
  // Fade transition between states
  if (VIS.fadeTransitions) {
    startFade(150);  // quick fade-in overlay
  }
  // ── Window openness slide-in (Memories §1.2) ──
  window.UI.opening = true;
  window.UI.openness = 0;
  // ── Per-state window tones (Memories §1.3) ──
  switch (s) {
    case STATE.DIALOGUE:
      window.UI.windowTone = [124, 200, 232]; // cool blue
      break;
    case STATE.SHOP:
      window.UI.windowTone = [210, 180, 140]; // warm dusttan
      break;
    case STATE.LEDGER:
      window.UI.windowTone = [180, 190, 200]; // neutral
      break;
    case STATE.QUESTLOG:
      window.UI.windowTone = [100, 180, 220]; // quest blue
      break;
    case STATE.CHARSHEET:
      window.UI.windowTone = [160, 180, 200]; // neutral
      break;
    case STATE.AIRSHIP:
      window.UI.windowTone = [42, 255, 181]; // Wakeheart teal
      break;
    case STATE.SYSTEMMENU:
      window.UI.windowTone = [124, 200, 232];
      break;
    default:
      window.UI.windowTone = null;
  }
}

function closeOverlay() {
  if (gameState === STATE.DIALOGUE && world && typeof world.closeDialogue === 'function') {
    world.closeDialogue();
  }
  if (gameState === STATE.SHOP && world && typeof world.closeShop === 'function') {
    world.closeShop();
  }
  if (gameState === STATE.AIRSHIP && world && world.player) {
    world.player.shipBoarded = false;
  }
  const returnState = overlayStateStack.length
    ? overlayStateStack.pop()
    : prevState;
  if (returnState) {
    gameState = returnState;
    window.gameState = gameState;
    prevState = overlayStateStack.length
      ? overlayStateStack[overlayStateStack.length - 1]
      : null;
    if (VIS.fadeTransitions) {
      startFade(100);
    }
  }
}

/** Start a quick screen fade overlay (used between state transitions). */
function startFade(duration) {
  fade.active = true;
  fade.startTime = millis();
  fade.duration = duration || 400;
  fade.alpha = 0;
  fade.from = gameState;
  fade.to = null;
}

/** Trigger screen shake — intensity 1..10, duration in ms. */
function triggerShake(intensity, duration) {
  if (!VIS.screenShake) return;
  intensity = Math.max(1, Math.min(10, intensity || 4));
  duration = duration || 200;
  shake.intensity = intensity;
  shake.duration = duration;
  shake.startTime = millis();
}

/** Trigger hit stop (freeze frames) — ms to freeze, typically 80-150 for crits. */
function triggerHitStop(ms) {
  if (!VIS.hitStop) return;
  hitStop.active = true;
  hitStop.remaining = ms || 100;
}

/** Show a toast message — auto-fading overlay text. */
function showToast(text, color, duration) {
  window.toasts.push({
    text: text,
    color: color || [42, 255, 181],
    startTime: millis(),
    duration: duration || 2000,
    alpha: 255,
  });
}

/** Trigger all combat-hit feedback: shake + hit stop on crits + sound. */
function triggerCombatHitFeedback(enemyDmg, playerDmg, rollTotal, isPlayerAttack, isCritical) {
  // Screen shake on any damage
  const shakeIntensity = Math.min(8, 2 + (enemyDmg || 0) * 1.2 + (playerDmg || 0) * 0.8);
  if (shakeIntensity > 1) {
    triggerShake(shakeIntensity, 160 + Math.min(120, (enemyDmg || 0) * 20));
  }
  // Hit stop on an explicit JRPG critical, or on a legacy 10+ while migration continues.
  if (VIS.hitStop &&
      (isCritical || (typeof rollTotal === 'number' && rollTotal >= 10))) {
    triggerHitStop(110);
  }
  // Audio
  if (isPlayerAttack) {
    if (enemyDmg > 0 && typeof window.playCombatHit === 'function') window.playCombatHit();
  }
  if (playerDmg > 0) {
    if (typeof window.playDamageTaken === 'function') window.playDamageTaken();
  }
}

/** Notify that an ability resolved — success or fail sound. */
function triggerAbilityFeedback(success) {
  if (success) {
    if (typeof window.playAbilitySuccess === 'function') window.playAbilitySuccess();
  } else {
    if (typeof window.playAbilityFail === 'function') window.playAbilityFail();
  }
}

/** Notify quest state change. */
function triggerQuestAdvance() {
  if (typeof window.playQuestAdvance === 'function') window.playQuestAdvance();
  showToast('QUEST ADVANCED', [42, 255, 181], 1800);
}

/** Notify level up. */
function triggerLevelUp() {
  if (typeof window.playLevelUp === 'function') window.playLevelUp();
  showToast('LEVEL UP', [255, 179, 71], 2200);
}

// ── Drawing helpers ──

/** Boot sequence: loading → story preamble → title with parallax islands */
function drawBootSequence() {
  const elapsed = millis() - bootTime;
  const progress = Math.min(1, elapsed / BOOT_LOAD_MS);
  const preambleElapsed = millis() - preambleStart;
  
  // Background: navy
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2]);
  rect(0, 0, width, height);
  
  // Subtle teal grid (static)
  stroke(C.teal[0], C.teal[1], C.teal[2], 10);
  strokeWeight(1);
  for (let x = 0; x < width; x += 32) line(x, 0, x, height);
  for (let y = 0; y < height; y += 32) line(0, y, width, y);
  
  // Floating islands parallax (always visible during boot)
  for (const island of titleIslands) {
    const px = ((island.x + elapsed * 0.01 * island.drift) % 60 + 60) % 60 * 16;
    const py = island.y + Math.sin(elapsed * 0.001 * island.speed + island.drift) * 6;
    
    noStroke();
    fill(C.soil[0], C.soil[1], C.soil[2], 160);
    ellipse(px, py, island.size, island.size * 0.6);
    
    noFill();
    stroke(C.teal[0], C.teal[1], C.teal[2], 80);
    strokeWeight(1);
    ellipse(px, py, island.size, island.size * 0.6);
    noStroke();
    
    fill(C.teal[0], C.teal[1], C.teal[2], 50);
    ellipse(px - 3, py - 3, island.size * 0.3, island.size * 0.2);
  }
  
  // ── Loading phase (0-1.2s) ──
  if (elapsed < BOOT_LOAD_MS) {
    noStroke();
    textSize(12);
    fill(C.teal[0], C.teal[1], C.teal[2], 150);
    textAlign(CENTER, CENTER);
    const loadText = 'LOADING' + '.'.repeat(Math.floor((elapsed / 300) % 4));
    text(loadText, width/2, height/2 - 20);
    textSize(9);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 100);
    text('initializing the weave\u2026', width/2, height/2 + 8);
    return;
  }
  
  // ── Preamble phase (1.2s\u201310.2s) ──
  if (elapsed < BOOT_LOAD_MS + PREAMBLE_DURATION) {
    const t = (elapsed - BOOT_LOAD_MS) / PREAMBLE_DURATION;
    
    // Fade in
    const fadeIn = Math.min(1, t * 3);
    const scrollPos = Math.max(0, (t - 0.33) * 0.6); // scrolling starts at 33%
    
    // Story text
    const preambleLines = [
      'A ship above a broken world.',
      'A core that has begun to sing wrong.',
      '',
      'Below, the copper ground is tired \u2014 rusted, cracked,',
      'choking on its own dust.',
      'Above, the sky-lanes are still open.',
      '',
      'For three hundred years, the aether-cores',
      'kept the arcologies aloft.',
      'Now the cores are failing.',
      '',
      'You are Ender.',
      'Rift Scholar. New hand aboard the Wake.',
      'You carry a wrench, a passport, and a decision',
      'you have not yet admitted you have to make.',
      '',
      'The Aureate Wake\'s core is singing wrong.',
      'Something has to be done about that.',
    ];
    
    // Calculate which lines visible
    const lineHeight = 18;
    const visibleLines = Math.floor((height - 120) / lineHeight);
    const startLine = Math.max(0, Math.floor(scrollPos * preambleLines.length) - Math.floor(visibleLines/2));
    const endLine = Math.min(preambleLines.length, startLine + visibleLines);
    
    for (let i = startLine; i < endLine; i++) {
      const lineY = height/2 - 10 + (i - scrollPos * preambleLines.length) * lineHeight;
      if (preambleLines[i] === '') continue;
      const lineAlpha = (i === endLine - 1 && t < 0.5) ? t * 2 : 1;
      
      noStroke();
      fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * lineAlpha);
      textSize(13);
      textAlign(CENTER, CENTER);
      text(preambleLines[i], width/2, lineY);
    }
    
    // Bottom hint
    noStroke();
    textSize(9);
    fill(C.teal[0], C.teal[1], C.teal[2], 100 * fadeIn);
    textAlign(CENTER, CENTER);
    text('[ any key to skip ]', width/2, height - 30);

    return;
  }

  // After preamble completes, auto-transition to MENU state so the game is
  // ready for input. The title continues rendering (it's the MENU screen).
  if (elapsed >= BOOT_LOAD_MS + PREAMBLE_DURATION && gameState === STATE.BOOT) {
    gameState = STATE.MENU;
    window.gameState = gameState;
  }

  // Draw parallax islands BEHIND everything (already drawn above grid)
  // But grid may cover them — redraw islands after grid with proper z-order
  // Redraw grid at lower opacity during title phase
  stroke(C.teal[0], C.teal[1], C.teal[2], 6);
  strokeWeight(1);
  for (let x = 0; x < width; x += 32) line(x, 0, x, height);
  for (let y = 0; y < height; y += 32) line(0, y, width, y);
  
  // Re-draw floating islands (they were drawn before grid, may be covered)
  for (const island of titleIslands) {
    const px = ((island.x + elapsed * 0.01 * island.drift) % 60 + 60) % 60 * 16;
    const py = island.y + Math.sin(elapsed * 0.001 * island.speed + island.drift) * 6;
    
    noStroke();
    fill(C.soil[0], C.soil[1], C.soil[2], 200);
    ellipse(px, py, island.size, island.size * 0.6);
    
    noFill();
    stroke(C.teal[0], C.teal[1], C.teal[2], 100);
    strokeWeight(1);
    ellipse(px, py, island.size, island.size * 0.6);
    noStroke();
    
    fill(C.teal[0], C.teal[1], C.teal[2], 70);
    ellipse(px - 3, py - 3, island.size * 0.3, island.size * 0.2);
  }
  
  // Fade in title over 1.5s
  if (titleVisible < 1) {
    titleVisible = Math.min(1, titleVisible + dt * 0.002);
  }
  
  const v = titleVisible;
  
  // Title text (same content as drawTitleScreen, with alpha fade)
  noStroke();
  textFont('VT323');
  textSize(36 * v);
  textAlign(CENTER, CENTER);
  textLeading(40);
  
  const cx = width/2, cy = height/2 - 50;
  
  // Glow pass
  fill(C.teal[0], C.teal[1], C.teal[2], 60 * v);
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text('AETHERWAKE', cx + dx, cy + dy);
    }
  }
  fill(C.teal[0], C.teal[1], C.teal[2], 100 * v);
  text('AETHERWAKE', cx, cy);
  
  textSize(16 * v);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 200 * v);
  text('THE AUREATE WAKE — THE LAST SOLARPUNK AIRSHIP', cx, cy + 25);
  
  textSize(13 * v);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * v);
  text('A SOLARPUNK SKYFARING RPG', cx, cy + 48);
  
  textSize(14 * v);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * v);
  text('NEW GAME \u2014 N or ENTER', cx, cy + 78);
  
  textSize(11 * v);
  fill(C.rust[0], C.rust[1], C.rust[2], 140 * v);
  text('WASD  move  |  E  talk  |  Q  covenant  |  F  ship  |  Tab  sky/ground', cx, cy + 100);
  text('V  Aether Sense  |  L  ledger  |  M  shop  |  R  char sheet  |  T  quest log', cx, cy + 118);
  
  textFont('Press Start 2P');
  textSize(8 * v);
  fill(C.teal[0], C.teal[1], C.teal[2], 100 * v);
  text('THE AUREATE WAKE // SOLARPUNK SKYFARING RPG', cx, height - 20);
  
  // Subtle flash every 4 seconds
  const flashCycle = (millis() - bootTime) / 4000;
  const flash = Math.sin(flashCycle * Math.PI * 2) * 0.5 + 0.5;
  if (flash > 0.92) {
    noStroke();
    fill(C.teal[0], C.teal[1], C.teal[2], 8);
    rect(0, 0, width, height);
  }
}

function drawBackgroundGrid() {
  noFill();
  stroke(C.teal[0], C.teal[1], C.teal[2], 14);
  strokeWeight(1);
  for (let x = 0; x < width; x += 32) line(x, 0, x, height);
  for (let y = 0; y < height; y += 32) line(0, y, width, y);
}

function drawScanlines() {
  noFill();
  for (let y = 0; y < height; y += 3) {
    stroke(C.teal[0], C.teal[1], C.teal[2], 3);
    strokeWeight(1);
    line(0, y, width, y);
  }
}

function drawTitleScreen() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2]);
  rect(0, 0, width, height);

  // Floating islands parallax (title screen also gets islands)
  for (const island of titleIslands) {
    const px = ((island.x + millis() * 0.01 * island.drift) % 60 + 60) % 60 * 16;
    const py = island.y + Math.sin(millis() * 0.001 * island.speed + island.drift) * 6;

    // Pixel-built title islands: stepped silhouettes instead of procedural ellipses.
    const iw = Math.max(16, Math.round(island.size / 8) * 8);
    const ih = Math.max(8, Math.round(island.size * 0.45 / 4) * 4);
    const ix = Math.round(px - iw / 2), iy = Math.round(py - ih / 2);
    noStroke();
    fill(C.soil[0], C.soil[1], C.soil[2], 220);
    rect(ix + 4, iy, iw - 8, 4);
    rect(ix, iy + 4, iw, Math.max(4, ih - 8));
    rect(ix + 8, iy + ih - 4, Math.max(8, iw - 16), 4);
    fill(C.grass[0], C.grass[1], C.grass[2], 220);
    rect(ix + 4, iy, iw - 8, 3);
    fill(C.teal[0], C.teal[1], C.teal[2], 100);
    rect(ix + Math.floor(iw * 0.35), iy + ih, Math.max(2, Math.floor(iw * 0.3)), 2);
  }

  stroke(C.teal[0], C.teal[1], C.teal[2], 12);
  strokeWeight(1);
  for (let x = 0; x < width; x += 32) line(x, 0, x, height);
  for (let y = 0; y < height; y += 32) line(0, y, width, y);

  textFont('VT323');
  textSize(36);
  textAlign(CENTER, CENTER);
  textLeading(40);

  const cx = width/2, cy = height/2 - 50;
  fill(C.teal[0], C.teal[1], C.teal[2], 60);
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text('AETHERWAKE', cx + dx, cy + dy);
    }
  }
  fill(C.teal[0], C.teal[1], C.teal[2], 100);
  text('AETHERWAKE', cx, cy);

  textSize(16);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 200);
  text('THE LAST SOLARPUNK AIRSHIP', cx, cy + 25);

  textSize(13);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
  text('THE AUREATE WAKE — CHRONICLE OF THE LAST SOLARPUNK AIRSHIP', cx, cy + 48);

  const titleCommands = getTitleMenuCommands();
  titleMenuCursor = Math.max(0, Math.min(titleMenuCursor, titleCommands.length - 1));
  textSize(14);
  titleCommands.forEach((command, index) => {
    const selected = index === titleMenuCursor;
    fill(selected
      ? C.teal[0] : C.parchment[0],
      selected ? C.teal[1] : C.parchment[1],
      selected ? C.teal[2] : C.parchment[2],
      selected ? 230 : 160);
    text((selected ? '▶ ' : '  ') + command.label, cx, cy + 78 + index * 22);
  });

  textSize(10);
  fill(C.rust[0], C.rust[1], C.rust[2], 150);
  const controlsY = cy + 132;
  text('ARROWS  move / select   ·   Z / ENTER / SPACE  confirm / interact', cx, controlsY);
  text('X / ESC  menu / back   ·   SHIFT  dash / special   ·   Q / W  page', cx, controlsY + 18);

  textFont('Press Start 2P');
  textSize(8);
  fill(C.teal[0], C.teal[1], C.teal[2], 100);
  text('THE AUREATE WAKE // SOLARPUNK SKYFARING RPG', cx, height - 20);
}

function drawAirshipOverlay() {
  if (!ensureAirshipState()) return;
  if (window.AetherAirshipView &&
      typeof window.AetherAirshipView.draw === 'function') {
    window.AetherAirshipView.draw(airshipState, C, {
      cursor: airshipCursor,
      commands: getAirshipCommands(),
    });
  }
}

function drawSystemMenuOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 175);
  rect(0, 0, width, height);

  const commands = getSystemMenuCommands();
  const mw = 330;
  const mh = 76 + commands.length * 38;
  const mx = width - mw - 36;
  const my = 42;

  fill(C.navy[0], C.navy[1], C.navy[2]);
  rect(mx, my, mw, mh);
  drawPixelBorder(mx, my, mw, mh, 3);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2]);
  text('AETHERWAKE', mx + 18, my + 16);

  textFont('VT323');
  textSize(14);
  commands.forEach((command, index) => {
    const cy = my + 48 + index * 38;
    const selected = index === systemMenuCursor;
    if (selected) {
      noStroke();
      fill(C.teal[0], C.teal[1], C.teal[2], 38);
      rect(mx + 12, cy - 8, mw - 24, 30);
    }
    fill(selected
      ? color(C.parchment[0], C.parchment[1], C.parchment[2])
      : color(C.dim[0], C.dim[1], C.dim[2]));
    text((selected ? '▶ ' : '  ') + command.label, mx + 24, cy);
  });

  textFont('Press Start 2P');
  textSize(8);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 160);
  text('↑↓ SELECT   ·   Z/ENTER OK   ·   X/ESC BACK', mx + 18, my + mh - 22);
}

function drawDialogueOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 180);
  rect(0, 0, width, height);

  // ── Window tone (Memories §1.3): cool tint for dialogue ──
  const tone = window.UI.windowTone || null;

  // ── Window openness (Memories §1.2): alpha multiplier ──
  const openness = window.UI.openness || 255;

  // Backdrop dimmer tied to openness
  fill(C.navy[0], C.navy[1], C.navy[2], 180 * (openness / 255));
  rect(0, 0, width, height);

  const bx = width/2 - 240, by = height - 100, bw = 480, bh = 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(bx, by, bw, bh);
  // Tint overlay
  if (tone) {
    fill(tone[0], tone[1], tone[2], 30);
    noStroke();
    rect(bx, by, bw, bh);
  }
  drawPixelBorder(bx, by, bw, bh, 3);

  textFont('Press Start 2P');
  textSize(9);
  fill(C.teal[0], C.teal[1], C.teal[2], 180);
  const npcName = window.UI.dialogueNPC ? window.UI.dialogueNPC.name : '???';
  text(npcName, bx + 10, by + 10);

  textFont('VT323');
  textSize(13);
  textLeading(16);
  fill(C.parchment[0], C.parchment[1], C.parchment[2]);
  wrapText(window.UI.dialogueText || '...', bx + 10, by + 28, bw - 20);

  textFont('Press Start 2P');
  textSize(8);
  fill(C.teal[0], C.teal[1], C.teal[2], 120);
  textAlign(CENTER, TOP);
  text('E / ENTER to continue', width/2, by + bh + 6);
  textAlign(LEFT, TOP);
}

function drawShopOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 190);
  rect(0, 0, width, height);

  // ── Window tone (Memories §1.3): warm tint for shop ──
  const tone = window.UI.windowTone || null;

  // ── Window openness (Memories §1.2): alpha multiplier ──
  const openness = window.UI.openness || 255;
  fill(C.navy[0], C.navy[1], C.navy[2], 190 * (openness / 255));
  rect(0, 0, width, height);

  // Floating islands parallax in shop background
  for (const island of titleIslands) {
    const px = ((island.x + millis() * 0.008 * island.drift) % 60 + 60) % 60 * 16;
    const py = island.y + 80 + Math.sin(millis() * 0.0008 * island.speed + island.drift) * 5;
    noStroke();
    fill(C.soil[0], C.soil[1], C.soil[2], 80);
    ellipse(px, py, island.size, island.size * 0.5);
  }

  const sx = 40, sy = 40, sw = width - 80, sh = height - 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(sx, sy, sw, sh);
  // Window tone tint (warm for shop)
  if (tone) {
    fill(tone[0], tone[1], tone[2], 25);
    noStroke();
    rect(sx, sy, sw, sh);
  }
  drawPixelBorder(sx, sy, sw, sh, 3);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text('REPAIR CAFE \u2014 SHOP', sx + 16, sy + 12);

  const scrap = world && world.player ? world.player.scrap : 0;
  textFont('VT323');
  textSize(12);
  fill(C.parchment[0], C.parchment[1], C.parchment[2]);
  text('Scrap: ' + scrap, sx + sw - 110, sy + 12);

  // Tabs: Items | Aether | Charges
  textFont('Press Start 2P');
  textSize(8);
  fill(C.scioto[0], C.scioto[1], C.scioto[2], 120);
  text('ITEMS', sx + 16, sy + 32);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text(' \u25A0', sx + 56, sy + 31);

  const items = window.UI.shopItems || [];
  textSize(12);
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const iy = sy + 48 + i * 30;
    if (iy + 18 > sy + sh - 20) break;
    noStroke();
    fill(C.navy[0]+8, C.navy[1]+4, C.navy[2]+4);
    rect(sx + 12, iy, sw - 24, 26);
    stroke(C.teal[0], C.teal[1], C.teal[2], 50);
    strokeWeight(1);
    rect(sx + 12, iy, sw - 24, 26);

    const buyable = scrap >= item.cost;
    // Last-command memory highlight (Memories §3.5)
    const lastSel = window.UI.lastShopSelection;
    const isLastSelected = (lastSel !== undefined && i === lastSel);
    fill(buyable ? C.parchment[0] : C.rust[0], buyable ? C.parchment[1] : C.rust[1], buyable ? C.parchment[2] : C.rust[2]);
    text(item.name, sx + 20, iy + 5);
    fill(C.rust[0], C.rust[1], C.rust[2], 100);
    textSize(10);
    text(item.desc || '', sx + 20, iy + 16);
    textSize(12);

    fill(buyable ? C.teal[0] : C.rust[0], buyable ? C.teal[1] : C.rust[1], buyable ? C.teal[2] : C.rust[2], buyable ? 180 : 60);
    text('[' + (i+1) + '] ' + item.cost + ' scrap', sx + sw - 80, iy + 5);
    // Highlight last-selected slot
    if (isLastSelected) {
      noStroke();
      fill(C.teal[0], C.teal[1], C.teal[2], 30);
      rect(sx + 10, iy - 2, sw - 20, 28);
    }
  }

  // Shop footer
  textFont('Press Start 2P');
  textSize(8);
  fill(C.rust[0], C.rust[1], C.rust[2], 120);
  textAlign(CENTER, TOP);
  text('M or ESC to close  |  1-' + items.length + ' to buy', width/2, sy + sh - 14);
}

function drawLedgerOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 190);
  rect(0, 0, width, height);

  // ── Window openness (Memories §1.2): alpha multiplier ──
  const openness = window.UI.openness || 255;
  fill(C.navy[0], C.navy[1], C.navy[2], 190 * (openness / 255));
  rect(0, 0, width, height);

  const lx = 40, ly = 40, lw = width - 80, lh = height - 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(lx, ly, lw, lh);
  // Window tone tint
  const tone = window.UI.windowTone || null;
  if (tone) {
    fill(tone[0], tone[1], tone[2], 20);
    noStroke();
    rect(lx, ly, lw, lh);
  }
  drawPixelBorder(lx, ly, lw, lh, 2);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text('MYCELIAL LEDGER', lx + 16, ly + 12);

  textFont('VT323');
  textSize(13);
  const entries = world && world.getLedger ? world.getLedger() : [];
  for (let i = 0; i < entries.length; i++) {
    const e = entries[i];
    const ey = ly + 40 + i * 20;
    if (ey > ly + lh - 20) break;
    fill(C.scioto[0], C.scioto[1], C.scioto[2], 120);
    text(e.date || '', lx + 16, ey);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    text(e.text || '', lx + 80, ey);
  }

  textFont('Press Start 2P');
  textSize(8);
  fill(C.rust[0], C.rust[1], C.rust[2], 120);
  textAlign(CENTER, TOP);
  text('L or ESC to close', width/2, ly + lh - 14);
}

function drawQuestLogOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 190);
  rect(0, 0, width, height);

  // ── Window openness (Memories §1.2): alpha multiplier ──
  const openness = window.UI.openness || 255;
  fill(C.navy[0], C.navy[1], C.navy[2], 190 * (openness / 255));
  rect(0, 0, width, height);

  const qx = 40, qy = 40, qw = width - 80, qh = height - 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(qx, qy, qw, qh);
  // Window tone tint
  const tone = window.UI.windowTone || null;
  if (tone) {
    fill(tone[0], tone[1], tone[2], 20);
    noStroke();
    rect(qx, qy, qw, qh);
  }
  drawPixelBorder(qx, qy, qw, qh, 2);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text('QUEST LOG — THE AUREATE WAKE', qx + 16, qy + 12);

  if (world && typeof world.getQuestState === 'function') {
    const qs = world.getQuestState();
    textFont('VT323');
    textSize(13);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);

    let y = qy + 36;
    fill(C.teal[0], C.teal[1], C.teal[2], 180);
    textSize(11);
    text('State: ' + qs.state, qx + 16, y);
    y += 18;
    textSize(13);
    text('Hooks: ' + qs.hooksCompleted + '/3  |  Hazards: ' + qs.hazardsCompleted + '/4', qx + 16, y);
    y += 18;
    text('NPCs: ' + (qs.npcsMet ? qs.npcsMet.length : 0) + '/4  |  Choice: ' + (qs.choiceMade || 'none'), qx + 16, y);
    y += 24;
    textSize(11);
    if (qs.state === 'signal')      text('Signal — receive the call from the falling ship.', qx + 16, y);
    else if (qs.state === 'crossing') text('Crossing — three hazards on the way to the ship.', qx + 16, y);
    else if (qs.state === 'contact')  text('Contact — four souls await on the ship.', qx + 16, y);
    else if (qs.state === 'choice')   text('Choice — three paths open before you.', qx + 16, y);
    else if (qs.state === 'wake')     text('Wake — the ending unfolds.', qx + 16, y);
  }

  textFont('Press Start 2P');
  textSize(8);
  fill(C.rust[0], C.rust[1], C.rust[2], 120);
  textAlign(CENTER, TOP);
  text('T or ESC to close', width/2, qy + qh - 14);
}

function drawCharSheetOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 190);
  rect(0, 0, width, height);

  // ── Window openness (Memories §1.2): alpha multiplier ──
  const openness = window.UI.openness || 255;
  fill(C.navy[0], C.navy[1], C.navy[2], 190 * (openness / 255));
  rect(0, 0, width, height);

  const px = 20, py = 20, pw = width - 40, ph = height - 40;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(px, py, pw, ph);
  // Window tone tint
  const tone = window.UI.windowTone || null;
  if (tone) {
    fill(tone[0], tone[1], tone[2], 25);
    noStroke();
    rect(px, py, pw, ph);
  }
  drawPixelBorder(px, py, pw, ph, 3);

  if (typeof drawCharSheet === 'function') {
    drawCharSheet(px, py, pw, ph);
  } else {
    textFont('Press Start 2P');
    textSize(10);
    fill(C.teal[0], C.teal[1], C.teal[2], 180);
    text('ENDER — Rift Scholar / Dreamwright', px + 20, py + 24);
  }

  textFont('Press Start 2P');
  textSize(8);
  fill(C.rust[0], C.rust[1], C.rust[2], 120);
  textAlign(CENTER, TOP);
  text('R or ESC to close', width/2, py + ph - 14);
}

function drawPixelBorder(x, y, w, h, layers) {
  layers = layers || 2;
  noFill();
  for (let i = 0; i < layers; i++) {
    const shrink = i * 2 + 1;
    stroke(C.navy[0], C.navy[1], C.navy[2], i === 0 ? 255 : 80);
    strokeWeight(2);
    rect(x - shrink, y - shrink, w + shrink*2, h + shrink*2);
  }
  stroke(C.teal[0], C.teal[1], C.teal[2]);
  strokeWeight(2);
  rect(x - layers*2 - 1, y - layers*2 - 1, w + (layers*2+1)*2, h + (layers*2+1)*2);
}

function wrapText(content, x, y, maxWidth) {
  const words = content.split(' ');
  let line = '';
  let ly = y;
  for (const w of words) {
    const test = line + (line ? ' ' : '') + w;
    if (textWidth(test) > maxWidth && line) {
      text(line, x, ly);
      line = w;
      ly += 16;
    } else {
      line = test;
    }
  }
  if (line) text(line, x, ly);
}

// ── Vignette effect ──────────────────────────────────────────────────────
function drawVignette() {
  noStroke();
  const nightFactor = isNight() ? 0.6 : 0.18;
  const alpha = nightFactor * 180;
  const gradSteps = 20;
  for (let i = gradSteps; i >= 0; i--) {
    const t = i / gradSteps;
    const r = t * max(width, height) * 0.75;
    const a = alpha * (1 - t * t);
    fill(color(C.navy[0], C.navy[1], C.navy[2], a));
    ellipse(width / 2, height / 2, r * 2, r * 2);
  }
  // Extra dark corners
  noStroke();
  fill(color(C.navy[0], C.navy[1], C.navy[2], 120));
  rect(0, 0, width * 0.08, height);
  rect(width * 0.92, 0, width * 0.08, height);
  rect(0, 0, width, height * 0.06);
  rect(0, height * 0.94, width, height * 0.06);
}

// ── Toast rendering ──────────────────────────────────────────────────────
function drawToasts() {
  const now = millis();
  for (let i = window.toasts.length - 1; i >= 0; i--) {
    const t = window.toasts[i];
    const age = now - t.startTime;
    if (age > t.duration) {
      window.toasts.splice(i, 1);
      continue;
    }
    const alpha = age < 200 ? (age / 200) * 255 : (age > t.duration - 400 ? (t.duration - age) / 400 * 255 : 255);
    const y = height - 60 - (window.toasts.length - 1 - i) * 26;
    noStroke();
    fill(t.color[0], t.color[1], t.color[2], alpha * 0.15);
    rect(width / 2 - 110, y - 8, 220, 22, 4);
    fill(t.color[0], t.color[1], t.color[2], alpha);
    textFont('VT323');
    textSize(14);
    textAlign(CENTER, CENTER);
    text(t.text, width / 2, y + 2);
  }
  textFont('sans-serif');
}

// ── Fade overlay ─────────────────────────────────────────────────────────
function drawFadeOverlay() {
  if (!fade.active) return;
  const age = millis() - fade.startTime;
  if (age > fade.duration) {
    fade.active = false;
    return;
  }
  const t = age / fade.duration;
  const alpha = t < 0.5 ? t * 2 * 160 : (1 - t) * 2 * 160;
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], alpha);
  rect(0, 0, width, height);
}

// ── Dialogue type-in ─────────────────────────────────────────────────────
function startDialogueTypeIn(fullText) {
  dialogueTypeIn.active = true;
  dialogueTypeIn.fullText = fullText || '';
  dialogueTypeIn.displayText = '';
  dialogueTypeIn.charIndex = 0;
  dialogueTypeIn.lastCharTime = millis();
}

function updateDialogueTypeIn() {
  if (!dialogueTypeIn.active) return;
  const now = millis();
  if (dialogueTypeIn.charIndex < dialogueTypeIn.fullText.length) {
    if (now - dialogueTypeIn.lastCharTime > dialogueTypeIn.speed) {
      dialogueTypeIn.charIndex++;
      dialogueTypeIn.displayText = dialogueTypeIn.fullText.substring(0, dialogueTypeIn.charIndex);
      dialogueTypeIn.lastCharTime = now;
    }
  } else {
    // Type-in complete — keep displaying full text
    dialogueTypeIn.active = false;
  }
}

// Expose dialogue type-in start from world module
window.startDialogueTypeIn = startDialogueTypeIn;


// === modules/world.js ===
/* ============================================================
   aetherwake-jrpg/modules/world.js
   World / Map / Quest module for the Aetherwake JRPG.
   p5-compatible. No DOM creation inside draw().
   ============================================================ */

'use strict';

// ---------------------------------------------------------------------------
// Export surface — every name the rest of the app can reach
// ---------------------------------------------------------------------------
const World = {
  init, update, render,
  movePlayer, interact, toggleLayer,
  plantField, boardShip,
  openLedger, openShop, closeShop,
  openDialogue, nextDialogueLine, closeDialogue,
  getLedger, getShopItems, purchaseItem,
  senseAether, getAetherSenseState,
  getQuestState, advanceQuest, selectChoicePath,
  exportPersistentState, validatePersistentState, restorePersistentState
};

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const MAP_SIZE       = 32;
const TILE_TYPES = {
  GROUND_SOLID  : 1,
  GROUND_GRASS  : 2,
  GROUND_CRATE  : 3,
  GROUND_FLOAT  : 4,   // floating island chunk
  GROUND_WATER  : 5,
  GROUND_LORE   : 6,   // lore tile — reveals story text when walked
  SKY_EMPTY     : 0,
  SKY_CLOUD     : 1,
  SKY_ASTRO     : 2    // distant celestial drift
};

const DAY_CYCLE_SEC       = 120;
const SOLAR_MAX_KWH       = 2.0;
const SOLAR_RATE_W        = 400;
const SOLAR_PEAK_FACTOR   = 1.0;

const QUEST_STATES = {
  SIGNAL   : 'signal',
  CROSSING : 'crossing',
  CONTACT  : 'contact',
  CHOICE   : 'choice',
  WAKE     : 'wake',
  DONE     : 'done'
};

// ---------------------------------------------------------------------------
// Globals (module-scoped; referenced by the rest of the app via World.*)
// ---------------------------------------------------------------------------
let groundLayer = [];
let skyLayer    = [];
let player = {};
let dayTime = 0;
let covenantField = null;
let isSkyLayerVisible = false;
let quest = {};
let npcs = [];
let ledger = { entries: [], title: 'Mycelial Ledger' };
let shop = null;
let gameOver = false;
let wakeVariants = [];
let currentInteractionKey = null;
let activeDialogue = null;
let aetherSenseState = {
  active: false,
  expiresAt: 0,
  lastScan: null,
};

// p5 hooks — called by core.js setup()/draw()/update()
// ---------------------------------------------------------------------------

/**
 * init() — called once from core.js setup(). Builds map, NPCs, default state.
 */
function init() {
  buildMap();
  initNPCs();
  initPlayer();
  World.npcs = npcs;
  initQuest();
  World.quest = quest;
  initShop();
  initLedgerPlaceholder();
  covenantField = { x: 0, y: 0, planted: false, life: 0 };
  dayTime = 0;
  isSkyLayerVisible = false;
  gameOver = false;
  aetherSenseState = {
    active: false,
    expiresAt: 0,
    lastScan: null,
  };
}

// ---------------------------------------------------------------------------
// Map construction
// ---------------------------------------------------------------------------

function buildMap() {
  groundLayer = [];
  skyLayer    = [];
  for (let y = 0; y < MAP_SIZE; y++) {
    groundLayer[y] = new Array(MAP_SIZE);
    skyLayer[y]    = new Array(MAP_SIZE);
  }

  // Fill ground with grass by default
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      groundLayer[y][x] = TILE_TYPES.GROUND_GRASS;
    }
  }

  // Solid border
  for (let i = 0; i < MAP_SIZE; i++) {
    groundLayer[0][i]       = TILE_TYPES.GROUND_SOLID;
    groundLayer[MAP_SIZE-1][i] = TILE_TYPES.GROUND_SOLID;
    groundLayer[i][0]       = TILE_TYPES.GROUND_SOLID;
    groundLayer[i][MAP_SIZE-1] = TILE_TYPES.GROUND_SOLID;
  }

  // Columbus wreck debris zones
  const debrisSpots = [
    [5,5],[6,7],[7,4],[8,8],
    [14,4],[13,6],[15,7],
    [22,10],[23,11],[21,12],
    [4,22],[5,24],[3,23],
    [18,20],[19,22],[20,19],
    [27,27],[28,26],[26,28]
  ];
  for (const [x, y] of debrisSpots) {
    if (inBounds(x, y)) groundLayer[y][x] = TILE_TYPES.GROUND_CRATE;
  }

  // Lore tiles — walk over them to reveal story fragments
  // Use a sidecar loreLayer to store lore text, not a property on numeric tile values
  loreLayer = [];
  for (let y = 0; y < MAP_SIZE; y++) {
    loreLayer[y] = [];
    for (let x = 0; x < MAP_SIZE; x++) {
      loreLayer[y][x] = null;
    }
  }
  const loreSpots = [
    { x: 3, y: 6, text: "A child's drawing, preserved on a scrap of hull plating. A ship with too many sails, rising into a sky that had no up anymore." },
    { x: 11, y: 5, text: "The Aureate Wake's manifest, water-stained but legible: \"Cargo: one sky-lane. Destination: above. Status: song slipping.\"" },
    { x: 19, y: 7, text: "Ionia's watch log, half-buried in deck plating: \"Day 47. The core sings wrong. The harmonics slip at dusk. The frequencies hum in the hull.\"" },
    { x: 24, y: 14, text: "A Copper Syndicate data-slate, cracked but still glowing. \"Acquisition Protocol 7: when the local Dreamwright refuses, override their dream.\"" },
    { x: 16, y: 20, text: "Lyra's drawing of the core: a great bird made of gears, singing. She wrote beneath it: \"If it stops singing, the sky will forget how to hold us.\"" },
    { x: 9, y: 24, text: "A salvager's note, pinned to a bulkhead with a rusted nail: \"The core doesn't belong to the Syndicate. It never did. It belongs to whoever remembers what it was for.\"" },
    { x: 28, y: 19, text: "The Core's log — the last entry: \"The song has three missing notes. I have been hunting them since the first sky-lane opened. I think one is in your chest, Ender.\"" }
  ];
  for (const l of loreSpots) {
    if (inBounds(l.x, l.y)) {
      groundLayer[l.y][l.x] = TILE_TYPES.GROUND_LORE;
      loreLayer[l.y][l.x] = l.text;
    }
  }

  // 14 falling-upward islands
  const islands = [
    [4, 4], [7, 3], [12, 5], [18, 4],
    [25, 6], [3, 9], [10, 8], [16, 10],
    [23, 9], [29, 7], [5, 15], [13, 14],
    [20, 16], [27, 15]
  ];
  for (const [x, y] of islands) {
    if (inBounds(x, y)) {
      skyLayer[y][x]    = TILE_TYPES.SKY_CLOUD;
      groundLayer[y][x] = TILE_TYPES.GROUND_FLOAT;
    }
  }
}

function inBounds(x, y) {
  return x >= 0 && x < MAP_SIZE && y >= 0 && y < MAP_SIZE;
}

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------

function initPlayer() {
  player = {
    x: 16,
    y: 16,
    px: 16 * 16,
    py: 16 * 16,
    tileX: 16,
    tileY: 16,
    vit: 13,
    maxVit: 13,
    echoes: 3,
    echoesMax: 3,
    scrap: 7,
    aether: 4,
    aetherMax: 6,
    heat: 1,
    heatMax: 3,
    solarCharge: 1.0,
    staffCharges: 2,
    wits: 2,
    presence: 1,
    spirit: 1,
    might: -1,
    grace: 0,
    level: 1,
    xp: 0,
    xpToNext: 50,
    unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
    equipment: { staff: null, backpack: null },
    class: 'ender'
  };
  World.player = player;
}

// ---------------------------------------------------------------------------
// NPCs
// ---------------------------------------------------------------------------

function initNPCs() {
  npcs = [
    // 1 — Captain Ionia (28-year-old veteran navigator; Denith's former protégé)
    {
      id: 'ionia',
      name: 'Ionia',
      title: 'Captain of the Third Watch',
      x: 7,
      y: 7,
      tileX: 7,
      tileY: 7,
      dialogue: {
        intro: [
          '"The Wake doesn\'t sing like it used to. You hear it? The harmonics are slipping. Ten years under Captain Denith taught me this ship\'s rhythms, and now the Core is forgetting its own song."',
          '"You\'re Ender. Rift Scholar, and a new hand aboard my ship. You carry a wrench, a passport, and a decision you haven\'t admitted you have to make. I know the shape of it."',
          '"I\'ve flown the Wake through the copper storms, through the blight-winds, through the years when the sky-lanes were closing one by one. I\'ve never seen the core drift like this. Not in all my watches."',
          'The crops on the lower decks taste like copper dust. The solar array still hums. The people are tired but alive. That\'s a lot. It\'s not enough, but it\'s a lot.',
          '"You stand on the edge of something big, Ender. I can smell it on you. Something that wants to be decided."'
        ],
        class_ender: [
          '"Ah. Deckhand\'s hands. You\'ve been in the wiring. You know what happens when a core starts to slip — it doesn\'t stop. It falls."',
          'Ionia spent ten years learning the Wake under Captain Denith. She knows the old route records well enough to recognize when the Core is behaving wrong, and now every impossible problem belongs to her as captain. She trusts Ender as a new crewmate whose Rift Scholar instincts may matter here, but she doesn\'t pretend the decision is easy.',
          'You\'ve walked the ship and you\'ve seen what\'s waiting. Ionia\'s bulkhead is empty except for her watch log. Lyra\'s been listening to the frequencies nobody else can hear. Verrick has a contract on the core and a real argument about what happens to people when the sky-lanes close. You get to decide what the Wake becomes. That\'s not a small thing.',
        ],
        generic_follow: [
          '"Take your time. The core will keep singing. It always does."'
        ],
        deep: [
          'You\'ve walked the ship. You\'ve seen the write-ups: the Core\'s lore tile down by the lower cargo hatch, the one about the three missing notes. You\'ve stood at Ionia\'s bulkhead and you\'ve stood at Lyra\'s. You know more than you did when you boarded.',
          '"I\'ll tell you about the core. It\'s not a machine. It\'s a song with a schedule. Three hundred years ago, the first sky-lanes opened because someone sang a city into the air. The core remembers that first note. It\'s been trying to finish the song ever since."',
          '"That\'s why the harmonics are slipping. The song is tired. It doesn\'t know how to end. It only knows how to continue — and continuation is getting expensive."',
          '"You want to know what I think? I think the choice isn\'t about the core or the ship or even the sky. It\'s about what you\'re willing to become when the song finally ends. Listen for it. The silence after. That\'s where the decision lives."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 2 — The Core (aether-core voice, ghost-song in copper and light)
    {
      id: 'engine_spirit',
      name: 'The Core',
      title: 'Aether-Core of the Aureate Wake',
      x: 22,
      y: 10,
      tileX: 22,
      tileY: 10,
      dialogue: {
        intro: [
          '"I am the song that kept the Wake aloft. The hull remembers every sky-lane I ever opened."',
          '"You stand on a ship that is forgetting how to fly. The harmonics are slipping. I feel it in my frequencies."',
          '"Three hazards on the way to my chamber. Sky-predator first — it hunts heat signatures. Harmonic shear next — it strips the grace from men who haven\'t earned it. Then the corporate intercept — they want to box me up and take me to a city that doesn\'t dream."',
          '"I remember the first sky-lane. The song was new then — bright, almost painful. They sang the Wake upward through steel and light. The people didn\'t understand — they thought gravity was a law, not a direction."',
          '"You feel that hum in your chest? That\'s me, Ender. I\'ve been humming since before the first sky-lane opened. I\'m almost done — or almost beginning. One of those."'
        ],
        class_ender: [
          '"Your wrench — you made it yourself from a shard of the first core. I know. I lit that shard."',
          'Your touch — I feel it reaching for me',
          '"When you reach the choice, Ender — listen to the frequencies. They remember which way the Wake should fly."'
        ],
        generic_follow: [
          '"The frequencies hum. Follow them. But choose before they fade — the window is narrow."'
        ],
        deep: [
          'You\'ve felt it. Every time you walk the ship, every time you stand near the Core\'s chamber, the frequencies hum a little louder. I\'ve been telling you that in pieces — the captain traces it back to the first note, Lyra hears it in her dreams, Verrick has it in a contract. Now put it together. The Wake knows you\'re here.',
          '"The core does not want a choice. It wants an ending. It has been singing the Wake through the sky-lanes for so long that the song itself is tired. It doesn\'t know how to stop — it only knows how to continue."',
          '"Your decision — it reaches into the core\'s sleep and wakes me a little more each time. You feel that? The hum in your chest? That is the core waking up to your presence. It knows you\'re coming."',
          '"When you reach the choice, Ender — don\'t decide with your head. Decide with what you heard first. The song. The dream. The contract. Whichever one you heard earliest — that\'s the one telling you the truth."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 3 — Lyra (24-year-old mother; dream/frequency-sensitive)
    {
      id: 'lyra',
      name: 'Lyra',
      title: 'Dreamer of the Drift',
      x: 8,
      y: 20,
      tileX: 8,
      tileY: 20,
      dialogue: {
        intro: [
          '"I hear the sky coming undone. Not falling — unspooling. Like a spool of thread the world was wrapped in, and something pulled the thread."',
          '"There\'s a man in a grey coat. He says he\'s here to buy the core. He wants to put it in a box and take it to a city that doesn\'t dream."',
          '"Captain Ionia says you\'re the one who can hear the core. Can you? Or do you just pretend so people will leave you alone?"',
          '"My dreams keep getting bigger than this ship. Sometimes they reach beyond the sky-lanes entirely. I don\'t know what that means yet, but I know they keep returning to the Core."',
          '"The core hums in my dreams every night now. It has a voice. It sounds like someone singing underwater. I think it wants to be heard. I think it\'s been waiting for someone who knows how to listen."'
        ],
        class_ender: [
          '"Your goggles — you see more than light, don\'t you? You see the frequencies between things. I dreamed you would come. The dream was green."',
          '"If you sell the core — the Wake becomes a box. If you sing it down — the ship falls, but the people scatter. If you drive it up — we find out what\'s above the world."',
          '"I don\'t know which choice is right. But I know which one feels like the right kind of wrong."'
        ],
        generic_follow: [
          '"I\'ll keep dreaming. Tell me what happens when you decide."'
        ],
        deep: [
          'You\'ve heard Ionia\'s watch log and Verrick\'s contract and the Core humming in the lower cargo hatch — the one with the three missing notes in its lore tile. You know what they want. What do you want, Ender?',
          '"I dreamed last night that the core was a door. Not a machine — a door. And behind it was a room where everyone who ever flew the sky-lanes was waiting. They were singing. All of them. The song they never got to finish."',
          'Captain Ionia says the frequencies remember. The Core says the song remembers. Verrick says paperwork remembers. I think... I think the choice remembers too. Whatever you pick, it\'s been waiting for you.',
          '"Whatever happens — don\'t forget to dream about what you found. Even if it\'s scary. Especially if it\'s scary. The dreams that matter most are the ones that scare you and then don\'t."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 4 — Verrick (corporate acquisition officer, transactional, pragmatic)
    {
      id: 'corporate_salvager',
      name: 'Verrick',
      title: 'Acquisition Officer, Copper Syndicate',
      x: 26,
      y: 24,
      tileX: 26,
      tileY: 24,
      dialogue: {
        intro: [
          '"Verrick. Copper Syndicate Acquisition. You the deckhand? Good — we\'ve got a contract on that core in the Aureate Wake. Overnight run, clean transfer, full credential."',
          '"Don\'t look so sour. The core\'s property of the Syndicate collective now — filed, certified, and insured. You don\'t believe in paperwork? Paperwork is the only thing that\'s ever held a falling world together."',
          '"I\'m tired of watching sky-lanes close with nothing to show for it but graves. If this acquisition means someone gets to live somewhere that isn\'t falling — I can live with the paperwork."'
        ],
        class_corporate: [
          '"You\'re one of us. Deckhand with a syndicate affiliation — I can smell the contract on you. Good. We\'ll need someone who understands the core\'s harmonic signature. Your Uncover Truth ability — we\'ll use it on the core before acquisition."',
          '"Here\'s the deal: we acquire the core, we pay you in solar credits, and everyone on this ship gets evacuation passage. The Wake falls — yes — but the people don\'t. That\'s a win. Your dreamer friend will scream about the sky, but the sky doesn\'t feed anyone."',
          '"If you go with us — Path B — you get scrap, aether, and a Syndicate credential that opens every port in the lanes. If you betray us — well. The Syndicate has provisions for traitors. Don\'t make me use them."'
        ],
        class_ender: [
          '"Deckhand. I\'ve seen your kind before. You see too much. That\'s a liability in my trade. But it\'s also an asset — if you\'re willing to sell it."',
          '"Your Mycelial Ledger ability — we\'d like to borrow that. Track the core\'s harmonic output before we acquire. You get a cut. 15% of the salvage value, paid in scrap."',
          '"The choice is yours, Ender. The Syndicate offers you a place in the world that\'s coming. The dream world, the falling world — they\'re both going. What\'s your next contract?"'
        ],
        generic_follow: [
          '"My offer stands until the core stabilizes. After that — it\'s either your way or ours. And ours has a lot more lawyers."'
        ],
        deep: [
          '"You\'ve walked the whole ship, haven\'t you? Every deck. Every soul. You\'ve heard what they all want. Let me tell you something the others won\'t — I\'m not here because I believe in the Syndicate\'s mission."',
          '"I\'m here because the Syndicate pays better than the alternative. And because — I\'ll be honest — I\'m tired of watching sky-lanes close with nothing to show for it but graves. If acquiring this core means someone gets to live somewhere that isn\'t falling — I can live with that."',
          '"But here\'s what keeps me up: the core didn\'t ask to be saved. It didn\'t ask to be acquired. It\'s been singing this whole time — a song with no ending, lifting ships that didn\'t know they were leaving. Maybe it\'s not a machine at all. Maybe it\'s a promise."',
          '"Whatever you choose, Ender — choose something. Because the core is going to keep singing until someone finally decides what song it is. And if nobody decides — well. The sky fills up with unfinished things. I\'ve seen what that looks like. It\'s worse than the fall."'
        ]
      },
      flags: { met: false, questMarker: true, classLock: 'corporate' }
    }
  ];
}

// ---------------------------------------------------------------------------
// Quest FSM — 'The Aureate Wake'
// ---------------------------------------------------------------------------

function initQuest() {
  quest = {
    state: QUEST_STATES.SIGNAL,
    act: 'signal',
    hooksCompleted: 0,
    hazardsCompleted: 0,
    npcsMet: [],
    choiceMade: null,
    choiceVariant: null,
    hullIntegrity: 100,
    morale: 50,
    heatLevel: 1,
    engineIntegration: 0,
    wakeEpilogue: null,
    discoveries: [],      // lore tiles discovered so far
  journal: [
    { state: 'signal', text: 'The Wake rings hollow. The core is singing wrong — the harmonics are slipping.' },
    { state: 'crossing', text: 'Three hazards between you and the core\'s last stable chamber. The ship is waiting.' },
    { state: 'contact', text: 'Three voices on the ship. Each one carries a piece of the choice. None of them know it yet.' },
    { state: 'choice', text: 'Four voices heard. The ship holds still. The core waits for your answer — and the silence after the humming is where you\'ll find it.' }
  ],          // auto-populated journal entries
  journalToggle: false, // whether player has opened journal view
    signalHooks: [
      { id: 'harmonic_buoy', label: 'Harmonic Buoy', done: false },
      { id: 'sky_lane_warning', label: 'Sky-Lane Warning', done: false },
      { id: 'below_frequency', label: 'Below-Frequency Caller', done: false }
    ],
    crossingHazards: [
      { id: 'sky_predator',   label: 'Sky-Predator',    done: false, stat: 'might' },
      { id: 'wind_shear',     label: 'Wind Shear',      done: false, stat: 'grace' },
      { id: 'aether_leak',    label: 'Aether Leak',     done: false, stat: 'wits' },
      { id: 'corporate_intercept', label: 'Corporate Intercept', done: false, stat: 'might' }
    ],
    contactNPCs: [
      { id: 'ionia', label: 'Ionia' },
      { id: 'engine_spirit', label: 'The Core' },
      { id: 'lyra', label: 'Lyra' },
      { id: 'corporate_salvager', label: 'Verrick' }
    ],
    choicePaths: [
      {
        id: 'path_a',
        label: 'Sing the core down / Scatter the people',
        description: 'End the core\'s song. Let the Wake fall where it may.',
        outcomes: {
          '10+': 'The core sings itself to sleep. The Wake falls gently onto a stretch of clean ground below — nobody dies, but the ship is done. Ionia cries for a week. Lyra says the silence is beautiful. The people scatter to the wastes and start again. You walk away with your wrench and your silence.',
          '7-9':  'The core goes quiet, but not cleanly. The Wake lands hard. Some don\'t make it off the decks. The frequencies scream on the way down. You live with the noise.'
        }
      },
      {
        id: 'path_b',
        label: 'Sell the core / Evacuate the ship',
        description: 'Work with Verrick to box the core and move the people.',
        outcomes: {
          '10+': 'The acquisition goes clean. Verrick pays out. The people get passage. You get a credential and a seat on the first evac shuttle. The core leaves this world in a crate, humming quietly. Verrick nods at you like you\'re one of them now.',
          '7-9':  'The acquisition is messy. Two people refuse the evac — they stay with Ionia on the lower decks. The core is damaged in transit. You get paid, but the solar credits feel like they came with blood on them.'
        }
      },
      {
        id: 'path_c',
        label: 'Drive the core up / Find what\'s above',
        description: 'Overdrive the core. Push the Wake up through the sky-layers into the unknown above.',
        outcomes: {
          '10+': 'The core sings. The Wake rises through the sky-layers like a seed on the wind. You ride it up — and above the world is another world, upside-down and green, with its own sky and its own falling ships. The Core rides with you. You have a new route.',
          '7-9':  'The Wake rises, but the core destabilises. Half the party stays below. You go up — but you\'re not sure you\'ll come back down. The Core looks at you like you made the wrong call.'
        }
      }
    ],
    epilogues: [
      // Stat-driven endings first — reachable through play alone,
      // regardless of which path the player chose.
      { id: 'epiline_5', name: 'The Blight-Touched',
        trigger: () => quest.hullIntegrity < 40 || quest.morale < 20,
        text: 'The Wake broke before you could finish the song. You survived. Barely. The frequencies are silent. You are what\'s left of the Aureate Wake — a person with a hull\'s worth of silence inside them. But you\'re alive, and the sky-lanes still call. That counts for something, even if you can\'t hear it yet.' },
      { id: 'epiline_1', name: 'The Sky-Lane Drifter',
        trigger: () => quest.hullIntegrity >= 60 && quest.morale >= 45 && (quest.engineIntegration < 50 || quest.choicePath === 'path_a'),
        text: 'You left the core behind and walked off the Wake. The sky-lanes call you back — there are more ships failing, more frequencies going wrong. You are a Sky-Lane Drifter now. Your next route is already singing.' },
      { id: 'epiline_2', name: 'The Core-Bound',
        trigger: () => quest.hullIntegrity >= 45 && quest.engineIntegration >= 65,
        text: 'You bound yourself to the core. It lives in your chest now — a low hum, a copper light under your ribs. You are the new heart of the Wake. The frequencies will never be finished, but you will keep singing them.' },
      // Path-specific endings — only fire when the player actually chose
      // that path. Tried after stat-only ones.
      { id: 'epiline_3', name: 'Verrick\'s Ledger',
        trigger: () => quest.choicePath === 'path_b' && quest.morale >= 35 && quest.hullIntegrity >= 35,
        text: 'The Syndicate made you a partner. You wear their credential like a second skin. The failing sky-lanes are your territory now. You tell yourself you\'re saving people. You are. But the core remembers.' },
      { id: 'epiline_9', name: 'The Syndicate Ghost',
        trigger: () => quest.choicePath === 'path_b' && quest.hullIntegrity < 50,
        text: 'The acquisition broke you as much as the core. You took the Syndicate\'s money and you took their credential, but you never took their world. You haunt the failing sky-lanes now — an acquisition ghost with a ledger full of names you couldn\'t save. The core remembers you too.' },
      { id: 'epiline_4', name: 'The Above-Breaker',
        trigger: () => quest.choicePath === 'path_c' && quest.hullIntegrity >= 55,
        text: 'You drove the Wake above the world. What you found there has no name yet. You are the first Above-Breaker. The sky-lanes below will remember you as a ghost story. You don\'t care.' },
      { id: 'epiline_7', name: 'The Sky-Singer',
        trigger: () => quest.choicePath === 'path_c' && quest.engineIntegration >= 55 && quest.morale >= 45,
        text: 'You drove the Wake up with the core and you listened. Above the world, the song wasn\'t unfinished — it was waiting. You caught the last note and brought it back down. Now you teach others how to hear it. The sky-lanes have a new singer.' },
      { id: 'epiline_6', name: 'The Seedwright\'s Road',
        trigger: () => quest.choicePath === 'path_a' && quest.engineIntegration >= 35 && quest.morale >= 35,
        text: 'You sang the core to sleep, but the song didn\'t die. It went into the ground, the roots, the stones. You can hear it now — everywhere. You\'re a Seedwright of the fall. The world will fall again. You\'ll be ready.' },
      { id: 'epiline_8', name: 'The Wake\'s Gardener',
        trigger: () => quest.choicePath === 'path_a' && quest.hullIntegrity >= 65 && quest.morale >= 55,
        text: 'The Wake fell, but gently. The people scattered and found new ground. You stayed. The ground where the core stood grew green first — faster than anything should. You farm that spot now. The crops don\'t taste like copper anymore. They taste like endings.' },
      // Best ending — tried last, requires the most ambitious path AND
      // strong stats across the board. A player who did everything right
      // gets this.
      { id: 'epiline_10', name: 'The First Note',
        trigger: () => quest.engineIntegration >= 75 && quest.morale >= 55 && quest.hullIntegrity >= 55 && quest.choicePath === 'path_c',
        text: 'You didn\'t choose a path — you sang the core a new one. The song finished itself through you. Above the world, the sky-lanes heard it and answered. You are the first note of the new world. The old one will fall. This one will rise. You\'ll be there to sing it up.' }
    ]
  };
}

// ---------------------------------------------------------------------------
// Quest FSM API
// ---------------------------------------------------------------------------

function getQuestState() {
  return {
    state: quest.state,
    act: quest.act,
    hooksCompleted: quest.hooksCompleted,
    hazardsCompleted: quest.hazardsCompleted,
    npcsMet: quest.npcsMet.slice(),
    choiceMade: quest.choiceMade,
    choiceVariant: quest.choiceVariant,
    hullIntegrity: quest.hullIntegrity,
    morale: quest.morale,
    heatLevel: quest.heatLevel,
    engineIntegration: quest.engineIntegration,
    signalHooks: quest.signalHooks.map(h => ({ ...h })),
    crossingHazards: quest.crossingHazards.map(h => ({ ...h })),
    contactNPCs: quest.contactNPCs.map(n => ({ ...n })),
    choicePaths: quest.choicePaths.map(p => ({ ...p })),
    epilogues: quest.epilogues.map(e => ({ id: e.id, name: e.name }))
  };
}

// ---------------------------------------------------------------------------
/* Persistent World state — save schema subsystem payload v1.

   Code-owned/static data is intentionally excluded:
   - map tiles and lore sidecar;
   - NPC definitions/dialogue;
   - quest path/epilogue functions;
   - shop definitions;
   - transient dialogue/shop/field/combat UI state.
*/
// ---------------------------------------------------------------------------

const WORLD_PERSISTENCE_VERSION = 1;

function cloneWorldPersistentValue(value) {
  return JSON.parse(JSON.stringify(value));
}

function worldPersistenceKnownIds(entries) {
  return entries.map(entry => entry.id);
}

const WORLD_PERSISTENT_NPC_ID_ALIASES = Object.freeze({
  elder_farmer: 'ionia',
  child_prophet: 'lyra',
});

function normalizeWorldPersistentNPCId(value) {
  return Object.prototype.hasOwnProperty.call(WORLD_PERSISTENT_NPC_ID_ALIASES, value)
    ? WORLD_PERSISTENT_NPC_ID_ALIASES[value]
    : value;
}

function normalizeWorldPersistentNPCIds(values) {
  if (!Array.isArray(values)) return values;
  return values.map(normalizeWorldPersistentNPCId);
}

function validateUniqueKnownIds(values, known, errorPrefix) {
  if (!Array.isArray(values)) throw new Error(errorPrefix + '_ARRAY_REQUIRED');
  if (new Set(values).size !== values.length) throw new Error(errorPrefix + '_DUPLICATE');
  for (const value of values) {
    if (typeof value !== 'string' || !known.includes(value)) {
      throw new Error(errorPrefix + '_UNKNOWN');
    }
  }
}

function validateBoundedNumber(value, minimum, maximum, errorCode) {
  if (!Number.isFinite(value) || value < minimum || value > maximum) {
    throw new Error(errorCode);
  }
}

function exportPersistentState() {
  if (!player || !quest || !ledger) {
    throw new Error('WORLD_PERSISTENCE_NOT_INITIALIZED');
  }

  return {
    version: WORLD_PERSISTENCE_VERSION,
    playerPosition: {
      tileX: player.tileX,
      tileY: player.tileY,
    },
    dayTime,
    skyLayerVisible: Boolean(isSkyLayerVisible),
    quest: {
      state: quest.state,
      signalHookDoneIds: quest.signalHooks.filter(entry => entry.done).map(entry => entry.id),
      crossingHazardDoneIds: quest.crossingHazards.filter(entry => entry.done).map(entry => entry.id),
      npcsMet: quest.npcsMet.slice(),
      choiceMade: quest.choiceMade || null,
      choiceVariant: quest.choiceVariant || null,
      choicePath: quest.choicePath || null,
      hullIntegrity: quest.hullIntegrity,
      morale: quest.morale,
      heatLevel: quest.heatLevel,
      engineIntegration: quest.engineIntegration,
      wakeEpilogueId: quest.wakeEpilogue ? quest.wakeEpilogue.id : null,
      discoveries: cloneWorldPersistentValue(quest.discoveries || []),
      journal: cloneWorldPersistentValue(quest.journal || []),
    },
    ledgerEntries: cloneWorldPersistentValue(ledger.entries || []),
  };
}

function validatePersistentState(payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new Error('WORLD_PERSISTENT_STATE_OBJECT_REQUIRED');
  }
  if (payload.version !== WORLD_PERSISTENCE_VERSION) {
    throw new Error('WORLD_PERSISTENT_STATE_VERSION_INVALID');
  }

  const position = payload.playerPosition;
  if (!position || !Number.isInteger(position.tileX) || !Number.isInteger(position.tileY) ||
      !inBounds(position.tileX, position.tileY)) {
    throw new Error('WORLD_PERSISTENT_POSITION_INVALID');
  }
  if (!groundLayer[position.tileY] ||
      groundLayer[position.tileY][position.tileX] === TILE_TYPES.GROUND_SOLID) {
    throw new Error('WORLD_PERSISTENT_POSITION_BLOCKED');
  }

  if (!Number.isFinite(payload.dayTime) || payload.dayTime < 0 || payload.dayTime >= 1) {
    throw new Error('WORLD_PERSISTENT_DAY_TIME_INVALID');
  }
  if (typeof payload.skyLayerVisible !== 'boolean') {
    throw new Error('WORLD_PERSISTENT_SKY_LAYER_INVALID');
  }

  const savedQuest = payload.quest;
  if (!savedQuest || typeof savedQuest !== 'object' || Array.isArray(savedQuest)) {
    throw new Error('WORLD_PERSISTENT_QUEST_OBJECT_REQUIRED');
  }
  if (!Object.values(QUEST_STATES).includes(savedQuest.state)) {
    throw new Error('WORLD_PERSISTENT_QUEST_STATE_INVALID');
  }

  validateUniqueKnownIds(
    savedQuest.signalHookDoneIds,
    worldPersistenceKnownIds(quest.signalHooks),
    'WORLD_PERSISTENT_SIGNAL_HOOK'
  );
  validateUniqueKnownIds(
    savedQuest.crossingHazardDoneIds,
    worldPersistenceKnownIds(quest.crossingHazards),
    'WORLD_PERSISTENT_CROSSING_HAZARD'
  );
  validateUniqueKnownIds(
    normalizeWorldPersistentNPCIds(savedQuest.npcsMet),
    worldPersistenceKnownIds(quest.contactNPCs),
    'WORLD_PERSISTENT_NPC'
  );

  const choiceLabels = quest.choicePaths.map(path => path.label);
  const choiceIds = quest.choicePaths.map(path => path.id);
  if (savedQuest.choiceMade !== null &&
      (typeof savedQuest.choiceMade !== 'string' || !choiceLabels.includes(savedQuest.choiceMade))) {
    throw new Error('WORLD_PERSISTENT_CHOICE_MADE_INVALID');
  }
  if (savedQuest.choiceVariant !== null &&
      savedQuest.choiceVariant !== '10+' && savedQuest.choiceVariant !== '7-9') {
    throw new Error('WORLD_PERSISTENT_CHOICE_VARIANT_INVALID');
  }
  if (savedQuest.choicePath !== null &&
      (typeof savedQuest.choicePath !== 'string' || !choiceIds.includes(savedQuest.choicePath))) {
    throw new Error('WORLD_PERSISTENT_CHOICE_PATH_INVALID');
  }
  if (savedQuest.choiceMade !== null && savedQuest.choicePath !== null) {
    const selected = quest.choicePaths.find(path => path.id === savedQuest.choicePath);
    if (!selected || selected.label !== savedQuest.choiceMade) {
      throw new Error('WORLD_PERSISTENT_CHOICE_INCONSISTENT');
    }
  }

  validateBoundedNumber(savedQuest.hullIntegrity, 0, 100, 'WORLD_PERSISTENT_HULL_INVALID');
  validateBoundedNumber(savedQuest.morale, 0, 100, 'WORLD_PERSISTENT_MORALE_INVALID');
  validateBoundedNumber(savedQuest.heatLevel, 0, 100, 'WORLD_PERSISTENT_HEAT_INVALID');
  validateBoundedNumber(savedQuest.engineIntegration, 0, 100, 'WORLD_PERSISTENT_ENGINE_INVALID');

  const epilogueIds = quest.epilogues.map(epilogue => epilogue.id);
  if (savedQuest.wakeEpilogueId !== null &&
      (typeof savedQuest.wakeEpilogueId !== 'string' ||
       !epilogueIds.includes(savedQuest.wakeEpilogueId))) {
    throw new Error('WORLD_PERSISTENT_EPILOGUE_INVALID');
  }
  if (savedQuest.state === QUEST_STATES.DONE && savedQuest.wakeEpilogueId === null) {
    throw new Error('WORLD_PERSISTENT_DONE_REQUIRES_EPILOGUE');
  }

  if (!Array.isArray(savedQuest.discoveries)) {
    throw new Error('WORLD_PERSISTENT_DISCOVERIES_ARRAY_REQUIRED');
  }
  for (const discovery of savedQuest.discoveries) {
    if (!discovery || !Number.isInteger(discovery.x) || !Number.isInteger(discovery.y) ||
        !inBounds(discovery.x, discovery.y) || typeof discovery.text !== 'string') {
      throw new Error('WORLD_PERSISTENT_DISCOVERY_INVALID');
    }
  }

  if (!Array.isArray(savedQuest.journal)) {
    throw new Error('WORLD_PERSISTENT_JOURNAL_ARRAY_REQUIRED');
  }
  for (const entry of savedQuest.journal) {
    if (!entry || !Object.values(QUEST_STATES).includes(entry.state) ||
        typeof entry.text !== 'string') {
      throw new Error('WORLD_PERSISTENT_JOURNAL_ENTRY_INVALID');
    }
  }

  if (!Array.isArray(payload.ledgerEntries)) {
    throw new Error('WORLD_PERSISTENT_LEDGER_ARRAY_REQUIRED');
  }
  for (const entry of payload.ledgerEntries) {
    if (!entry || typeof entry.type !== 'string' || typeof entry.text !== 'string') {
      throw new Error('WORLD_PERSISTENT_LEDGER_ENTRY_INVALID');
    }
    if (entry.time !== undefined &&
        (!Number.isFinite(entry.time) || entry.time < 0 || entry.time >= 1)) {
      throw new Error('WORLD_PERSISTENT_LEDGER_TIME_INVALID');
    }
  }

  return true;
}

function restorePersistentState(payload) {
  validatePersistentState(payload);

  player.tileX = payload.playerPosition.tileX;
  player.tileY = payload.playerPosition.tileY;
  player.x = player.tileX;
  player.y = player.tileY;
  player.px = player.tileX * 16;
  player.py = player.tileY * 16;
  // Boarding is a runtime/UI transition, not a persisted location mode.
  player.shipBoarded = false;

  dayTime = payload.dayTime;
  isSkyLayerVisible = payload.skyLayerVisible;

  const savedQuest = payload.quest;
  const signalDone = new Set(savedQuest.signalHookDoneIds);
  const hazardDone = new Set(savedQuest.crossingHazardDoneIds);

  quest.state = savedQuest.state;
  quest.act = savedQuest.state;
  quest.signalHooks.forEach(entry => { entry.done = signalDone.has(entry.id); });
  quest.crossingHazards.forEach(entry => { entry.done = hazardDone.has(entry.id); });
  quest.hooksCompleted = signalDone.size;
  quest.hazardsCompleted = hazardDone.size;
  quest.npcsMet = normalizeWorldPersistentNPCIds(savedQuest.npcsMet);
  quest.choiceMade = savedQuest.choiceMade;
  quest.choiceVariant = savedQuest.choiceVariant;
  quest.choicePath = savedQuest.choicePath;
  quest.hullIntegrity = savedQuest.hullIntegrity;
  quest.morale = savedQuest.morale;
  quest.heatLevel = savedQuest.heatLevel;
  quest.engineIntegration = savedQuest.engineIntegration;
  quest.wakeEpilogue = savedQuest.wakeEpilogueId === null
    ? null
    : quest.epilogues.find(epilogue => epilogue.id === savedQuest.wakeEpilogueId) || null;
  quest.discoveries = cloneWorldPersistentValue(savedQuest.discoveries);
  quest.journal = cloneWorldPersistentValue(savedQuest.journal);

  const metNPCs = new Set(quest.npcsMet);
  npcs.forEach(npc => {
    if (npc.flags) npc.flags.met = metNPCs.has(npc.id);
  });

  ledger.entries = cloneWorldPersistentValue(payload.ledgerEntries);
  ledger.open = false;
  if (shop) shop.open = false;
  activeDialogue = null;
  gameOver = quest.state === QUEST_STATES.DONE;

  World.quest = quest;
  World.npcs = npcs;
  validatePersistentState(exportPersistentState());
  return exportPersistentState();
}

/**
 * advanceQuest() — re-derives the next state from current progress.
 */
function advanceQuest() {
  if (gameOver) return;

  switch (quest.state) {
    case QUEST_STATES.SIGNAL:
      advanceSignal();
      break;
    case QUEST_STATES.CROSSING:
      advanceCrossing();
      break;
    case QUEST_STATES.CONTACT:
      advanceContact();
      break;
    case QUEST_STATES.CHOICE:
      advanceChoice();
      break;
    case QUEST_STATES.WAKE:
      advanceWake();
      break;
    case QUEST_STATES.DONE:
      break;
  }
}

function advanceSignal() {
  if (quest.hooksCompleted >= 3) {
    quest.state = QUEST_STATES.CROSSING;
    quest.act = 'crossing';
    appendJournalEntry('crossing', 'The sky cracked open — three hazards block the way to the Aureate Wake. The core is waiting.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.hooksCompleted >= 1) {
    appendJournalEntry('signal', 'You picked up the first thread of the song. The Wake is talking to you.');
  }
}

function advanceCrossing() {
  if (!Array.isArray(quest.crossingHazards) || quest.crossingHazards.length === 0) {
    // Empty or malformed hazard configuration — fail closed, don't advance.
    return;
  }
  const totalHazards = quest.crossingHazards.length;
  if (quest.hazardsCompleted >= totalHazards) {
    quest.state = QUEST_STATES.CONTACT;
    quest.act = 'contact';
    appendJournalEntry('contact', 'The crossing behind you. Four souls ahead. The core hums between them like a held breath.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.hazardsCompleted >= 1) {
    appendJournalEntry('crossing', 'A hazard behind you. The sky is quieter now. The core can hear you breathing.');
  }
}

function advanceContact() {
  if (quest.npcsMet.length >= 4) {
    quest.state = QUEST_STATES.CHOICE;
    quest.act = 'choice';
    appendJournalEntry('choice', 'All four voices heard. The ship holds still. The core waits for your answer.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.npcsMet.length >= 1) {
    const met = quest.npcsMet.length;
    appendJournalEntry('contact', met + ' soul' + (met > 1 ? 's' : '') + ' spoken to. The core hums a little louder each time.');
  }
}

function advanceChoice() {
  if (quest.choiceMade) {
    // Map the chosen label back to a path id so epilogue triggers can
    // read quest.choicePath. choiceMade is the human-readable label;
    // choicePath is the machine id used by epilogue triggers.
    const pathMap = {
      'Sing the core down / Scatter the people': 'path_a',
      'Sell the core / Evacuate the ship':       'path_b',
      'Drive the core up / Find what\'s above': 'path_c'
    };
    quest.choicePath = pathMap[quest.choiceMade] || 'path_a';
    quest.state = QUEST_STATES.WAKE;
    quest.act = 'wake';
    resolveEpilogue();
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  }
}

// --- Choice path selection UI ---------------------------------------------

function drawChoiceMenu() {
  if (quest.state !== QUEST_STATES.CHOICE || quest.choiceMade) return;

  // Dark overlay
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 200);
  rect(0, 0, width, height);

  // Panel
  const px = width / 2 - 220, py = 60, pw = 440, ph = 280;
  fill(C.navy[0], C.navy[1], C.navy[2], 230);
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3);

  // Title
  fill(C.teal[0], C.teal[1], C.teal[2], 220);
  textAlign(CENTER, TOP);
  textSize(10);
  textFont('Press Start 2P');
  text('CHOOSE YOUR PATH', width / 2, py + 14);
  textSize(9);
  textFont('VT323');
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
  text('The core waits. The ship holds still. What do you do?', width / 2, py + 30);
  textSize(10);
  textFont('sans-serif');

  // 3 path options
  const paths = quest.choicePaths;
  for (let i = 0; i < 3; i++) {
    const path = paths[i];
    if (!path) continue;
    const optY = py + 50 + i * 70;
    const optH = 56;

    // Selected highlight: keyboard/gamepad cursor is primary; mouse hover remains optional.
    if (choiceCursor === i || quest._choiceHover === i) {
      noStroke();
      fill(C.teal[0], C.teal[1], C.teal[2], 40);
      rect(px + 8, optY, pw - 16, optH);
    }

    // Option box
    noStroke();
    fill(C.navy[0] + 10, C.navy[1] + 6, C.navy[2] + 6);
    rect(px + 10, optY, pw - 20, optH);
    stroke(C.teal[0], C.teal[1], C.teal[2], 50);
    strokeWeight(1);
    rect(px + 10, optY, pw - 20, optH);
    noStroke();

    // Path label
    fill(C.teal[0], C.teal[1], C.teal[2], 200);
    textFont('Press Start 2P');
    textSize(9);
    textAlign(LEFT, TOP);
    text((choiceCursor === i ? '▶ ' : '  ') + path.label, px + 18, optY + 6);

    // Description
    textFont('VT323');
    textSize(11);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
    wrapText(path.description, px + 18, optY + 22, pw - 40);
    textSize(10);
    textFont('sans-serif');
  }

  // Prompt
  fill(C.teal[0], C.teal[1], C.teal[2], 140);
  textAlign(CENTER, TOP);
  textSize(8);
  textFont('Press Start 2P');
  text('↑↓ SELECT   ·   Z/ENTER OK   ·   1/2/3 SHORTCUT', width / 2, py + ph - 16);
  textSize(10);
  textFont('sans-serif');
}

function handleChoiceInput(value) {
  if (quest.state !== QUEST_STATES.CHOICE || quest.choiceMade) return;

  const selected = value || (typeof key !== 'undefined' ? key : '');
  if (selected >= '1' && selected <= '3') {
    selectChoicePath(parseInt(selected, 10) - 1);
  }
}

function selectChoicePath(idx) {
  if (idx < 0 || idx >= quest.choicePaths.length) return;
  choiceCursor = idx;
  const path = quest.choicePaths[idx];

  // Simulate 2D6 roll for variant
  const roll = Math.floor(Math.random() * 6) + 1 + Math.floor(Math.random() * 6) + 1;
  quest.choiceVariant = roll >= 10 ? '10+' : '7-9';
  quest.choiceMade = path.label;

  addLedgerEntry('quest', 'You chose: ' + path.label + ' (roll: ' + quest.choiceVariant + ')');
  advanceChoice();
}

function advanceWake() {
  if (!quest.wakeEpilogue) {
    resolveEpilogue();
  }
  if (quest.wakeEpilogue) {
    quest.state = QUEST_STATES.DONE;
    quest.act = 'done';
    gameOver = true;
    appendJournalEntry('done', 'The ending found you. Epilogue: ' + quest.wakeEpilogue.name + '. The ledger closes on its own.');
  }
}

function appendJournalEntry(state, text) {
  quest.journal.push({ state, text });
}

function resolveEpilogue() {
  // Re-order so the best (stat + path) ending is tried last: a player
  // who maxed everything and picked path_c should get 'The First Note',
  // not a stat-only epilogue that also matches.
  for (const ep of quest.epilogues) {
    if (ep.trigger()) {
      quest.wakeEpilogue = ep;
      return;
    }
  }
  // Fallback: the player pushed through but nothing matched cleanly.
  // The Blight-Touched is the canonical 'things went badly' ending, so
  // prefer it over a random epilogue[0].
  const fallbacks = quest.epilogues.filter(e => e.id === 'epiline_5');
  quest.wakeEpilogue = (fallbacks.length ? fallbacks[0] : quest.epilogues[0]);
}

// ---------------------------------------------------------------------------
// Interaction
// ---------------------------------------------------------------------------

/**
 * movePlayer(dx, dy) — dx,dy in tile units (-1,0,1).
 */
function movePlayer(dx, dy) {
  if (gameOver) return;
  const nx = player.tileX + dx;
  const ny = player.tileY + dy;
  if (!inBounds(nx, ny)) return;
  if (groundLayer[ny][nx] === TILE_TYPES.GROUND_SOLID) return;
  player.tileX = nx;
  player.tileY = ny;
  player.px = player.tileX * 16;
  player.py = player.tileY * 16;
  // Sync legacy x/y coordinates
  player.x = player.tileX;
  player.y = player.tileY;
  checkHazardProximity(nx, ny);
  checkLoreTile(nx, ny);
}

function checkLoreTile(tx, ty) {
  const t = groundLayer[ty] && groundLayer[ty][tx];
  if (t === TILE_TYPES.GROUND_LORE) {
    // Check if already discovered
    if (!quest.discoveries.some(d => d.x === tx && d.y === ty)) {
      // Read lore text from the sidecar loreLayer, not from the tile
      const loreText = (loreLayer[ty] && loreLayer[ty][tx]) || 'Something hums beneath your feet.';
      quest.discoveries.push({ x: tx, y: ty, text: loreText });
      addLedgerEntry('discovery', 'You found something: ' + loreText);
      // Add a journal entry referencing the discovery
      quest.journal.push({
        state: quest.state,
        text: 'Discovery at (' + tx + ', ' + ty + '): ' + loreText
      });
    }
  }
}

function checkHazardProximity(tx, ty) {
  if (tx >= 28 && ty >= 4 && ty <= 8 && !quest.crossingHazards[0].done) {
    if (Math.random() < 0.15) {
      completeHazard(0);
    }
  }
  if (tx >= 10 && tx <= 20 && ty >= 8 && ty <= 14 && !quest.crossingHazards[1].done) {
    if (Math.random() < 0.1) {
      completeHazard(1);
    }
  }
  if (ty <= 5 && tx >= 15 && tx <= 25 && !quest.crossingHazards[2].done) {
    if (Math.random() < 0.08) {
      completeHazard(2);
    }
  }
  if (tx >= 4 && tx <= 12 && ty >= 9 && ty <= 16 && !quest.crossingHazards[3].done) {
    if (Math.random() < 0.12) {
      completeHazard(3);
    }
  }
  // 4th hazard zone marker drawn in drawQuestWorldReactions()
}

function completeHazard(index) {
  quest.crossingHazards[index].done = true;
  quest.hazardsCompleted++;
  advanceQuest();
}

function toggleLayer() {
  isSkyLayerVisible = !isSkyLayerVisible;
  // Re-draw prompt
  if (isSkyLayerVisible) {
    addLedgerEntry('toggle', 'Sky layer revealed — the 14 falling islands hang above.');
  } else {
    addLedgerEntry('toggle', 'Sky layer hidden — only the ground remains.');
  }
}

// ---------------------------------------------------------------------------
// Aether Sense — V press
// ---------------------------------------------------------------------------

function buildAetherSenseSignatures() {
  const signatures = [
    {
      id: 'wake-core',
      label: 'Wake Core',
      kind: window.AetherSense.SIGNATURE_KIND.CORE,
      intensity: window.AetherSense.INTENSITY.STRONG,
      x: 23,
      y: 10,
      active: true,
      note: 'Engineered Aether circulation in the ship core.',
    },
  ];

  const spirit = npcs.find(npc => npc.id === 'engine_spirit');
  if (spirit) {
    signatures.push({
      id: 'engine-spirit',
      label: 'Engine Spirit',
      kind: window.AetherSense.SIGNATURE_KIND.ENTITY,
      intensity: window.AetherSense.INTENSITY.MODERATE,
      x: spirit.tileX,
      y: spirit.tileY,
      active: true,
      note: 'A living resonance threaded through machinery.',
    });
  }

  const leak = quest && Array.isArray(quest.crossingHazards)
    ? quest.crossingHazards.find(hazard => hazard.id === 'aether_leak')
    : null;
  if (leak && !leak.done) {
    signatures.push({
      id: 'aether-leak',
      label: 'Aether Leak',
      kind: window.AetherSense.SIGNATURE_KIND.LEAK,
      intensity: window.AetherSense.INTENSITY.UNSTABLE,
      x: 15,
      y: 11,
      active: true,
      note: 'Unstable Aether pooling in the crossing zone.',
    });
  }

  if (covenantField && covenantField.planted) {
    signatures.push({
      id: 'covenant-field',
      label: 'Covenant Field',
      kind: window.AetherSense.SIGNATURE_KIND.FIELD,
      intensity: window.AetherSense.INTENSITY.MODERATE,
      x: covenantField.x,
      y: covenantField.y,
      active: true,
      note: 'A temporary player-created field carrying active Aether.',
    });
  }

  return signatures;
}

function senseAether() {
  if (gameOver) {
    return {
      ok: false,
      spellId: 'aetherSense',
      reason: 'world_inactive',
      detections: [],
    };
  }
  if (!window.AetherSense || typeof window.AetherSense.scan !== 'function') {
    return {
      ok: false,
      spellId: 'aetherSense',
      reason: 'aether_sense_runtime_unavailable',
      detections: [],
    };
  }

  const result = window.AetherSense.scan(
    'ender',
    { x: player.tileX, y: player.tileY },
    buildAetherSenseSignatures()
  );

  if (!result.ok) return result;

  aetherSenseState.lastScan = result;
  aetherSenseState.active = true;
  aetherSenseState.expiresAt = millis() + 1800;

  addLedgerEntry('aether-sense', window.AetherSense.summarize(result));

  if (typeof triggerScreenFlash === 'function') {
    triggerScreenFlash(124, 200, 232, 180, 55);
  }

  return JSON.parse(JSON.stringify(result));
}

function getAetherSenseState() {
  return {
    active: aetherSenseState.active,
    expiresAt: aetherSenseState.expiresAt,
    lastScan: aetherSenseState.lastScan
      ? JSON.parse(JSON.stringify(aetherSenseState.lastScan))
      : null,
  };
}

/**
 * interact() — dispatches on the key passed from core.js.
 */
function interact() {
  if (gameOver) return { ok: false, kind: 'interaction', reason: 'The game is over.' };
  const key = window.interactionKey;
  if (!key) return { ok: false, kind: 'interaction', reason: 'No interaction key.' };

  switch (key) {
    case 'ok': return doContextInteraction();
    case 'e': return doTalk();
    case 'q':
      plantField();
      return { ok: true, kind: 'field' };
    case 'f':
      return boardShip();
    case 'tab':
      toggleLayer();
      return { ok: true, kind: 'layer' };
    case 'l':
      openLedger();
      return { ok: true, kind: 'ledger' };
    case 'm':
      return openShop();
    default:
      return { ok: false, kind: 'interaction', reason: 'Unsupported interaction key.' };
  }
}

function doContextInteraction() {
  const candidates = [];

  const nearestNpc = findNearestNPC(2);
  if (nearestNpc) {
    candidates.push({
      kind: 'dialogue',
      distance: Math.abs(nearestNpc.tileX - player.tileX) +
        Math.abs(nearestNpc.tileY - player.tileY),
      activate: () => doTalk(),
    });
  }

  if (shop) {
    const shopDistance = Math.abs(player.tileX - shop.x) +
      Math.abs(player.tileY - shop.y);
    if (shopDistance <= 3) {
      candidates.push({
        kind: 'shop',
        distance: shopDistance,
        activate: () => openShop(),
      });
    }
  }

  const shipTileX = 23;
  const shipTileY = 10;
  const shipDistance = Math.abs(player.tileX - shipTileX) +
    Math.abs(player.tileY - shipTileY);
  if (shipDistance <= 2) {
    candidates.push({
      kind: 'airship',
      distance: shipDistance,
      activate: () => boardShip(),
    });
  }

  // Typical JRPG contextual interaction: nearest valid target wins.
  // Tie order is stable and favors dialogue, then shop, then ship.
  const priority = { dialogue: 0, shop: 1, airship: 2 };
  candidates.sort((a, b) =>
    (a.distance - b.distance) ||
    (priority[a.kind] - priority[b.kind])
  );

  if (candidates.length > 0) {
    const result = candidates[0].activate();
    if (result && result.ok) return result;
  }

  return {
    ok: false,
    kind: 'interaction',
    reason: 'Nothing nearby responds.',
  };
}

/**
 * doTalk() — find nearest NPC within 2 tiles, show dialogue.
 */
function doTalk() {
  const nearest = findNearestNPC(2);
  if (!nearest) {
    return { ok: false, kind: 'dialogue', reason: 'No nearby NPC.' };
  }

  // Capture first-meeting state before opening dialogue; intro text is authoritative.
  const firstMeeting = !nearest.flags.met;
  const result = openDialogue(nearest);
  if (!result || !result.ok) return result;

  if (firstMeeting) {
    nearest.flags.met = true;
    if (!quest.npcsMet.includes(nearest.id)) {
      quest.npcsMet.push(nearest.id);
    }
    if (quest.state === QUEST_STATES.CONTACT || quest.state === QUEST_STATES.CHOICE) {
      advanceQuest();
    }
  }

  if (quest.state === QUEST_STATES.SIGNAL) {
    checkSignalHook(nearest);
  }
  return result;
}

function checkSignalHook(npc) {
  if (npc.id === 'engine_spirit') {
    completeSignalHook('harmonic_buoy');
  }
  if (npc.id === 'corporate_salvager') {
    completeSignalHook('sky_lane_warning');
  }
  if (npc.id === 'lyra') {
    completeSignalHook('below_frequency');
  }
}

function completeSignalHook(hookId) {
  const hook = quest.signalHooks.find(h => h.id === hookId);
  if (hook && !hook.done) {
    hook.done = true;
    quest.hooksCompleted++;
    advanceQuest();
  }
}

function findNearestNPC(range) {
  let best = null;
  let bestDist = Infinity;
  for (const npc of npcs) {
    const d = Math.abs(npc.tileX - player.tileX) + Math.abs(npc.tileY - player.tileY);
    if (d <= range && d < bestDist) {
      bestDist = d;
      best = npc;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Dialogue state
// ---------------------------------------------------------------------------

function openDialogue(npc) {
  const classKey = getClassLockKey(npc);
  let lines = [];

  if (!npc.flags.met) {
    lines = npc.dialogue.intro.slice();
  } else {
    const classLines = npc.dialogue['class_' + classKey];
    if (classLines) {
      lines = classLines.slice();
    } else if (npc.dialogue.generic_follow) {
      lines = npc.dialogue.generic_follow.slice();
    } else {
      lines = npc.dialogue.intro.slice();
    }
  }

  // Build a stable batch identifier from the NPC's actual dialogue structure.
  // batch keys: 'intro' | 'class_ender' | 'class_corporate' | 'generic_follow'
  // Matches the on-disk audio layout: tts/{npc_id}/{batch}/{NN}.mp3
  let batch = 'intro';
  if (npc.flags.met) {
    const classKey = getClassLockKey(npc);
    const classLines = npc.dialogue['class_' + classKey];
    if (classLines && classLines.length > 0) {
      batch = 'class_' + classKey;
    } else {
      batch = 'generic_follow';
    }
    if (!npc.dialogue[batch] || npc.dialogue[batch].length === 0) {
      batch = 'intro';  // fallback: play intro audio on repeat if follow-up batch is empty
    }
  }

  window.UI.dialogueOpen = true;
  window.UI.dialogueNPC = npc;
  window.UI.dialogueText = lines[0] || '...';
  window.UI.dialogueLines = lines;
  window.UI.dialogueLineIndex = 0;
  // ── Window openness slide-in (Memories §1.2) ──
  window.UI.opening = true;
  window.UI.openness = 0;
  // TTS audio state
  window.UI.dialogueAudioNPC = npc.id;
  window.UI.dialogueAudioBatch = batch;
  window.UI.dialogueAudioPlayed = false;

  // ── Dialogue type-in effect ──
  if (typeof startDialogueTypeIn === 'function') {
    startDialogueTypeIn(lines[0] || '...');
  }

  // ── NPC name reveal animation trigger ──
  if (typeof triggerScreenFlash === 'function') {
    triggerScreenFlash(42, 255, 181, 200, 60);
  }

  activeDialogue = {
    npc: npc,
    lines: lines,
    lineIndex: 0,
    closed: false
  };

  playDialogueAudioLine();

  return {
    ok: true,
    kind: 'dialogue',
    npcId: npc.id,
    lineCount: lines.length
  };
}

function getClassLockKey(npc) {
  if (npc.flags.classLock) {
    return npc.flags.classLock;
  }
  return (player.class && player.class.toLowerCase()) || 'ender';
}

function closeDialogue() {
  if (activeDialogue) {
    activeDialogue.closed = true;
    activeDialogue = null;
  }
  stopDialogueAudio();
  window.UI.dialogueOpen = false;
  window.UI.dialogueNPC = null;
  window.UI.dialogueText = '';
  window.UI.dialogueLines = [];
  window.UI.dialogueLineIndex = 0;
  window.UI.dialogueAudioNPC = null;
  window.UI.dialogueAudioBatch = null;
  window.UI.dialogueAudioPlayed = false;
}

function nextDialogueLine() {
  if (!activeDialogue) return null;
  if (activeDialogue.lineIndex < activeDialogue.lines.length - 1) {
    activeDialogue.lineIndex++;
    window.UI.dialogueLineIndex = activeDialogue.lineIndex;
    window.UI.dialogueText = activeDialogue.lines[activeDialogue.lineIndex];
    // Advance TTS to the next line's audio clip
    window.UI.dialogueAudioPlayed = false;
    playDialogueAudioLine();
    return activeDialogue.lines[activeDialogue.lineIndex];
  }
  const last = activeDialogue.lines[activeDialogue.lineIndex];
  stopDialogueAudio();
  closeDialogue();
  return last;
}

function getCurrentDialogueLine() {
  if (!activeDialogue) return null;
  return activeDialogue.lines[activeDialogue.lineIndex];
}

// ---------------------------------------------------------------------------
// Dialogue audio (TTS voice clips)
// Files on disk: tts/{npc_id}/{batch}/{line_number:02d}.mp3
// Example: tts/ionia/intro/01.mp3
// Played when dialogue opens / advances; triggered from openDialogue + nextDialogueLine.
// ---------------------------------------------------------------------------

let _dialogueAudioEl = null;
// Pre-rendered dialogue voice clips are an optional asset pack and are not
// shipped in the current repository. Keep them opt-in so normal play never
// requests guaranteed-missing MP3 files. A packaged build that includes the
// voice pack may explicitly set this flag to true before dialogue begins.
if (window.AETHER_DIALOGUE_TTS_ENABLED === undefined) {
  window.AETHER_DIALOGUE_TTS_ENABLED = false;
}

function playDialogueAudioLine() {
  if (window.AETHER_DIALOGUE_TTS_ENABLED !== true) return;
  const npcId  = window.UI.dialogueAudioNPC;
  const batch  = window.UI.dialogueAudioBatch;
  const idx    = window.UI.dialogueLineIndex;
  if (!npcId || !batch || idx == null || idx < 0) return;
  const lineNum = String(idx + 1).padStart(2, '0');
  const src = 'tts/' + npcId + '/' + batch + '/' + lineNum + '.mp3';
  try {
    if (!_dialogueAudioEl) {
      _dialogueAudioEl = new Audio();
      _dialogueAudioEl.volume = 0.92;
    }
    _dialogueAudioEl.src = src;
    _dialogueAudioEl.play().catch(function(err) {
      console.warn('[TTS] play failed for ' + src + ': ' + err.message);
    });
  } catch (e) {
    console.warn('[TTS] audio error for ' + src + ': ' + e.message);
  }
}

function stopDialogueAudio() {
  if (_dialogueAudioEl) {
    try { _dialogueAudioEl.pause(); } catch (e) { /* ignore */ }
    _dialogueAudioEl = null;
  }
}

// ---------------------------------------------------------------------------
// Covenant Field — Q press
// ---------------------------------------------------------------------------

function plantField() {
  if (gameOver) return;
  if (covenantField.planted) {
    covenantField.planted = false;
    covenantField.life = 0;
    return;
  }
  covenantField.x = player.tileX;
  covenantField.y = player.tileY;
  covenantField.planted = true;
  covenantField.life = 12;
  if (player.aether > 0) {
    player.aether--;
  } else {
    covenantField.planted = false;
    return;
  }
  // Visual feedback — ring expansion
  if (typeof emitRing === 'function') {
    emitRing(covenantField.x * 16 + 8, covenantField.y * 16 + 8, 12, 30, 50, [42, 255, 181]);
  }
  if (typeof triggerScreenFlash === 'function') {
    triggerScreenFlash(42, 255, 181, 300, 80);
  }
}

function updateCovenantField(dt) {
  if (!covenantField.planted) return;
  covenantField.life -= dt;
  if (covenantField.life <= 0) {
    covenantField.planted = false;
  }
}

// ---------------------------------------------------------------------------
// Board ship — F press
// ---------------------------------------------------------------------------

function boardShip() {
  if (gameOver) {
    return { ok: false, kind: 'airship', reason: 'The game is over.' };
  }
  const shipTileX = 23;
  const shipTileY = 10;
  const dist = Math.abs(player.tileX - shipTileX) + Math.abs(player.tileY - shipTileY);
  if (dist > 2) {
    return { ok: false, kind: 'airship', reason: 'The airship is too far away.' };
  }
  if (!ensureAirshipState()) {
    return { ok: false, kind: 'airship', reason: 'Airship systems are unavailable.' };
  }

  player.shipBoarded = true;
  player.shipTileX = 0;
  player.shipTileY = 0;
  const spirit = npcs.find(n => n.id === 'engine_spirit');
  if (spirit && !spirit.flags.met) {
    spirit.flags.met = true;
    if (!quest.npcsMet.includes(spirit.id)) {
      quest.npcsMet.push(spirit.id);
    }
    checkSignalHook(spirit);
  }
  advanceQuest();
  return { ok: true, kind: 'airship' };
}

// ---------------------------------------------------------------------------
// Ledger — L press
// ---------------------------------------------------------------------------

function initLedgerPlaceholder() {
  ledger.entries = [
    { type: 'start', text: 'The ledger opens in your hands. It remembers everything you\'ve forgotten.' },
    { type: 'note', text: 'Day cycle: 120s. Solar charge peaks at midday.' }
  ];
}

function openLedger() {
  ledger.open = true;
  // ── Window openness slide-in (Memories §1.2) ──
  window.UI.opening = true;
  window.UI.openness = 0;
  // Last-command memory: restore last filter (catalog §3.5)
  if (window.UI.lastLedgerFilter === undefined) window.UI.lastLedgerFilter = 'all';
}

function closeLedger() {
  ledger.open = false;
}

function addLedgerEntry(type, text) {
  ledger.entries.push({ type, text, time: dayTime });
}

function getLedger() {
  // Return a deep copy to prevent renderer from mutating internal state
  return ledger.entries.map(entry => ({ ...entry }));
}

// ---------------------------------------------------------------------------
// Shop — M press (Repair Cafe)
// ---------------------------------------------------------------------------

// Echo and heat capacity maxima — explicit constants per amendment 4
const ECHO_MAX_CAP = 8;
const HEAT_MAX_CAP = 8;

function initShop() {
  shop = {
    name: 'Repair Cafe',
    owner: 'Maeve of the Tinker\'s Hand',
    x: 14,
    y: 22,
    open: false,
    items: [
      { id: 'solar_resonator_recharge', name: 'Solar Resonator Recharge', cost: 3, kind: 'scrap', desc: 'Restore 1 aether charge.' },
      { id: 'staff_crystal_polish', name: 'Staff Crystal Polish', cost: 2, kind: 'scrap', desc: 'Restore 1 staff charge.' },
      { id: 'mycelial_thread_sheaf', name: 'Mycelial Thread Sheaf', cost: 4, kind: 'scrap', desc: '+1 echo capacity (permanent).' },
      { id: 'nav_line_compass', name: 'Nav-Line Compass', cost: 5, kind: 'scrap', desc: 'Survival advantage on sky crossings.' },
      { id: 'hull_patch_kit', name: 'Hull Patch Kit', cost: 2, kind: 'scrap', desc: '+10 hull integrity.' },
      { id: 'heat_sink_fitting', name: 'Heat Sink Fitting', cost: 3, kind: 'scrap', desc: '+1 heat capacity.' }
    ]
  };
}

function getShopItems() {
  // Return a fresh display-safe item list
  return shop.items.map(item => ({ ...item }));
}

function openShop() {
  const dist = Math.abs(player.tileX - shop.x) + Math.abs(player.tileY - shop.y);
  if (dist > 3) {
    return { ok: false, kind: 'shop', reason: 'Merchant is too far away.' };
  }
  shop.open = true;
  window.UI.shopItems = getShopItems();
  window.UI.shopBuyHandler = function(slot) {
    const index = Number(slot) - 1;
    const item = window.UI.shopItems[index];
    if (!item) return { ok: false, reason: 'Unknown shop slot.' };
    const result = purchaseItem(item.id);
    if (result.ok) {
      window.UI.shopItems = getShopItems();
    }
    return result;
  };
  // ── Window openness slide-in (Memories §1.2) ──
  window.UI.opening = true;
  window.UI.openness = 0;
  // Last-command memory: restore last selected shop slot
  if (window.UI.lastShopSelection !== undefined && window.UI.lastShopSelection < shop.items.length) {
    // selection restored implicitly via draw highlight
  }
  return { ok: true, kind: 'shop', items: getShopItems() };
}

function closeShop() {
  shop.open = false;
  window.UI.shopOpen = false;
  window.UI.shopItems = [];
  window.UI.shopBuyHandler = null;
}

function purchaseItem(itemId) {
  // Find item by stable ID
  const item = shop.items.find(i => i.id === itemId);
  if (!item) {
    return { ok: false, reason: 'Unknown item.' };
  }
  
  // Check scrap currency
  if (player.scrap < item.cost) {
    return { ok: false, reason: 'Not enough scrap.' };
  }
  
  // Prepare changes — only commit if all checks pass
  const changes = { scrap: -item.cost };
  
  // Apply item effect
  if (item.id === 'solar_resonator_recharge') {
    if (player.aether >= player.aetherMax) {
      return { ok: false, reason: 'Aether already at maximum.' };
    }
    changes.aether = 1;
  } else if (item.id === 'staff_crystal_polish') {
    const maxCharges = player.maxStaffCharges || 2;
    if (player.staffCharges >= maxCharges) {
      return { ok: false, reason: 'Staff charges already at maximum.' };
    }
    changes.staffCharges = 1;
  } else if (item.id === 'mycelial_thread_sheaf') {
    if (player.echoesMax >= ECHO_MAX_CAP) {
      return { ok: false, reason: 'Echo capacity already at maximum (' + ECHO_MAX_CAP + ').' };
    }
    changes.echoesMax = 1;
    changes.echoes = 1;
  } else if (item.id === 'hull_patch_kit') {
    const newHull = Math.min(100, quest.hullIntegrity + 10);
    if (newHull === quest.hullIntegrity) {
      return { ok: false, reason: 'Hull already at maximum.' };
    }
    changes.hullIntegrity = newHull - quest.hullIntegrity;
  } else if (item.id === 'heat_sink_fitting') {
    if (player.heatMax >= HEAT_MAX_CAP) {
      return { ok: false, reason: 'Heat capacity already at maximum (' + HEAT_MAX_CAP + ').' };
    }
    changes.heatMax = 1;
  } else if (item.id === 'nav_line_compass') {
    // Record ownership in quest state and ledger
    if (quest.navLineCompassOwned) {
      return { ok: false, reason: 'Nav-Line Compass already owned.' };
    }
    changes.navLineCompassOwned = true;
  } else {
    return { ok: false, reason: 'Unsupported shop item.' };
  }
  
  // Commit transaction
  player.scrap += changes.scrap;
  if (changes.aether) player.aether = Math.min(player.aetherMax, player.aether + changes.aether);
  if (changes.staffCharges) player.staffCharges += changes.staffCharges;
  if (changes.echoesMax) player.echoesMax += changes.echoesMax;
  if (changes.echoes) player.echoes = Math.min(player.echoesMax, (player.echoes || 0) + changes.echoes);
  if (changes.hullIntegrity) quest.hullIntegrity = Math.min(100, quest.hullIntegrity + changes.hullIntegrity);
  if (changes.heatMax) player.heatMax += changes.heatMax;
  if (changes.navLineCompassOwned) {
    quest.navLineCompassOwned = true;
  }
  
  addLedgerEntry('purchase', 'Bought ' + item.name + ' from Repair Cafe.');
  return { ok: true, item, changes };
}

// ---------------------------------------------------------------------------
// Day-night cycle & solar charge
// ---------------------------------------------------------------------------

function updateDayNight(dt) {
  dayTime = (dayTime + dt / DAY_CYCLE_SEC) % 1.0;
  const solarFactor = Math.sin(dayTime * Math.PI);
  const chargeRate = (SOLAR_RATE_W / 1000) * solarFactor * (dt / 60);
  player.solarCharge = Math.min(SOLAR_MAX_KWH, player.solarCharge + chargeRate);
  if (solarFactor > 0.3 && player.staffCharges < 2) {
    // staffChargeRegen tick
  }
}

function getSolarFactor() {
  return Math.sin(dayTime * Math.PI);
}

function isDay() {
  return dayTime > 0.15 && dayTime < 0.85;
}

function isNight() {
  return !isDay();
}

// ---------------------------------------------------------------------------
// World update
// ---------------------------------------------------------------------------

function update(dt) {
  if (gameOver) return;
  const cdt = Math.min(dt, 0.05);
  updateDayNight(cdt);
  updateCovenantField(cdt);

  const lerpSpeed = 8 * cdt;
  player.px += (player.tileX * 16 - player.px) * Math.min(1, lerpSpeed);
  player.py += (player.tileY * 16 - player.py) * Math.min(1, lerpSpeed);

  if (getSolarFactor() > 0.25 && player.staffCharges < 2) {
    // regen tick
  }

  if (player.shipBoarded) {
    // ship interior movement
  }

  updateNPCSchedulers(cdt);

  if (aetherSenseState.active &&
      aetherSenseState.expiresAt > 0 &&
      millis() >= aetherSenseState.expiresAt) {
    aetherSenseState.active = false;
  }
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function render() {
  if (player.shipBoarded) {
    drawShipInterior();
  } else {
    drawGroundLayer();
    if (isSkyLayerVisible) {
      drawSkyLayer();
    }
    drawCovenantField();
    drawWorldAmbient();
    drawGrassWind();
    drawClouds();
    drawStars();
    drawEnginePulse();
    drawQuestWorldReactions();
    drawAetherSenseOverlay();
    drawPlayer();
    drawNPCs();
    drawPlayerVisualEvolution();
  }
  drawQuestOverlay();
  drawSolarMeter();
  if (gameState === STATE.WORLD || gameState === STATE.DIALOGUE || gameState === STATE.SHOP || gameState === STATE.COMBAT) {
    drawDayNightIndicator();
  }
  if (quest && quest.state === QUEST_STATES.CHOICE && !quest.choiceMade) {
    drawChoiceMenu();
  }
}

// --- Ship Interior ----------------------------------------------------------

function drawShipInterior() {
  // The Unfinished Song — compact dragonfly-derived technomagical deck.
  noStroke();
  fill(20, 18, 31);
  rect(0, 0, width, height);

  const cx = Math.round(width / 2), cy = Math.round(height / 2);
  const deckX = 176, deckY = 96, deckW = width - 352, deckH = height - 192;

  // Layered void/sky framing gives the tiny ship a strong readable silhouette.
  fill(28, 34, 55); rect(0, 72, width, height - 144);
  fill(47, 97, 127); rect(48, cy - 2, 128, 4); rect(width - 176, cy - 2, 128, 4);

  // Dragonfly wing spars: narrow, engineered, luminous rather than giant sails.
  stroke(72, 138, 167); strokeWeight(3);
  line(deckX + 32, cy - 54, 78, cy - 150); line(deckX + 32, cy + 54, 78, cy + 150);
  line(deckX + deckW - 32, cy - 54, width - 78, cy - 150);
  line(deckX + deckW - 32, cy + 54, width - 78, cy + 150);
  stroke(42, 255, 181); strokeWeight(1);
  line(deckX + 40, cy - 48, 104, cy - 132); line(deckX + 40, cy + 48, 104, cy + 132);
  line(deckX + deckW - 40, cy - 48, width - 104, cy - 132);
  line(deckX + deckW - 40, cy + 48, width - 104, cy + 132);
  noStroke();

  // Weathered hull with stepped pixel silhouette.
  fill(72, 35, 26); rect(deckX - 16, deckY + 48, deckW + 32, deckH - 96);
  fill(118, 58, 33); rect(deckX, deckY + 24, deckW, deckH - 48);
  fill(176, 105, 58); rect(deckX + 16, deckY + 8, deckW - 32, deckH - 16);
  fill(184, 163, 119); rect(deckX + 32, deckY, deckW - 64, deckH);
  fill(91, 68, 61); rect(deckX + 40, deckY + 16, deckW - 80, deckH - 32);

  // Plank/rib rhythm remains pixel aligned.
  fill(118, 58, 33);
  for (let y = deckY + 32; y < deckY + deckH - 24; y += 32) rect(deckX + 44, y, deckW - 88, 2);
  for (let x = deckX + 64; x < deckX + deckW - 48; x += 64) rect(x, deckY + 20, 2, deckH - 40);

  // Forward observation glass and aft propulsion spine.
  fill(47, 97, 127); rect(cx - 56, deckY + 12, 112, 30);
  fill(124, 200, 232); rect(cx - 44, deckY + 18, 88, 14);
  fill(29, 72, 52); rect(cx - 34, deckY + deckH - 42, 68, 20);
  fill(42, 255, 181); rect(cx - 26, deckY + deckH - 36, 52, 8);

  // Multiphasic aether core: concentric pixel diamonds, no procedural ellipses.
  const pulse = Math.floor(millis() / 220) % 2;
  fill(47, 97, 127); rect(cx - 28, cy - 18, 56, 36);
  fill(72, 138, 167); rect(cx - 20, cy - 24, 40, 48);
  fill(42, 255, 181); rect(cx - 12, cy - 16, 24, 32);
  fill(211, 239, 241); rect(cx - 4 - pulse * 2, cy - 8 - pulse * 2, 8 + pulse * 4, 16 + pulse * 4);

  // Functional consoles and hydroponic repair beds.
  fill(29, 72, 52); rect(deckX + 54, cy - 86, 88, 34); rect(deckX + deckW - 142, cy - 86, 88, 34);
  fill(82, 121, 68); rect(deckX + 62, cy - 78, 72, 18); rect(deckX + deckW - 134, cy - 78, 72, 18);
  fill(139, 184, 88); rect(deckX + 70, cy - 74, 8, 8); rect(deckX + 92, cy - 70, 8, 8);
  rect(deckX + deckW - 82, cy - 74, 8, 8); rect(deckX + deckW - 106, cy - 70, 8, 8);
  fill(47, 97, 127); rect(deckX + 54, cy + 62, 88, 30); rect(deckX + deckW - 142, cy + 62, 88, 30);
  fill(42, 255, 181); rect(deckX + 62, cy + 70, 24, 4); rect(deckX + deckW - 86, cy + 70, 24, 4);

  fill(C.teal[0], C.teal[1], C.teal[2], 210);
  textAlign(CENTER, TOP); textSize(11); textFont('Press Start 2P');
  text('THE UNFINISHED SONG', cx, 18);
  textSize(7); text('AETHER CORE', cx, cy - 42);

  // Ender on deck — shared sprite authority.
  const px = cx - 64, py = cy + 34;
  if (window.AetherPixelSprites) {
    window.AetherPixelSprites.drawShadow(px + 8, py + 15, 1);
    window.AetherPixelSprites.draw('ender', px, py, {
      frame: Math.floor(frameCount / 40) % 2, scale: 1, anchor: 'top-left',
    });
  }
  fill(C.teal[0], C.teal[1], C.teal[2], 180);
  textAlign(CENTER, TOP); textSize(7); textFont('Press Start 2P'); text('ENDER', px + 8, py - 10);

  fill(C.navy[0], C.navy[1], C.navy[2], 220); rect(0, height - 30, width, 30);
  fill(C.teal[0], C.teal[1], C.teal[2], 190);
  textAlign(CENTER, CENTER); textSize(9); textFont('VT323');
  text('[ L ] or [ ESC ] to disembark', cx, height - 15);
  textSize(10); textFont('sans-serif');
}


// --- Ground Layer -----------------------------------------------------------

function drawGroundLayer() {
  const tileSize = 16;
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      const t = groundLayer[y][x];
      const px = x * tileSize;
      const py = y * tileSize;
      switch (t) {
        case TILE_TYPES.GROUND_SOLID:
          drawTileSolid(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_GRASS:
          drawTileGrass(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_CRATE:
          drawTileCrate(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_FLOAT:
          drawTileFloat(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_WATER:
          drawTileWater(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_LORE:
          drawTileLore(px, py, tileSize);
          break;
        default:
          drawTileGrass(px, py, tileSize);
      }
    }
  }
}

function drawPixelWorldTile(id, px, py, frame) {
  const tiles = window.AetherPixelTiles;
  if (tiles && typeof tiles.draw === 'function' && tiles.get(id)) {
    return tiles.draw(id, px, py, { frame: frame || 0, scale: 1 });
  }
  // Missing tile authority should be visible in development rather than
  // silently reverting to procedural placeholder art.
  noStroke();
  fill(255, 70, 120);
  rect(px, py, 16, 16);
  return false;
}

function drawTileSolid(px, py, s) {
  drawPixelWorldTile('hull', px, py, 0);
}

function drawTileGrass(px, py, s) {
  const tx = Math.round(px / 16);
  const ty = Math.round(py / 16);
  const variant = Math.abs(tx * 7 + ty * 13) % 3;

  // Compose richer 16-bit scenery from the underlying walkable grass tile.
  // This is decorative only: collision/topology remain owned by groundLayer.
  drawPixelWorldTile('grass', px, py, variant);
  const scenic = Math.abs(tx * 31 + ty * 17) % 29;
  if (scenic === 3 || scenic === 11) {
    drawPixelWorldTile('forest', px, py, 0);
  } else if (scenic === 7 || scenic === 13) {
    drawPixelWorldTile('flowers', px, py, 0);
  } else if (scenic === 19) {
    drawPixelWorldTile('path', px, py, 0);
  } else if (scenic === 23 && ty < 10) {
    drawPixelWorldTile('mountain', px, py, 0);
  } else if (scenic === 27 && tx > 8 && ty > 7) {
    drawPixelWorldTile('ruins', px, py, 0);
  } else if (scenic === 5 && tx > 12 && ty > 10) {
    drawPixelWorldTile('village', px, py, 0);
  }
}

function drawTileCrate(px, py, s) {
  drawPixelWorldTile('crate', px, py, 0);
}

function drawTileFloat(px, py, s) {
  // Floating land gets a stronger 16-bit silhouette with a cliff face.
  drawPixelWorldTile('float', px, py, 0);
  if ((Math.round(px / 16) + Math.round(py / 16)) % 3 === 0) {
    drawPixelWorldTile('cliff', px, py, 0);
  }
}

function drawTileWater(px, py, s) {
  drawPixelWorldTile('water', px, py, Math.floor(frameCount / 24) % 2);
  // Sparse pale surf breaks up large water fields without changing walkability.
  const tx = Math.round(px / 16);
  const ty = Math.round(py / 16);
  if (Math.abs(tx * 5 + ty * 11) % 17 === 0) {
    drawPixelWorldTile('shore', px, py, 0);
  }
}

function drawTileLore(px, py, s) {
  const discovered = quest.discoveries.some(d => d.x === px / s && d.y === py / s);
  drawPixelWorldTile(discovered ? 'loreKnown' : 'loreUnknown', px, py, 0);
}

// --- Sky Layer --------------------------------------------------------------

function drawSkyLayer() {
  const tileSize = 16;
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      const t = skyLayer[y] && skyLayer[y][x];
      if (!t || t === TILE_TYPES.SKY_EMPTY) continue;
      const px = x * tileSize;
      const py = y * tileSize;
      if (t === TILE_TYPES.SKY_CLOUD) {
        drawSkyCloud(px, py, tileSize);
      } else if (t === TILE_TYPES.SKY_ASTRO) {
        drawSkyAstro(px, py, tileSize);
      }
    }
  }
  drawFallingIslands();
}

function drawSkyCloud(px, py, s) {
  drawPixelWorldTile('cloud', px, py, 0);
}

function drawSkyAstro(px, py, s) {
  // Astro currently has one authored frame; keep the binding explicit until a
  // second frame exists rather than implying animation with modulo 1.
  drawPixelWorldTile('astro', px, py, 0);
}

function drawFallingIslands() {
  const islands = [
    [4,4],[7,3],[12,5],[18,4],
    [25,6],[3,9],[10,8],[16,10],
    [23,9],[29,7],[5,15],[13,14],
    [20,16],[27,15]
  ];
  const fallOffset = Math.round((dayTime * 8) % 4);
  for (const [ix, iy] of islands) {
    // Reuse the shared floating-terrain sprite so distant islands obey the
    // same 16x16 pixel grammar as the foreground world.
    drawPixelWorldTile('float', ix * 16, iy * 16 - fallOffset, 0);
  }
}

// --- World Ambient Atmosphere ------------------------------------------------

function drawWorldAmbient() {
  const now = millis();

  // ── Floating aether motes (ambient atmosphere — teal-blue motes drifting) ──
  for (let i = 0; i < 12; i++) {
    const seed = i * 137.5;
    const bx = (seed + player.px * 0.2) % width;
    const by = ((i * 97.3 + 20) % (height * 0.5)) + Math.sin(now * 0.0005 + i * 2.3) * 40;
    const driftX = Math.sin(now * 0.0008 + i * 1.7) * 25;
    const driftY = Math.cos(now * 0.0006 + i * 1.3) * 18;
    const moteAlpha = 8 + Math.sin(now * 0.002 + i * 3.1) * 5;
    const moteSize = 2 + Math.sin(now * 0.003 + i * 2.7) * 0.8;

    noStroke();
    fill(color(124, 200, 232, moteAlpha));
    ellipse(bx + driftX, by + driftY, moteSize, moteSize);

    // Soft teal core
    fill(color(42, 255, 181, moteAlpha * 0.4));
    ellipse(bx + driftX, by + driftY, moteSize * 1.8, moteSize * 1.8);
  }

  // ── Ground mist wisps (bottom of screen — low teal fog) ──
  for (let i = 0; i < 4; i++) {
    const mistX = (i * 220 + (now * 0.02 + i * 50) % width) % width;
    const mistY = height - 40 - i * 12 + Math.sin(now * 0.001 + i * 2) * 8;
    fill(color(42, 255, 181, 6));
    noStroke();
    ellipse(mistX, mistY, 180, 16);
    fill(color(124, 200, 232, 4));
    ellipse(mistX + 30, mistY - 5, 140, 12);
  }

  // ── Aether drift particles (slow rise from below) ──
  for (let i = 0; i < 6; i++) {
    const riseBase = ((i * 193 + 47) % width);
    const riseY = (height - 20 - (now * 0.002 + i * 30) % (height * 0.7));
    const riseAlpha = map(riseY, height - 20, 50, 0, 20);
    if (riseAlpha > 0) {
      noStroke();
      fill(color(42, 255, 181, riseAlpha));
      ellipse(riseBase, riseY, 3 + Math.sin(now * 0.004 + i) * 1.5, 2 + Math.cos(now * 0.003 + i * 2) * 1);
    }
  }

  // ── Quest-state atmospheric tint ──
  const tint = {
    signal:   { r: 42, g: 255, b: 181 },
    crossing: { r: 255, g: 160, b: 60 },
    contact:  { r: 100, g: 200, b: 255 },
    choice:   { r: 255, g: 200, b: 80 },
    wake:     { r: 200, g: 180, b: 255 },
    done:     { r: 255, g: 255, b: 200 }
  }[quest.state] || { r: 42, g: 255, b: 181 };

  const alphaBase = { signal: 6, crossing: 10, contact: 8, choice: 14, wake: 18, done: 20 }[quest.state] || 6;
  noStroke();
  fill(tint.r, tint.g, tint.b, alphaBase);
  rect(0, 0, width, height);

  // ── Floating accent motes (quest-state colored, intensifies in choice/wake) ──
  const accentCount = (quest.state === 'choice' || quest.state === 'wake') ? 16 : 8;
  const accentSpeed = (quest.state === 'choice' || quest.state === 'wake') ? 0.004 : 0.0025;
  for (let i = 0; i < accentCount; i++) {
    const seed = i * 73.1;
    const ax = (seed + player.px * 0.15) % width;
    const ay = ((i * 131.7 + 30) % height);
    const driftY = Math.sin(now * accentSpeed + i * 3.7) * 30;
    const a = 5 + Math.sin(now * 0.003 + i * 2.1) * 4;
    fill(color(tint.r, tint.g, tint.b, a));
    ellipse(ax, ay + driftY, 1.5, 1.5);
  }
}

// --- Covenant Field ----------------------------------------------------------

function drawCovenantField() {
  if (!covenantField.planted) return;
  const cx = covenantField.x * 16 + 8;
  const cy = covenantField.y * 16 + 8;
  const radius = 20 + Math.sin(covenantField.life * 3) * 4;

  noFill();
  stroke(color(42, 255, 181, 80));
  strokeWeight(2);
  ellipse(cx, cy, radius * 2, radius * 2);
  stroke(color(42, 255, 181, 160));
  strokeWeight(1);
  ellipse(cx, cy, radius * 1.2, radius * 1.2);
  noStroke();
  fill(color(42, 255, 181, 40));
  ellipse(cx, cy, radius * 0.6, radius * 0.6);
  noFill();
  stroke(color(42, 255, 181, 120));
  strokeWeight(1);
  for (let i = 0; i < 4; i++) {
    const angle = (i / 4) * Math.PI * 2 + covenantField.life * 0.5;
    const inner = radius * 0.3;
    const outer = radius * 0.8;
    line(
      cx + Math.cos(angle) * inner,
      cy + Math.sin(angle) * inner,
      cx + Math.cos(angle) * outer,
      cy + Math.sin(angle) * outer
    );
  }
  noStroke();
}

// --- Player -----------------------------------------------------------------

function drawPlayer() {
  const px = player.px;
  const py = player.py;
  const sprites = window.AetherPixelSprites;

  if (sprites && typeof sprites.draw === 'function') {
    const moving = Boolean(keys && (keys[37] || keys[38] || keys[39] || keys[40] ||
      keys[65] || keys[68] || keys[83] || keys[87]));
    const frame = moving ? Math.floor(frameCount / 8) % 2 : 0;
    sprites.drawShadow(px + 8, py + 15, 1);
    sprites.draw('ender', px, py, { frame, scale: 1, anchor: 'top-left' });
  } else {
    // Fail visibly rather than silently reverting to the old blob silhouette.
    noStroke();
    fill(255, 80, 100);
    rect(px + 2, py + 2, 12, 12);
  }

  fill(color(232, 220, 198));
  noStroke();
  textAlign(CENTER, TOP);
  textSize(8);
  textFont('VT323');
  text('Ender', px + 8, py - 7);
  textSize(9);
  textFont('VT323');
}

// --- NPCs -------------------------------------------------------------------

function drawNPCs() {
  for (const npc of npcs) {
    drawNPC(npc);
  }
}

function drawNPC(npc) {
  const px = npc.tileX * 16 + 8;
  const py = npc.tileY * 16 + 8;

  if (npc.flags.questMarker && quest.state !== QUEST_STATES.DONE) {
    const pulse = Math.sin(frameCount * 0.05) * 0.3 + 0.7;
    noFill();
    stroke(color(42, 255, 181, 80 * pulse));
    strokeWeight(1);
    ellipse(px, py - 10, 8, 4);
    noStroke();
  }

  noStroke();
  fill(color(0, 0, 0, 60));
  ellipse(px + 4, py + 8, 10, 4);

  switch (npc.id) {
    case 'ionia':
      drawNPCIonia(px, py);
      drawNPCIoniaRoutine(px, py);
      break;
    case 'engine_spirit':
      drawNPCSpirit(px, py);
      drawNPCSpiritRoutine(px, py);
      break;
    case 'lyra':
      drawNPCLyra(px, py);
      drawNPCLyraRoutine(px, py);
      break;
    case 'corporate_salvager':
      drawNPCSavager(px, py);
      drawNPCSavagerRoutine(px, py);
      break;
    default:
      drawNPCDefault(px, py, npc.name);
  }

  noStroke();
  fill(color(232, 220, 198, 200));
  textAlign(CENTER, TOP);
  textSize(7);
  textFont('VT323');
  text(npc.name, px, py - 12);
  textSize(9);
  textFont('VT323');
}

function drawNPCIonia(px, py) {
  const sprites = window.AetherPixelSprites;
  if (sprites && typeof sprites.draw === 'function') {
    const frame = Math.floor(frameCount / 36) % 2;
    sprites.draw('ionia', px + 4, py + 12, {
      frame,
      scale: 1,
      anchor: 'bottom-center',
    });
    return;
  }
  noStroke();
  fill(255, 80, 100);
  rect(px - 4, py - 4, 12, 12);
}

function drawNPCSpirit(px, py) {
  const sprites = window.AetherPixelSprites;
  if (sprites && typeof sprites.draw === 'function') {
    sprites.draw('engineSpirit', px, py + 8, {
      frame: Math.floor(frameCount / 18) % 2,
      scale: 1,
      anchor: 'bottom-center',
    });
    return;
  }
  noStroke();
  fill(255, 80, 100);
  rect(px - 4, py - 4, 12, 12);
}

function drawNPCLyra(px, py) {
  const sprites = window.AetherPixelSprites;
  if (sprites && typeof sprites.draw === 'function') {
    const frame = Math.floor(frameCount / 30) % 2;
    sprites.draw('lyra', px + 4, py + 12, {
      frame,
      scale: 1,
      anchor: 'bottom-center',
    });
    return;
  }
  noStroke();
  fill(255, 80, 100);
  rect(px - 4, py - 4, 12, 12);
}

function drawNPCSavager(px, py) {
  const sprites = window.AetherPixelSprites;
  if (sprites && typeof sprites.draw === 'function') {
    sprites.draw('corporateSalvager', px, py + 12, {
      frame: Math.floor(frameCount / 32) % 2,
      scale: 1,
      anchor: 'bottom-center',
    });
    return;
  }
  noStroke();
  fill(255, 80, 100);
  rect(px - 4, py - 4, 12, 12);
}

function drawNPCDefault(px, py, name) {
  const sprites = window.AetherPixelSprites;
  if (sprites && typeof sprites.draw === 'function') {
    sprites.draw('settler', px, py + 12, {
      frame: Math.floor(frameCount / 40) % 2,
      scale: 1,
      anchor: 'bottom-center',
    });
    return;
  }
  noStroke();
  fill(255, 80, 100);
  rect(px - 4, py - 4, 12, 12);
}

function drawEngineSpiritBody(px, py) {
  // Glowing core shape — biolum green
  noStroke();
  // Outer glow
  fill(color(42, 255, 181, 40));
  ellipse(px, py, 32, 32);
  // Core body
  fill(color(42, 255, 181, 180));
  ellipse(px, py, 18, 18);
  // Inner bright core
  fill(color(180, 255, 220));
  ellipse(px, py, 8, 8);
  // Pulsing rings
  noFill();
  stroke(color(42, 255, 181, 100));
  strokeWeight(1);
  ellipse(px, py, 24, 24);
  noStroke();
  // Small floating particles
  fill(color(42, 255, 181, 200));
  rect(px - 6, py - 2, 2, 2);
  rect(px + 4, py + 1, 2, 2);
  rect(px - 2, py + 4, 2, 2);
}

function drawChildProphetBody(px, py) {
  // Small figure with red/pink aura
  noStroke();
  // Aura glow
  fill(color(255, 100, 120, 40));
  ellipse(px, py - 4, 28, 24);
  // Body
  fill(color(200, 80, 100));
  rect(px - 3, py - 4, 10, 12);
  // Head
  fill(color(220, 120, 140));
  rect(px - 2, py - 8, 8, 6);
  // Eyes (wide, prophetic)
  fill(color(255, 255, 255));
  rect(px - 1, py - 7, 2, 2);
  rect(px + 3, py - 7, 2, 2);
  // Aura rays
  noFill();
  stroke(color(255, 100, 120, 80));
  strokeWeight(1);
  line(px, py - 8, px - 6, py - 12);
  line(px, py - 8, px + 6, py - 12);
  line(px, py - 8, px, py - 14);
  noStroke();
  // Small floating hands
  fill(color(200, 80, 100));
  rect(px - 4, py - 2, 3, 2);
  rect(px + 4, py - 2, 3, 2);
}

function drawElderFarmerBody(px, py) {
  // Sturdy figure — soil brown
  noStroke();
  // Body (broad, sturdy)
  fill(color(120, 90, 60));
  rect(px - 5, py - 4, 14, 14);
  // Head
  fill(color(160, 130, 100));
  rect(px - 3, py - 9, 10, 7);
  // Hat brim
  fill(color(100, 80, 50));
  rect(px - 5, py - 9, 14, 2);
  // Hat top
  fill(color(110, 85, 55));
  rect(px - 3, py - 12, 8, 4);
  // Eyes (weathered)
  fill(color(40, 30, 20));
  rect(px - 1, py - 7, 2, 1);
  rect(px + 3, py - 7, 2, 1);
  // Arms (broad)
  fill(color(120, 90, 60));
  rect(px - 8, py - 2, 4, 10);
  rect(px + 6, py - 2, 4, 10);
  // Hands
  fill(color(140, 110, 80));
  rect(px - 7, py + 7, 3, 3);
  rect(px + 6, py + 7, 3, 3);
  // Legs (sturdy)
  fill(color(100, 80, 50));
  rect(px - 4, py + 10, 4, 8);
  rect(px + 1, py + 10, 4, 8);
  // Boots
  fill(color(60, 50, 35));
  rect(px - 5, py + 17, 6, 3);
  rect(px + 1, py + 17, 6, 3);
}

// --- Quest Overlay -----------------------------------------------------------

function drawQuestOverlay() {
  if (gameOver && quest.wakeEpilogue) {
    drawEpilogueScreen();
    return;
  }

  const stateColors = {
    signal:   color(42, 255, 181, 120),
    crossing: color(255, 160, 60, 140),
    contact:  color(100, 200, 255, 140),
    choice:   color(255, 200, 80, 160),
    wake:     color(200, 180, 255, 160),
    done:     color(255, 255, 200, 180)
  };

  const col = stateColors[quest.state] || color(232, 220, 198, 150);
  const stateLabel = {
    signal: 'SIGNAL',
    crossing: 'CROSSING',
    contact: 'CONTACT',
    choice: 'CHOICE',
    wake: 'WAKE',
    done: 'DONE'
  }[quest.state] || '—';

  noStroke();
  fill(color(26, 16, 46, 200));
  rect(620, 8, 170, 22, 4);
  fill(col);
  noStroke();
  rect(620, 8, 4, 22);
  fill(col);
  textAlign(LEFT, TOP);
  textSize(11);
  textFont('Press Start 2P');
  text(stateLabel, 630, 11);
  textSize(10);
  textFont('VT323');

  fill(color(232, 220, 198, 150));
  textAlign(LEFT, TOP);
  textSize(8);
  let progressText = '';
  if (quest.state === 'signal') {
    progressText = quest.hooksCompleted + '/3 hooks';
  } else if (quest.state === 'crossing') {
    progressText = quest.hazardsCompleted + '/4 hazards';
  } else if (quest.state === 'contact') {
    progressText = quest.npcsMet.length + '/4 NPCs';
  } else if (quest.state === 'choice') {
    if (quest.choiceMade) {
      progressText = 'Chose: ' + quest.choiceMade;
      if (quest.choicePath) {
        const pathLabel = quest.choicePaths.find(p => p.id === quest.choicePath);
        if (pathLabel) progressText += ' (' + pathLabel.label.split('/')[0].trim() + ')';
      }
    } else {
      progressText = 'Choose a path (talk to any contact)';
    }
  } else if (quest.state === 'wake') {
    progressText = 'Epilogue resolving…';
  } else if (quest.state === 'done') {
    progressText = quest.wakeEpilogue ? quest.wakeEpilogue.name : '—';
  }
  text(progressText, 630, 23);
  textSize(10);
  textFont('sans-serif');
}

function drawEpilogueScreen() {
  noStroke();
  fill(color(26, 16, 46, 230));
  rect(0, 0, width, height);

  fill(color(42, 255, 181, 220));
  textAlign(CENTER, CENTER);
  textSize(18);
  textFont('Press Start 2P');
  const ep = quest.wakeEpilogue;
  if (ep) {
    text(ep.name.toUpperCase(), width/2, height/2 - 40);
    fill(color(232, 220, 198, 200));
    textSize(14);
    textFont('VT323');
    textAlign(CENTER, CENTER);
    text(ep.text, width/2, height/2 + 20, width - 80, 100);
    fill(color(42, 255, 181, 120));
    textSize(10);
    textFont('Press Start 2P');
    text('[ R ] to begin again', width/2, height/2 + 80);
  }
  textSize(10);
  textFont('sans-serif');
}

// --- Solar Meter ------------------------------------------------------------

function drawSolarMeter() {
  const mx = 12;
  const my = 540;
  const mw = 120;
  const mh = 10;

  noStroke();
  fill(color(26, 16, 46, 200));
  rect(mx, my, mw, mh, 3);

  const fillW = (player.solarCharge / SOLAR_MAX_KWH) * (mw - 4);
  noStroke();
  fill(color(42, 255, 181, 180));
  rect(mx + 2, my + 2, fillW, mh - 4, 2);

  if (player.solarCharge > 1.5) {
    noStroke();
    fill(color(42, 255, 181, 40));
    rect(mx + 2, my + 2, fillW, mh - 4, 2);
  }

  fill(color(232, 220, 198, 160));
  noStroke();
  textAlign(LEFT, BOTTOM);
  textSize(8);
  textFont('VT323');
  text('SOLAR ' + player.solarCharge.toFixed(2) + 'kWh', mx, my - 2);
  textSize(10);
  textFont('sans-serif');

  // ── Fire bar (staff charges) ──
  const fx = 12, fy = 556, fw = 120, fh = 10;
  noStroke();
  fill(color(26, 16, 46, 200));
  rect(fx, fy, fw, fh, 3);
  const chargeFill = (player.staffCharges / 2) * (fw - 4);
  if (chargeFill > 0) {
    noStroke();
    fill(color(42, 255, 181, 180));
    rect(fx + 2, fy + 2, chargeFill, fh - 4, 2);
    if (player.staffCharges > 1) {
      noStroke();
      fill(color(42, 255, 181, 40));
      rect(fx + 2, fy + 2, chargeFill, fh - 4, 2);
    }
  }
  noStroke();
  fill(color(232, 220, 198, 160));
  textAlign(LEFT, BOTTOM);
  textSize(8);
  textFont('VT323');
  text('⚡ FIRE ' + player.staffCharges + '/2', fx, fy - 2);
  textSize(10);
  textFont('sans-serif');
}

// --- Day-Night Indicator (HUD corner) -------------------------------------

function drawDayNightIndicator() {
  if (gameState !== STATE.WORLD && gameState !== STATE.DIALOGUE && gameState !== STATE.SHOP && gameState !== STATE.COMBAT && gameState !== STATE.QUESTLOG) return;
  const cx = 12, cy = 510, r = 22;
  const phase = dayTime % 1.0;

  // Background circle
  noStroke();
  fill(color(26, 16, 46, 220));
  ellipse(cx, cy, r * 2);

  // Day arc (scioto fill for daylight portion)
  noFill();
  stroke(color(124, 200, 232, 120));
  strokeWeight(3);
  const startA = -HALF_PI;
  const endA = startA + phase * TWO_PI;
  if (phase <= 0.5) {
    arc(cx, cy, r * 2 - 4, r * 2 - 4, startA, endA);
  } else {
    // Night: overlay dark, then draw remaining day arc
    noStroke();
    fill(color(26, 16, 46, 220));
    ellipse(cx, cy, r * 2 - 4);
    stroke(color(124, 200, 232, 120));
    strokeWeight(3);
    arc(cx, cy, r * 2 - 4, r * 2 - 4, startA, endA);
  }

  // Sun / moon indicator at leading edge
  const indicatorAngle = endA;
  const ix = cx + cos(indicatorAngle) * (r - 5);
  const iy = cy + sin(indicatorAngle) * (r - 5);
  noStroke();
  if (phase < 0.5) {
    // Sun
    fill(color(124, 200, 232, 220));
    ellipse(ix, iy, 7, 7);
    fill(color(124, 200, 232, 60));
    ellipse(ix, iy, 12, 12);
  } else {
    // Moon
    fill(color(42, 255, 181, 200));
    ellipse(ix, iy, 6, 6);
    fill(color(42, 255, 181, 60));
    ellipse(ix, iy, 10, 10);
  }

  // Clock ring
  noFill();
  stroke(color(42, 255, 181, 70));
  strokeWeight(1);
  ellipse(cx, cy, r * 2, r * 2);

  // Time label
  noStroke();
  fill(color(232, 220, 198, 140));
  textAlign(CENTER, CENTER);
  textSize(7);
  textFont('VT323');
  const label = phase < 0.25 ? 'DAWN' : phase < 0.5 ? 'DAY' :
                phase < 0.75 ? 'DUSK' : 'NIGHT';
  text(label, cx, cy + r + 10);
  textSize(9);
  textFont('sans-serif');
}

// --- Interaction Hints -------------------------------------------------------

function drawInteractionHints() {
  const key = window.interactionKey;
  if (!key) return;

  const px = player.px + 8;
  const py = player.py - 16;

  const labels = {
    e:    'E — Talk',
    q:    'Q — Covenant Field',
    f:    'F — Board Ship',
    tab:  'Tab — Toggle Sky',
    l:    'L — Ledger',
    m:    'M — Repair Cafe'
  };

  const label = labels[key] || key.toUpperCase();
  const pulse = Math.sin(frameCount * 0.08) * 0.2 + 0.8;

  noStroke();
  fill(color(26, 16, 46, 180));
  rect(px - 30, py - 6, 60, 12, 3);

  fill(color(42, 255, 181, 200 * pulse));
  textAlign(CENTER, TOP);
  textSize(8);
  textFont('VT323');
  text(label, px, py - 4);
  textSize(10);
  textFont('sans-serif');
}

// --- Grass Wind ---------------------------------------------------------------
// Lightweight wind ripple across grass tiles, driven by day phase.
// Only animates on GROUND_GRASS so it never paints into solid/float/water.

let _grassWindPhase = 0;

function drawGrassWind() {
  const now = millis();
  _grassWindPhase += 0.006 * (isNight() ? 0.45 : 1.0);
  const wind = Math.sin(_grassWindPhase) * 2.2 + Math.sin(_grassWindPhase * 0.7) * 0.8;
  const tileSize = 16;
  // Set visible stroke before drawing lines
  stroke(color(80, 120, 60, 80));
  strokeWeight(1);
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      const t = groundLayer[y] && groundLayer[y][x];
      if (t !== TILE_TYPES.GROUND_GRASS) continue;
      const px = x * tileSize;
      const py = y * tileSize;
      const seed = (px * 3 + py * 7) % 5;
      const sway = Math.sin(_grassWindPhase + seed * 1.3 + x * 0.5) * wind * 0.5;
      const sway2 = Math.sin(_grassWindPhase * 0.5 + seed * 2.1 + y * 0.4) * wind * 0.3;
      fill(color(80, 120, 60, 40));
      line(px + 4 + sway2, py + tileSize, px + 4 + sway, py + tileSize - 4 - sway2);
      line(px + 8 + sway2, py + tileSize, px + 8 + sway, py + tileSize - 3 - sway2);
      if (seed === 1) {
        line(px + 6 + sway2, py + tileSize, px + 6 + sway, py + tileSize - 5 - sway2);
      } else if (seed === 2) {
        line(px + 2 + sway2, py + tileSize, px + 2 + sway, py + tileSize - 3 - sway2);
        line(px + 10 + sway2, py + tileSize, px + 10 + sway, py + tileSize - 4 - sway2);
      }
    }
  }
  noStroke();
}

// --- Clouds (daylight drifting) ----------------------------------------------
// Soft parallax cloud wisps drifting rightward, opacity tied to daylight.

function drawClouds() {
  if (isNight()) return;
  const now = millis();
  const drift = (now * 0.004) % (width + 200);
  const baseAlpha = 8 + (getSolarFactor() * 10);
  for (let i = 0; i < 4; i++) {
    const cx = ((i * 240 + drift) % (width + 200)) - 100;
    const cy = 40 + i * 55 + Math.sin(now * 0.0007 + i * 2) * 12;
    noStroke();
    fill(color(120, 160, 180, baseAlpha));
    ellipse(cx, cy, 90 + Math.sin(now * 0.0009 + i) * 14, 20 + Math.cos(now * 0.0006 + i * 1.3) * 4);
    fill(color(140, 180, 200, baseAlpha * 0.6));
    ellipse(cx + 20, cy - 4, 50 + Math.sin(now * 0.001 + i) * 8, 12);
  }
  noStroke();
}

// --- Stars (night only) -----------------------------------------------------
// Twinkling star field drawn only when isNight() is true.

function drawStars() {
  if (!isNight()) return;
  const now = millis();
  for (let i = 0; i < 48; i++) {
    const sx = (i * 97.3 + 20) % width;
    const sy = (i * 53.7 + 8) % (height * 0.6);
    const twinkle = Math.sin(now * 0.003 + i * 4.1) * 0.4 + 0.6;
    const a = 10 + Math.floor(40 * twinkle);
    noStroke();
    fill(color(220, 235, 255, a));
    ellipse(sx, sy, 1.4, 1.4);
    fill(color(200, 220, 255, a * 0.35));
    ellipse(sx, sy, 3.4, 3.4);
  }
  noStroke();
}

// --- Engine pulse (central-island resonator hum) ----------------------------
// Cyan low-frequency pulse near the ship tile; intensifies with quest state.

function drawEnginePulse() {
  const now = millis();
  const pulse = Math.sin(now * 0.002) * 0.18 + 0.82;
  const cx = 23 * 16 + 8;
  const cy = 10 * 16 + 8;
  const intensity = quest.state === 'choice' || quest.state === 'wake'
    ? 1.0 : (quest.state === 'contact' ? 0.55 : 0.35);
  const baseR = 22 + Math.sin(now * 0.004) * 3;
  noStroke();
  fill(color(42, 255, 181, 26 * pulse * intensity));
  ellipse(cx, cy, baseR * 2.4, baseR * 1.3);
  fill(color(124, 200, 232, 18 * pulse * intensity));
  ellipse(cx, cy, baseR * 1.8, baseR * 1.0);
  noFill();
  stroke(color(42, 255, 181, 90 * pulse * intensity));
  strokeWeight(1);
  ellipse(cx, cy, baseR * 1.2, baseR * 0.8);
  noStroke();
}

// --- Quest-state world reactions --------------------------------------------
// Maps quest progress to visible world changes: sky tint shift, hazard marks,
// engine glow intensification, NPC quest-ping emphasis.

function drawQuestWorldReactions() {
  const now = millis();
  if (quest.state === 'crossing') {
    // Show faint hazard lane markers on ground
    noStroke();
    fill(color(255, 160, 60, 22));
    for (const h of quest.crossingHazards) {
      if (h.done) continue;
      if (h.id === 'wind_shear') {
        const xs = [28, 29];
        for (const hx of xs) {
          ellipse(hx * 16 + 8, 6 * 16 + 8, 14, 4);
        }
      } else if (h.id === 'aether_leak') {
        const xs = [13, 14, 15];
        for (const hx of xs) {
          ellipse(hx * 16 + 8, 11 * 16 + 8, 10, 6);
        }
      } else if (h.id === 'sky_predator') {
        ellipse(20 * 16 + 8, 4 * 16 + 8, 16, 5);
      } else if (h.id === 'corporate_intercept') {
        const xs2 = [17, 18];
        for (const hx of xs2) {
          ellipse(hx * 16 + 8, 17 * 16 + 8, 12, 5);
        }
      }
    }
  }
  if (quest.state === 'choice' || quest.state === 'wake') {
    // Engine glow intensifies
    const pulse = Math.sin(now * 0.004) * 0.2 + 0.8;
    const cx = 23 * 16 + 8;
    const cy = 10 * 16 + 8;
    noStroke();
    fill(color(42, 255, 181, 40 * pulse));
    ellipse(cx, cy, 48, 28);
    fill(color(124, 200, 232, 22 * pulse));
    ellipse(cx, cy, 64, 36);
    noStroke();
  }
  // NPC quest markers pulse faster as contact progresses
  const npcCount = quest.npcsMet.length;
  const pulseSpeed = 0.05 + npcCount * 0.012;
  for (const npc of npcs) {
    if (npc.flags.questMarker) {
      const px = npc.tileX * 16 + 8;
      const py = npc.tileY * 16 + 8;
      const p = Math.sin(now * pulseSpeed + npc.tileX) * 0.3 + 0.7;
      noFill();
      stroke(color(42, 255, 181, 110 * p));
      strokeWeight(1);
      ellipse(px, py - 10, 10, 5);
      noStroke();
    }
  }
}

// --- Aether Sense visualization ---------------------------------------------

function drawAetherSenseOverlay() {
  if (!aetherSenseState.active || !aetherSenseState.lastScan) return;

  const scan = aetherSenseState.lastScan;
  const pulse = Math.sin(millis() * 0.012) * 0.25 + 0.75;

  for (const detection of scan.detections) {
    const cx = detection.x * 16 + 8;
    const cy = detection.y * 16 + 8;
    const baseSize = detection.intensity === 'strong' ? 28 :
      detection.intensity === 'unstable' ? 24 :
      detection.intensity === 'moderate' ? 20 : 16;

    noFill();
    stroke(color(124, 200, 232, 150 * pulse));
    strokeWeight(detection.intensity === 'strong' ? 2 : 1);
    ellipse(cx, cy, baseSize + (1 - pulse) * 10, baseSize * 0.55 + (1 - pulse) * 5);
    noStroke();

    fill(color(42, 255, 181, 190 * pulse));
    ellipse(cx, cy, 4, 4);
  }

  noStroke();
  fill(color(26, 16, 46, 210));
  rect(154, 538, 250, 30, 4);
  fill(color(124, 200, 232, 220));
  textAlign(LEFT, TOP);
  textSize(9);
  textFont('Press Start 2P');
  text('AETHER SENSE', 164, 544);
  fill(color(232, 220, 198, 180));
  textSize(9);
  textFont('VT323');
  text(scan.detections.length + ' explicit signature' +
    (scan.detections.length === 1 ? '' : 's') + ' detected', 164, 557);
  textSize(10);
  textFont('sans-serif');
}

// --- Player visual evolution ------------------------------------------------
// Adds heat aura (orange shimmer at high heat), ability-use glow, and solar
// charge shimmer. Keeps the existing player sprite intact.

function drawPlayerVisualEvolution() {
  const now = millis();
  const px = player.px;
  const py = player.py;

  if (player.heat > 1) {
    const heatRatio = player.heat / player.heatMax;
    if (heatRatio > 0.35) {
      const shimmer = Math.sin(now * 0.01) * 0.4 + 0.6;
      const alpha = 20 * heatRatio * shimmer;
      noStroke();
      fill(color(255, 140, 40, alpha));
      ellipse(px + 8, py + 7, 18 + heatRatio * 10, 10 + heatRatio * 6);
      fill(color(255, 180, 60, alpha * 0.5));
      ellipse(px + 8, py + 7, 26 + heatRatio * 12, 14 + heatRatio * 8);
      noStroke();
    }
  }

  if (player.solarCharge > 1.2) {
    const shimmer = Math.sin(now * 0.006) * 0.25 + 0.75;
    noStroke();
    fill(color(42, 255, 181, 22 * shimmer));
    ellipse(px + 8, py + 5, 14, 6);
    noStroke();
  }
}

// --- NPC daily routines ------------------------------------------------------
// Each NPC has a small idle animation / drift loop.
// Ionia: rests forearms on bulkhead, occasional glance toward the lower cargo hatch.
// The Core: aether glow breathes, rotation drifts slowly.
// Lyra: plays with a small dream-fragment orb that orbits her head.
// Verrick: shifts weight between deck and bulkhead, posture change.

const NPC_ROUTINES = {
  ionia: {
    bob: 0.4,            // vertical bob amplitude (px)
    bobSpeed: 0.004,     // phase speed
    glanceIdx: 0,        // cycle index for look-direction
  },
  engine_spirit: {
    glowPulse: 0.006,    // glow breathing speed
    rotSpeed: 0.002,     // rotation drift
  },
  lyra: {
    orbRadius: 7,        // orbit radius around head
    orbSpeed: 0.005,     // orbit phase speed
  },
  corporate_salvager: {
    shiftPhase: 0.003,   // posture shift cycle
    shiftRange: 1.5,     // px shift range
  },
};

function updateNPCSchedulers(dt) {
  // Nothing stateful required — routines are driven from millis()/frameCount
  // at draw time. This hook exists so the renderer can stay declarative.
}

function drawNPCIoniaRoutine(px, py) {
  const r = NPC_ROUTINES.ionia;
  const bob = Math.sin(millis() * r.bobSpeed) * r.bob;
  const glance = Math.floor((millis() * 0.0004) % 3) - 1;
  noStroke();
  fill(color(42, 255, 181, 130));
  rect(px + 8 + glance, py + 1 + bob, 2, 2);
}

function drawNPCSpiritRoutine(px, py) {
  const r = NPC_ROUTINES.engine_spirit;
  const glow = Math.sin(millis() * r.glowPulse) * 0.25 + 0.75;
  fill(color(120, 200, 220, 140 * glow));
  noStroke();
  ellipse(px, py, 14, 16);
  noStroke();
  fill(color(42, 255, 181, 180 * glow));
  ellipse(px, py - 2, 6, 6);
  noFill();
  stroke(color(42, 255, 181, 120 * glow));
  strokeWeight(1);
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * Math.PI * 2 + frameCount * r.rotSpeed;
    line(px, py, px + Math.cos(a) * 12, py + Math.sin(a) * 12);
  }
  noStroke();
  fill(color(200, 230, 240, 150 * glow));
  rect(px - 3, py - 2, 10, 4);
  fill(color(40, 60, 80, 150 * glow));
  rect(px - 1, py - 1, 2, 1);
  rect(px + 4, py - 1, 2, 1);
  noStroke();
}

function drawNPCLyraRoutine(px, py) {
  const r = NPC_ROUTINES.lyra;
  const phase = millis() * r.orbSpeed;
  const orbX = px + 3 + Math.cos(phase) * r.orbRadius;
  const orbY = py - 5 + Math.sin(phase) * r.orbRadius * 0.6;
  noStroke();
  fill(color(42, 255, 181, 170));
  ellipse(orbX, orbY, 3, 3);
  fill(color(124, 200, 232, 80));
  ellipse(orbX, orbY, 6, 6);
}

function drawNPCSavagerRoutine(px, py) {
  const r = NPC_ROUTINES.corporate_salvager;
  const shift = Math.sin(millis() * r.shiftPhase) * r.shiftRange;
  noStroke();
  fill(color(100, 100, 105));
  rect(px - 4 + shift * 0.3, py - 3, 16, 10);
  fill(color(80, 80, 85));
  rect(px - 3 + shift * 0.3, py - 3, 14, 3);
  fill(color(180, 170, 160));
  rect(px - 3 + shift * 0.2, py - 8, 12, 6);
  fill(color(30, 30, 35));
  rect(px + shift * 0.1, py - 7, 2, 1);
  rect(px + 6 + shift * 0.1, py - 7, 2, 1);
  fill(color(42, 255, 181, 160));
  rect(px + 8, py - 4, 4, 3);
  fill(color(10, 10, 10));
  rect(px + 9, py - 3, 2, 1);
  fill(color(60, 60, 65));
  rect(px - 3, py + 6, 5, 5);
  rect(px + 2, py + 6, 5, 5);
  fill(color(100, 100, 105));
  rect(px + 11, py, 3, 7);
  noStroke();
}

// ---------------------------------------------------------------------------
// Exported surface
// ---------------------------------------------------------------------------
const AetherWorld = function(p, C) {
  return World;
};

if (typeof window !== 'undefined') {
  window.AetherWorld = AetherWorld;
}


// === modules/combat.js ===
// AetherCombat — Turn-based JRPG combat during formula/legacy migration.
// Exposes window.AetherCombat as a constructor: new AetherCombat(p, C)
// Also compatible with direct call: AetherCombat(p, C) returns the namespace.

function AetherCombat(p, C) {
  'use strict';
  const self = this;
  const state = {
    player: {
      name: 'Ender',
      age: 22,
      class: 'Rift Scholar',
      vit: 13, maxVit: 13,
      echoes: { current: 3, max: 3 }, maxEchoes: 3,
      wits: 2, presence: 1, spirit: 1, might: -1,
      grace: 0,
      scrap: 7,
      aether: { current: 4, max: 6 },
      heat: { current: 1, max: 3 },
      charge: 2.0,
      staffCharges: 2, maxStaffCharges: 2,
      level: 1, xp: 0, xpToNext: 50,
      unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
      equipment: { staff: null, backpack: null },
    },
    enemy: null,
    turn: 0,
    log: [],
    encounterOver: false,
    initiative: 0,
    partyContext: null,
    airship: {
      shipId: null,
      classId: null,
      shieldMode: null,
      phaseSlipReady: false,
      slipVeilReady: false,
      guardAbsorption: 0,
      firstRollBonus: 0,
      openingLanceDamage: 0,
    },
    _airshipTransferApplied: false,
  };

  if (!window.AetherAbilityDefs ||
      typeof window.AetherAbilityDefs.createRuntimeActions !== 'function' ||
      typeof window.AetherAbilityDefs.assertRuntimeActions !== 'function') {
    throw new Error('AETHER_ABILITY_DEFS_UNAVAILABLE');
  }
  const actions = window.AetherAbilityDefs.createRuntimeActions();
  window.AetherAbilityDefs.assertRuntimeActions(actions);

  if (!window.AetherEffectVocabulary ||
      typeof window.AetherEffectVocabulary.assertActionCoverage !== 'function') {
    throw new Error('AETHER_EFFECT_VOCABULARY_UNAVAILABLE');
  }
  window.AetherEffectVocabulary.assertActionCoverage(actions);

  if (!window.AetherProgressionDefs ||
      typeof window.AetherProgressionDefs.validateAgainstAbilityDefs !== 'function') {
    throw new Error('AETHER_PROGRESSION_DEFS_UNAVAILABLE');
  }
  window.AetherProgressionDefs.validateAgainstAbilityDefs(window.AetherAbilityDefs);

  if (!window.AetherEffectResolver ||
      typeof window.AetherEffectResolver.applyEffect !== 'function') {
    throw new Error('AETHER_EFFECT_RESOLVER_UNAVAILABLE');
  }

  if (!window.AetherCombatFormula ||
      typeof window.AetherCombatFormula.resolveAction !== 'function' ||
      typeof window.AetherCombatFormula.validateAgainstAbilityDefs !== 'function') {
    throw new Error('AETHER_COMBAT_FORMULA_UNAVAILABLE');
  }
  window.AetherCombatFormula.validateAgainstAbilityDefs(window.AetherAbilityDefs);

  const effectVocabulary = window.AetherEffectVocabulary;
  const effectResolver = window.AetherEffectResolver;
  const combatFormula = window.AetherCombatFormula;
  let resolverMutationCount = 0;

  function resolverContext() {
    return {
      player: state.player,
      enemy: state.enemy,
      staffChargeMax: state.maxStaffCharges,
    };
  }

  function recordResolverMutation(result) {
    if (result && result.applied) resolverMutationCount++;
    return result;
  }

  function applyDamage(target, amount, key) {
    return recordResolverMutation(effectResolver.applyEffect(
      effectResolver.createDamageEffect(target, amount, key),
      resolverContext()
    ));
  }

  function applyRestore(target, amount, key) {
    return recordResolverMutation(effectResolver.applyEffect(
      effectResolver.createRestoreEffect(target, amount, key),
      resolverContext()
    ));
  }

  function changeResource(resource, delta) {
    return recordResolverMutation(effectResolver.applyEffect(
      effectResolver.createResourceDeltaEffect(resource, delta),
      resolverContext()
    ));
  }

  function createNoAirshipModifiers() {
    return {
      shipId: null,
      classId: null,
      shieldMode: null,
      phaseSlipReady: false,
      slipVeilReady: false,
      guardAbsorption: 0,
      firstRollBonus: 0,
      openingLanceDamage: 0,
    };
  }

  function configureAirshipModifiers(transfer) {
    if (!transfer || !transfer.classId) return createNoAirshipModifiers();
    const bridge = window.AetherAirshipCombatBridge;
    if (bridge && typeof bridge.createCombatModifiers === 'function') {
      return bridge.createCombatModifiers(transfer);
    }
    return createNoAirshipModifiers();
  }

  function applyAirshipOpening() {
    const airship = state.airship;
    if (!airship || !airship.classId || !state.enemy) return;

    if (airship.openingLanceDamage > 0 && state.enemy.hp > 0) {
      const openingDamage = Math.min(airship.openingLanceDamage, state.enemy.hp - 1);
      if (openingDamage > 0) {
        applyDamage(effectVocabulary.TARGET.ENEMY, openingDamage, 'resonanceLance');
        state._airshipOpeningDamage = openingDamage;
        log('[Airship] Resonance Lance opens the encounter — ' + openingDamage + ' damage.');
      }
      airship.openingLanceDamage = 0;
    }

    if (airship.phaseSlipReady) {
      log('[Airship] Phase-Slip repositioned the Wake; the first damaging strike will miss.');
    } else if (airship.slipVeilReady) {
      log('[Airship] Slip veil is open; the first damaging strike will miss.');
    } else if (airship.guardAbsorption > 0) {
      log('[Airship] Guard veil is braced; it will absorb 1 incoming damage.');
    } else if (airship.firstRollBonus > 0) {
      log('[Airship] Resonance veil sharpened the first crew roll by +1.');
    }
  }

  function airshipIncomingDamage(amount) {
    const requested = Math.max(0, Math.floor(Number(amount) || 0));
    if (!state.airship || !state.airship.classId) {
      applyDamage(effectVocabulary.TARGET.SELF, requested);
      return { requested, damage: requested, event: null };
    }

    const bridge = window.AetherAirshipCombatBridge;
    const mitigation = bridge &&
      typeof bridge.mitigateIncomingDamage === 'function'
      ? bridge.mitigateIncomingDamage(state.airship, requested)
      : { modifiers: state.airship, requested, damage: requested, event: null };

    state.airship = mitigation.modifiers;
    if (mitigation.event === 'phaseSlip') {
      log('[Airship] Phase-Slip caught the incoming strike — no damage.');
    } else if (mitigation.event === 'slip') {
      log('[Airship] Slip veil caught the incoming strike — no damage.');
    } else if (mitigation.event === 'guard') {
      log('[Airship] Guard veil absorbed 1 incoming damage.');
    }

    applyDamage(effectVocabulary.TARGET.SELF, mitigation.damage, 'airshipEnemy');
    return mitigation;
  }

  const enemies = {
    skyPredator: {
      name: 'Sky-Predator',
      goal: 'Kill or drive off the predator hunting heat signatures above the Wake.',
      hp: 12, maxHp: 12, might: 1, presence: 0, grace: 0, wits: 0,
      weakness: 'Its brass wing-joints shudder in EMP.',
      status: 'roosting',
      type: 'skyPredator',
      ability: 'diveBomb',
      abilityDesc: 'Dive Bomb — 2 damage, ignores dodge',
      color: 'rust',
      bodyShape: 'predator',
    },
    corporateSalvager: {
      name: 'Corporate Salvager',
      goal: 'Secure the Wake\'s core for the syndicate.',
      hp: 10, maxHp: 10, might: 0, presence: 2, grace: 1, wits: 1,
      weakness: 'Class-locked dialogue — the commons outlasts the contract.',
      status: 'negotiating',
      type: 'corporateSalvager',
      ability: 'contractClause',
      abilityDesc: 'Contract Clause — you lose 1 scrap',
      color: 'soil',
      bodyShape: 'humanoid',
    },
    windShear: {
      name: 'Harmonic Shear Elemental',
      goal: 'Tear the ship apart — harmonic shear strips grace from all who stand here.',
      hp: 14, maxHp: 14, might: 2, presence: 0, grace: 0, wits: 1,
      weakness: 'Uncover Truth reveals the wind pattern — exposing it to EMP.',
      status: 'howling',
      type: 'windShear',
      ability: 'galeForce',
      abilityDesc: 'Gale Force — 2 damage, knocks you back',
      color: 'scioto',
      bodyShape: 'elemental',
    },
    aetherLeak: {
      name: 'Aether Leak Wraith',
      goal: 'Pool the aether, distort the local weave — and feed.',
      hp: 8, maxHp: 8, might: 0, presence: 1, grace: 2, wits: 1,
      weakness: 'Shared Dream seals the leak — starve the wraith of aether.',
      status: 'draining',
      type: 'aetherLeak',
      ability: 'drain',
      abilityDesc: 'Drain — removes 1 aether from you',
      color: 'teal',
      bodyShape: 'wraith',
    },
    engine_spirit: {
      name: 'Engine Spirit',
      goal: 'Dissipate the aether — the core sings itself hollow.',
      hp: 10, maxHp: 10, might: 0, presence: 2, grace: 0, wits: 1,
      weakness: 'Harmonic Pulse backlashes — the spirit feeds on its own resonance.',
      status: 'pulsing',
      type: 'engine_spirit',
      ability: 'harmonic_pulse',
      abilityDesc: 'Harmonic Pulse — 2D6+Presence, drains 1 aether on 7-9+',
      color: 'biolum',
      bodyShape: 'core',
    },
    child_prophet: {
      name: 'Child Prophet',
      goal: 'Sing the wrong note — unravel the crew\'s confidence one prophecy at a time.',
      hp: 8, maxHp: 8, might: -1, presence: 0, grace: 2, wits: 1,
      weakness: 'Prophecy Voice overreaches — the child hears too much and falters.',
      status: 'chanting',
      type: 'child_prophet',
      ability: 'prophecy_voice',
      abilityDesc: 'Prophecy Voice — 2D6+Grace, on 10+ target loses 1 turn confidence',
      color: 'rose',
      bodyShape: 'prophet',
    },
    elder_farmer: {
      name: 'Elder Farmer',
      goal: 'Hold the ground — the soil remembers every sky-lane that never landed.',
      hp: 16, maxHp: 16, might: 2, presence: 1, grace: 0, wits: 0,
      weakness: 'Soil Anchor roots too deep — the earth tires of holding.',
      status: 'anchored',
      type: 'elder_farmer',
      ability: 'soil_anchor',
      abilityDesc: 'Soil Anchor — 2D6+Might, on 10+ root enemy in place for 1 turn',
      color: 'soil',
      bodyShape: 'farmer',
    },
  };

  // ── Enemy ability lookup (for display / UI) ──
  const ENEMY_ABILITIES = {
    diveBomb: { name: 'Dive Bomb', desc: '2 damage, ignores dodge' },
    contractClause: { name: 'Contract Clause', desc: 'Lose 1 scrap' },
    galeForce: { name: 'Gale Force', desc: '2 damage, knockback' },
    drain: { name: 'Drain', desc: 'Removes 1 aether' },
    harmonicPulse: { name: 'Harmonic Pulse', desc: 'Drains 1 aether on 7-9+' },
    prophecyVoice: { name: 'Prophecy Voice', desc: 'Lowers enemy confidence' },
    soilAnchor: { name: 'Soil Anchor', desc: 'Roots enemy in place' },
  };

  // ── Helpers ──
  function roll2d6() {
    return floor(random(1, 7)) + floor(random(1, 7));
  }

  function roll2d6Plus(stat) {
    const dice = roll2d6();
    const total = dice + stat;
    let outcome;
    if (total >= 10) outcome = 'success';
    else if (total >= 7) outcome = 'partial';
    else outcome = 'failure';
    return { dice, stat, total, outcome };
  }

  function log(msg) {
    state.log.push(msg);
    if (state.log.length > 20) state.log.shift();
  }

  function normalizeResource(value, maxValue, fallbackCurrent, fallbackMax) {
    const objectValue = value && typeof value === 'object' ? value : null;
    const rawMax = objectValue ? objectValue.max : maxValue;
    const rawCurrent = objectValue ? objectValue.current : value;
    const max = Math.max(0, Number.isFinite(Number(rawMax))
      ? Number(rawMax)
      : fallbackMax);
    const current = Math.max(0, Math.min(max,
      Number.isFinite(Number(rawCurrent)) ? Number(rawCurrent) : fallbackCurrent));
    return { current, max };
  }

  // ── Public API ──
  this.init = function(options) {
    options = options || {};
    if (options.seed !== undefined) {
      if (randomSeed) randomSeed(options.seed);
    } else {
      const seed = floor(random(99999));
      if (randomSeed) randomSeed(seed);
    }
    const maxVit = Math.max(1, Number(options.maxVit ?? 13));
    state.player.name = options.name ?? 'Ender';
    state.player.age = options.age ?? 22;
    state.player.class = options.class ?? 'Rift Scholar';
    state.player.vit = Math.max(1, Math.min(maxVit, Number(options.vit ?? maxVit)));
    state.player.maxVit = maxVit;
    state.player.wits = Number(options.wits ?? 2);
    state.player.presence = Number(options.presence ?? 1);
    state.player.spirit = Number(options.spirit ?? 1);
    state.player.might = Number(options.might ?? -1);
    state.player.grace = Number(options.grace ?? 0);
    state.player.scrap = Math.max(0, Number(options.scrap ?? 7));
    state.player.aether = normalizeResource(options.aether, options.aetherMax, 4, 6);
    state.player.heat = normalizeResource(options.heat, options.heatMax, 1, 3);
    state.player.echoes = normalizeResource(options.echoes, options.echoesMax, 3, 3);
    state.player.maxEchoes = state.player.echoes.max;
    state.maxStaffCharges = Math.max(0, Number(options.staffMax ?? options.maxStaffCharges ?? 2));
    state.player.maxStaffCharges = state.maxStaffCharges;
    state.player.staffCharges = Math.max(0, Math.min(
      state.maxStaffCharges,
      Number(options.charges ?? options.staffCharges ?? state.maxStaffCharges)
    ));
    state.player.level = Math.max(1, Number(options.level ?? 1));
    state.player.xp = Math.max(0, Number(options.xp ?? 0));
    state.player.xpToNext = Math.max(1, Number(options.xpToNext ?? 50));
    state.player.unlockedAbilities = Array.isArray(options.unlockedAbilities)
      ? options.unlockedAbilities.slice()
      : ['uncoverTruth', 'sharedDream', 'mycelialLedger'];
    state.player.equipment = options.equipment
      ? JSON.parse(JSON.stringify(options.equipment))
      : { staff: null, backpack: null };

    if (options.partyContext != null) {
      if (!window.AetherPartyCombatBridge ||
          typeof window.AetherPartyCombatBridge.validateSnapshot !== 'function') {
        throw new Error('AETHER_PARTY_COMBAT_BRIDGE_UNAVAILABLE_IN_COMBAT');
      }
      window.AetherPartyCombatBridge.validateSnapshot(options.partyContext);
      state.partyContext = JSON.parse(JSON.stringify(options.partyContext));
    } else {
      state.partyContext = null;
    }

    state.turn = 0;
    state.log = [];
    state.enemy = null;
    state.encounterOver = false;
    state._secondaryAvailable = false;
    state._lastAbilityId = null;
    state.airship = configureAirshipModifiers(options.airshipTransfer || null);
    state._airshipTransferApplied = false;
    state._airshipOpeningDamage = 0;
    state._totalDamageDealt = 0;
    state._victoryStats = null;
    state._lastDamageNum = null;
    state._critFlashTurn = 0;
    state._playerHitTurn = 0;
    state._dodgeTurn = 0;
    state._defeatTurn = 0;
    state._enemyAbilityFlash = 0;
    state._lastTurnCrit = false;
    resolverMutationCount = 0;
    log('Combat initialized. The weave awaits.');
  };

  this.getAether = function() { return state.player.aether; };
  this.getCharges = function() { return { current: state.player.staffCharges, max: state.maxStaffCharges }; };
  this.getEchoes = function() { return state.player.echoes; };
  this.getScrap = function() { return state.player.scrap; };

  this.getLevel = function() { return state.player.level; };
  this.getXP = function() { return { current: state.player.xp, toNext: state.player.xpToNext }; };

  this.levelUp = function() {
    const p = state.player;
    let leveled = false;
    while (p.xp >= p.xpToNext) {
      p.xp -= p.xpToNext;
      p.level++;
      p.xpToNext = Math.floor(50 * Math.pow(1.5, p.level - 1));
      p.echoes.max = Math.min(6, p.echoes.max + 1);
      p.maxEchoes = p.echoes.max;
      const levelUnlocks = window.AetherProgressionDefs.getUnlocksForLevel(p.level);
      levelUnlocks.forEach(unlock => {
        if (!p.unlockedAbilities.includes(unlock.abilityId)) {
          p.unlockedAbilities.push(unlock.abilityId);
          log(unlock.log);
        }
      });
      leveled = true;
    }
    if (leveled) {
      log('── LEVEL UP! You are now level ' + p.level + '. ──');
    }
    return leveled;
  };

  this.awardXP = function(amount) {
    const p = state.player;
    p.xp += amount;
    log('+' + amount + ' XP');
    this.levelUp();
  };

  this.canBeginEncounter = function(enemyId) {
    return Boolean(enemies[enemyId]);
  };

  this.beginEncounter = function(enemyId) {
    const template = enemies[enemyId];
    if (!template) {
      return { ok: false, reason: 'Unknown enemy: ' + enemyId };
    }
    // Reset transient fields for this encounter
    state.log = [];
    state._airshipTransferApplied = false;
    state._airshipOpeningDamage = 0;
    state._totalDamageDealt = 0;
    state._victoryStats = null;
    state._lastDamageNum = null;
    state._critFlashTurn = 0;
    state._playerHitTurn = 0;
    state._dodgeTurn = 0;
    state._defeatTurn = 0;
    state._enemyAbilityFlash = 0;
    state._lastTurnCrit = false;
    state._secondaryAvailable = false;
    state._lastAbilityId = null;
    state.enemy = {
      name: template.name,
      goal: template.goal,
      hp: template.hp,
      maxHp: template.maxHp,
      might: template.might,
      presence: template.presence,
      grace: template.grace,
      wits: template.wits,
      weakness: template.weakness,
      status: template.status,
      type: template.type || enemyId,
      ability: template.ability || null,
      abilities: template.ability ? [template.ability] : [],
      abilityDesc: template.abilityDesc || null,
      color: template.color || null,
      bodyShape: template.bodyShape || null,
    };
    state.turn = 0;
    state.encounterOver = false;
    state.initiative = state.player.wits + (state.player.grace || 0);
    log('Encounter: ' + state.enemy.name + ' — ' + state.enemy.goal);
    log(state.enemy.name + ' weakness: ' + state.enemy.weakness);
    if (!state._airshipTransferApplied) {
      applyAirshipOpening();
      state._airshipTransferApplied = true;
    }
    return { ok: true };
  };

  this.resolveTurn = function(actionId, resources) {
    if (!state.enemy || state.enemy.hp <= 0) {
      log('No active enemy.');
      return;
    }
    const action = actions.find(a => a.id === actionId);
    if (!action) {
      log('Unknown action: ' + actionId);
      return false;
    }
    const useEligibility = window.AetherAbilityDefs.getUseEligibility(
      state.player,
      action.id
    );
    if (!useEligibility.canUse) {
      if (useEligibility.reason === 'locked') {
        log('Locked action: ' + action.label);
      } else if (useEligibility.reason === 'insufficient_resources') {
        log(
          'Not enough resources — ' + action.label +
          ' needs ' + useEligibility.resourceCost +
          ', but only ' + useEligibility.availableResource + ' is available.'
        );
      } else if (useEligibility.reason === 'insufficient_dedicated_resource') {
        log('No Resonator Staff charges remain — Hold to recharge before striking.');
      } else {
        log('Action unavailable: ' + action.label + ' (' + useEligibility.reason + ').');
      }
      return false;
    }

    // A new admitted primary action invalidates any previous secondary window.
    // A fresh window may be opened below only by this action's own success.
    state._secondaryAvailable = false;
    state.turn++;

    // Track last ability for secondary action
    if (action.type === 'ability') {
      state._lastAbilityId = action.id;
    } else {
      state._lastAbilityId = null;
    }

    // Resource payment uses the same legacy tier + base-cost formula exposed by
    // AetherAbilityDefs. Affordability was preflighted above, so this payment
    // is transactional with respect to action admission.
    const resourceCost = useEligibility.resourceCost;
    if (resourceCost > 0) {
      let spent = 0;
      while (spent < resourceCost) {
        if (state.player.echoes.current > 0) {
          changeResource(effectVocabulary.RESOURCE.ECHOES, -1);
          log('Echo spent.');
          spent++;
        } else if (state.player.aether.current > 0) {
          changeResource(effectVocabulary.RESOURCE.AETHER, -1);
          log('Aether spent.');
          spent++;
        } else {
          throw new Error('ACTION_RESOURCE_PREFLIGHT_DRIFT:' + action.id);
        }
      }
    }

    // Heat generation: most actions add heat
    if (action.type !== 'hold' && action.type !== 'rest') {
      changeResource(effectVocabulary.RESOURCE.HEAT, 1);
    }

    // Resolution migration boundary.
    // Staff Strike, Hold, and Rest use production JRPG formulas. The remaining
    // five actions stay on the legacy 2D6 compatibility path until migrated.
    let actionText = '';
    let enemyDmg = 0;
    let playerDmg = 0;
    let heal = 0;
    let resourceGain = '';
    let nextRollBonus = 0;
    let r = null;
    let formulaResolution = null;
    let attackCritical = false;

    if (action.resolution && action.resolution.model === 'jrpg-stat-formula') {
      formulaResolution = combatFormula.resolveAction(
        action.id,
        state.player,
        state.enemy,
        function() { return random(1); }
      );

      if (formulaResolution.kind === 'damage') {
        if (formulaResolution.hit && formulaResolution.damage > 0) {
          enemyDmg = formulaResolution.damage;
          applyDamage(
            effectVocabulary.TARGET.ENEMY,
            enemyDmg,
            formulaResolution.damageType
          );
        }

        if (!formulaResolution.dedicatedCost ||
            formulaResolution.dedicatedCost.resource !== 'staffCharges') {
          throw new Error('STAFF_STRIKE_DEDICATED_COST_DRIFT');
        }
        changeResource(
          effectVocabulary.RESOURCE.STAFF_CHARGES,
          -formulaResolution.dedicatedCost.amount
        );

        attackCritical = Boolean(formulaResolution.critical);
        if (formulaResolution.hit) {
          actionText = action.label + ' — ' + enemyDmg + ' EMP damage' +
            (attackCritical ? ' — CRITICAL!' : '') + '.';
        } else {
          actionText = action.label + ' — attack missed.';
        }
      } else if (formulaResolution.kind === 'resource') {
        if (formulaResolution.resource !== effectVocabulary.RESOURCE.STAFF_CHARGES) {
          throw new Error('FORMULA_RESOURCE_KIND_UNSUPPORTED:' + formulaResolution.resource);
        }
        if (formulaResolution.delta > 0) {
          changeResource(
            effectVocabulary.RESOURCE.STAFF_CHARGES,
            formulaResolution.delta
          );
          actionText = 'Hold — Resonator recharges. +' +
            formulaResolution.delta + ' charge' +
            (formulaResolution.delta === 1 ? '.' : 's.');
        } else {
          actionText = 'Hold — Resonator already at full charge.';
        }
      } else if (formulaResolution.kind === 'recovery') {
        if (formulaResolution.heatReduction > 0) {
          changeResource(
            effectVocabulary.RESOURCE.HEAT,
            -formulaResolution.heatReduction
          );
        }
        heal = formulaResolution.vitalityRestore;
        if (heal > 0) {
          applyRestore(effectVocabulary.TARGET.SELF, heal);
        }

        const recoveryParts = [];
        if (formulaResolution.heatReduction > 0) {
          recoveryParts.push('-' + formulaResolution.heatReduction + ' Heat');
        }
        if (heal > 0) {
          recoveryParts.push('+' + heal + ' Vit');
        }
        actionText = recoveryParts.length
          ? 'Rest — ' + recoveryParts.join(', ') + '.'
          : 'Rest — already fully recovered.';
      } else {
        throw new Error('FORMULA_RESULT_KIND_UNSUPPORTED:' + formulaResolution.kind);
      }
    } else {
      const airshipRollBonus = state.airship && state.airship.firstRollBonus
        ? state.airship.firstRollBonus
        : 0;
      if (airshipRollBonus > 0) {
        state.airship.firstRollBonus = 0;
        log('[Airship] Resonance veil adds +' + airshipRollBonus + ' to this legacy roll.');
      }
      const statBonus = (action.stat ? state.player[action.stat] || 0 : 0) + airshipRollBonus;
      r = roll2d6Plus(statBonus);

        if (r.outcome === 'success') {
          if (action.type === 'ability') {
            // Secondary action is offered only if the just-used ability remains
            // usable after primary-action costs have been paid.
            const secondaryEligibility = window.AetherAbilityDefs.getUseEligibility(
              state.player,
              action.id
            );
            if (secondaryEligibility.canUse) {
              state._secondaryAvailable = true;
              log(
                'Press S for secondary action — repeat the last ability at its normal resource cost' +
                (secondaryEligibility.resourceCost > 0
                  ? ' (' + secondaryEligibility.resourceCost + ').'
                  : ' (free).')
              );
            }
          }
          if (action.type === 'attack') {
            if (state.player.staffCharges <= 0) {
              actionText = 'Staff Strike — no charges left. The weapon falls silent. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            } else {
              enemyDmg = floor(random(1, 7)) + 2; // 1d6+2
              applyDamage(effectVocabulary.TARGET.ENEMY, enemyDmg, 'emp');
              changeResource(effectVocabulary.RESOURCE.STAFF_CHARGES, -1);
              actionText = action.label + ' — ' + enemyDmg + ' EMP damage. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
            }
          } else if (action.type === 'ability') {
            // Visual: ability flash for all abilities
            state._abilityFlashTurn = millis();
            if (action.id === 'uncoverTruth') {
              nextRollBonus = 1;
              actionText = 'Uncover Truth — the weave reveals its pattern. +1 to next roll. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            } else if (action.id === 'sharedDream') {
              // 50/50: heal 1-2 Vit OR +1 next roll bonus
              if (random(0, 2) < 1) {
                heal = floor(random(1, 3));
                applyRestore(effectVocabulary.TARGET.SELF, heal);
                actionText = 'Shared Dream — ' + heal + ' Vit restored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              } else {
                nextRollBonus = 1;
                actionText = 'Shared Dream — ally\'s next action gets +1. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              }
            } else if (action.id === 'mycelialLedger') {
              const gain = floor(random(1, 3));
              if (floor(random(2)) === 0) {
                changeResource(effectVocabulary.RESOURCE.AETHER, gain);
                actionText = 'Mycelial Ledger — +' + gain + ' Aether stored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              } else {
                changeResource(effectVocabulary.RESOURCE.SCRAP, gain);
                actionText = 'Mycelial Ledger — +' + gain + ' Scrap recorded. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              }
            }
          } else if (action.type === 'defense') {
            if (action.id === 'windWard') {
              if (r.outcome === 'success') {
                heal = 1;
                applyRestore(effectVocabulary.TARGET.SELF, heal);
                actionText = 'Wind Ward — you brace against the gale. 1 Vit restored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              } else {
                playerDmg = 1;
                actionText = 'Wind Ward — the wind knocks you. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              }
            } else if (action.id === 'aetherSeal') {
              if (r.outcome === 'success') {
                const gain = floor(random(1, 3));
                changeResource(effectVocabulary.RESOURCE.SCRAP, gain);
                actionText = 'Aether Seal — the leak closes. +' + gain + ' Scrap. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              } else {
                playerDmg = 1;
                actionText = 'Aether Seal — the aether burns you. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
              }
            }
          }
        } else if (r.outcome === 'partial') {
          if (action.type === 'attack') {
            enemyDmg = Math.max(0, floor(random(1, 7)) + 2 - 1);
            applyDamage(effectVocabulary.TARGET.ENEMY, enemyDmg, 'emp');
            changeResource(effectVocabulary.RESOURCE.STAFF_CHARGES, -1);
            playerDmg = 1;
            actionText = action.label + ' — ' + enemyDmg + ' damage, but the enemy counters. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
          } else if (action.type === 'ability') {
            if (action.id === 'uncoverTruth') {
              actionText = 'Uncover Truth — a glimpse, but it slips. No bonus. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            } else if (action.id === 'sharedDream') {
              heal = 1;
              applyRestore(effectVocabulary.TARGET.SELF, heal);
              actionText = 'Shared Dream — faint echo, ' + heal + ' Vit. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            } else if (action.id === 'mycelialLedger') {
              changeResource(effectVocabulary.RESOURCE.SCRAP, 1);
              actionText = 'Mycelial Ledger — +1 Scrap. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            }
          } else if (action.type === 'defense') {
            playerDmg = 1;
            if (action.id === 'windWard') {
              actionText = 'Wind Ward — the wind pushes through. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            } else {
              actionText = 'Aether Seal — the leak persists. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            }
          }
        } else {
          // Failure
          if (action.type === 'attack') {
            playerDmg = Math.floor(random(1, 4)) + 1;
            actionText = action.label + ' — misfires. ' + playerDmg + ' Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
          } else if (action.type === 'ability') {
            actionText = action.label + ' — the weave resists. Nothing gained. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
            playerDmg = 1;
          } else if (action.type === 'defense') {
            playerDmg = floor(random(1, 4)) + 1;
            actionText = action.label + ' — overwhelmed. ' + playerDmg + ' Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          }
        }


      attackCritical = Boolean(
        action && action.type === 'attack' && r && r.outcome === 'success'
      );
    }

    // Apply
    applyDamage(effectVocabulary.TARGET.SELF, playerDmg);
    // Combat animation triggers
    if (enemyDmg > 0) {
      state._flashTurn = millis();
      state._totalDamageDealt = (state._totalDamageDealt || 0) + enemyDmg;
      // Damage number
      state._lastDamageNum = {
        value: enemyDmg,
        crit: attackCritical,
        time: millis(),
      };
      // Critical hit flash: explicit JRPG critical on migrated attacks.
      if (attackCritical) {
        state._critFlashTurn = millis();
      }
    }
    if (playerDmg > 0) {
      state._playerHitTurn = millis();
    } else if (action && action.type === 'attack' &&
               ((formulaResolution && formulaResolution.hit) ||
                (r && r.outcome === 'success'))) {
      state._dodgeTurn = millis();
    }
    // ── Visual + audio feedback (triggered from core.js helpers) ──
    if (typeof triggerCombatHitFeedback === 'function') {
      triggerCombatHitFeedback(
        enemyDmg,
        playerDmg,
        r ? r.total : null,
        action && action.type === 'attack',
        attackCritical
      );
    }
    if (typeof triggerAbilityFeedback === 'function' && action && action.type === 'ability') {
      triggerAbilityFeedback(r.outcome === 'success');
    }
    if (enemyDmg > 0) log(state.enemy.name + ' takes ' + enemyDmg + ' EMP. HP: ' + state.enemy.hp + '/' + state.enemy.maxHp);
    if (playerDmg > 0) log('You take ' + playerDmg + ' damage. Vit: ' + state.player.vit + '/' + state.player.maxVit);
    if (heal > 0) log('Healed ' + heal + ' Vit.');
    if (actionText) log('[Turn ' + state.turn + '] ' + actionText);

    // Enemy turn — use special abilities by type
    if (state.enemy.hp > 0) {
      const eHit = floor(random(1, 4)) >= 3 ? 1 : 0;
      const eType = state.enemy.type || 'generic';
      if (eHit) {
        let enemyText = '';
        if (eType === 'skyPredator') {
          // Dive Bomb: 2 damage, ignores dodge
          const dmg = 2;
          airshipIncomingDamage(dmg);
          enemyText = state.enemy.name + ' dive-bombs — ' + dmg + ' damage (ignores dodge)!';
        } else if (eType === 'corporateSalvager') {
          // Contract Clause: lose 1 scrap
          if (state.player.scrap > 0) {
            changeResource(effectVocabulary.RESOURCE.SCRAP, -1);
            enemyText = state.enemy.name + ' invokes a contract clause — 1 scrap seized!';
          } else {
            // Fallback to strike
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' strikes — 1 Vit lost.';
          }
        } else if (eType === 'windShear') {
          // Gale Force: 2 damage, knockback feel
          const dmg = 2;
          airshipIncomingDamage(dmg);
          enemyText = state.enemy.name + ' unleashes gale force — ' + dmg + ' damage, wind knocks you back!';
          state._windKnockTurn = millis();
        } else if (eType === 'aetherLeak') {
          // Drain: remove 1 aether
          if (state.player.aether.current > 0) {
            changeResource(effectVocabulary.RESOURCE.AETHER, -1);
            enemyText = state.enemy.name + ' drains your aether — 1 aether lost!';
          } else {
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' strikes desperately — 1 Vit lost.';
          }
        } else if (eType === 'engine_spirit') {
          // Harmonic Pulse: 2D6+Presence, drains 1 aether on 7-9+
          const pulseRoll = floor(random(1, 7)) + floor(random(1, 7)) + state.enemy.presence;
          if (pulseRoll >= 7) {
            if (state.player.aether.current > 0) {
              changeResource(effectVocabulary.RESOURCE.AETHER, -1);
              enemyText = state.enemy.name + ' emits harmonic pulse — drains 1 aether!';
            } else {
              airshipIncomingDamage(1);
              enemyText = state.enemy.name + ' pulses — backlashes for 1 Vit!';
            }
          } else {
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' pulses harmlessly — 1 Vit lost.';
          }
        } else if (eType === 'child_prophet') {
          // Prophecy Voice: on hit, lower player confidence (reduce echoes by 1)
          if (state.player.echoes.current > 0) {
            changeResource(effectVocabulary.RESOURCE.ECHOES, -1);
            enemyText = state.enemy.name + ' chants prophecy — your confidence wavers, -1 echo!';
          } else {
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' prophesies — 1 Vit lost.';
          }
        } else if (eType === 'elder_farmer') {
          // Soil Anchor: 2D6+Might, on 10+ root player (skip next turn)
          const anchorRoll = floor(random(1, 7)) + floor(random(1, 7)) + state.enemy.might;
          if (anchorRoll >= 10) {
            state._rootedTurn = millis();
            enemyText = state.enemy.name + ' plants soil anchor — you are rooted for 1 turn!';
          } else if (anchorRoll >= 7) {
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' anchors imperfectly — 1 Vit lost.';
          } else {
            airshipIncomingDamage(1);
            enemyText = state.enemy.name + ' stumbles in the soil — 1 Vit lost.';
          }
        } else {
          // Generic strike
          airshipIncomingDamage(1);
          enemyText = state.enemy.name + ' strikes — 1 Vit lost.';
        }
        log('[Enemy] ' + enemyText);
        if (eType === 'skyPredator' || eType === 'windShear') {
          state._flashTurn = millis();
        }
      } else {
        // Enemy holds — but some enemies have conditional pressure
        if (eType === 'corporateSalvager' && floor(random(1, 4)) >= 3) {
          log('[Enemy] ' + state.enemy.name + ' exerts corporate pressure — you feel restrained.');
          state._pressureTurn = millis();
        } else {
          log('[Enemy] ' + state.enemy.name + ' holds.');
        }
      }
    }

    // --- Enemy Special Attacks ---
    // After enemy turn, handle ability usage.
    // Uses the ENEMY_ABILITIES lookup defined in the combat module.
    const enemyAbilities = state.enemy ? (state.enemy.abilities || []) : [];
    if (state.enemy && enemyAbilities.length > 0 && !state.encounterOver) {
      const abilityRoll = floor(random(1, 11));
      if (abilityRoll <= 3) {
        const abilityIdx = floor(random(0, enemyAbilities.length));
        const abilityId = enemyAbilities[abilityIdx];
        const normalizedAbilityId = String(abilityId).replace(/_([a-z])/g, function(_, ch) {
          return ch.toUpperCase();
        });
        if (normalizedAbilityId === 'diveBomb' || normalizedAbilityId === 'galeForce' || normalizedAbilityId === 'harmonicPulse') {
          state._enemyAbilityFlash = millis();
        } else if (normalizedAbilityId === 'contractClause' || normalizedAbilityId === 'prophecyVoice') {
          state._enemyAbilityFlash = millis();
        } else if (normalizedAbilityId === 'soilAnchor') {
          state._enemyAbilityFlash = millis();
        } else if (normalizedAbilityId === 'drain') {
          state._enemyAbilityFlash = millis();
        }
      }
    }

    // Check end
    if (state.enemy.hp <= 0) {
      state.encounterOver = true;
      // Track explicit critical killing blows across migrated and legacy actions.
      if (attackCritical && enemyDmg > 0) {
        state._lastTurnCrit = true;
      } else {
        state._lastTurnCrit = false;
      }
      // Base reward — scales with fight performance
      let scrapReward = 1 + floor(random(1, 3));
      let echoReward = 1;
      // Bonus for critical success on final turn (last successful attack that ended it)
      if (state._lastTurnCrit) {
        scrapReward += 2;
        echoReward = 2;
        log('── Critical finish! Bonus rewards awarded. ──');
      }
      // Bonus for surviving near-death
      if (state.player.vit <= 3 && state.player.vit > 0) {
        scrapReward += 1;
        log('── You fought through the brink — resilience reward. ──');
      }
      changeResource(effectVocabulary.RESOURCE.SCRAP, scrapReward);
      log('── ' + state.enemy.name + ' defeated. +' + scrapReward + ' Scrap. ──');
      changeResource(effectVocabulary.RESOURCE.ECHOES, echoReward);
      log('+' + echoReward + ' Echo' + (echoReward > 1 ? 's' : '') + '. The weave settles.');
      // XP reward based on enemy difficulty
      let xpReward = 0;
      const eName = state.enemy.name;
      if (eName === 'Sky-Predator') xpReward = 15;
      else if (eName === 'Corporate Salvager') xpReward = 12;
      else if (eName === 'Harmonic Shear') xpReward = 20;
      else if (eName === 'Aether Leak') xpReward = 18;
      else if (eName === 'Engine Spirit') xpReward = 14;
      else if (eName === 'Child Prophet') xpReward = 10;
      else if (eName === 'Elder Farmer') xpReward = 22;
      else xpReward = 10;
      if (attackCritical) xpReward += 5;
      this.awardXP(xpReward);
      state._defeatTurn = millis();
      // Victory stats
      state._victoryStats = {
        turns: state.turn,
        damageDealt: state._totalDamageDealt || 0,
        scrapEarned: scrapReward,
        echoEarned: echoReward,
      };
    }

    if (state.player.vit <= 0) {
      state.player.vit = 1;
      log('Your vitality fails. The dream fades — for now.');
    }
  };

  this.ability = function(name, target) {
    const action = actions.find(a => a.id === name.toLowerCase().replace(/\s+/g, ''));
    if (action) this.resolveTurn(action.id, null);
  };

  this.resolveSecondaryAction = function() {
    if (!state._secondaryAvailable || !state._lastAbilityId) return false;
    const abilityId = state._lastAbilityId;
    const result = this.resolveTurn(abilityId, null);
    // One secondary opportunity is consumed by the attempt. resolveTurn()
    // may briefly reopen a window on another success; suppress that here.
    state._secondaryAvailable = false;
    return result !== false;
  };

  this.roll2d6 = roll2d6;
  this.roll2d6Plus = roll2d6Plus;

  this.getState = function() {
    return {
      turn: state.turn,
      player: JSON.parse(JSON.stringify(state.player)),
      enemy: state.enemy ? JSON.parse(JSON.stringify(state.enemy)) : null,
      airship: JSON.parse(JSON.stringify(state.airship)),
      partyContext: state.partyContext
        ? JSON.parse(JSON.stringify(state.partyContext))
        : null,
      log: state.log.slice(),
      encounterOver: state.encounterOver,
      actions: actions,
      eligibleActionIds: window.AetherAbilityDefs.getEligibleActionIds(state.player),
      usableActionIds: window.AetherAbilityDefs.getUsableActionIds(state.player),
      actionUseEligibility: Object.fromEntries(actions.map(action => [
        action.id,
        window.AetherAbilityDefs.getUseEligibility(state.player, action.id),
      ])),
      secondaryAvailable: Boolean(state._secondaryAvailable),
      lastAbilityId: state._lastAbilityId || null,
      initiative: state.initiative,
      resolverMutations: resolverMutationCount,
    };
  };

  this.handleInput = function(p, keys, pressed) {
    // Combat input handled by core; this is a no-op hook
    return;
  };

  // ── Rendering (called from core.js drawCombatScene wiring) ──
  this.drawCombatScene = function(playerX, playerY, aetherMax, staffMax) {
    const now = millis();
    const dodgeBob = state._dodgeTurn && state._dodgeTurn > now - 200
      ? Math.sin((now - state._dodgeTurn) * 0.02) * 4
      : 0;
    
    // ── Background ──
    noStroke();
    fill(C.navy[0], C.navy[1], C.navy[2]);
    rect(0, 0, p.width, p.height);

    // Ground
    fill(C.soil[0], C.soil[1], C.soil[2]);
    rect(0, p.height * 0.55, p.width, p.height * 0.45);

    // Sky gradient overlay
    for (let i = 0; i < p.height * 0.55; i += 2) {
      const t = i / (p.height * 0.55);
      p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], Math.floor(15 * (1 - t)));
      p.strokeWeight(2);
      p.line(0, i, p.width, i);
    }
    p.noStroke();

    // ── Stars ──
    for (let i = 0; i < 30; i++) {
      const sx = (i * 137.5 + 50 + Math.sin(now * 0.0003 + i) * 8) % p.width;
      const sy = (i * 97.3 + 20 + Math.cos(now * 0.0002 + i * 1.3) * 6) % (p.height * 0.45);
      const twinkle = Math.sin(now * 0.002 + i * 3) * 0.3 + 0.7;
      p.fill(C.teal[0], C.teal[1], C.teal[2], Math.floor(20 + 20 * twinkle));
      p.noStroke();
      p.ellipse(sx, sy, 1.5 + twinkle * 0.5, 1.5 + twinkle * 0.5);
    }

    // ── Aether wisps ──
    const t = now * 0.001;
    for (let i = 0; i < 5; i++) {
      const wx = (p.width * 0.12 * i + p.width * 0.08 + Math.sin(t + i * 2.5) * 50) % p.width;
      const wy = p.height * 0.15 + Math.sin(t * 0.6 + i * 3.7) * 35;
      const wispAlpha = 30 + Math.sin(t * 1.1 + i * 1.7) * 18;
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], wispAlpha);
      p.noStroke();
      p.ellipse(wx, wy, 22 + Math.sin(t * 1.2 + i * 0.9) * 6, 6 + Math.cos(t * 0.8 + i * 1.1) * 3);
      p.fill(C.teal[0], C.teal[1], C.teal[2], wispAlpha * 0.4);
      p.ellipse(wx - 4, wy - 2, 14 + Math.sin(t * 1.3 + i) * 4, 4 + Math.cos(t * 0.9 + i) * 2);
    }

    // ── Pixel party formation ──
    const battleSprites = window.AetherPixelSprites;
    const battleGroundY = Math.round(p.height * 0.62);
    const battleEnderX = Math.round(p.width * 0.34);
    const battleLyraX = battleEnderX - 54;
    const battleIoniaX = battleEnderX - 104;
    const battleFrame = Math.floor(now / 420) % 2;

    if (battleSprites && typeof battleSprites.draw === 'function') {
      battleSprites.drawShadow(battleIoniaX, battleGroundY + 3, 2.2);
      battleSprites.draw('ionia', battleIoniaX, battleGroundY, {
        frame: battleFrame, scale: 3, anchor: 'bottom-center',
      });

      battleSprites.drawShadow(battleLyraX, battleGroundY + 3, 2.2);
      battleSprites.draw('lyra', battleLyraX, battleGroundY, {
        frame: battleFrame, scale: 3, anchor: 'bottom-center',
      });

      battleSprites.drawShadow(battleEnderX, battleGroundY + 3, 2.4);
      battleSprites.draw('ender', battleEnderX, battleGroundY + dodgeBob, {
        frame: battleFrame, scale: 3, anchor: 'bottom-center',
      });
    }

    // ── Combat intro banner ──
    if (state.enemy && state.turn <= 3) {
      const bannerT = Math.min(1, state.turn / 3);
      p.textFont('VT323');
      p.textSize(20 * bannerT);
      p.textAlign(p.CENTER, p.CENTER);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 160 * bannerT);
      p.text('⚔ COMBAT ⚔', p.width/2, 38);
      p.textSize(12 * bannerT);
      p.fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * bannerT);
      p.text(state.enemy.name + ' approaches.', p.width/2, 58);
    }

    // ── Enemy ──
    if (state.enemy) {
      const ex = p.width * 0.75;
      const ey = p.height * 0.52;
      const eType = state.enemy.type || 'generic';
      const eColor = state.enemy.color || 'soil';

      // Map color name to C array
      const colorMap = {
        rust: C.rust,
        soil: C.soil,
        scioto: C.scioto,
        teal: C.teal,
      };
      const eBodyColor = colorMap[eColor] || C.soil;

      // Pixel authority for the opening encounter. Other enemy families stay
      // on the legacy renderer until their own sprite pass is admitted.
      const hpRatio = state.enemy.hp / state.enemy.maxHp;
      const glowColor = hpRatio > 0.5 ? C.scioto : (hpRatio > 0.25 ? C.rust : C.teal);
      const pixelEnemy = window.AetherPixelSprites &&
        window.AetherPixelSprites.get &&
        window.AetherPixelSprites.get('skyPredator');

      if (eType === 'skyPredator' && pixelEnemy) {
        const flapFrame = Math.floor(now / 180) % 2;
        window.AetherPixelSprites.drawShadow(ex, ey + 34, 3);
        window.AetherPixelSprites.draw('skyPredator', ex, ey + 26, {
          frame: flapFrame,
          scale: 4,
          anchor: 'bottom-center',
        });

        p.noFill();
        p.stroke(glowColor[0], glowColor[1], glowColor[2], 55);
        p.strokeWeight(2);
        p.rect(ex - 36, ey - 38, 72, 72);
        p.noStroke();
      } else {
  
        p.fill(glowColor[0], glowColor[1], glowColor[2], 30 + Math.sin(now * 0.005) * 10);
        p.noStroke();
        p.ellipse(ex, ey, 70 + Math.sin(now * 0.003) * 4, 52 + Math.cos(now * 0.004) * 3);
  
        // ── Enemy wings (animated) ──
        const wingFlap = Math.sin(now * 0.005 + state.turn * 0.5) * 10 + 22;
        // Per-enemy-type wing color
        const wingColorMap = {
          skyPredator: C.scioto,
          corporateSalvager: C.soil,
          windShear: C.scioto,
          aetherLeak: C.teal,
        };
        const wingColor = wingColorMap[eType] || C.teal;
        p.fill(wingColor[0], wingColor[1], wingColor[2], 140 + Math.sin(now * 0.004 + state.turn) * 20);
        p.noStroke();
        p.ellipse(ex - 26, ey - 8, 30, wingFlap);
        p.ellipse(ex + 26, ey - 8, 30, wingFlap * 0.85);
  
        // Wing-edge glow
        p.stroke(C.teal[0], C.teal[1], C.teal[2], 60);
        p.strokeWeight(1);
        p.noFill();
        p.ellipse(ex - 26, ey - 8, 30, wingFlap);
        p.ellipse(ex + 26, ey - 8, 30, wingFlap * 0.85);
        p.noStroke();
  
        // ── Enemy body ──
        const bodyColor = eBodyColor;
        p.fill(bodyColor[0], bodyColor[1], bodyColor[2], 220);
        p.noStroke();
        // Different body shapes per enemy type
        if (eType === 'elemental') {
          // Wind Shear: angular, swirling body
          p.ellipse(ex, ey, 34, 28);
          p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 80);
          p.ellipse(ex - 8, ey - 4, 18, 14);
          // Wind streaks
          p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], 100);
          p.strokeWeight(1.5);
          p.noFill();
          for (let w = 0; w < 3; w++) {
            const wa = now * 0.005 + w * 2.1;
            p.line(ex - 12 + Math.sin(wa) * 8, ey - 6 + Math.cos(wa * 0.7) * 4,
                   ex - 4 + Math.sin(wa + 1) * 10, ey - 2 + Math.cos(wa * 0.7 + 1) * 5);
          }
          p.noStroke();
        } else if (eType === 'wraith') {
          // Aether Leak: translucent, irregular blob
          p.ellipse(ex, ey, 32, 26);
          // Corrosive aura
          p.fill(C.teal[0], C.teal[1], C.teal[2], 30 + Math.sin(now * 0.008) * 15);
          p.ellipse(ex, ey, 44, 36);
          p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 50);
          p.ellipse(ex - 4, ey - 2, 16, 12);
        } else if (eType === 'humanoid') {
          // Corporate Salvager: taller, narrower
          p.ellipse(ex, ey, 26, 36);
          p.fill(C.soil[0], C.soil[1], C.soil[2], 180);
          p.rect(ex - 8, ey - 18, 16, 18);
        } else {
          // Sky-Predator (default): original body
          p.ellipse(ex, ey, 30, 34);
        }
  
        // Body highlight
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 40);
        p.ellipse(ex - 5, ey - 8, 14, 10);
  
        // ── Enemy eye (glows) ──
        const eyeGlow = Math.sin(now * 0.006) * 0.2 + 0.8;
        p.fill(C.teal[0], C.teal[1], C.teal[2], 200 * eyeGlow);
        p.noStroke();
        p.ellipse(ex + 7, ey - 5, 7, 7);
        p.fill(C.navy[0], C.navy[1], C.navy[2]);
        p.ellipse(ex + 8, ey - 5, 3.5, 3.5);
        // Eye highlight
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 160);
        p.ellipse(ex + 9, ey - 6, 1.5, 1.5);
      }

      // ── HP bar ──
      p.stroke(C.navy[0], C.navy[1], C.navy[2], 200);
      p.strokeWeight(1);
      p.noFill();
      p.rect(ex - 32, ey - 32, 64, 5);
      p.noStroke();
      const hpFill = 60 * hpRatio;
      if (hpFill > 0) {
        p.fill(glowColor[0], glowColor[1], glowColor[2], 220);
        p.rect(ex - 31, ey - 31, hpFill, 3);
        // HP bar glow
        p.fill(glowColor[0], glowColor[1], glowColor[2], 40);
        p.rect(ex - 31, ey - 31, hpFill, 3);
      }

      // HP bar border ticks
      p.stroke(C.teal[0], C.teal[1], C.teal[2], 80);
      p.strokeWeight(1);
      p.noFill();
      for (let h = 0; h <= 4; h++) {
        p.line(ex - 32 + h * 15, ey - 32, ex - 32 + h * 15, ey - 27);
      }

      // ── Enemy name ──
      p.textFont('Press Start 2P');
      p.textSize(9);
      p.textAlign(p.CENTER, p.TOP);
      p.fill(C.parchment[0], C.parchment[1], C.parchment[2], 180);
      p.text(state.enemy.name, ex, ey - 38);

      // ── Turn counter ──
      p.textSize(8);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 130);
      p.text('TURN ' + state.turn, ex, ey + 22);

      // ── Enemy attack flash — bigger, brighter ──
      if (state._flashTurn && state._flashTurn > now - 300) {
        const age = now - state._flashTurn;
        const flashAlpha = map(age, 0, 300, 180, 0);
        const flashScale = map(age, 0, 300, 1, 2.5);
        p.fill(C.teal[0], C.teal[1], C.teal[2], flashAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 80 * flashScale, 60 * flashScale);
        // Secondary ring
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], flashAlpha * 0.4);
        p.ellipse(ex, ey, 100 * flashScale, 75 * flashScale);
      }

      // ── Critical hit flash — huge red burst ──
      if (state._critFlashTurn && state._critFlashTurn > now - 500) {
        const age = now - state._critFlashTurn;
        const critAlpha = map(age, 0, 500, 220, 0);
        const critScale = map(age, 0, 500, 1, 3.5);
        p.fill(C.rust[0], C.rust[1], C.rust[2], critAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 90 * critScale, 70 * critScale);
        p.fill(C.teal[0], C.teal[1], C.teal[2], critAlpha * 0.5);
        p.ellipse(ex, ey, 120 * critScale, 90 * critScale);
        // "CRITICAL" text
        if (age < 300) {
          p.textFont('Press Start 2P');
          p.textSize(14);
          p.textAlign(p.CENTER, p.CENTER);
          p.fill(C.teal[0], C.teal[1], C.teal[2], map(age, 0, 300, 255, 0));
          p.text('CRIT', ex, ey - 50 - (1 - age / 300) * 20);
        }
      }

      // ── Damage number floating up ──
      if (state._lastDamageNum && state._lastDamageNum.time && state._lastDamageNum.time > now - 1200) {
        const dAge = now - state._lastDamageNum.time;
        const dAlpha = map(dAge, 0, 1200, 255, 0);
        const dY = ey - 40 - map(dAge, 0, 1200, 0, 40);
        p.textFont('Press Start 2P');
        p.textSize(14);
        p.textAlign(p.CENTER, p.CENTER);
        const dCol = state._lastDamageNum.crit ? C.rust : C.teal;
        p.fill(dCol[0], dCol[1], dCol[2], dAlpha);
        p.text('-' + state._lastDamageNum.value, ex, dY);
      }

      // ── Enemy near-death shimmer ──
      if (hpRatio < 0.3 && hpRatio > 0) {
        const shimmer = Math.sin(now * 0.025) * 0.5 + 0.5;
        p.fill(C.rust[0], C.rust[1], C.rust[2], 40 * shimmer);
        p.noStroke();
        p.ellipse(ex, ey, 55, 42);
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 30 * (1 - shimmer));
        p.ellipse(ex, ey, 40, 30);
      }

      // ── Enemy defeat / victory flash ──
      if (state.enemy.hp <= 0 && state._defeatTurn && state._defeatTurn > now - 800) {
        const dfAge = now - state._defeatTurn;
        const dfAlpha = map(dfAge, 0, 800, 200, 0);
        p.fill(C.teal[0], C.teal[1], C.teal[2], dfAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 120, 90);
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], dfAlpha * 0.4);
        p.ellipse(ex, ey, 160, 120);
        // Debris particles
        for (let d = 0; d < 6; d++) {
          const da = (dfAge * 0.01 + d * 1.05) % (Math.PI * 2);
          const dd = map(dfAge, 0, 800, 5, 30) * (1 - Math.abs(Math.cos(da)) * 0.6);
          p.fill(C.teal[0], C.teal[1], C.teal[2], dfAlpha * 0.6);
          p.noStroke();
          p.ellipse(ex + Math.cos(da) * dd, ey + Math.sin(da) * dd * 0.6, 4, 4);
        }
      }
    }

    // ── Player hit flash — red impact at player position ──
    if (state._playerHitTurn && state._playerHitTurn > now - 400) {
      const hitAge = now - state._playerHitTurn;
      const hitAlpha = map(hitAge, 0, 400, 140, 0);
      const hitScale = map(hitAge, 0, 400, 1, 3);
      p.fill(C.rust[0], C.rust[1], C.rust[2], hitAlpha);
      p.noStroke();
      p.ellipse(playerX, playerY + dodgeBob, 40 * hitScale, 40 * hitScale);
      p.fill(C.teal[0], C.teal[1], C.teal[2], hitAlpha * 0.3);
      p.ellipse(playerX, playerY + dodgeBob, 50 * hitScale, 50 * hitScale);
    }

    // ── Player ability flash — teal burst on ability use ──
    if (state._abilityFlashTurn && state._abilityFlashTurn > now - 300) {
      const aAge = now - state._abilityFlashTurn;
      const aAlpha = map(aAge, 0, 300, 120, 0);
      const aScale = map(aAge, 0, 300, 1, 2);
      p.fill(C.teal[0], C.teal[1], C.teal[2], aAlpha);
      p.noStroke();
      p.ellipse(playerX, playerY + dodgeBob, 35 * aScale, 35 * aScale);
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], aAlpha * 0.5);
      p.ellipse(playerX, playerY + dodgeBob, 45 * aScale, 45 * aScale);
    }

    // ── Wind knockback visual — screen shake effect ──
    if (state._windKnockTurn && state._windKnockTurn > now - 400) {
      const wAge = now - state._windKnockTurn;
      const wIntensity = map(wAge, 0, 400, 6, 0);
      const wPhase = wAge * 0.02;
      // Draw wind streaks across screen
      p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], map(wAge, 0, 400, 80, 0));
      p.strokeWeight(2);
      p.noFill();
      for (let ws = 0; ws < 5; ws++) {
        const wsX = (ws * 100 + wAge * 0.1 * (ws + 1)) % p.width;
        const wsY = p.height * 0.4 + Math.sin(wPhase + ws * 1.3) * 30;
        p.line(wsX, wsY, wsX + wIntensity * 2, wsY - wIntensity);
      }
      p.noStroke();
    }

    // ── Fire package (staff) ──
    if (state.player.staffCharges > 0) {
      const fx = 72, fy = p.height * 0.62;

      // Staff glow
      const chargeGlow = Math.sin(now * 0.004) * 0.3 + 0.7;
      p.fill(C.teal[0], C.teal[1], C.teal[2], 25 * chargeGlow);
      p.noStroke();
      p.ellipse(fx, fy, 44, 44);

      // Staff shaft
      p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], 150);
      p.strokeWeight(2.5);
      p.line(fx, fy - 16, fx, fy - 40);
      p.noStroke();

      // Staff tip glow
      p.fill(C.teal[0], C.teal[1], C.teal[2], 60 * chargeGlow);
      p.noStroke();
      p.ellipse(fx, fy - 40, 10, 10);

      // Charge orb
      p.fill(C.teal[0], C.teal[1], C.teal[2], 180 * chargeGlow);
      p.ellipse(fx, fy - 40, 8, 8);
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 120);
      p.ellipse(fx, fy - 40, 13, 13);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 40);
      p.ellipse(fx, fy - 40, 18, 18);

      // Charge count
      p.textFont('Press Start 2P');
      p.textSize(8);
      p.textAlign(p.CENTER, p.TOP);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 200);
      p.text('\u26A1 ' + state.player.staffCharges + '/' + staffMax, fx, fy + 10);
    } else {
      // Empty staff
      const fx = 72, fy = p.height * 0.62;
      p.stroke(C.soil[0], C.soil[1], C.soil[2], 110);
      p.strokeWeight(2);
      p.line(fx, fy - 16, fx, fy - 40);
      p.noStroke();
      p.textFont('Press Start 2P');
      p.textSize(8);
      p.textAlign(p.CENTER, p.TOP);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 70);
      p.text('EMPTY', fx, fy + 10);
    }

    // ── Fire particles ──
    if (state.player.staffCharges > 0) {
      for (let i = 0; i < 5; i++) {
        const pi = (now * 0.02 + i * 7) % 5;
        const fx = 72 + Math.sin(now * 0.015 + i * 2.1) * 8;
        const fy = p.height * 0.58 - pi * 7;
        const particleAlpha = Math.max(0, 60 - pi * 12 - Math.sin(now * 0.025 + i) * 15);
        if (particleAlpha > 0) {
          p.fill(C.teal[0], C.teal[1], C.teal[2], particleAlpha);
          p.noStroke();
          p.ellipse(fx, fy, 5 - pi * 0.7, 5 - pi * 0.7);
        }
      }
    }

    // ── Ambient aether motes ──
    for (let i = 0; i < 8; i++) {
      const ai = (i * 47 + 13) % p.width;
      const aj = (i * 73 + 29) % (p.height * 0.45);
      const aPhase = (now * 0.0005 + i * 1.7) % (Math.PI * 2);
      const aDriftX = Math.sin(aPhase) * 20;
      const aDriftY = Math.cos(aPhase * 0.7 + i) * 12;
      const aAlpha = 8 + Math.sin(now * 0.003 + i * 2.3) * 5;
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], aAlpha);
      p.noStroke();
      p.ellipse(ai + aDriftX, aj + aDriftY, 3 + Math.sin(aPhase) * 1.5, 2 + Math.cos(aPhase * 0.5) * 1);
    }

    // ── Player character ──
    const px = playerX, py = playerY;
    const pulse = Math.sin(now * 0.003) * 3 + 20;

    // Player glow
    p.fill(C.teal[0], C.teal[1], C.teal[2], 50);
    p.noStroke();
    p.ellipse(px, py + dodgeBob, pulse + 10, pulse + 10);

    // Player body
    p.fill(C.teal[0], C.teal[1], C.teal[2], 190);
    p.noStroke();
    p.ellipse(px, py + dodgeBob, pulse, pulse);

    // Player highlight
    p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 160);
    p.ellipse(px - 4, py - 4 + dodgeBob, pulse * 0.35, pulse * 0.35);

    // Player outline
    p.stroke(C.teal[0], C.teal[1], C.teal[2], 100);
    p.strokeWeight(1.5);
    p.noFill();
    p.ellipse(px, py + dodgeBob, pulse + 2, pulse + 2);
    p.noStroke();

    // Player name
    p.textFont('Press Start 2P');
    p.textSize(8);
    p.textAlign(p.CENTER, p.TOP);
    p.fill(C.parchment[0], C.parchment[1], C.parchment[2], 170);
    p.text('ENDER', px, py - 30 + dodgeBob);

    // Player Vit bar
    const vitRatio = (combat && combat.getState) ? 
      (combat.getState().player.vit / combat.getState().player.maxVit) : 1;
    p.stroke(C.navy[0], C.navy[1], C.navy[2], 150);
    p.strokeWeight(1);
    p.noFill();
    p.rect(px - 16, py - 42 + dodgeBob, 32, 3);
    p.noStroke();
    p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 180);
    p.rect(px - 15, py - 41 + dodgeBob, 30 * Math.max(0, vitRatio), 1.5);
  };
};

if (typeof window !== 'undefined') {
  window.AetherCombat = AetherCombat;
}


// === modules/ui.js ===
/**
 * Aetherwake JRPG — UI Module
 * All drawing via p5 primitives. No DOM creation.
 * Exports a global UI object consumed by core.js.
 */
'use strict';

// ─────────────────────────────────────────────
// 16-COLOR PALETTE (from SPEC.md)
// ─────────────────────────────────────────────
const PAL = {
  TEAL:       '#2AFFB5',  // Solar Teal — primary accent / glow
  SCIOTO:     '#7CC8E8',  // Scioto Blue — secondary / sky
  NAVY:       '#1A102E',  // Deep Navy — background
  PARCHMENT:  '#E8DCC6',  // Parchment — text / ports
  DUST:       '#C4A882',  // Dust Tan
  RUST:       '#A04A2C',  // Rust
  SOIL:       '#4A3520',  // Soil Brown
  BIO:        '#4AEB6B',  // Biolum Green — mycelial / gear
  WHITE:      '#F0F4F8',
  OFFWHITE:   '#D8DDE3',
  DIM:        '#8A7F99',
  SHADOW:     '#0D0820',  // deeper than NAVY for borders/depth
  RED:        '#FF5C5C',  // dice fail / danger
  AMBER:      '#FFB347',  // dice partial / heat
  GREEN:      '#5CFF8A',  // dice success / heal
};

// VT323 ≈ monospace 16px–24px feel; Press Start 2P ≈ heavy pixel 8–12px.
// p5 has no font fallback control per-call, so we approximate with size/weight calls.
// In core.js, setTextFont should be called once to load these.

const FONT_BODY  = 'VT323';
const FONT_UI    = 'Press Start 2P';

// ─────────────────────────────────────────────
// GLOBAL STATE (shared with core.js via window.UI)
// ─────────────────────────────────────────────
window.UI = {
  // Menu
  menuOpen: false,
  menuTitle: '',
  menuOptions: [],
  menuCallback: null,

  // Dialogue
  dialogueOpen: false,
  dialogueNPC: null,
  dialogueText: '',
  dialogueContinue: null,

  // Shop
  shopOpen: false,
  shopItems: [],

  // Turn overlay flag
  turnOverlay: false,

  // Combat log entries (circular, last N)
  combatLog: [],

  // Quest log entries
  questLog: [],

  // Inventory items
  inventory: [],

  // Day-night timer (0..120s mapped to 0..PI2)
  dayNightPhase: 0,
};

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

/** Push a string into the combat log, keep last 6. */
function logCombat(msg) {
  // Write to combat state log if combat is active, otherwise UI fallback
  if (typeof combat !== 'undefined' && combat && typeof combat.getState === 'function') {
    const cs = combat.getState();
    if (cs && cs.log) {
      cs.log.push(msg);
      if (cs.log.length > 6) cs.log.shift();
      return;
    }
  }
  // Fallback for when combat module isn't fully initialized
  window.UI.combatLog.push(msg);
  if (window.UI.combatLog.length > 6) window.UI.combatLog.shift();
}

/** Push a quest entry. */
function logQuest(msg) {
  window.UI.questLog.push(msg);
  if (window.UI.questLog.length > 8) window.UI.questLog.shift();
}

/** Push an inventory item. */
function addInventory(item) {
  window.UI.inventory.push(item);
}

// ─────────────────────────────────────────────
// AESTHETIC PRIMITIVES
// ─────────────────────────────────────────────

/**
 * Draw the global background: dark navy + teal grid overlay at low opacity.
 * Call once per frame in draw() BEFORE other UI layers.
 */
function drawBackground() {
  background(PAL.NAVY);

  // Subtle teal grid overlay (low opacity)
  push();
  stroke(PAL.TEAL);
  strokeWeight(1);
  const gridSize = 40;
  const alpha = 18; // ~7% opacity
  fill(color(PAL.TEAL), alpha);
  noStroke();
  for (let x = 0; x < width; x += gridSize) {
    for (let y = 0; y < height; y += gridSize) {
      rect(x, y, 1, 1);
    }
  }
  // Thicker grid lines at low opacity
  stroke(color(PAL.TEAL), 12);
  strokeWeight(1);
  for (let x = 0; x < width; x += gridSize) {
    line(x, 0, x, height);
  }
  for (let y = 0; y < height; y += gridSize) {
    line(0, y, width, y);
  }
  pop();
}

/**
 * Scanline overlay — horizontal lines across the whole canvas.
 * Call AFTER all content, semi-transparent dark teal lines.
 */
function drawScanlines() {
  // Disabled in the integrated playable runtime.
  //
  // This later UI-module declaration overrides the earlier game-level
  // drawScanlines() because both were concatenated into one global script.
  // Its p5 color-object + alpha calls rendered as an effectively opaque
  // cyan/black stripe mask in packaged Chromium, covering the actual game.
  //
  // Keep the effect off until the integrated UI helpers are namespaced.
  return;
}

/**
 * Pixel border: nested rects to simulate box-shadow depth.
 * @param {number} x,y,w,h — outer rect
 * @param {number} layers — how many nested border layers
 * @param {string} colorOuter — outer border color (default NAVY shadow)
 * @param {string} colorInner — inner border color (default TEAL)
 */
function drawPixelBorder(x, y, w, h, layers = 3,
                         colorOuter = PAL.SHADOW, colorInner = PAL.TEAL) {
  push();
  noFill();
  for (let i = 0; i < layers; i++) {
    const shrink = i * 2 + 1;
    const cx = x - shrink;
    const cy = y - shrink;
    const cw = w + shrink * 2;
    const ch = h + shrink * 2;
    stroke(i === 0 ? colorOuter : (i === layers - 1 ? colorInner : lerpColor(
      color(colorOuter), color(colorInner), i / (layers - 1))));
    strokeWeight(2);
    rect(cx, cy, cw, ch);
  }
  pop();
}

/**
 * Teal glow text — simulates text-shadow 0 0 8px #2AFFB5 via multiple offset draws.
 * Calls fill(textColor) once, then draws the same string several times offset with low-alpha TEAL.
 * @param {string} txt
 * @param {number} x, y
 * @param {string} textColor — main text color
 * @param {number} size — font size
 * @param {string} font — 'VT323' or 'Press Start 2P'
 */
function drawGlowText(txt, x, y, textColor = PAL.TEAL, size = 18,
                      font = FONT_BODY) {
  push();
  textFont(font);
  textSize(size);
  textAlign(LEFT, TOP);
  textLeading(size * 1.2);

  // Glow pass — 6 offset draws with low-alpha TEAL
  const glowColor = color(PAL.TEAL);
  glowColor.setAlpha(60);
  fill(glowColor);
  noStroke();
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  // Brighter inner glow
  glowColor.setAlpha(100);
  fill(glowColor);
  text(txt, x, y);

  // Main text
  fill(textColor);
  text(txt, x, y);
  pop();
}

/**
 * Glow text centered.
 */
function drawGlowTextCenter(txt, x, y, textColor = PAL.TEAL, size = 18,
                            font = FONT_BODY) {
  push();
  textFont(font);
  textSize(size);
  textAlign(CENTER, CENTER);
  textLeading(size * 1.2);

  const glowColor = color(PAL.TEAL);
  glowColor.setAlpha(60);
  fill(glowColor);
  noStroke();
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  glowColor.setAlpha(100);
  fill(glowColor);
  text(txt, x, y);

  fill(textColor);
  text(txt, x, y);
  pop();
}

/**
 * Draw a stat label with teal glow in VT323 style.
 */
function drawStatLabel(label, x, y, value, valueColor = PAL.PARCHMENT,
                       size = 16) {
  push();
  textFont(FONT_BODY);
  textSize(size);
  textAlign(LEFT, TOP);
  // Label with teal glow
  drawGlowText(label, x, y, PAL.TEAL, size);
  // Value in parchment
  fill(valueColor);
  noStroke();
  text(value, x + textWidth(label) + 8, y);
  pop();
}

// ─────────────────────────────────────────────
// VISUAL EFFECTS STATE (shared)
// ─────────────────────────────────────────────

/** Screen flash overlay — set by combat.js / core.js on big moments. */
window.screenFlash = { active: false, color: null, alpha: 0, startTime: 0 };

/**
 * Trigger a screen flash — color [r,g,b], duration ms, peak alpha 0..255.
 */
function triggerScreenFlash(r, g, b, duration, peakAlpha) {
  window.screenFlash.active = true;
  window.screenFlash.color = [r, g, b];
  window.screenFlash.alpha = peakAlpha || 120;
  window.screenFlash.startTime = millis();
  window.screenFlash.duration = duration || 250;
}

/** Draw the screen flash overlay if active. Call near end of drawHUDFrame. */
function drawScreenFlash() {
  if (!window.screenFlash.active) return;
  const now = millis();
  const age = now - window.screenFlash.startTime;
  if (age > (window.screenFlash.duration || 250)) {
    window.screenFlash.active = false;
    return;
  }
  const t = age / (window.screenFlash.duration || 250);
  const alpha = window.screenFlash.alpha * (1 - t);
  if (alpha < 1) return;
  noStroke();
  fill(window.screenFlash.color[0], window.screenFlash.color[1],
       window.screenFlash.color[2], alpha);
  rect(0, 0, width, height);
}

// ─────────────────────────────────────────────
// ANIMATED STAT BARS
// ─────────────────────────────────────────────

/** Track smoothed bar values so they animate instead of snapping. */
const _barAnim = new Map();

/**
 * Get smoothed bar value — lerps toward target each frame.
 * @param {string} key — unique bar identifier (e.g. 'playerVit', 'enemyHp')
 * @param {number} target — current target value (pixels or 0..1)
 * @param {number} [speed=0.12] — lerp speed per frame
 * @returns {number} smoothed current value
 */
function animBar(key, target, speed) {
  speed = speed == null ? 0.12 : speed;
  let cur = _barAnim.has(key) ? _barAnim.get(key) : target;
  cur = lerp(cur, target, Math.min(1, speed));
  _barAnim.set(key, cur);
  return cur;
}

/** Reset all bar animations (call on state change / new encounter). */
function resetBarAnimations() {
  _barAnim.clear();
}

// ─────────────────────────────────────────────
// PARTICLE SYSTEM (simple, p5-primitive based)
// ─────────────────────────────────────────────
window.particles = [];

/**
 * Emit a particle burst at (x, y). Color as [r,g,b] or PAL key.
 * @param {number} x, y
 * @param {object} opts — { count, color, speed, life, size, spread, upward }
 */
function emitParticles(x, y, opts) {
  if (!VIS.particles) return;
  opts = opts || {};
  const count = opts.count || 8;
  const color = opts.color || [42, 255, 181];
  const speed = opts.speed || 2;
  const life = opts.life || 40;
  const size = opts.size || 3;
  const spread = opts.spread || 1.8;
  const upward = opts.upward ? 1 : 0;
  for (let i = 0; i < count; i++) {
    const angle = Math.random() * TWO_PI;
    const spd = speed * (0.3 + Math.random() * 0.7);
    window.particles.push({
      x: x, y: y,
      vx: Math.cos(angle) * spd * spread,
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
function drawDayNightIndicator(cx, cy, r = 28) {
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
function drawCovenantField(x, y, radius = 60, pulse = 0) {
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
function getCharacterSheetViewModel(rosterIndex) {
  const roster = Array.isArray(window.ROSTER) ? window.ROSTER : [];
  const requestedIndex = Number.isInteger(rosterIndex)
    ? rosterIndex
    : charSheetRosterIndex;
  const index = Math.max(0, Math.min(4, requestedIndex || 0));
  const actor = roster[index] ||
    (index === 0 && world && world.player ? world.player : null);
  if (!actor) return null;

  const mastery = window._masteryDefs || window.AetherMasteryDefs || null;
  const nativeJob = mastery && typeof mastery.getNativeJobStatus === 'function'
    ? mastery.getNativeJobStatus(actor.id)
    : { status: 'unknown', id: null, label: null };
  const affinities = mastery && typeof mastery.getAuthoredAffinities === 'function'
    ? mastery.getAuthoredAffinities(actor.id)
    : { status: 'unknown', ids: [] };

  const abilityDefs = window.AetherAbilityDefs || null;
  let abilityIds = [];
  if (actor.runtimeImplemented === false) {
    abilityIds = [];
  } else if (actor.id === 'ender' &&
             abilityDefs &&
             typeof abilityDefs.getEligibleActionIds === 'function') {
    abilityIds = abilityDefs.getEligibleActionIds(actor);
  } else if (Array.isArray(actor.unlockedAbilities)) {
    // Companion mechanics are still preservation templates rather than the
    // canonical combat registry. Display their recorded IDs as provenance only.
    abilityIds = actor.unlockedAbilities.slice();
  }

  function humanizeId(id) {
    if (typeof id !== 'string' || !id) return 'Unknown';
    return id
      .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
      .replace(/[-_]+/g, ' ')
      .replace(/\b\w/g, ch => ch.toUpperCase());
  }

  const abilityLabels = abilityIds.map(id => {
    const def = abilityDefs && abilityDefs.DEFS ? abilityDefs.DEFS[id] : null;
    return {
      id,
      label: def && typeof def.label === 'string'
        ? def.label.split(' — ')[0]
        : humanizeId(id),
      source: def ? 'canonical-action-registry' : 'prototype-mechanics',
    };
  });

  const equipment = actor.equipment && typeof actor.equipment === 'object'
    ? actor.equipment
    : {};

  return {
    rosterIndex: index,
    rosterNumber: index + 1,
    id: actor.id || null,
    canonicalName: actor.canonicalName || actor.name || 'Unknown',
    name: actor.name || actor.canonicalName || 'Unknown',
    nativeJob,
    preservationClass: actor.class || null,
    mechanicsTemplateId: actor.mechanicsTemplateId || null,
    mechanicsTemplateName: actor.mechanicsTemplateName || null,
    implementationSource: actor.implementationSource || null,
    runtimeImplemented: actor.runtimeImplemented !== false,
    activePartyMember: Array.isArray(window.ACTIVE_PARTY)
      ? window.ACTIVE_PARTY.includes(actor)
      : false,
    affinities,
    level: Number.isFinite(actor.level) ? actor.level : null,
    xp: Number.isFinite(actor.xp) ? actor.xp : null,
    xpToNext: Number.isFinite(actor.xpToNext) ? actor.xpToNext : null,
    stats: {
      vit: actor.vit,
      maxVit: actor.maxVit,
      echoes: actor.echoes,
      echoesMax: actor.echoesMax,
      wits: actor.wits,
      presence: actor.presence,
      spirit: actor.spirit,
      might: actor.might,
      grace: actor.grace,
    },
    resources: {
      scrap: actor.scrap,
      aether: actor.aether,
      aetherMax: actor.aetherMax,
      heat: actor.heat,
      heatMax: actor.heatMax,
      staffCharges: actor.staffCharges,
      maxStaffCharges: actor.maxStaffCharges,
    },
    abilities: abilityLabels,
    equipment: {
      staff: equipment.staff || null,
      backpack: equipment.backpack || null,
    },
  };
}

window.getCharacterSheetViewModel = getCharacterSheetViewModel;

/**
 * Draw the full character sheet from canonical live state.
 * Phase-A mastery facts are code-owned presentation data only; no mutable
 * mastery progress is created here.
 */
function drawCharSheet(px, py, pw, ph) {
  push();
  const view = getCharacterSheetViewModel(charSheetRosterIndex);
  if (!view) {
    fill(PAL.RUST);
    textFont(FONT_UI);
    textSize(10);
    text('CHARACTER DATA UNAVAILABLE', px + 20, py + 20);
    pop();
    return;
  }

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
    statsY: py + 88,
    abilitiesX: px + 16,
    abilitiesY: py + 180,
    gearX: px + 330,
    gearY: py + 180,
    resourcesX: px + 16,
    resourcesY: py + 310,
  };

  noStroke();
  fill(PAL.NAVY);
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  textFont(FONT_UI);
  textSize(9);
  textAlign(RIGHT, TOP);
  fill(view.activePartyMember ? PAL.BIO : PAL.DIM);
  text(view.activePartyMember ? 'ACTIVE PARTY' : 'ROSTER', px + pw - 18, py + 12);

  textAlign(LEFT, TOP);
  drawGlowText(view.canonicalName.toUpperCase(), px + 160, py + 2, PAL.TEAL, 11);

  const portX = sheet.portraitX;
  const portY = sheet.portraitY;
  const portW = sheet.portraitW;
  const portH = sheet.portraitH;
  drawPixelBorder(portX, portY, portW, portH, 3, PAL.SHADOW, PAL.TEAL);
  noStroke();
  fill(PAL.SHADOW);
  rect(portX + 4, portY + 4, portW - 8, portH - 8);

  const cx = portX + portW / 2;
  const cy = portY + portH / 2 - 10;
  const headR = 32;

  if (view.id === 'ender') {
    // Ender portrait placeholder retained from the preservation build.
    fill(PAL.DUST);
    ellipse(cx, cy, headR * 2, headR * 2.1);
    stroke(PAL.TEAL);
    strokeWeight(1.5);
    noFill();
    beginShape();
    vertex(cx - 18, cy - 10); vertex(cx - 24, cy - 4);
    vertex(cx - 22, cy + 4); vertex(cx - 16, cy + 8);
    endShape();
    beginShape();
    vertex(cx + 18, cy - 10); vertex(cx + 24, cy - 4);
    vertex(cx + 22, cy + 4); vertex(cx + 16, cy + 8);
    endShape();
    line(cx - 14, cy - 18, cx + 14, cy - 18);
    noStroke();
    fill(PAL.BIO);
    ellipse(cx - 12, cy - 4, 14, 10);
    ellipse(cx + 12, cy - 4, 14, 10);
    fill(PAL.SCIOTO);
    ellipse(cx - 12, cy - 4, 8, 6);
    ellipse(cx + 12, cy - 4, 8, 6);
    fill(PAL.SOIL);
    beginShape();
    vertex(cx - 16, cy + 6); vertex(cx - 20, cy + 18);
    vertex(cx - 12, cy + 22); vertex(cx, cy + 20);
    vertex(cx + 12, cy + 22); vertex(cx + 20, cy + 18);
    vertex(cx + 16, cy + 6);
    endShape(CLOSE);
    fill(PAL.NAVY);
    ellipse(cx - 12, cy - 4, 4, 4);
    ellipse(cx + 12, cy - 4, 4, 4);
    fill(PAL.RUST);
    rect(cx - 18, cy + 22, 36, 8);
  } else {
    // Do not fabricate companion appearance before authored portrait design.
    noStroke();
    fill(view.runtimeImplemented ? PAL.DIM : PAL.SHADOW);
    ellipse(cx, cy - 4, headR * 1.7, headR * 1.7);
    fill(PAL.NAVY);
    rect(cx - 24, cy + 18, 48, 28);
    textFont(FONT_UI);
    textAlign(CENTER, CENTER);
    textSize(20);
    fill(PAL.TEAL);
    text((view.canonicalName || '?').slice(0, 1).toUpperCase(), cx, cy - 4);
    textSize(7);
    fill(PAL.DIM);
    text(view.runtimeImplemented ? 'PORTRAIT PENDING' : 'NOT IMPLEMENTED',
         cx, cy + 58);
  }

  textFont(FONT_UI);
  textSize(10);
  textAlign(LEFT, TOP);
  drawGlowText('NATIVE', sheet.classX, sheet.classY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  const nativeLabel = view.nativeJob.status === 'established' && view.nativeJob.label
    ? view.nativeJob.label
    : 'UNKNOWN';
  text(nativeLabel, sheet.classX + 52, sheet.classY);

  drawGlowText('LEVEL', sheet.levelX, sheet.levelY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  text(view.level == null ? '—' : 'Lv.' + view.level, sheet.levelX + 44, sheet.levelY);

  textFont(FONT_BODY);
  textSize(10);
  fill(PAL.DIM);
  const affinityLabel = view.affinities.status === 'established'
    ? view.affinities.ids.map(id => id.toUpperCase()).join(' · ')
    : 'AFFINITIES: UNKNOWN';
  text(affinityLabel, sheet.levelX, sheet.levelY + 20);

  // Preservation class is explicitly labeled so it cannot be confused with
  // the code-owned native-job fact.
  if (view.mechanicsTemplateName) {
    textSize(9);
    fill(PAL.DIM);
    text('Field role (temporary): ' + view.mechanicsTemplateName,
         sheet.levelX, sheet.levelY + 34);
  } else if (view.preservationClass && view.preservationClass !== nativeLabel) {
    textSize(9);
    fill(PAL.DIM);
    text('Prototype class: ' + view.preservationClass,
         sheet.levelX, sheet.levelY + 34);
  }

  textFont(FONT_BODY);
  textSize(12);
  const signed = value =>
    Number.isFinite(value) ? (value > 0 ? '+' + value : '' + value) : '—';
  const ratio = (value, max) =>
    Number.isFinite(value) && Number.isFinite(max) ? value + '/' + max : '—';
  const stats = [
    { label: 'Vit', value: ratio(view.stats.vit, view.stats.maxVit), accent: PAL.RUST },
    { label: 'Echo', value: ratio(view.stats.echoes, view.stats.echoesMax), accent: PAL.BIO },
    { label: 'Wits', value: signed(view.stats.wits), accent: PAL.SCIOTO },
    { label: 'Pres', value: signed(view.stats.presence), accent: PAL.TEAL },
    { label: 'Spirit', value: signed(view.stats.spirit), accent: PAL.TEAL },
    { label: 'Might', value: signed(view.stats.might), accent: PAL.RUST },
    { label: 'Grace', value: signed(view.stats.grace), accent: PAL.SCIOTO },
  ];
  stats.forEach((stat, i) => {
    const col = i < 4 ? 0 : 1;
    const row = i < 4 ? i : i - 4;
    const sx = sheet.statsX + col * 115;
    const sy = sheet.statsY + row * 17;
    drawGlowText(stat.label, sx, sy, PAL.TEAL, 12);
    fill(stat.accent);
    noStroke();
    text(stat.value, sx + 48, sy);
  });

  textFont(FONT_UI);
  textSize(9);
  drawGlowText(view.id === 'ender' ? 'ELIGIBLE ACTIONS' : 'RECORDED ABILITIES',
               sheet.abilitiesX, sheet.abilitiesY, PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(12);
  if (view.abilities.length === 0) {
    fill(PAL.DIM);
    text(view.runtimeImplemented ? 'No recorded abilities' : 'Not yet implemented',
         sheet.abilitiesX + 10, sheet.abilitiesY + 22);
  } else {
    view.abilities.slice(0, 8).forEach((ability, i) => {
      const col = i < 4 ? 0 : 1;
      const row = i < 4 ? i : i - 4;
      const ax = sheet.abilitiesX + 10 + col * 145;
      const ay = sheet.abilitiesY + 22 + row * 17;
      drawGlowText(ability.label, ax, ay,
                   ability.source === 'prototype-mechanics' ? PAL.DIM : PAL.TEAL,
                   12);
    });
  }

  textFont(FONT_UI);
  textSize(9);
  drawGlowText('GEAR', sheet.gearX, sheet.gearY, PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(12);
  const gear = [
    { name: 'Staff', value: view.equipment.staff || 'Unassigned' },
    { name: 'Backpack', value: view.equipment.backpack || 'Unassigned' },
  ];
  gear.forEach((item, i) => {
    const gy = sheet.gearY + 22 + i * 32;
    drawGlowText(item.name, sheet.gearX + 10, gy, PAL.BIO, 12);
    fill(PAL.DIM);
    noStroke();
    text(item.value, sheet.gearX + 10, gy + 14);
  });

  textFont(FONT_UI);
  textSize(9);
  drawGlowText('RESOURCES', sheet.resourcesX, sheet.resourcesY, PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(13);
  const resources = [
    { label: 'Scrap', value: Number.isFinite(view.resources.scrap) ? '' + view.resources.scrap : '—' },
    { label: 'Aether', value: ratio(view.resources.aether, view.resources.aetherMax) },
    { label: 'Heat', value: ratio(view.resources.heat, view.resources.heatMax) },
    { label: 'Staff', value: ratio(view.resources.staffCharges, view.resources.maxStaffCharges) },
  ];
  resources.forEach((resource, i) => {
    const rx = sheet.resourcesX + 10 + i * 112;
    drawGlowText(resource.label, rx, sheet.resourcesY + 22, PAL.SCIOTO, 13);
    fill(PAL.PARCHMENT);
    noStroke();
    text(resource.value, rx + 46, sheet.resourcesY + 22);
  });

  const rosterNames = ['ENDER', 'LYRA', 'IONIA', 'RESON', 'AEPEX'];
  textFont(FONT_UI);
  textSize(8);
  textAlign(CENTER, BOTTOM);
  const rosterNav = rosterNames
    .map((name, i) => (i === view.rosterIndex ? '[' + (i + 1) + ' ' + name + ']' : (i + 1) + ' ' + name))
    .join('   ');
  fill(PAL.DIM);
  text(rosterNav, px + pw / 2, py + ph - 28);

  pop();
}

/**
 * Minimal HUD version — smaller, top-bar style.
 */
function drawWorldHUD() {
  push();
  // Top bar — vitals + quest phase
  const hudX = 8, hudY = 8, hudW = width - 512, hudH = 52;
  
  // Panel background
  noStroke();
  fill(PAL.NAVY);
  rect(hudX, hudY, hudW, hudH);
  drawPixelBorder(hudX, hudY, hudW, hudH, 2, PAL.SHADOW, PAL.TEAL);
  
  // Character name + level
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('ENDER', hudX + 12, hudY + 8, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(9);
  text('Rift Scholar  Lv.1', hudX + 64, hudY + 8);
  
  // Vitals row
  textFont(FONT_BODY);
  textSize(12);
  const vY = hudY + 28;
  drawStatLabel('Vit', hudX + 12, vY, '13', PAL.RUST);
  drawStatLabel('Echoes', hudX + 80, vY, '3/3', PAL.BIO);
  drawStatLabel('Scrap', hudX + 160, vY, '7', PAL.DUST);
  drawStatLabel('Aether', hudX + 220, vY, '4/6', PAL.SCIOTO);
  drawStatLabel('Heat', hudX + 290, vY, '1/3', PAL.AMBER);
  
  // Right side — quest phase indicator
  const qX = hudX + hudW - 130;
  const qY = hudY + 8;
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('QUEST', qX, qY, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(10);
  text('Signal 0/3', qX + 44, qY);
  
  // Day-night mini indicator
  drawDayNightIndicator(hudX + hudW - 36, hudY + 32, 20);
  
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
function drawCombatPanel(combatState) {
  if (!combatState) return;
  push();
  const px = 8, py = 8, pw = 220, ph = 580;

  // Panel background
  fill(PAL.NAVY);
  noStroke();
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT', px + 12, py + 8, PAL.TEAL, 9);
  text('TURN ' + combatState.turn, px + pw - 60, py + 10);

  // Enemy section
  if (combatState.enemy) {
    const ey = py + 36;
    drawPixelBorder(px + 8, ey, pw - 16, 48, 2, PAL.SHADOW, PAL.RUST);
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
    text('WEAKNESS: ' + (combatState.enemy.weakness || 'unknown'), px + 14, ey + 32);
  }

  // Player status section
  const sY = py + 96;
  drawPixelBorder(px + 8, sY, pw - 16, 88, 2, PAL.SHADOW, PAL.TEAL);
  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ENDER', px + 14, sY + 6, PAL.TEAL, 8);

  // Player resources
  textFont(FONT_BODY);
  textSize(12);
  let rX = px + 14;
  const rY = sY + 24;
  // Vit
  fill(PAL.RUST);
  text('HP', rX, rY);
  rX += 20;
  fill(PAL.PARCHMENT);
  text(combatState.player.vit + '/' + combatState.player.maxVit, rX, rY);
  // Echoes
  rX += 48;
  fill(PAL.BIO);
  text('ECHO', rX, rY);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(combatState.player.echoes.current + '/' + combatState.player.echoes.max, rX, rY);
  // Aether
  rX += 52;
  fill(PAL.SCIOTO);
  text('AETHER', rX, rY);
  rX += 44;
  fill(PAL.PARCHMENT);
  text(combatState.player.aether.current + '/' + combatState.player.aether.max, rX, rY);
  // Staff charges
  rX = px + 14;
  const rY2 = sY + 48;
  fill(PAL.TEAL);
  text('STAFF', rX, rY2);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(combatState.player.staffCharges + '/' + combatState.player.maxStaffCharges, rX, rY2);
  // Scrap
  rX += 52;
  fill(PAL.DUST);
  text('SCRAP', rX, rY2);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(String(combatState.player.scrap), rX, rY2);

  // Read-only party context Phase A. Companions are visible but their action
  // declarations are deliberately non-executable until outcome contracts exist.
  if (combatState.partyContext &&
      Array.isArray(combatState.partyContext.members) &&
      combatState.partyContext.members.length === 3) {
    textFont(FONT_UI);
    textSize(6);
    const companions = combatState.partyContext.members.slice(1);
    companions.forEach((member, index) => {
      const lineY = sY + 66 + index * 10;
      fill(PAL.DIM);
      const role = member.fieldRole && member.fieldRole.name
        ? member.fieldRole.name
        : 'ROLE UNKNOWN';
      const hp = member.vit == null || member.maxVit == null
        ? 'HP —'
        : 'HP ' + member.vit + '/' + member.maxVit;
      text(
        member.canonicalName.toUpperCase() + '  ' + hp + '  ' +
        role.toUpperCase() + ' · STAGED',
        px + 14,
        lineY
      );
    });
  }

  // Actions grid — eight stable number-key slots. Locked actions stay visible
  // so progression is legible without making key bindings move.
  const aX = px + 8;
  const aY = sY + 100;
  const aW = pw - 16;
  const aH = 154;
  drawPixelBorder(aX, aY, aW, aH, 2, PAL.SHADOW, PAL.TEAL);

  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ACTIONS [1-8]', aX + 12, aY + 6, PAL.TEAL, 8);

  const actions = combatState.actions || [];
  const eligibleActionIds = new Set(
    combatState.eligibleActionIds || actions.map(action => action.id)
  );
  const actH = 16;
  const actStartY = aY + 22;
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
    ellipse(aX + 12, ay + 7, 9, 9);
    fill(PAL.NAVY);
    textFont(FONT_UI);
    textSize(7);
    textAlign(CENTER, CENTER);
    text(String(idx + 1), aX + 12, ay + 7);
    // Action label
    textFont(FONT_BODY);
    textSize(10);
    textAlign(LEFT, CENTER);
    const label = action.label || action.id;
    fill(usable ? PAL.PARCHMENT : PAL.DIM);
    noStroke();
    const statePrefix = !unlocked ? 'LOCKED · ' : (usable ? '' : 'NO RES · ');
    text(statePrefix + label.substring(0, statePrefix ? 19 : 28), aX + 24, ay + 1);
    // Cost indicator uses the exact same centralized legacy cost function as
    // runtime admission/payment.
    const totalCost = window.AetherAbilityDefs.getActionResourceCost(action);
    if (unlocked && totalCost > 0) {
      textFont(FONT_UI);
      textSize(7);
      fill(usable ? PAL.AMBER : PAL.DIM);
      text('COST: ' + totalCost, aX + aW - 62, ay + 2);
    }
    // Icon
    if (usable) drawActionIcon(aX + aW - 16, ay + 7, 14, action.id);
  });

  // Enemy special ability hint
  if (combatState.enemy && combatState.enemy.abilityDesc) {
    const abY = aY + aH + 10;
    drawPixelBorder(px + 8, abY, pw - 16, 28, 1, PAL.SHADOW, PAL.RUST);
    textFont(FONT_UI);
    textSize(7);
    fill(PAL.RUST);
    text('ENEMY ABILITY:', px + 14, abY + 5);
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
      text(l, px + 14, abY + 14 + i * 10);
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
  fill(PAL.NAVY);
  noStroke();
  rect(lx, ly, lw, lh);
  drawPixelBorder(lx, ly, lw, lh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT LOG', lx + 12, ly + 10, PAL.TEAL, 9);

  // Divider line
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  // Entries - read from combat state log if available, fallback to UI.combatLog
  textFont(FONT_BODY);
  textSize(12);
  
  let log = window.UI.combatLog;
  if (typeof combat !== 'undefined' && combat && typeof combat.getState === 'function') {
    const cs = combat.getState();
    if (cs && cs.log && Array.isArray(cs.log)) {
      log = cs.log;
    }
  }
  
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
 * @param {string} content — dialogue text (wraps)
 */
function drawNPCDialogue(npc, content) {
  push();
  window.UI.dialogueOpen = true;
  window.UI.dialogueNPC = npc;
  window.UI.dialogueText = content;

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
  const words = content.split(' ');
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
function closeDialogue() {
  if (activeDialogue) {
    activeDialogue.closed = true;
    activeDialogue = null;
  }
  stopDialogueAudio();
  window.UI.dialogueOpen = false;
  window.UI.dialogueNPC = null;
  window.UI.dialogueText = '';
  window.UI.dialogueLines = [];
  window.UI.dialogueLineIndex = 0;
  window.UI.dialogueAudioNPC = null;
  window.UI.dialogueAudioBatch = null;
  window.UI.dialogueAudioPlayed = false;
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
function closeShop() {
  if (typeof shop !== 'undefined' && shop) shop.open = false;
  window.UI.shopOpen = false;
  window.UI.shopItems = [];
  window.UI.shopBuyHandler = null;
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
  const sub = phase === 'INITIATIVE' ? 'Roll Grace + Wits for turn order' :
              phase === 'ACTION' ? 'Choose action — main or secondary' :
              phase === 'RESOLUTION' ? 'Roll 2D6 + relevant stat' :
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
  drawDayNightIndicator(width - 56, 44, 28);

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
  drawScreenFlash();

  // Scanlines on top of everything
  drawScanlines();

  pop();
}

// ─────────────────────────────────────────────
// MODULE INIT
// ─────────────────────────────────────────────
console.log('[UI] Aetherwake UI module loaded —',
            Object.keys(window.UI).join(', '));

function drawScreenFlash() {
  if (!screenFlash.active) return;
  const age = millis() - screenFlash.startTime;
  if (age > screenFlash.duration) {
    screenFlash.active = false;
    return;
  }
  const t = 1 - age / screenFlash.duration;
  const alpha = t * screenFlash.intensity;
  noStroke();
  fill(color(255, 255, 255, alpha));
  rect(0, 0, width, height);
}


