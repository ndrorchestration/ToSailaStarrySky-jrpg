// NON_RUNTIME_MIRROR
// modules/core.js is NOT loaded by the playable Aetherwake entrypoints.
// Changes here do NOT change the current game runtime.
// Playable runtime authority: ../aetherwake.js
// Runtime authority contract: ../docs/RUNTIME_AUTHORITY.md
// Retain only as a historical/modular mirror until explicitly extracted or retired.

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
};

// ── State ──
const STATE = {
  BOOT: 'boot', MENU: 'menu', WORLD: 'world', COMBAT: 'combat',
  DIALOGUE: 'dialogue', SHOP: 'shop', LEDGER: 'ledger',
  QUESTLOG: 'questlog', CHARSHEET: 'charsheet',
};
let gameState = STATE.BOOT;
window.gameState = gameState;  // expose for debug
let prevState = null;
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
function setup() {
  window._setupOrder = window._setupOrder ? window._setupOrder + '→setup-start' : 'setup-start';
  const canvas = createCanvas(960, 640);
  window._setupOrder = window._setupOrder + '→canvas-done';
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
  if (typeof window.AetherWorld !== 'undefined') {
    world = window.AetherWorld(p5, C);
    window._world = world;
    if (world && typeof world.init === 'function') world.init();
  }
  window._setupOrder = window._setupOrder + '→combat-start';
  if (typeof window.AetherCombat !== 'undefined') {
    combat = new window.AetherCombat(p5, C);
    window._combat = combat;
    if (combat && typeof combat.init === 'function') combat.init();
  }
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

  // Auto-start from MENU after 3s idle — bridges the BOOT→MENU→WORLD gap
  // so a single N press (or no press) still reaches the world.
  if (gameState === STATE.MENU && menuAutoStartTimer === 0) {
    menuAutoStartTimer = millis();
  } else if (gameState === STATE.MENU &&
             menuAutoStartTimer > 0 &&
             millis() - menuAutoStartTimer > 3000) {
    startGame();
  }

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
  else if (gameState === STATE.WORLD) {
    if (world && typeof world.update === 'function') world.update(dt / 1000);
    if (world && typeof world.render === 'function') world.render();
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
    // Override the dialogue text with the type-in version
    if (window.UI.dialogueText) {
      window.UI.dialogueText = dialogueTypeIn.displayText;
    }
  }

  drawScanlines();
}

// ── Input ──
// Interaction key for world module (set by keyPressed, read by world.interact)
let interactionKey = null;

