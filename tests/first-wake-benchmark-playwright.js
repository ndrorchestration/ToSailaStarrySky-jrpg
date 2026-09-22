'use strict';

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const BASE = path.resolve(__dirname, '..');
const PORT = Number(process.env.AETHERWAKE_BENCHMARK_PORT || 8092);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function createServer() {
  return http.createServer((req, res) => {
    const parsed = new URL(req.url, `http://127.0.0.1:${PORT}`);
    let requested = decodeURIComponent(parsed.pathname);
    if (requested === '/') requested = '/index-embedded.html';
    const relative = requested.replace(/^\\/+/, '');
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

async function setPlayer(page, tileX, tileY) {
  await page.evaluate(({ tileX, tileY }) => {
    const p = window._world.player;
    p.tileX = tileX;
    p.tileY = tileY;
    p.x = tileX;
    p.y = tileY;
    p.px = tileX * 16;
    p.py = tileY * 16;
  }, { tileX, tileY });
}

async function talkAt(page, tileX, tileY) {
  await setPlayer(page, tileX, tileY);
  await page.keyboard.press('e');
  await page.waitForFunction(() => window.gameState === 'dialogue', undefined, { timeout: 5000 });
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });
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

  try {
    const response = await page.goto(
      `http://127.0.0.1:${PORT}/index-embedded.html`,
      { waitUntil: 'domcontentloaded', timeout: 20000 }
    );
    assert(response && response.ok(), 'benchmark entrypoint did not load');
    await page.waitForSelector('canvas', { timeout: 15000 });
    await page.waitForFunction(() =>
      window._world &&
      window._combat &&
      window.AetherFirstWakeOpening &&
      document.querySelector('canvas') &&
      document.querySelector('canvas').width === 960 &&
      document.querySelector('canvas').height === 640
    , undefined, { timeout: 15000 });

    // BOOT/MENU -> authored opening, then advance through Sequence 09 to WORLD.
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.gameState === 'opening', undefined, { timeout: 5000 });
    for (let i = 0; i < 10; i++) await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    const handoff = await page.evaluate(() => ({
      openingComplete: window._firstWakeOpeningState && window._firstWakeOpeningState.complete,
      activeIds: window.ACTIVE_PARTY.map(character => character.id),
      quest: window._world.getQuestState(),
    }));
    assert(handoff.openingComplete === true, 'First Wake opening did not complete');
    assert(handoff.activeIds.join('|') === 'ender|lyra',
      'First Wake benchmark handoff did not preserve Ender + Lyra');
    assert(handoff.quest.state === 'signal', 'First Wake did not hand off into signal quest state');

    // Real quest-log input path.
    await page.keyboard.press('t');
    await page.waitForFunction(() => window.gameState === 'questlog', undefined, { timeout: 5000 });
    const questLog = await page.evaluate(() => window._world.getQuestState());
    assert(questLog.state === 'signal', 'quest log opened with wrong quest state');
    assert(Array.isArray(questLog.journal) && questLog.journal.length >= 1,
      'quest log has no authored journal/objective data');
    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    // Complete all three signal hooks through the normal proximity + E interaction path.
    // Core, Verrick, Lyra.
    for (const [x, y] of [[22,10], [26,24], [8,20]]) {
      await talkAt(page, x, y);
    }

    const afterSignals = await page.evaluate(() => window._world.getQuestState());
    assert(afterSignals.hooksCompleted === 3, 'all three signal hooks did not complete');
    assert(afterSignals.signalHooks.every(hook => hook.done === true),
      'signal hook records did not all become complete');
    assert(afterSignals.state === 'crossing',
      '3/3 signal hooks did not advance First Wake to Crossing');

    // Each Crossing hazard must launch its mapped real encounter and only a real
    // combat victory may mark it complete.
    const expectedEnemies = [
      'Sky-Predator',
      'Wind Shear Elemental',
      'Aether Leak Wraith',
      'Corporate Salvager',
    ];

    for (let index = 0; index < 4; index++) {
      const started = await page.evaluate(i => triggerHazardEncounter(i), index);
      assert(started === true, `Crossing hazard ${index} did not launch`);
      await page.waitForFunction(() => window.gameState === 'combat', undefined, { timeout: 5000 });

      const enemyName = await page.evaluate(() => window._combat.getState().enemy.name);
      assert(enemyName === expectedEnemies[index],
        `Crossing hazard ${index} launched unexpected enemy: ${enemyName}`);

      const victory = await page.evaluate(() => {
        for (let turn = 0; turn < 80; turn++) {
          const state = window._combat.getState();
          if (state.encounterOver && state.enemy && state.enemy.hp <= 0) return state;
          if (state.player.staffCharges > 0) window._combat.resolveTurn('staffStrike');
          else window._combat.resolveTurn('hold');
        }
        return window._combat.getState();
      });
      assert(victory.encounterOver === true && victory.enemy.hp <= 0,
        `Crossing hazard ${index} could not reach deterministic combat victory`);

      await page.evaluate(() => finishCombat());
      await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

      const progress = await page.evaluate(() => window._world.getQuestState());
      assert(progress.hazardsCompleted === index + 1,
        `Crossing hazard ${index} did not increment exactly once`);
      assert(progress.crossingHazards[index].done === true,
        `Crossing hazard ${index} did not persist completion`);
    }

    const afterCrossing = await page.evaluate(() => window._world.getQuestState());
    assert(afterCrossing.hazardsCompleted === 4, 'Crossing did not reach 4/4 hazards');
    assert(afterCrossing.state === 'contact', '4/4 hazards did not advance to Contact');

    // The three signal NPCs are already heard; Ionia is the fourth authored voice.
    await talkAt(page, 7, 7);
    const afterContacts = await page.evaluate(() => window._world.getQuestState());
    assert(afterContacts.npcsMet.length === 4, 'First Wake did not record all four authored voices');
    assert(new Set(afterContacts.npcsMet).size === 4, 'First Wake contact records contain duplicates');
    assert(afterContacts.state === 'choice', '4/4 contacts did not advance to Choice');

    // Real choice input must enter the deliberate WAKE state rather than skip it.
    await page.keyboard.press('1');
    await page.waitForFunction(() =>
      window._world.getQuestState().state === 'wake' && window.gameState === 'world'
    , undefined, { timeout: 5000 });

    const wake = await page.evaluate(() => ({
      quest: window._world.getQuestState(),
      canSave: canSaveNow(),
      gameOver: Boolean(gameOver),
    }));
    assert(wake.quest.choiceMade, 'choice input did not record a selected path');
    assert(wake.quest.state === 'wake', 'choice skipped the deliberate WAKE state');
    assert(wake.canSave === false, 'WAKE transient state incorrectly allows saving');
    assert(wake.gameOver === false, 'WAKE state prematurely ended the game');

    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window._world.getQuestState().state === 'done',
      undefined, { timeout: 5000 });

    const done = await page.evaluate(() => ({
      quest: window._world.getQuestState(),
      gameOver: Boolean(gameOver),
    }));
    assert(done.quest.state === 'done' && done.gameOver === true,
      'deliberate WAKE advance did not reach bounded ending state');

    if (errors.length) throw new Error('benchmark browser errors:\n' + errors.join('\n'));

    console.log('Aetherwake First Wake live benchmark: PASS');
    console.log(JSON.stringify({
      hooksCompleted: afterSignals.hooksCompleted,
      hazardsCompleted: afterCrossing.hazardsCompleted,
      contacts: afterContacts.npcsMet,
      choiceMade: wake.quest.choiceMade,
      finalState: done.quest.state,
    }));
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
