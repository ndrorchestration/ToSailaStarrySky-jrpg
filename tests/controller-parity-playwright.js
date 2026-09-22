'use strict';

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const BASE = path.resolve(__dirname, '..');
const PORT = Number(process.env.AETHERWAKE_CONTROLLER_TEST_PORT || 8093);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function createServer() {
  return http.createServer((req, res) => {
    const parsed = new URL(req.url, `http://127.0.0.1:${PORT}`);
    let requested = decodeURIComponent(parsed.pathname);
    if (requested === '/') requested = '/index-embedded.html';
    const relative = requested.replace(/^\/+/, '');
    const fullPath = path.resolve(BASE, relative);
    if (!fullPath.startsWith(BASE + path.sep) && fullPath !== BASE) {
      res.writeHead(403); res.end('Forbidden'); return;
    }
    fs.readFile(fullPath, (err, data) => {
      if (err) { res.writeHead(404); res.end('Not found'); return; }
      const mime = {
        '.html': 'text/html; charset=utf-8',
        '.js': 'application/javascript; charset=utf-8',
        '.css': 'text/css; charset=utf-8',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.mp3': 'audio/mpeg',
        '.svg': 'image/svg+xml',
      }[path.extname(fullPath).toLowerCase()] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      res.end(data);
    });
  });
}

async function pulseButton(page, index) {
  await page.evaluate(i => window.__awTestPadSetButton(i, true), index);
  await page.waitForTimeout(80);
  await page.evaluate(i => window.__awTestPadSetButton(i, false), index);
  await page.waitForTimeout(80);
}

async function setAxes(page, x, y) {
  await page.evaluate(({ x, y }) => window.__awTestPadSetAxes(x, y), { x, y });
  await page.waitForTimeout(80);
}

