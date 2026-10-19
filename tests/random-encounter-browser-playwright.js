'use strict';

const assert = require('assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const PORT = 4299;

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

  async function findWorldPath({ targetX = null, targetY = null, range = 0,
    hazardIndex = null, outsideHazard = false }) {
    return page.evaluate(({ targetX, targetY, range, hazardIndex, outsideHazard }) => {
      const world = window._world;
      const player = world && world.player;
      if (!world || !player || typeof world.isWalkableTile !== 'function') return null;

      const quest = world.getQuestState();
      const zones = [
        (x, y) => x >= 28 && y >= 4 && y <= 8,
        (x, y) => x >= 10 && x <= 20 && y >= 8 && y <= 14,
        (x, y) => y <= 5 && x >= 15 && x <= 25,
        (x, y) => x >= 4 && x <= 12 && y >= 9 && y <= 16,
      ];
      const dirs = [
        { dx: 1, dy: 0, key: 'ArrowRight' },
        { dx: -1, dy: 0, key: 'ArrowLeft' },
        { dx: 0, dy: 1, key: 'ArrowDown' },
        { dx: 0, dy: -1, key: 'ArrowUp' },
      ];
      const isTarget = (x, y) => {
        if (hazardIndex !== null) {
          return outsideHazard ? !zones[hazardIndex](x, y) : zones[hazardIndex](x, y);
        }
        return Math.abs(x - targetX) + Math.abs(y - targetY) <= range;
      };
      const isForbiddenHazard = (x, y) => {
        if (quest.state !== 'crossing' || hazardIndex === null || outsideHazard) return false;
        for (let i = 0; i < zones.length; i++) {
          if (i === hazardIndex) continue;
          const hazard = quest.crossingHazards[i];
          if (hazard && !hazard.done && zones[i](x, y)) return true;
        }
        return false;
      };

      const queue = [{ x: player.tileX, y: player.tileY, path: [] }];
      const seen = new Set([player.tileX + ',' + player.tileY]);
      while (queue.length) {
        const current = queue.shift();
        if (isTarget(current.x, current.y)) return current.path;
        for (const dir of dirs) {
          const x = current.x + dir.dx;
          const y = current.y + dir.dy;
          const key = x + ',' + y;
          if (seen.has(key) || !world.isWalkableTile(x, y) || isForbiddenHazard(x, y)) continue;
          seen.add(key);
          queue.push({ x, y, path: current.path.concat(dir.key) });
        }
      }
      return null;
    }, { targetX, targetY, range, hazardIndex, outsideHazard });
  }

  async function walkPath(path, stopState = null) {
    assert(Array.isArray(path), 'no walkable world path found');
    const result = await page.evaluate(({ path, stopState }) => {
      const deltaByKey = {
        ArrowRight: [1, 0],
        ArrowLeft: [-1, 0],
        ArrowDown: [0, 1],
        ArrowUp: [0, -1],
      };
      let steps = 0;
      for (const key of path) {
        if (stopState && window.gameState === stopState) break;
        if (window.gameState !== 'world') {
          return { ok: false, reason: 'LEFT_WORLD', state: window.gameState, steps };
        }
        const delta = deltaByKey[key];
        const player = window._world.player;
        const beforeX = player.tileX;
        const beforeY = player.tileY;
        window._world.movePlayer(delta[0], delta[1]);
        steps++;
        if (stopState && window.gameState === stopState) break;
        if (player.tileX === beforeX && player.tileY === beforeY) {
          return { ok: false, reason: 'MOVE_REJECTED', key, beforeX, beforeY, steps };
        }
      }
      return {
        ok: true,
        state: window.gameState,
        steps,
        tileX: window._world.player.tileX,
        tileY: window._world.player.tileY,
      };
    }, { path, stopState });
    assert.strictEqual(result.ok, true,
      'planned BFS traversal failed: ' + JSON.stringify(result));
  }

  async function walkNear(targetX, targetY, range = 2) {
    const path = await findWorldPath({ targetX, targetY, range });
    await walkPath(path);
  }

  async function walkIntoHazard(hazardIndex) {
    const path = await findWorldPath({ hazardIndex });
    await walkPath(path, 'combat');
    await page.waitForFunction(() => window.gameState === 'combat',
      undefined, { timeout: 5000 });
  }

  async function walkOutsideHazard(hazardIndex) {
    const path = await findWorldPath({ hazardIndex, outsideHazard: true });
    await walkPath(path);
    assert.strictEqual(await page.evaluate(() => window.gameState), 'world');
  }

  async function startWorldDialogue() {
    const opened = await page.evaluate(() => {
      window.interactionKey = 'e';
      window._world.interact();
      window.interactionKey = null;
      return window.gameState === 'dialogue';
    });
    assert.strictEqual(opened, true, 'world interaction did not open dialogue');
  }

  async function finishDialogue() {
    for (let i = 0; i < 64; i++) {
      const state = await page.evaluate(() => window.gameState);
      if (state !== 'dialogue') {
        assert.strictEqual(state, 'world',
          'dialogue closed into an unexpected state: ' + state);
        return;
      }
      await page.evaluate(() => {
        window._world.nextDialogueLine();
      });
    }
    throw new Error('dialogue did not close within 64 advances');
  }

  async function winCurrentCombat(expectedName) {
    await page.waitForFunction(() =>
      window.gameState === 'combat' &&
      window._combat &&
      window._combat.getState &&
      window._combat.getState().enemy
    , undefined, { timeout: 5000 });

    const start = await page.evaluate(() => window._combat.getState());
    assert(new RegExp(expectedName, 'i').test(String(start.enemy.name || start.enemy.id || '')),
      'unexpected Chapter 1 hazard enemy: ' + (start.enemy.name || start.enemy.id));

    let analyzed = false;
    for (let step = 0; step < 12; step++) {
      const before = await page.evaluate(() => window._combat.getState());
      if (before.encounterOver) break;

      let actionKey;
      if (!analyzed &&
          Array.isArray(before.usableActionIds) &&
          before.usableActionIds.includes('uncoverTruth')) {
        actionKey = '2';
        analyzed = true;
      } else if (Number(before.player.staffCharges || 0) > 0) {
        actionKey = '1';
      } else {
        actionKey = '5'; // Hold: recharge the Resonator Staff.
      }

      const beforeTurn = before.turn;
      await page.keyboard.press(actionKey);
      await page.waitForFunction(previousTurn => {
        const state = window._combat.getState();
        return state.encounterOver || state.turn > previousTurn;
      }, beforeTurn, { timeout: 4000 });
    }

    const terminal = await page.evaluate(() => window._combat.getState());
    assert.strictEqual(terminal.encounterOver, true,
      expectedName + ' did not reach a terminal state through player actions');
    assert(terminal.enemy && terminal.enemy.hp <= 0,
      expectedName + ' terminal state was not a victory');

    await page.keyboard.press('Enter');
    await page.waitForFunction(() => window.gameState === 'world',
      undefined, { timeout: 5000 });
    return terminal;
  }

  try {
    const response = await page.goto(
      'http://127.0.0.1:' + PORT + '/index-embedded.html?randomEncounters=1',
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

    // Player-paced production path: opening sting completes first; story pages
    // advance explicitly until the title is reached, then a separate input starts New Game.
    await page.waitForTimeout(1400);
    for (let advance = 0; advance < 8; advance++) {
      if (await page.evaluate(() => window.gameState === 'menu')) break;
      await page.waitForTimeout(700);
      await page.keyboard.press('Enter');
    }
    await page.waitForFunction(() => window.gameState === 'menu', undefined, { timeout: 5000 });
    await page.waitForTimeout(3400);
    assert.strictEqual(await page.evaluate(() => window.gameState), 'menu',
      'title/menu auto-started without explicit player input');
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
    await walkNear(22, 10, 2);
    await startWorldDialogue();
    await finishDialogue();

    let signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 1);
    assert.strictEqual(signal.state, 'signal');
    assert.strictEqual(signal.signalHooks[0].done, true);

    // Signal contact 2: Lyra at (8,20).
    await walkNear(8, 20, 2);
    await startWorldDialogue();
    await finishDialogue();

    signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 2);
    assert.strictEqual(signal.state, 'signal');
    assert.strictEqual(signal.signalHooks[2].done, true);

    // Signal contact 3: Verrick at (26,24). The third hook must unlock CROSSING.
    await walkNear(26, 24, 2);
    await startWorldDialogue();
    await finishDialogue();

    signal = await page.evaluate(() => window._world.getQuestState());
    assert.strictEqual(signal.hooksCompleted, 3);
    assert.strictEqual(signal.signalHooks[1].done, true);
    assert.strictEqual(signal.state, 'crossing',
      'all three authored signal contacts must unlock CROSSING');
    assert.strictEqual(signal.hazardsCompleted, 0);
    assert.strictEqual(signal.npcsMet.length, 0,
      'SIGNAL conversations must not silently pre-complete the later CONTACT phase');

    // Review-mode random encounter is triggered through valid real world
    // steps, not via direct startCombat calls or state mutation.
    const walkResult = await page.evaluate(() => {
      const world=window._world;
      const safe=(x,y)=>world.isWalkableTile(x,y) &&
        !(x>=28 && y>=4 && y<=8) &&
        !(x>=10 && x<=20 && y>=8 && y<=14) &&
        !(y<=5 && x>=15 && x<=25) &&
        !(x>=4 && x<=12 && y>=9 && y<=16);
      let steps=0;
      for(;steps<26 && window.gameState==='world';steps++){
        const x=world.player.tileX,y=world.player.tileY;
        const adjacent=[[1,0],[-1,0],[0,1],[0,-1]].find(([dx,dy])=>safe(x+dx,y+dy));
        if(!adjacent)throw new Error('NO_SAFE_WALK_PATH_FROM_'+x+'_'+y);
        world.movePlayer(adjacent[0],adjacent[1]);
      }
      return {steps,gameState:window.gameState,at:[world.player.tileX,world.player.tileY],
        enemy:window._combat.getState().enemy};
    });
    assert.strictEqual(walkResult.gameState,'combat',
      'opt-in random encounter never reached dedicated battle: '+JSON.stringify(walkResult));
    assert(walkResult.steps>=12 && walkResult.steps<=26,
      'random encounter timing outside bounded range: '+JSON.stringify(walkResult));
    assert(walkResult.enemy && /aether.?leak/i.test(walkResult.enemy.name),
      'review random encounter must use expected enemy: '+JSON.stringify(walkResult));
    const evidenceDir=path.join(ROOT,'art-staging','combat','review');
    fs.mkdirSync(evidenceDir,{recursive:true});
    await page.screenshot({path:path.join(evidenceDir,'random-encounter-arena-review.png')});
    const turn0=await page.evaluate(()=>window._combat.getState().turn);
    await page.keyboard.press('1');
    await page.waitForFunction(before => {
      const state=window._combat.getState();
      return state.encounterOver||state.turn>before;
    },turn0,{timeout:5000});
    await winCurrentCombat('Aether');
    assert.strictEqual(await page.evaluate(()=>window.gameState),'world');
    assert.deepStrictEqual(errors,[],errors.join('\n'));
    console.log('Aetherwake opt-in random encounter: real movement ? arena ? turn commands ? victory ? world PASS');
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error);process.exitCode=1;});
