'use strict';

const assert = require('assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const PORT = 4191;

function createServer() {
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

(async () => {
  const server = createServer();
  await new Promise(resolve => server.listen(PORT, '127.0.0.1', resolve));
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const errors = [];

  page.on('pageerror', error => errors.push('PAGE: ' + error.message));
  page.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('Failed to load resource')) {
      errors.push('CONSOLE: ' + msg.text());
    }
  });

  async function waitScene(id) {
    await page.waitForFunction(sceneId =>
      window.gameState === 'opening' &&
      window._firstWakeOpeningState &&
      window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).id === sceneId,
      id, { timeout: 6000 });
  }

  async function waitPresentationReady() {
    await page.waitForFunction(() =>
      window.AetherFirstWakeOpening.presentationReady(window._firstWakeOpeningState) === true,
      undefined, { timeout: 6000 });
  }

  async function pressMany(key, count) {
    for (let i = 0; i < count; i++) await page.keyboard.press(key);
  }

  async function finishDialogue() {
    for (let i = 0; i < 10; i++) {
      const state = await page.evaluate(() => window.gameState);
      if (state !== 'dialogue') break;
      await page.keyboard.press('e');
    }
    await page.waitForFunction(() => window.gameState === 'world',
      undefined, { timeout: 5000 });
  }

  try {
    const response = await page.goto(
      'http://127.0.0.1:' + PORT + '/index-embedded.html',
      { waitUntil: 'domcontentloaded', timeout: 20000 }
    );
    assert(response && response.ok(), 'embedded Chapter 1 runtime did not load');

    await page.waitForFunction(() =>
      window.__awRuntimeReady === true &&
      window.AetherFirstWakeOpening &&
      window._firstWakeOpeningState &&
      window._world &&
      window._combat &&
      document.querySelector('canvas')
    , undefined, { timeout: 15000 });

    // BOOT -> MENU -> OPENING through the real production input path.
    await page.keyboard.press('Enter');
    await waitScene('arrival_horizon');

    await waitPresentationReady();
    await page.keyboard.press('Enter');
    await waitScene('ender_arrives');

    await waitPresentationReady();
    await page.keyboard.press('Enter');
    await waitScene('dock_walk');

    // Sequence 02: player must physically reach the Wake.
    await page.keyboard.press('Enter');
    await pressMany('ArrowRight', 8);
    await page.waitForFunction(() => window._firstWakeOpeningState.dockWalk.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await waitScene('berth_task');

    // Sequence 03: three berth interactions.
    await page.keyboard.press('Enter');
    await pressMany('e', 3);
    await page.waitForFunction(() => window._firstWakeOpeningState.berthTask.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await waitScene('talen_staying');

    // Sequence 04: two Talen interactions.
    await page.keyboard.press('Enter');
    await pressMany('e', 2);
    await page.waitForFunction(() => window._firstWakeOpeningState.talenBeat.ready === true,
      undefined, { timeout: 5000 });
    await page.keyboard.press('Enter');
    await waitScene('lyra_family');

    // Sequence 05: route-chart discovery triggers the Wrong Song.
    await pressMany('ArrowRight', 2);
    await pressMany('ArrowUp', 3);
    await page.keyboard.press('e');
    await waitScene('wrong_song');

    // Sequence 06: physically find Lyra.
    await pressMany('ArrowRight', 2);
    await pressMany('ArrowDown', 1);
    await page.keyboard.press('e');
    await waitScene('ionia_practical');

    const afterLyra = await page.evaluate(() => ({
      active: window.ACTIVE_PARTY.map(character => character.id),
      playable: window.ROSTER.find(character => character.id === 'lyra').playable,
    }));
    assert(afterLyra.active.includes('lyra'), 'Lyra did not join after the authored discovery');
    assert.strictEqual(afterLyra.playable, true, 'Lyra did not become playable after joining');

    // Sequence 07: physically find Ionia at navigation.
    await pressMany('ArrowRight', 5);
    await pressMany('ArrowUp', 1);
    await page.keyboard.press('e');
    await waitScene('core_walk');

    // Sequence 08: collect systems + frequency in flexible order.
    await pressMany('ArrowLeft', 1);
    await pressMany('ArrowDown', 3);
    await page.keyboard.press('e');
    let investigation = await page.evaluate(() =>
      window.AetherFirstWakeOpening.wakeExplorationView(window._firstWakeOpeningState)
    );
    assert.deepStrictEqual(investigation.clues, ['systems']);
    assert.strictEqual(investigation.coreUnlocked, false);

    await pressMany('ArrowLeft', 2);
    await pressMany('ArrowDown', 1);
    await page.keyboard.press('e');
    investigation = await page.evaluate(() =>
      window.AetherFirstWakeOpening.wakeExplorationView(window._firstWakeOpeningState)
    );
    assert.deepStrictEqual(investigation.clues, ['systems','frequency']);
    assert.strictEqual(investigation.coreUnlocked, true,
      'two independent clues must unlock the Core route');

    // Enter the Core threshold deliberately.
    await pressMany('ArrowRight', 4);
    await pressMany('ArrowUp', 1);
    await page.keyboard.press('e');
    await waitScene('first_wake_card');

    // Sequence 09 chapter card -> live Chapter I world.
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.gameState === 'world' &&
      window._firstWakeOpeningState &&
      window._firstWakeOpeningState.complete === true
    , undefined, { timeout: 5000 });

    const handoff = await page.evaluate(() => ({
      gameState: window.gameState,
      quest: window._world.getQuestState(),
      active: window.ACTIVE_PARTY.map(character => character.id),
      autosaveReason: window._lastAutosaveReason || null,
    }));

    assert.strictEqual(handoff.gameState, 'world');
    assert.deepStrictEqual(handoff.active, ['ender','lyra']);
    assert.strictEqual(handoff.quest.state, 'signal');
    assert.strictEqual(handoff.quest.crossingHazards.length, 4,
      'Chapter I world must own the canonical four-hazard Crossing route');

    // Continue with actual world movement: Ender starts at (16,16).
    // Signal contact 1: The Core at (22,10).
    await pressMany('ArrowRight', 6);
    await pressMany('ArrowUp', 6);
    await page.keyboard.press('e');
    await page.waitForFunction(() => window.gameState === 'dialogue',
      undefined, { timeout: 3000 });
    await finishDialogue();

    let signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 1);
    assert.strictEqual(signal.state, 'signal');
    assert.strictEqual(signal.signalHooks[0].done, true);

    // Signal contact 2: Lyra at (8,20).
    await pressMany('ArrowLeft', 14);
    await pressMany('ArrowDown', 10);
    await page.keyboard.press('e');
    await page.waitForFunction(() => window.gameState === 'dialogue',
      undefined, { timeout: 3000 });
    await finishDialogue();

    signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 2);
    assert.strictEqual(signal.state, 'signal');
    assert.strictEqual(signal.signalHooks[2].done, true);

    // Signal contact 3: Verrick at (26,24). The third hook must unlock CROSSING.
    await pressMany('ArrowRight', 18);
    await pressMany('ArrowDown', 4);
    await page.keyboard.press('e');
    await page.waitForFunction(() => window.gameState === 'dialogue',
      undefined, { timeout: 3000 });
    await finishDialogue();

    signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 3);
    assert.strictEqual(signal.signalHooks[1].done, true);
    assert.strictEqual(signal.state, 'crossing',
      'all three authored signal contacts must unlock CROSSING');
    assert.strictEqual(signal.hazardsCompleted, 0);

    // From Verrick (26,24), enter the Sky-Predator zone at x>=28,y<=8.
    // No random roll is permitted: the first valid zone entry must start combat.
    await pressMany('ArrowRight', 2);
    await pressMany('ArrowUp', 16);
    await page.waitForFunction(() => window.gameState === 'combat',
      undefined, { timeout: 5000 });

    const hazardCombat = await page.evaluate(() => {
      const state = window._combat && window._combat.getState ? window._combat.getState() : null;
      return {
        gameState: window.gameState,
        enemy: state && state.enemy ? {
          id: state.enemy.id || null,
          name: state.enemy.name || null,
          hp: state.enemy.hp,
        } : null,
        quest: window._world.getQuestState(),
      };
    });
    assert.strictEqual(hazardCombat.gameState, 'combat');
    assert(hazardCombat.enemy, 'hazard zone did not create a combat enemy');
    assert(
      hazardCombat.enemy.id === 'skyPredator' ||
      /sky.?predator/i.test(String(hazardCombat.enemy.name || '')),
      'first Crossing hazard did not launch the Sky-Predator encounter'
    );
    assert.strictEqual(hazardCombat.quest.hazardsCompleted, 0,
      'hazard must not complete merely by entering combat');

    assert.deepStrictEqual(errors, [], errors.join('\n'));
    console.log('Aetherwake Chapter 1 opening + SIGNAL + deterministic hazard entry: PASS');
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
