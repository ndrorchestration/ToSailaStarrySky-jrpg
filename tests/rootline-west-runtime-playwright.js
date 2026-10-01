'use strict';

const assert = require('assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');
const saveSystem = require('../modules/save-system.js');
const air = require('../modules/air-navigation.js');

const ROOT = path.resolve(__dirname, '..');
const PORT = 4193;
const STORAGE_KEY = 'aetherwake.save.v1.manual-1';

function server() {
  return http.createServer((req, res) => {
    const parsed = new URL(req.url, 'http://127.0.0.1:' + PORT);
    let requested = decodeURIComponent(parsed.pathname);
    if (requested === '/') requested = '/index-embedded.html';
    const relative = requested.replace(/^\/+/, '');
    const full = path.resolve(ROOT, relative);
    if (!full.startsWith(ROOT + path.sep) && full !== ROOT) {
      res.writeHead(403); res.end('Forbidden'); return;
    }
    fs.readFile(full, (err, data) => {
      if (err) { res.writeHead(404); res.end('Not found'); return; }
      const mime = {
        '.html':'text/html; charset=utf-8',
        '.js':'application/javascript; charset=utf-8',
        '.css':'text/css; charset=utf-8',
        '.png':'image/png',
        '.svg':'image/svg+xml',
        '.mp3':'audio/mpeg',
      }[path.extname(full).toLowerCase()] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      res.end(data);
    });
  });
}

function makeStartingV1Envelope() {
  const fixture = JSON.parse(fs.readFileSync(
    path.join(ROOT, 'tests', 'fixtures', 'saves', 'schema-v1-manual-1.json'),
    'utf8'
  ));
  fixture.world = fixture.world || fixture.payload.world;
  fixture.payload.runtime.scene = 'world';
  fixture.payload.world.playerPosition = {
    tileX: 23,
    tileY: 10,
    px: 23 * 16,
    py: 10 * 16,
  };
  fixture.payload.airNavigation = air.exportPersistentState(air.createState({
    x: 8,
    y: 22,
    altitude: 'cruise',
    speed: 0,
    discoveredRoutes: ['rootline-west'],
    mooredLandmarkId: 'wake-dock',
  }));
  const body = { ...fixture };
  delete body.checksum;
  fixture.checksum = saveSystem.checksum(body);
  saveSystem.validateEnvelopeIntegrity(fixture);
  return fixture;
}

async function reachMenu(page) {
  await page.waitForFunction(() => window.__awRuntimeReady === true,
    undefined, { timeout: 15000 });
  await page.waitForTimeout(1400);
  for (let i = 0; i < 8; i++) {
    if (await page.evaluate(() => window.gameState === 'menu')) return;
    await page.waitForTimeout(700);
    await page.keyboard.press('Enter');
  }
  await page.waitForFunction(() => window.gameState === 'menu',
    undefined, { timeout: 5000 });
}

