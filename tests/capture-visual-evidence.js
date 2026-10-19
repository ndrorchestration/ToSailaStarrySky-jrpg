'use strict';

const { chromium } = require('playwright');
const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { execFileSync } = require('child_process');
const { URL } = require('url');

const BASE = path.resolve(__dirname, '..');
const PORT = Number(process.env.AETHERWAKE_VISUAL_EVIDENCE_PORT || 8097);
const OUT = path.resolve(
  process.env.AETHERWAKE_VISUAL_EVIDENCE_DIR ||
  path.join(BASE, 'visual-evidence')
);
const RESAMPLE = process.env.AETHERWAKE_ENDER_RESAMPLE_REVIEW || '';
if (RESAMPLE && !['lanczos', 'bicubic'].includes(RESAMPLE)) {
  throw new Error('Invalid Ender resampling review mode');
}
const RUNTIME_QUERY = process.env.AETHERWAKE_CANDIDATE_FIELD_REVIEW === '1'
  ? '?candidateFieldArt=1' + (RESAMPLE ? '&enderReviewResample=' + RESAMPLE : '')
  : '';
const RUNTIME_URL = `http://127.0.0.1:${PORT}/index-embedded.html${RUNTIME_QUERY}`;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function resolveSourceBinding() {
  const explicit = process.env.AETHERWAKE_SOURCE_SHA || process.env.GITHUB_SHA;
  if (explicit) return { sha: explicit, mode: 'environment', workingTreeClean: null };
  try {
    const sha = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: BASE, encoding: 'utf8' }).trim();
    const status = execFileSync('git', ['status', '--porcelain'], { cwd: BASE, encoding: 'utf8' }).trim();
    return { sha, mode: 'local-git-head', workingTreeClean: status.length === 0 };
  } catch (error) {
    return { sha: 'LOCAL_UNBOUND', mode: 'unbound', workingTreeClean: null };
  }
}

