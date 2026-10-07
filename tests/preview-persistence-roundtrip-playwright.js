'use strict';

const assert = require('assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const PORT = 4189;

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
    const response = await page.goto('http://127.0.0.1:' + PORT + '/index-embedded.html',
      { waitUntil: 'domcontentloaded', timeout: 20000 });
    assert(response && response.ok(), 'Preview runtime did not load');

    await page.waitForFunction(() =>
      window.__awRuntimeReady === true &&
      window._world &&
      window._persistenceRuntime &&
      window.AetherSaveSystem &&
      document.querySelector('canvas')
    , undefined, { timeout: 15000 });

    // Establish a stable WORLD boundary without widening authored-route smoke.
    await page.evaluate(() => {
      gameState = STATE.WORLD;
      window.gameState = gameState;
      prevState = null;
      window.AetherSaveSystem.remove('manual-1');
    });

    const before = await page.evaluate(() => ({
      world: window._world.snapshotPersistentState(),
      ender: JSON.parse(JSON.stringify(window.ROSTER[0])),
      activeIds: window.ACTIVE_PARTY.map(character => character.id),
      air: window.AetherAirNavigation.exportPersistentState(window._airNavigationState),
    }));

    // Real manual input path: F5 opens Save; Enter confirms slot 1.
    await page.keyboard.press('F5');
    await page.waitForFunction(() => window.gameState === 'saveload',
      undefined, { timeout: 3000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window._lastSaveResult &&
      window._lastSaveResult.envelope &&
      window._lastSaveResult.envelope.slot === 'manual-1' &&
      window.gameState === 'saveload'
    , undefined, { timeout: 3000 });

    const savedPayload = await page.evaluate(() => {
      const loaded = window.AetherSaveSystem.load('manual-1');
      return JSON.parse(JSON.stringify(loaded.envelope.payload));
    });
    assert(savedPayload && savedPayload.runtime && savedPayload.world &&
      savedPayload.quest && savedPayload.party,
      'manual save must retain a complete persistence payload');

    // Return, then deliberately damage several independent live state owners.
    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.gameState === 'world',
      undefined, { timeout: 3000 });

    await page.evaluate(() => {
      window._world.player.tileX = 2;
      window._world.player.tileY = 3;
      window._world.player.px = 32;
      window._world.player.py = 48;
      window.ROSTER[0].scrap = (window.ROSTER[0].scrap || 0) + 77;
      window._airNavigationState.x = 21;
      window._airNavigationState.y = 13;
      window._airNavigationState.mooredLandmarkId = null;
      window._airNavigationState.speed = 2;
    });

    const mutated = await page.evaluate(() => ({
      tileX: window._world.player.tileX,
      tileY: window._world.player.tileY,
      scrap: window.ROSTER[0].scrap,
      airX: window._airNavigationState.x,
      airY: window._airNavigationState.y,
    }));
    assert(mutated.tileX === 2 && mutated.tileY === 3,
      'world mutation did not take effect before load');
    assert(mutated.scrap !== savedPayload.party.roster[0].scrap,
      'party mutation did not take effect before load');
    assert(mutated.airX === 21 && mutated.airY === 13,
      'air-navigation mutation did not take effect before load');

    // Real manual input path: F9 opens Load; Enter confirms slot 1.
    await page.keyboard.press('F9');
    await page.waitForFunction(() => window.gameState === 'saveload',
      undefined, { timeout: 3000 });
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window._lastLoadResult &&
      window._lastLoadResult.envelope &&
      window._lastLoadResult.envelope.slot === 'manual-1' &&
      window.gameState === 'world'
    , undefined, { timeout: 3000 });

    const after = await page.evaluate(() => ({
      world: window._world.snapshotPersistentState(),
      ender: JSON.parse(JSON.stringify(window.ROSTER[0])),
      activeIds: window.ACTIVE_PARTY.map(character => character.id),
      air: window.AetherAirNavigation.exportPersistentState(window._airNavigationState),
    }));

    const expectedWorldStable = {
      runtime: {
        skyLayerVisible: savedPayload.runtime.skyLayerVisible,
      },
      world: JSON.parse(JSON.stringify(savedPayload.world)),
      quest: JSON.parse(JSON.stringify(savedPayload.quest)),
    };
    const afterWorldStable = JSON.parse(JSON.stringify(after.world));
    delete afterWorldStable.runtime.dayTime;
    assert.deepStrictEqual(afterWorldStable, expectedWorldStable,
      'world/quest/non-clock runtime state must match the persisted payload exactly');

    const restoredClockAdvance =
      (after.world.runtime.dayTime - savedPayload.runtime.dayTime + 1) % 1;
    assert(restoredClockAdvance >= 0 && restoredClockAdvance < 0.01,
      'restored world clock must resume only a bounded amount after the persisted value');
    const expectedEnderStable = JSON.parse(JSON.stringify(savedPayload.party.roster[0]));
    const afterEnderStable = JSON.parse(JSON.stringify(after.ender));
    const savedSolarCharge = expectedEnderStable.solarCharge;
    const restoredSolarCharge = afterEnderStable.solarCharge;
    delete expectedEnderStable.solarCharge;
    delete afterEnderStable.solarCharge;
    assert.deepStrictEqual(afterEnderStable, expectedEnderStable,
      'Ender non-solar canonical party state must match the persisted payload exactly');
    assert(Number.isFinite(savedSolarCharge) && Number.isFinite(restoredSolarCharge) &&
      restoredSolarCharge >= savedSolarCharge &&
      restoredSolarCharge - savedSolarCharge < 0.001,
      'restored solar charge must resume only a bounded amount after the persisted value');
    assert.deepStrictEqual(after.activeIds, savedPayload.party.activeIds,
      'active party IDs must match the persisted payload exactly');
    assert.deepStrictEqual(after.air, savedPayload.airNavigation,
      'air-navigation state must match the persisted payload exactly');

    const slot = await page.evaluate(() =>
      window.AetherSaveSystem.list().find(entry => entry.slot === 'manual-1')
    );
    assert(slot && slot.exists && slot.valid,
      'manual-1 was not retained as a valid save after round trip');

    // Semantic-backup recovery: a checksum-valid but semantically impossible
    // primary must fall back to the previous valid backup.
    const recoveryFixture = await page.evaluate(() => {
      window.AetherSaveSystem.remove('manual-2');
      const payload = window._persistenceRuntime.buildSavePayload();
      const meta = {
        gameVersion: '0.1.0-semantic-backup-test',
        playtimeMs: payload.runtime.playtimeMs,
        chapter: 'Chapter I — First Wake',
        location: 'Aureate Wake',
        partySummary: window.ACTIVE_PARTY.map(character => character.name || character.id),
      };

      const first = window.AetherSaveSystem.save('manual-2', payload, meta);
      window.AetherSaveSystem.save('manual-2', payload, meta);
      const key = first.path.replace('localStorage://', '');
      const backupBefore = window.localStorage.getItem(key + '.bak');

      const impossible = JSON.parse(JSON.stringify(payload));
      impossible.world.playerPosition.px += 1;
      const badPrimary = window.AetherSaveSystem.makeEnvelope('manual-2', impossible, meta);
      window.localStorage.setItem(key, JSON.stringify(badPrimary));

      const recovered = window._persistenceRuntime.loadSemanticallyValidSaveCandidate('manual-2');
      return {
        key,
        backupBefore,
        recovered: {
          semanticBackupRecovery: Boolean(recovered && recovered.semanticBackupRecovery),
          primarySemanticError: recovered && recovered.primarySemanticError,
          path: recovered && recovered.path,
          payload: recovered && recovered.envelope
            ? JSON.parse(JSON.stringify(recovered.envelope.payload))
            : null,
        },
      };
    });

    assert.strictEqual(recoveryFixture.recovered.semanticBackupRecovery, true,
      'semantic-invalid primary must recover through the valid backup');
    assert(/SAVE_WORLD_PX_MISMATCH/.test(recoveryFixture.recovered.primarySemanticError || ''),
      'semantic recovery must retain the primary semantic failure reason');
    assert(recoveryFixture.recovered.path.endsWith('.bak'),
      'semantic recovery must identify the backup path');

    // Real player Load path must consume the same semantic backup candidate.
    await page.keyboard.press('F9');
    await page.waitForFunction(() => window.gameState === 'saveload',
      undefined, { timeout: 3000 });
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window._lastLoadRecovery &&
      window._lastLoadRecovery.slot === 'manual-2' &&
      window._lastLoadRecovery.source === 'backup' &&
      window.gameState === 'world'
    , undefined, { timeout: 3000 });

    const recoveryEvidence = await page.evaluate(() => ({
      recovery: JSON.parse(JSON.stringify(window._lastLoadRecovery)),
      backupRaw: window.localStorage.getItem(
        window.AetherSaveSystem.getStorage().path('manual-2').replace('localStorage://', '') + '.bak'
      ),
    }));
    assert(/SAVE_WORLD_PX_MISMATCH/.test(recoveryEvidence.recovery.primarySemanticError || ''),
      'player Load recovery lost the semantic primary error');

    // The next manual save to that recovered slot must preserve the known-good backup.
    await page.keyboard.press('F5');
    await page.waitForFunction(() => window.gameState === 'saveload',
      undefined, { timeout: 3000 });
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window._lastSaveResult &&
      window._lastSaveResult.envelope &&
      window._lastSaveResult.envelope.slot === 'manual-2' &&
      window.gameState === 'saveload'
    , undefined, { timeout: 3000 });

    const afterRecoverySave = await page.evaluate(() => {
      const key = window.AetherSaveSystem.getStorage().path('manual-2').replace('localStorage://', '');
      return {
        preservedBackup: Boolean(window._lastSaveResult && window._lastSaveResult.preservedBackup),
        backupRaw: window.localStorage.getItem(key + '.bak'),
      };
    });
    assert.strictEqual(afterRecoverySave.preservedBackup, true,
      'manual save after semantic recovery must request backup preservation');
    assert.strictEqual(afterRecoverySave.backupRaw, recoveryFixture.backupBefore,
      'manual save after semantic recovery replaced the known-good backup');

    await page.keyboard.press('Escape');
    await page.waitForFunction(() => window.gameState === 'world',
      undefined, { timeout: 3000 });

    // Transactional load apply: failures after canonical mutation must restore
    // the exact pre-attempt runtime rather than leave a half-loaded game.
    async function exerciseRollbackFault(stage, tag) {
      const evidence = await page.evaluate(({ stage, tag }) => {
        const target = window.AetherSaveSystem.load('manual-1').envelope;

        // Establish a live baseline that is deliberately different from target.
        window.ROSTER[0].scrap = (window.ROSTER[0].scrap || 0) + (tag === 'party' ? 17 : 23);
        window._world.player.tileX = tag === 'party' ? 4 : 5;
        window._world.player.tileY = tag === 'party' ? 6 : 7;
        window._world.player.px = window._world.player.tileX * 16;
        window._world.player.py = window._world.player.tileY * 16;
        window._airNavigationState.x = tag === 'party' ? 31 : 29;
        window._airNavigationState.y = tag === 'party' ? 14 : 12;
        window._airNavigationState.mooredLandmarkId = null;

        const before = window._persistenceRuntime.captureLiveRuntimeForLoadRollback();
        window.__AETHERWAKE_LOAD_TEST_HOOK__ = currentStage => {
          if (currentStage === stage) throw new Error('TEST_LOAD_FAULT_' + tag.toUpperCase());
        };

        let error = null;
        try {
          window._persistenceRuntime.applySaveEnvelope(target);
        } catch (candidate) {
          error = candidate.message;
        } finally {
          delete window.__AETHERWAKE_LOAD_TEST_HOOK__;
        }

        const after = window._persistenceRuntime.captureLiveRuntimeForLoadRollback();
        return {
          error,
          rollback: JSON.parse(JSON.stringify(window._lastLoadRollback)),
          before: JSON.parse(JSON.stringify(before)),
          after: JSON.parse(JSON.stringify(after)),
        };
      }, { stage, tag });

      assert.strictEqual(evidence.error, 'TEST_LOAD_FAULT_' + tag.toUpperCase(),
        tag + ' fault did not escape the transactional apply path');
      assert(evidence.rollback && evidence.rollback.restored === true,
        tag + ' fault did not record a successful rollback');
      assert.strictEqual(
        JSON.stringify(evidence.after),
        JSON.stringify(evidence.before),
        tag + ' fault left live runtime state changed after rollback'
      );
    }

    await exerciseRollbackFault('after-party', 'party');
    await exerciseRollbackFault('after-world', 'world');

    // If rollback itself fails, the transaction must report both failures
    // rather than claiming recovery.
    const combinedFailure = await page.evaluate(() => {
      const target = window.AetherSaveSystem.load('manual-1').envelope;
      window.ROSTER[0].scrap = (window.ROSTER[0].scrap || 0) + 31;

      window.__AETHERWAKE_LOAD_TEST_HOOK__ = stage => {
        if (stage === 'after-party') throw new Error('TEST_PRIMARY_APPLY_FAILURE');
        if (stage === 'rollback-start') throw new Error('TEST_ROLLBACK_FAILURE');
      };

      let error = null;
      try {
        window._persistenceRuntime.applySaveEnvelope(target);
      } catch (candidate) {
        error = candidate.message;
      } finally {
        delete window.__AETHERWAKE_LOAD_TEST_HOOK__;
      }
      return {
        error,
        rollback: JSON.parse(JSON.stringify(window._lastLoadRollback)),
      };
    });

    assert(/LOAD_APPLY_AND_ROLLBACK_FAILED:TEST_PRIMARY_APPLY_FAILURE\|TEST_ROLLBACK_FAILURE/.test(
      combinedFailure.error || ''
    ), 'rollback failure did not produce a combined fail-closed error');
    assert(combinedFailure.rollback &&
      combinedFailure.rollback.restored === false &&
      combinedFailure.rollback.error === 'TEST_PRIMARY_APPLY_FAILURE' &&
      combinedFailure.rollback.rollbackError === 'TEST_ROLLBACK_FAILURE',
      'rollback-failure evidence did not preserve both error causes');

    assert.deepStrictEqual(errors, [], errors.join('\n'));
    console.log('Aetherwake manual persistence browser round trip: PASS');
  } finally {
    await browser.close();
    await new Promise(resolve => srv.close(resolve));
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