(async () => {
  const srv = server();
  await new Promise(resolve => srv.listen(PORT, '127.0.0.1', resolve));
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const errors = [];

  page.on('pageerror', err => errors.push('PAGE: ' + err.message));
  page.on('console', msg => {
    if (msg.type() === 'error' &&
        !msg.text().includes('Failed to load resource') &&
        !msg.text().includes('title audio')) {
      errors.push('CONSOLE: ' + msg.text());
    }
  });

  try {
    const initial = makeStartingV1Envelope();
    await page.addInitScript(({ key, value }) => {
      window.localStorage.setItem(key, value);
    }, { key: STORAGE_KEY, value: JSON.stringify(initial) });

    let response = await page.goto('http://127.0.0.1:' + PORT + '/index-embedded.html',
      { waitUntil: 'domcontentloaded', timeout: 20000 });
    assert(response && response.ok(), 'Rootline browser runtime did not load');
    await reachMenu(page);

    // Production Continue path migrates the schema-v1 fixture into the v2 runtime.
    await page.keyboard.press('c');
    await page.waitForFunction(() => window.gameState === 'world',
      undefined, { timeout: 5000 });
    const migrated = await page.evaluate(() => ({
      schema: window._lastLoadResult && window._lastLoadResult.envelope.schemaVersion,
      x: window._world.player.tileX,
      y: window._world.player.tileY,
      discoveredRoutes: window._airNavigationState.discoveredRoutes.slice(),
      condition: window._routeNetwork.conditionFor(window._routeNetworkState, 'rootline-west'),
    }));
    assert.strictEqual(migrated.schema, 2, 'Continue did not migrate schema v1 to v2');
    assert.deepStrictEqual(migrated.discoveredRoutes, ['rootline-west']);
    assert.strictEqual(migrated.condition, 'open');
    assert.strictEqual(migrated.x, 23);
    assert.strictEqual(migrated.y, 10);

    // Real WORLD input: F boards the Wake and enters AIRSHIP.
    await page.keyboard.press('f');
    await page.waitForFunction(() => window.gameState === 'airship',
      undefined, { timeout: 3000 });

    // Real AIRSHIP input: R deliberately engages the known open lane.
    await page.keyboard.press('r');
    await page.waitForFunction(() => window._activeRouteAssistId === 'rootline-west',
      undefined, { timeout: 3000 });

    const assistedBefore = await page.evaluate(() => ({
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
    }));
    await page.keyboard.press('ArrowRight');
    const assistedAfter = await page.evaluate(() => ({
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
      assist: window._activeRouteAssistId,
    }));
    const assistedDistance = Math.hypot(
      assistedAfter.x - assistedBefore.x,
      assistedAfter.y - assistedBefore.y
    );
    assert(assistedDistance > 1,
      'engaged Rootline West did not move farther than ordinary free flight');
    assert.strictEqual(assistedAfter.assist, 'rootline-west');

    // Deliberate disengage restores ordinary free flight.
    await page.keyboard.press('r');
    assert.strictEqual(await page.evaluate(() => window._activeRouteAssistId), null);
    const freeBefore = await page.evaluate(() => ({
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
    }));
    await page.keyboard.press('ArrowRight');
    const freeAfter = await page.evaluate(() => ({
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
    }));
    const freeDistance = Math.hypot(freeAfter.x - freeBefore.x, freeAfter.y - freeBefore.y);
    assert(assistedDistance > freeDistance,
      'lane assist did not provide a measurable benefit over free flight');

    // Navigate close to the authored upper trace using ordinary flight.
    await page.keyboard.press('ArrowUp');
    await page.keyboard.press('ArrowUp');
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('e'); // cruise -> high; production altitude input scans clues.

    await page.waitForFunction(() =>
      window._routeNetworkState.discoveredClues.includes('rootline-west-upper-trace'),
      undefined, { timeout: 3000 });

    const trace = await page.evaluate(() => ({
      altitude: window._airNavigationState.altitude,
      x: window._airNavigationState.x,
      y: window._airNavigationState.y,
      clues: window._routeNetworkState.discoveredClues.slice(),
    }));
    assert.strictEqual(trace.altitude, 'high');

    // Real AIRSHIP input: F confirms the in-range trace and persists the bounded precedent.
    await page.keyboard.press('f');
    await page.waitForFunction(() =>
      window._routeNetwork.conditionFor(window._routeNetworkState, 'rootline-west') === 'shifted',
      undefined, { timeout: 3000 });

    const shifted = await page.evaluate(() => ({
      condition: window._routeNetwork.conditionFor(window._routeNetworkState, 'rootline-west'),
      precedents: window._routeNetworkState.precedents.slice(),
      assist: window._activeRouteAssistId,
    }));
    assert.strictEqual(shifted.condition, 'shifted');
    assert(shifted.precedents.includes('LOCAL_ROUTE_ASSISTANCE'));
    assert.strictEqual(shifted.assist, null);

    // SHIFTED routes must refuse ordinary lane assist.
    await page.keyboard.press('r');
    assert.strictEqual(await page.evaluate(() => window._activeRouteAssistId), null,
      'shifted Rootline West re-engaged ordinary lane assist');

    // Real AIRSHIP manual save path.
    await page.keyboard.press('F5');
    await page.waitForFunction(() => window.gameState === 'saveload',
      undefined, { timeout: 3000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window._lastSaveResult &&
      window._lastSaveResult.envelope &&
      window._lastSaveResult.envelope.slot === 'manual-1',
      undefined, { timeout: 3000 });

    const saved = await page.evaluate(() => {
      const loaded = window.AetherSaveSystem.load('manual-1');
      return {
        schema: loaded.envelope.schemaVersion,
        scene: loaded.envelope.payload.runtime.scene,
        routeNetwork: JSON.parse(JSON.stringify(loaded.envelope.payload.routeNetwork)),
      };
    });
    assert.strictEqual(saved.schema, 2);
    assert.strictEqual(saved.scene, 'airship');
    assert.strictEqual(saved.routeNetwork.operationalStates['rootline-west'], 'shifted');
    assert(saved.routeNetwork.discoveredClues.includes('rootline-west-upper-trace'));
    assert(saved.routeNetwork.precedents.includes('LOCAL_ROUTE_ASSISTANCE'));

    // Full runtime restart: persisted route consequence must survive Continue.
    await page.reload({ waitUntil: 'domcontentloaded', timeout: 20000 });
    await reachMenu(page);
    await page.keyboard.press('c');
    await page.waitForFunction(() => window.gameState === 'airship',
      undefined, { timeout: 5000 });

    const restored = await page.evaluate(() => ({
      condition: window._routeNetwork.conditionFor(window._routeNetworkState, 'rootline-west'),
      clues: window._routeNetworkState.discoveredClues.slice(),
      precedents: window._routeNetworkState.precedents.slice(),
      assist: window._activeRouteAssistId,
    }));
    assert.strictEqual(restored.condition, 'shifted');
    assert(restored.clues.includes('rootline-west-upper-trace'));
    assert(restored.precedents.includes('LOCAL_ROUTE_ASSISTANCE'));
    assert.strictEqual(restored.assist, null,
      'transient lane assist must not survive save/restart');

    // Return to Wake Dock with ordinary flight and consume the bounded precedent once visibly.
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('d');

    await page.waitForFunction(() =>
      Array.isArray(window.toasts) &&
      window.toasts.some(toast => /ROOTLINE REPORT ACKNOWLEDGED/.test(String(toast.text || toast.message || ''))),
      undefined, { timeout: 3000 });

    const docked = await page.evaluate(() => ({
      moored: window._airNavigationState.mooredLandmarkId,
      toast: window.toasts.map(t => t.text || t.message || '').find(t => /ROOTLINE REPORT ACKNOWLEDGED/.test(t)) || null,
    }));
    assert.strictEqual(docked.moored, 'wake-dock');
    assert(docked.toast, 'Wake Dock did not visibly consume the bounded route precedent');

    assert.deepStrictEqual(errors, [], 'browser emitted unexpected errors: ' + errors.join(' | '));
    console.log('Aetherwake Rootline West browser/player-path proof: PASS');
  } finally {
    await browser.close();
    await new Promise(resolve => srv.close(resolve));
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