function createServer() {
  return http.createServer((req, res) => {
    const parsed = new URL(req.url, `http://127.0.0.1:${PORT}`);
    let requested = decodeURIComponent(parsed.pathname);
    if (requested === '/') requested = '/index-embedded.html';

    const relative = requested.replace(/^\/+/, '');
    const fullPath = path.resolve(BASE, relative);
    if (!fullPath.startsWith(BASE + path.sep) && fullPath !== BASE) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    fs.readFile(fullPath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
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

async function waitForRuntime(page) {
  await page.waitForSelector('canvas', { timeout: 15000 });
  await page.waitForFunction(() =>
    window.__awRuntimeReady &&
    window._world &&
    window._combat &&
    window.AetherFirstWakeOpening &&
    window._firstWakeOpeningState &&
    document.querySelector('canvas') &&
    document.querySelector('canvas').width === 960 &&
    document.querySelector('canvas').height === 640
  , undefined, { timeout: 15000 });
}

async function advanceBootToMenu(page) {
  await page.waitForTimeout(1800);
  await page.locator('canvas').click({ position: { x: 480, y: 320 } });
  for (let advance = 0; advance < 8; advance++) {
    if (await page.evaluate(() => window.gameState === 'menu')) break;
    await page.waitForTimeout(700);
    await page.keyboard.press('Enter');
  }
  await page.waitForFunction(() => window.gameState === 'menu', undefined, { timeout: 5000 });
}

async function bootToWorld(page) {
  await page.goto(RUNTIME_URL, {
    waitUntil: 'domcontentloaded',
    timeout: 20000,
  });
  await waitForRuntime(page);

  await advanceBootToMenu(page);
  await page.keyboard.press('Enter');
  await page.waitForFunction(() => window.gameState === 'opening', undefined, { timeout: 5000 });

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.presentationReady(window._firstWakeOpeningState) === true
  , undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'ender_arrives'
  , undefined, { timeout: 5000 });
  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.presentationReady(window._firstWakeOpeningState) === true
  , undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');

  for (let i = 0; i < 8; i++) await page.keyboard.press('ArrowRight');
  await page.waitForFunction(() => window._firstWakeOpeningState.dockWalk.ready === true,
    undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'berth_task'
  , undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');
  for (let i = 0; i < 3; i++) await page.keyboard.press('e');
  await page.waitForFunction(() => window._firstWakeOpeningState.berthTask.ready === true,
    undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'talen_staying'
  , undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');
  for (let i = 0; i < 2; i++) await page.keyboard.press('e');
  await page.waitForFunction(() => window._firstWakeOpeningState.talenBeat.ready === true,
    undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'lyra_family'
  , undefined, { timeout: 5000 });
  for (let i = 0; i < 2; i++) await page.keyboard.press('ArrowRight');
  for (let i = 0; i < 3; i++) await page.keyboard.press('ArrowUp');
  await page.keyboard.press('e');
  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'wrong_song'
  , undefined, { timeout: 5000 });

  for (let i = 0; i < 2; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('e');
  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'ionia_practical'
  , undefined, { timeout: 5000 });

  for (let i = 0; i < 5; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowUp');
  await page.keyboard.press('e');
  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'core_walk'
  , undefined, { timeout: 5000 });

  await page.keyboard.press('ArrowLeft');
  for (let i = 0; i < 3; i++) await page.keyboard.press('ArrowDown');
  await page.keyboard.press('e');
  for (let i = 0; i < 2; i++) await page.keyboard.press('ArrowLeft');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('e');
  for (let i = 0; i < 4; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowUp');
  await page.keyboard.press('e');

  await page.waitForFunction(() =>
    window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'first_wake_card'
  , undefined, { timeout: 5000 });
  await page.keyboard.press('Enter');
  await page.waitForFunction(() =>
    window.gameState === 'world' &&
    window._firstWakeOpeningState &&
    window._firstWakeOpeningState.complete === true &&
    window._world &&
    window._world.player
  , undefined, { timeout: 5000 });
}

function sha256(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

async function measureFrameTiming(page, id, sampleFramesPerWindow = 60, sampleWindows = 3) {
  const stats = await page.evaluate(async ({ sampleFramesPerWindow, sampleWindows }) => {
    const windows = [];
    for (let windowIndex = 0; windowIndex < sampleWindows; windowIndex++) {
      const deltas = [];
      let previous = performance.now();
      await new Promise(resolve => {
        function tick(now) {
          deltas.push(now - previous);
          previous = now;
          if (deltas.length >= sampleFramesPerWindow) resolve();
          else requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
      });
      deltas.sort((a, b) => a - b);
      const pick = q => deltas[Math.min(deltas.length - 1, Math.floor((deltas.length - 1) * q))];
      windows.push({
        sampleFrames: deltas.length,
        p50: pick(0.50),
        p95: pick(0.95),
        max: deltas[deltas.length - 1],
      });
    }

    const all = windows.flatMap(item => item.sampleFrames ? [] : []);
    const p95s = windows.map(item => item.p95).sort((a,b) => a-b);
    const p50s = windows.map(item => item.p50).sort((a,b) => a-b);
    const median = values => values[Math.floor(values.length / 2)];
    const nav = performance.getEntriesByType('navigation')[0];
    const memory = performance.memory || null;
    const medianP50 = median(p50s);
    const medianP95 = median(p95s);
    return {
      sampleFrames: sampleFramesPerWindow * sampleWindows,
      sampleFramesPerWindow,
      sampleWindows,
      frameMsP50: Number(medianP50.toFixed(2)),
      frameMsP95: Number(medianP95.toFixed(2)),
      frameMsMax: Number(Math.max(...windows.map(item => item.max)).toFixed(2)),
      windowP95Median: Number(medianP95.toFixed(2)),
      windowP95Worst: Number(Math.max(...p95s).toFixed(2)),
      estimatedFpsP50: Number((1000 / medianP50).toFixed(1)),
      estimatedFpsP95: Number((1000 / medianP95).toFixed(1)),
      loadEventMs: nav ? Number(nav.loadEventEnd.toFixed(2)) : null,
      jsHeapUsedBytes: memory ? memory.usedJSHeapSize : null,
      jsHeapTotalBytes: memory ? memory.totalJSHeapSize : null,
      deviceMemoryGiB: navigator.deviceMemory || null,
      windows: windows.map((item, index) => ({
        index,
        p50: Number(item.p50.toFixed(2)),
        p95: Number(item.p95.toFixed(2)),
        max: Number(item.max.toFixed(2)),
      })),
    };
  }, { sampleFramesPerWindow, sampleWindows });
  return { id, ...stats };
}

async function capture(page, id, description) {
  await page.waitForTimeout(220);
  const file = path.join(OUT, id + '.png');
  await page.screenshot({ path: file, fullPage: false });
  const canvas = await page.evaluate(() => {
    const node = document.querySelector('canvas');
    const rect = node ? node.getBoundingClientRect() : null;
    return node && rect ? {
      logicalWidth: node.width,
      logicalHeight: node.height,
      cssWidth: Math.round(rect.width),
      cssHeight: Math.round(rect.height),
    } : null;
  });
  assert(canvas, 'canvas missing during visual capture: ' + id);

  return {
    id,
    description,
    file: path.basename(file),
    sha256: sha256(file),
    viewport: { width: 1440, height: 960 },
    canvas,
  };
}

(async () => {
  fs.rmSync(OUT, { recursive: true, force: true });
  fs.mkdirSync(OUT, { recursive: true });

  const server = createServer();
  await new Promise(resolve => server.listen(PORT, '127.0.0.1', resolve));

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
  const errors = [];

  page.on('pageerror', err => errors.push('PAGE: ' + err.message));
  page.on('requestfailed', req => {
    const url = req.url();
    const errorText = req.failure()?.errorText || 'failed';
    if (errorText === 'net::ERR_ABORTED' &&
        /\/assets\/audio\/[^/]+\.mp3(?:\?.*)?$/.test(url)) return;
    errors.push('REQUEST: ' + url + ' - ' + errorText);
  });
  page.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('Failed to load resource')) {
      errors.push('CONSOLE: ' + msg.text());
    }
  });

  try {
    const captures = [];
    const performanceSamples = [];

    // 0 â€” Shared-authority title screen after real boot/preamble.
    await page.goto(RUNTIME_URL, {
      waitUntil: 'domcontentloaded',
      timeout: 20000,
    });
    await waitForRuntime(page);
    await page.waitForTimeout(1800);
    captures.push(await capture(
      page,
      '00-prologue-page',
      'Authored sky-world prologue page with cinematic JRPG continuation cue'
    ));
    await advanceBootToMenu(page);
    captures.push(await capture(
      page,
      '00-title-screen',
      'Shared-authority Aetherwake title screen'
    ));
    performanceSamples.push(await measureFrameTiming(page, '00-title-screen'));

    // 1 â€” First Wake interactive dock-walk presentation.
    await page.goto(RUNTIME_URL, {
      waitUntil: 'domcontentloaded',
      timeout: 20000,
    });
    await waitForRuntime(page);
    await advanceBootToMenu(page);
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.gameState === 'opening', undefined, { timeout: 5000 });
    await page.waitForFunction(() =>
      window._firstWakeOpeningState && window._firstWakeOpeningState.sceneTicks >= 20
    , undefined, { timeout: 5000 });
    await page.evaluate(() => {
      window._firstWakeOpeningState.sceneTicks = 34;
      if (typeof window.noLoop === 'function') window.noLoop();
      if (typeof window.redraw === 'function') window.redraw();
    });
    captures.push(await capture(
      page,
      '00a-opening-world-reveal',
      'HUD-light First Wake establishing shot before location/title narration appears'
    ));
    await page.evaluate(() => { if (typeof window.loop === 'function') window.loop(); });
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.presentationReady(window._firstWakeOpeningState) === true
    , undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'ender_arrives'
    , undefined, { timeout: 5000 });
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.presentationReady(window._firstWakeOpeningState) === true
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '00b-first-wake-ionia-arrival',
      'First character introduction with admitted Ionia portrait presentation'
    ));
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'dock_walk'
    , undefined, { timeout: 5000 });
    for (let i = 0; i < 4; i++) await page.keyboard.press('ArrowRight');
    await page.waitForFunction(() =>
      window._firstWakeOpeningState.dockWalk &&
      window._firstWakeOpeningState.dockWalk.x === 4
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '01-first-wake-dock-walk',
      'First Wake Sequence 02 shared-authority visual stage'
    ));

    // 1b — First Wake cabin/interior authored substrate.
    for (let i = 0; i < 4; i++) await page.keyboard.press('ArrowRight');
    await page.waitForFunction(() => window._firstWakeOpeningState.dockWalk.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'berth_task'
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '01b-first-wake-cabin',
      'First Wake authored cabin substrate with live character staging'
    ));

    // 1c — Wrong Song dramatic beat.
    await page.keyboard.press('Enter');
    for (let i = 0; i < 3; i++) await page.keyboard.press('e');
    await page.waitForFunction(() => window._firstWakeOpeningState.berthTask.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'talen_staying'
    , undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    for (let i = 0; i < 2; i++) await page.keyboard.press('e');
    await page.waitForFunction(() => window._firstWakeOpeningState.talenBeat.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'lyra_family'
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '01c-first-wake-lyra-family',
      'First Wake Lyra family beat with authored cabin and provisional field identity'
    ));
    for (let i = 0; i < 2; i++) await page.keyboard.press('ArrowRight');
    for (let i = 0; i < 3; i++) await page.keyboard.press('ArrowUp');
    await page.keyboard.press('e');
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === 'wrong_song'
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '01c-first-wake-wrong-song',
      'First Wake Wrong Song dramatic visual set piece'
    ));

    // 2 — Dragonfly Dusk Dock benchmark.
    await bootToWorld(page);
    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 22; p.tileY = 16;
      p.x = 22; p.y = 16;
      p.px = 22 * 16; p.py = 16 * 16;

      if (!window._airNavigationState) throw new Error('AIR_NAVIGATION_STATE_UNAVAILABLE');
      window._airNavigationState.x = 8;
      window._airNavigationState.y = 22;
      window._airNavigationState.altitude = 'cruise';
      window._airNavigationState.speed = 0;
      window._airNavigationState.mooredLandmarkId = 'wake-dock';
    });
    captures.push(await capture(
      page,
      '02-dragonfly-dusk-dock',
      'Dragonfly Dusk Dock benchmark candidate'
    ));
    performanceSamples.push(await measureFrameTiming(page, '02-dragonfly-dusk-dock'));

    // 2 â€” Representative dialogue.
    await page.evaluate(() => {
      const p = window._world.player;
      p.tileX = 7; p.tileY = 7;
      p.x = 7; p.y = 7;
      p.px = 7 * 16; p.py = 7 * 16;
    });
    await page.keyboard.press('e');
    await page.waitForFunction(() =>
      window.gameState === 'dialogue' &&
      window.UI &&
      window.UI.dialogueNPC &&
      window.UI.dialogueNPC.name === 'Captain Ionia'
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '03-dialogue-ionia',
      'Representative Ionia dialogue visual gate'
    ));

    // 3 â€” Representative combat.
    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });
    await page.evaluate(() => {
      if (typeof startCombat !== 'function') throw new Error('startCombat is unavailable');
      startCombat('skyPredator');
    });
    await page.waitForFunction(() =>
      window.gameState === 'combat' &&
      window._combat &&
      window._combat.getState &&
      window._combat.getState().enemy &&
      window._combat.getState().enemy.type === 'skyPredator'
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '04-combat-sky-predator',
      'Representative Sky-Predator combat visual gate'
    ));
    performanceSamples.push(await measureFrameTiming(page, '04-combat-sky-predator'));

    // 4 â€” Dragonfly flight.
    await bootToWorld(page);
    await page.evaluate(() => {
      if (typeof enterAirNavigation !== 'function') {
        throw new Error('ENTER_AIR_NAVIGATION_UNAVAILABLE');
      }
      if (!enterAirNavigation()) throw new Error('ENTER_AIR_NAVIGATION_FAILED');

      const s = window._airNavigationState;
      s.x = 18;
      s.y = 15;
      s.altitude = 'cruise';
      s.heading = 0.15;
      s.speed = 2;
      s.mooredLandmarkId = null;
      if (!s.discovered.includes('verdant-crown')) s.discovered.push('verdant-crown');
      if (!s.discoveredRoutes.includes('rootline-west')) {
        s.discoveredRoutes.push('rootline-west');
      }
    });
    await page.waitForFunction(() => window.gameState === 'airship', undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '05-dragonfly-flight',
      'Representative Dragonfly open-sky flight visual gate'
    ));
    performanceSamples.push(await measureFrameTiming(page, '05-dragonfly-flight'));

    // 5a — Rootline West deliberate lane-assist review state.
    await page.evaluate(() => {
      const s = window._airNavigationState;
      s.x = 12;
      s.y = 19;
      s.altitude = 'cruise';
      s.speed = 1;
      s.mooredLandmarkId = null;
      if (!s.discoveredRoutes.includes('rootline-west')) s.discoveredRoutes.push('rootline-west');
    });
    captures.push(await capture(
      page,
      '05a0-rootline-west-available',
      'Rootline West OPEN discovered corridor before lane assist engagement'
    ));
    await page.keyboard.press('r');
    await page.waitForFunction(() => window._activeRouteAssistId === 'rootline-west',
      undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '05a-rootline-west-assist',
      'Rootline West OPEN route with deliberate lane assist engaged'
    ));

    // 5b — High-altitude upper-trace evidence and contextual chart cue.
    await page.keyboard.press('r');
    await page.evaluate(() => {
      const s = window._airNavigationState;
      s.x = 12;
      s.y = 18;
      s.altitude = 'cruise';
      s.speed = 1;
      s.mooredLandmarkId = null;
    });
    await page.keyboard.press('e');
    await page.waitForFunction(() =>
      window._routeNetworkState &&
      window._routeNetworkState.discoveredClues.includes('rootline-west-upper-trace'),
      undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '05b-rootline-west-upper-trace',
      'Rootline West high-altitude upper trace in range with contextual chart cue'
    ));

    // 5c — Persistable shifted-route presentation after chart confirmation.
    await page.keyboard.press('f');
    await page.waitForFunction(() =>
      window._routeNetwork &&
      window._routeNetwork.conditionFor(window._routeNetworkState, 'rootline-west') === 'shifted',
      undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '05c-rootline-west-shifted',
      'Rootline West SHIFTED operational condition after upper-trace chart confirmation'
    ));

    // 6 â€” Aerial combat context inherited from real flight state.
    await page.evaluate(() => {
      const s = window._airNavigationState;
      s.x = 19;
      s.y = 11;
      s.altitude = 'cruise';
      s.speed = 2;
      s.mooredLandmarkId = null;
      if (typeof startCombat !== 'function') throw new Error('START_COMBAT_UNAVAILABLE');
      startCombat('skyPredator', window.gameState);
    });
    await page.waitForFunction(() =>
      window.gameState === 'combat' &&
      window._combat &&
      window._combat.getState &&
      window._combat.getState().enemy
    , undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '06-sky-combat-crosswind',
      'Sky-Predator aerial combat under Crosswind flight context'
    ));

    // 7 ? Diagnostic five-character identity lineup on an isolated one-shot
    // canvas so the live game loop cannot overwrite the review artifact.
    await page.goto(`http://127.0.0.1:${PORT}/tests/character-identity-evidence.html`, {
      waitUntil: 'domcontentloaded', timeout: 20000,
    });
    await page.waitForFunction(() => window.__identityEvidenceReady === true, undefined, { timeout: 5000 });
    captures.push(await capture(
      page,
      '07-character-identity-lineup',
      'Diagnostic five-character field-silhouette and portrait identity lineup'
    ));

    assert(errors.length === 0, 'visual capture runtime errors:\n' + errors.join('\n'));

    const manifest = {
      contract: 'AETHERWAKE_VISUAL_EVIDENCE_V1',
      generatedAt: new Date().toISOString(),
      sourceSha: resolveSourceBinding().sha,
      sourceBinding: resolveSourceBinding(),
      rendering: {
        browser: 'playwright-chromium',
        viewport: { width: 1440, height: 960 },
        logicalCanvas: { width: 960, height: 640 },
      },
      acceptanceBoundary:
        'CAPTURE_ONLY_NOT_VISUAL_PASS: screenshots require human review against docs/VISUAL_BIBLE.md and docs/VISUAL_BENCHMARK_SCENE.md',
      captures,
      performanceSamples,
    };

    const manifestPath = path.join(OUT, 'manifest.json');
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');

    console.log('AETHERWAKE_VISUAL_EVIDENCE=CAPTURED');
    console.log('AETHERWAKE_VISUAL_EVIDENCE_COUNT=' + captures.length);
    console.log('AETHERWAKE_VISUAL_PERFORMANCE_SAMPLES=' + performanceSamples.length);
    console.log('AETHERWAKE_VISUAL_EVIDENCE_MANIFEST=' + manifestPath);
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(err => {
  console.error(err.stack || err);
  process.exit(1);
});