(async () => {
  const server = createServer();
  await new Promise(resolve => server.listen(PORT, '127.0.0.1', resolve));

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const errors = [];

  page.on('pageerror', err => errors.push(`PAGE: ${err.message}`));
  page.on('requestfailed', request => {
    errors.push(`REQUEST: ${request.url()} — ${request.failure()?.errorText || 'failed'}`);
  });
  page.on('response', response => {
    if (response.status() < 400) return;
    if (/\/tts\/[^/]+\/[^/]+\/\d+\.mp3(?:\?.*)?$/.test(response.url())) return;
    errors.push(`HTTP ${response.status()} ${response.url()}`);
  });
  page.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('Failed to load resource')) {
      errors.push(`CONSOLE: ${msg.text()}`);
    }
  });

  await page.addInitScript(() => {
    const pad = {
      index: 0,
      id: 'Aetherwake Test Standard Gamepad',
      connected: true,
      mapping: 'standard',
      timestamp: 0,
      axes: [0, 0, 0, 0],
      buttons: Array.from({ length: 17 }, () => ({ pressed: false, touched: false, value: 0 }))
    };
    window.__awTestPad = pad;
    window.__awTestPadSetButton = function(index, pressed) {
      pad.buttons[index].pressed = Boolean(pressed);
      pad.buttons[index].touched = Boolean(pressed);
      pad.buttons[index].value = pressed ? 1 : 0;
      pad.timestamp += 1;
    };
    window.__awTestPadSetAxes = function(x, y) {
      pad.axes[0] = x;
      pad.axes[1] = y;
      pad.timestamp += 1;
    };
    Object.defineProperty(Navigator.prototype, 'getGamepads', {
      configurable: true,
      value: function() { return [pad]; }
    });
  });

  try {
    const response = await page.goto(
      `http://127.0.0.1:${PORT}/index-embedded.html`,
      { waitUntil: 'domcontentloaded', timeout: 20000 }
    );
    assert(response && response.ok(), 'controller parity entrypoint did not load');
    await page.waitForSelector('canvas', { timeout: 15000 });
    await page.waitForFunction(() =>
      window.__awRuntimeReady === true &&
      window._gamepadInput &&
      window._focusManager &&
      window._userSettingsSystem
    , undefined, { timeout: 15000 });

    // Controller Menu button opens Settings directly from BOOT.
    await pulseButton(page, 9);
    await page.waitForFunction(() => window.gameState === 'settings', undefined, { timeout: 5000 });
    let settingsState = await page.evaluate(() => ({
      focus: window._settingsMenuFocus && window._settingsMenuFocus.focusedId,
      storage: window._userSettingsStorage,
    }));
    assert(settingsState.focus === 'textScale', 'Settings did not begin on deterministic first focus');

    // Navigate to Reduced Motion and toggle it through controller Confirm.
    await pulseButton(page, 13);
    await pulseButton(page, 13);
    await page.waitForFunction(() =>
      window._settingsMenuFocus && window._settingsMenuFocus.focusedId === 'reducedMotion'
    , undefined, { timeout: 5000 });
    await pulseButton(page, 0);
    await page.waitForFunction(() =>
      window._userSettings &&
      window._userSettings.reducedMotion === true &&
      window._appliedAccessibilitySettings &&
      window._appliedAccessibilitySettings.reducedMotion === true
    , undefined, { timeout: 5000 });

    const persisted = await page.evaluate(() => {
      const raw = localStorage.getItem('aetherwake.settings.v1');
      return raw ? JSON.parse(raw) : null;
    });
    assert(persisted && persisted.settings && persisted.settings.reducedMotion === true,
      'controller Settings change did not persist independently');

    // Cancel returns to title/menu; Confirm starts authored First Wake.
    await pulseButton(page, 1);
    await page.waitForFunction(() => window.gameState === 'menu', undefined, { timeout: 5000 });
    await pulseButton(page, 0);
    await page.waitForFunction(() =>
      window.gameState === 'opening' &&
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).sequence === 0
    , undefined, { timeout: 5000 });

    // Advance Sequences 00–09 with controller Confirm only.
    for (let i = 0; i < 10; i++) await pulseButton(page, 0);
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });
    const openingResult = await page.evaluate(() => ({
      complete: window._firstWakeOpeningState.complete,
      activeIds: window.ACTIVE_PARTY.map(character => character.id)
    }));
    assert(openingResult.complete === true, 'controller did not complete authored opening');
    assert(openingResult.activeIds.join('|') === 'ender|lyra',
      'controller opening lost authored Ender + Lyra party state');

    // Held standard-stick movement uses the semantic repeat path.
    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 16; p.tileY = 16; p.x = 16; p.y = 16; p.px = 16 * 16; p.py = 16 * 16;
    });
    await setAxes(page, 0.8, 0);
    await page.waitForFunction(() => window._world.player.tileX > 16, undefined, { timeout: 5000 });
    await setAxes(page, 0, 0);

    // Single-press controller Save/Load route: Menu opens the focused overlay.
    const savePosition = await page.evaluate(() => ({
      tileX: window._world.player.tileX,
      tileY: window._world.player.tileY,
    }));
    await pulseButton(page, 9);
    await page.waitForFunction(() =>
      window.gameState === 'saveload' &&
      window._saveMenuFocus &&
      window._saveMenuFocus.focusedId === 'manual-1'
    , undefined, { timeout: 5000 });

    // Confirm in default Save mode writes manual-1 and reopens on the same focus.
    await pulseButton(page, 0);
    await page.waitForFunction(() =>
      window.gameState === 'saveload' &&
      window._latestSaveMeta &&
      window._latestSaveMeta.slot === 'manual-1' &&
      window._saveMenuFocus &&
      window._saveMenuFocus.focusedId === 'manual-1'
    , undefined, { timeout: 5000 });

    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 25; p.tileY = 25; p.x = 25; p.y = 25;
      p.px = 25 * 16; p.py = 25 * 16;
    });

    // D-pad right switches to Load mode; Confirm restores the same focused slot.
    await pulseButton(page, 15);
    await pulseButton(page, 0);
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });
    const loadedPosition = await page.evaluate(() => ({
      tileX: window._world.player.tileX,
      tileY: window._world.player.tileY,
    }));
    assert(loadedPosition.tileX === savePosition.tileX &&
           loadedPosition.tileY === savePosition.tileY,
      'controller Save/Load overlay did not restore the saved world position');

    // Controller opens and closes a read-only overlay.
    await pulseButton(page, 3);
    await page.waitForFunction(() => window.gameState === 'questlog', undefined, { timeout: 5000 });
    await pulseButton(page, 1);
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    // Controller Interact opens dialogue; controller Cancel closes it.
    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 7; p.tileY = 7; p.x = 7; p.y = 7; p.px = 7 * 16; p.py = 7 * 16;
    });
    await pulseButton(page, 0);
    await page.waitForFunction(() => window.gameState === 'dialogue', undefined, { timeout: 5000 });
    await pulseButton(page, 1);
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    // Real controller boarding path near the ship.
    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 23; p.tileY = 10; p.x = 23; p.y = 10; p.px = 23 * 16; p.py = 10 * 16;
    });
    await pulseButton(page, 2);
    await page.waitForFunction(() => window.gameState === 'airship', undefined, { timeout: 5000 });

    const flightBefore = await page.evaluate(() => ({
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
      altitude: window._airNavigationState.altitude,
      moored: window._airNavigationState.mooredLandmarkId
    }));
    assert(flightBefore.moored === 'wake-dock', 'controller boarding did not begin at Wake Dock');

    // Right trigger raises altitude.
    await pulseButton(page, 7);
    const altitudeAfter = await page.evaluate(() => window._airNavigationState.altitude);
    assert(altitudeAfter === 'high', 'controller right trigger did not raise altitude');

    // Cast off and move one step, still close enough to re-dock.
    await setAxes(page, 0.8, 0);
    await page.waitForFunction(x => window._airNavigationState.x > x, flightBefore.x, { timeout: 5000 });
    await setAxes(page, 0, 0);
    assert(await page.evaluate(() => window._airNavigationState.mooredLandmarkId === null),
      'controller movement did not cast off');

    await pulseButton(page, 0);
    await page.waitForFunction(() =>
      window._airNavigationState.mooredLandmarkId === 'wake-dock'
    , undefined, { timeout: 5000 });

    // East button is context-prioritized to Land in AIRSHIP.
    await pulseButton(page, 1);
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    // Controller combat uses deterministic semantic focus rather than numeric-key emulation.
    await page.evaluate(() => {
      if (typeof startCombat !== 'function') throw new Error('startCombat unavailable');
      startCombat('skyPredator');
    });
    await page.waitForFunction(() =>
      window.gameState === 'combat' &&
      window._combatActionFocus &&
      window._combatActionFocus.focusedId === 'staffStrike'
    , undefined, { timeout: 5000 });

    await pulseButton(page, 13);
    await page.waitForFunction(() =>
      window._combatActionFocus && window._combatActionFocus.focusedId === 'uncoverTruth'
    , undefined, { timeout: 5000 });

    await pulseButton(page, 12);
    await page.waitForFunction(() =>
      window._combatActionFocus && window._combatActionFocus.focusedId === 'staffStrike'
    , undefined, { timeout: 5000 });

    const combatTurnBefore = await page.evaluate(() => window._combat.getState().turn);
    await pulseButton(page, 0);
    await page.waitForFunction(before => window._combat.getState().turn > before,
      combatTurnBefore, { timeout: 5000 });

    const combatFocusResult = await page.evaluate(() => ({
      turn: window._combat.getState().turn,
      focusedId: window._combatActionFocus && window._combatActionFocus.focusedId,
      encounterOver: window._combat.getState().encounterOver
    }));
    assert(combatFocusResult.turn > combatTurnBefore,
      'controller Confirm did not execute the focused combat action');
    assert(combatFocusResult.focusedId === 'staffStrike',
      'combat focus did not remain stable after action execution');

    await page.evaluate(() => finishCombat());
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    if (errors.length) throw new Error('controller parity browser errors:\n' + errors.join('\n'));

    const final = await page.evaluate(() => ({
      gameState: window.gameState,
      reducedMotion: window._userSettings.reducedMotion,
      lastGamepadPoll: window._lastGamepadPoll,
      lastDispatchHandled: window._lastGamepadDispatchHandled
    }));
    assert(final.gameState === 'world', 'controller parity path did not end in stable WORLD');
    assert(final.reducedMotion === true, 'controller-configured setting was not retained');

    console.log('Aetherwake controller parity smoke: PASS');
    console.log(JSON.stringify({ openingResult, savePosition, loadedPosition, flightBefore, altitudeAfter, combatFocusResult, final }));
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