function keyPressed() {
  keys[keyCode] = true;
  keysPressed[keyCode] = true;
  handleInput();

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
    // C = 67: start combat encounter (dev/testing)
    else if (keyCode === 67) {
      if (combat && typeof combat.beginEncounter === 'function') {
        startCombat('skyPredator');
      }
    }
  }
  // Shop buy-by-number (1-9)
  if (gameState === STATE.SHOP) {
    if (typeof key === 'string' && key >= '1' && key <= '9') {
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
  if (gameState === STATE.MENU) {
    if (key === 'n' || key === 'N' || key === 'Enter' || key === ' ') {
      startGame();
    }
    // Remove return; to allow fall-through from BOOT→MENU→WORLD in same key event
  }
  if (gameState === STATE.WORLD) {
    if (key === 'c' || key === 'C') {
      if (combat && typeof combat.beginEncounter === 'function') {
        startCombat('skyPredator');
      }
    }
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
    // Start game on Enter/Space/N (from both keyPressed path and character path).
    // For headless Chromium (Playwright testing): keyTyped may not fire reliably
    // for letter keys, so also handle keyPressed keyCode path explicitly.
    if (keysPressed[13] || keysPressed[32] || keysPressed[78] || keysPressed[110] ||
        (typeof key !== 'undefined' && (key === 'Enter' || key === ' ' || key === 'n' || key === 'N'))) {
      startGame();
    }
    return;
  }

  if (gameState === STATE.WORLD) {
    handleWorldInput();
  }
  else if (gameState === STATE.COMBAT) {
    if (combat && typeof combat.handleInput === 'function') {
      combat.handleInput(keys, keysPressed);
    }
    // Number keys 1-5 trigger combat actions
    if (typeof key === 'string' && key >= '1' && key <= '5' && combat && typeof combat.resolveTurn === 'function') {
      const actionId = ['staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold'][key.charCodeAt(0) - 49];
      if (actionId) {
        combat.resolveTurn(actionId, null);
      }
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
  // WASD movement with key repeat
  const now = millis();
  const delay = 200, rate = 60;

  for (const code of [UP_ARROW, DOWN_ARROW, LEFT_ARROW, RIGHT_ARROW]) {
    if (keys[code]) {
      if (!keyRepeat[code]) {
        keyRepeat[code] = now;
        keyRepeatFirst[code] = true;
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
    if (world && typeof world.boardShip === 'function') world.boardShip();
  }
  if (keysPressed[9]) {    // Tab
    if (world && typeof world.toggleLayer === 'function') world.toggleLayer();
  }
  if (keysPressed[76]) {   // L
    openState(STATE.LEDGER);
  }
  if (keysPressed[77]) {   // M
    openState(STATE.SHOP);
  }
  if (keysPressed[82]) {   // R
    openState(STATE.CHARSHEET);
  }
  if (keysPressed[84]) {   // T
    openState(STATE.QUESTLOG);
  }
  // C: start combat encounter (dev/testing — triggers a Sky-Predator fight)
  if (keysPressed[67]) {   // C
    if (combat && typeof combat.beginEncounter === 'function') {
      startCombat('skyPredator');
    }
  }
  if (keysPressed[27]) {   // ESC
    closeOverlay();
  }
}

function doMove(code) {
  if (!world || typeof world.movePlayer !== 'function') return;
  if (code === UP_ARROW)    world.movePlayer(0, -1);
  if (code === DOWN_ARROW)  world.movePlayer(0, 1);
  if (code === LEFT_ARROW)  world.movePlayer(-1, 0);
  if (code === RIGHT_ARROW) world.movePlayer(1, 0);
}

function startGame() {
  // DO NOT call world.init() again — it was called in setup() and resets
  // the player, NPCs, quest, shop, and ledger to initial state. We only
  // transition to WORLD state so the draw/update loop starts rendering.
  if (combat && typeof combat.init === 'function') {
    combat.init({
      vit: world.player.vit,
      scrap: world.player.scrap,
      aether: { current: world.player.aether, max: world.player.aetherMax },
      heat: { current: world.player.heat, max: world.player.heatMax },
      echoes: { current: world.player.echoes, max: world.player.echoesMax },
      charges: world.player.staffCharges,
      staffMax: 2,
      aetherMax: world.player.aetherMax,
      heatMax: world.player.heatMax,
      echoesMax: world.player.echoesMax,
      level: world.player.level,
      xp: world.player.xp,
      xpToNext: world.player.xpToNext,
      unlockedAbilities: world.player.unlockedAbilities,
      equipment: world.player.equipment,
    });
  }
  gameState = STATE.WORLD;
  window.gameState = gameState;
  prevState = null;
}

// ── Combat launcher: triggers an encounter ──
function startCombat(enemyId) {
  if (!combat || !world) return;
  combat.init({
    vit: world.player.vit,
    scrap: world.player.scrap,
    aether: { current: world.player.aether, max: world.player.aetherMax },
    heat: { current: world.player.heat, max: world.player.heatMax },
    echoes: { current: world.player.echoes, max: world.player.echoesMax },
    charges: world.player.staffCharges,
    staffMax: 2,
    aetherMax: world.player.aetherMax,
    heatMax: world.player.heatMax,
    echoesMax: world.player.echoesMax,
    level: world.player.level,
    xp: world.player.xp,
    xpToNext: world.player.xpToNext,
    unlockedAbilities: world.player.unlockedAbilities,
    equipment: world.player.equipment,
  });
  combat.beginEncounter(enemyId || 'skyPredator');
  gameState = STATE.COMBAT;
  window.gameState = gameState;
}

function openState(s) {
  prevState = gameState;
  gameState = s;
  window.gameState = gameState;
  // Fade transition between states
  if (VIS.fadeTransitions) {
    startFade(150);  // quick fade-in overlay
  }
}

function closeOverlay() {
  if (prevState) {
    gameState = prevState;
    window.gameState = gameState;
    prevState = null;
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
function triggerCombatHitFeedback(enemyDmg, playerDmg, rollTotal, isPlayerAttack) {
  // Screen shake on any damage
  const shakeIntensity = Math.min(8, 2 + (enemyDmg || 0) * 1.2 + (playerDmg || 0) * 0.8);
  if (shakeIntensity > 1) {
    triggerShake(shakeIntensity, 160 + Math.min(120, (enemyDmg || 0) * 20));
  }
  // Hit stop on critical hit (10+)
  if (VIS.hitStop && rollTotal >= 10) {
    triggerHitStop(110);
  }
  // Audio
  if (isPlayerAttack) {
    if (enemyDmg > 0) window.playCombatHit();
  }
  if (playerDmg > 0) {
    window.playDamageTaken();
  }
}

/** Notify that an ability resolved — success or fail sound. */
function triggerAbilityFeedback(success) {
  if (success) {
    window.playAbilitySuccess();
  } else {
    window.playAbilityFail();
  }
}

/** Notify quest state change. */
function triggerQuestAdvance() {
  window.playQuestAdvance();
  showToast('QUEST ADVANCED', [42, 255, 181], 1800);
}

/** Notify level up. */
function triggerLevelUp() {
  window.playLevelUp();
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
      'The skies remember what the earth forgot.',
      '',
      'Above Columbus, the archipelago of fallen islands',
      'hangs in the aether \u2014 seventeen shards of a world',
      'that broke its own gravity.',
      '',
      'Beneath them, the last aether-core still hums.',
      'A ship that lifted cities and has not come down.',
      '',
      'You are Ender. Deckhand. Engineer-in-training.',
      'You carry the song in your bones.',
      '',
      'The Aureate Wake, the last solarpunk airship,',
      'has chosen you to finish it.',
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
  text('THE SKIES REMEMBER', cx, cy + 25);
  
  textSize(13 * v);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * v);
  text('YOUNG ENDER\u2019S JOURNEY', cx, cy + 48);
  
  textSize(14 * v);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160 * v);
  text('NEW GAME \u2014 N or ENTER', cx, cy + 78);
  
  textSize(11 * v);
  fill(C.rust[0], C.rust[1], C.rust[2], 140 * v);
  text('WASD  move  |  E  talk  |  Q  covenant  |  F  ship  |  Tab  sky/ground', cx, cy + 100);
  text('L  ledger  |  M  shop  |  R  char sheet  |  T  quest log', cx, cy + 118);
  
  textFont('Press Start 2P');
  textSize(8 * v);
  fill(C.teal[0], C.teal[1], C.teal[2], 100 * v);
  text('AETHERWAKE // YOUNG ENDER  //  TURN-BASED 2D6 PbtA', cx, height - 20);
  
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
  text('THE SKIES REMEMBER', cx, cy + 25);

  textSize(13);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
  text('YOUNG ENDER\'S JOURNEY', cx, cy + 48);

  textSize(14);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
  text('NEW GAME — N or ENTER', cx, cy + 78);

  textSize(11);
  fill(C.rust[0], C.rust[1], C.rust[2], 140);
  text('WASD  move  |  E  talk  |  Q  covenant  |  F  ship  |  Tab  sky/ground', cx, cy + 100);
  text('L  ledger  |  M  shop  |  R  char sheet  |  T  quest log', cx, cy + 118);

  textFont('Press Start 2P');
  textSize(8);
  fill(C.teal[0], C.teal[1], C.teal[2], 100);
  text('AETHERWAKE // YOUNG ENDER  //  TURN-BASED 2D6 PbtA', cx, height - 20);
}

function drawDialogueOverlay() {
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2], 180);
  rect(0, 0, width, height);

  const bx = width/2 - 240, by = height - 100, bw = 480, bh = 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(bx, by, bw, bh);
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
  drawPixelBorder(sx, sy, sw, sh, 3);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text('REPAIR CAFE \u2014 SHOP', sx + 16, sy + 12);

  const scrap = combat ? combat.getScrap ? combat.getScrap() : 7 : 7;
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
    fill(buyable ? C.parchment[0] : C.rust[0], buyable ? C.parchment[1] : C.rust[1], buyable ? C.parchment[2] : C.rust[2]);
    text(item.name, sx + 20, iy + 5);
    fill(C.rust[0], C.rust[1], C.rust[2], 100);
    textSize(10);
    text(item.desc || '', sx + 20, iy + 16);
    textSize(12);

    fill(buyable ? C.teal[0] : C.rust[0], buyable ? C.teal[1] : C.rust[1], buyable ? C.teal[2] : C.rust[2], buyable ? 180 : 60);
    text('[' + (i+1) + '] ' + item.cost + ' scrap', sx + sw - 80, iy + 5);
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

  const lx = 40, ly = 40, lw = width - 80, lh = height - 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(lx, ly, lw, lh);
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

  const qx = 40, qy = 40, qw = width - 80, qh = height - 80;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(qx, qy, qw, qh);
  drawPixelBorder(qx, qy, qw, qh, 2);

  textFont('Press Start 2P');
  textSize(10);
  fill(C.teal[0], C.teal[1], C.teal[2], 200);
  text('QUEST LOG — THE ISLAND THAT FALLS UPWARD', qx + 16, qy + 12);

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
    text('Hooks: ' + qs.hooksCompleted + '/3  |  Hazards: ' + qs.hazardsCompleted + '/3', qx + 16, y);
    y += 18;
    text('NPCs: ' + (qs.npcsMet ? qs.npcsMet.length : 0) + '/4  |  Choice: ' + (qs.choiceMade || 'none'), qx + 16, y);
    y += 24;
    textSize(11);
    if (qs.state === 'signal')      text('Signal — receive the call from the falling island.', qx + 16, y);
    else if (qs.state === 'crossing') text('Crossing — three hazards on the way to the island.', qx + 16, y);
    else if (qs.state === 'contact')  text('Contact — four souls await on the island.', qx + 16, y);
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

  const px = 20, py = 20, pw = width - 40, ph = height - 40;
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3);

  if (typeof drawCharSheet === 'function') {
    drawCharSheet(px, py, pw, ph);
  } else {
    textFont('Press Start 2P');
    textSize(10);
    fill(C.teal[0], C.teal[1], C.teal[2], 180);
    text('ENDER — Deckhand / Engineer-in-training', px + 20, py + 24);
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

function wrapText(text, x, y, maxWidth) {
  const words = text.split(' ');
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
  const nightFactor = window._isNight ? 0.6 : 0.18;
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
