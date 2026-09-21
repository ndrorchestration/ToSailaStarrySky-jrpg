const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const BASE = path.resolve(__dirname, '..');
const PORT = Number(process.env.AETHERWAKE_TEST_PORT || 8091);

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
      }[path.extname(fullPath).toLowerCase()] || 'application/octet-stream';

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

  page.on('pageerror', err => errors.push(`PAGE: ${err.message}`));
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(`CONSOLE: ${msg.text()}`);
  });

  try {
    const response = await page.goto(
      `http://127.0.0.1:${PORT}/index-embedded.html`,
      { waitUntil: 'domcontentloaded', timeout: 20000 }
    );
    assert(response && response.ok(), 'index-embedded.html did not load successfully');

    await page.waitForSelector('canvas', { timeout: 15000 });
    await page.waitForFunction(() =>
      window._charcreate &&
      window._combat &&
      window._world &&
      document.querySelector('canvas') &&
      document.querySelector('canvas').width === 960 &&
      document.querySelector('canvas').height === 640
    , undefined, { timeout: 15000 });

    const debugOverlayState = await page.evaluate(() =>
      ['debug-overlay', 'aw-debug-overlay'].map(id => {
        const node = document.getElementById(id);
        return {
          id,
          display: node ? getComputedStyle(node).display : 'missing',
          debugEnabled: Boolean(window.__awDebugEnabled),
        };
      })
    );
    assert(debugOverlayState.every(entry => entry.debugEnabled === false),
      'normal launch unexpectedly enabled debug mode');
    assert(debugOverlayState.every(entry => entry.display === 'none'),
      'normal launch exposed a debug overlay');

    // One real Enter follows the production input path:
    // BOOT → MENU → CHARCREATE and char-create title → name.
    await page.keyboard.press('Enter');
    await page.waitForFunction(() =>
      window.gameState === 'charcreate' &&
      window._charcreate &&
      window._charcreate.phase === 'name'
    , undefined, { timeout: 5000 });

    // The current prototype defaults to Sky-Sailor if no numeric job key is
    // chosen. Avoid numeric selection here so this smoke test does not couple
    // itself to prototype name/job input quirks.
    await page.keyboard.type('Lyra');
    await page.keyboard.press('Enter');

    await page.waitForFunction(() =>
      window._charcreate &&
      window._charcreate.phase === 'name' &&
      window._charcreate.slot === 1 &&
      window._charcreate.party &&
      window._charcreate.party[1]
    , undefined, { timeout: 5000 });

    await page.keyboard.type('Ionia');
    await page.keyboard.press('Enter');

    await page.waitForFunction(() =>
      window._charcreate &&
      window._charcreate.phase === 'review' &&
      window._charcreate.party &&
      window._charcreate.party[2]
    , undefined, { timeout: 5000 });

    const review = await page.evaluate(() => ({
      partyLength: window._charcreate.party.length,
      ender: window._charcreate.party[0] && window._charcreate.party[0].name,
      companion1: window._charcreate.party[1] && window._charcreate.party[1].name,
      companion2: window._charcreate.party[2] && window._charcreate.party[2].name,
    }));

    assert(review.partyLength === 3, 'prototype review did not contain three party slots');
    assert(review.ender === 'Ender', 'Ender missing from prototype party');
    assert(review.companion1 === 'Lyra', 'first companion name was not retained');
    assert(review.companion2 === 'Ionia', 'second companion name was not retained');

    await page.keyboard.press('Enter');

    await page.waitForFunction(() =>
      window.gameState === 'world' &&
      window._world &&
      window._world.player
    , undefined, { timeout: 5000 });

    const worldBeforeCombat = await page.evaluate(() => ({
      name: window._world.player.name,
      className: window._world.player.class,
      level: window._world.player.level,
      xp: window._world.player.xp,
    }));

    assert(typeof worldBeforeCombat.name === 'string' && worldBeforeCombat.name.length > 0,
      'CHARCREATE → WORLD lost player name');
    assert(typeof worldBeforeCombat.className === 'string' && worldBeforeCombat.className.length > 0,
      'CHARCREATE → WORLD lost player class');

    const partyArchitecture = await page.evaluate(() => ({
      rosterLength: window.ROSTER && window.ROSTER.length,
      activeLength: window.ACTIVE_PARTY && window.ACTIVE_PARTY.length,
      rosterIds: window.ROSTER && window.ROSTER.map(character => character.id),
      activeIds: window.ACTIVE_PARTY && window.ACTIVE_PARTY.map(character => character.id),
      rosterRefs: window.ROSTER && window.ACTIVE_PARTY && [
        window.ACTIVE_PARTY[0] === window.ROSTER[0],
        window.ACTIVE_PARTY[1] === window.ROSTER[1],
        window.ACTIVE_PARTY[2] === window.ROSTER[2],
      ],
      worldLeadRef: Boolean(window._world && window.ROSTER &&
        window._world.player === window.ROSTER[0]),
      legacyPartyAlias: window.party === window.ACTIVE_PARTY,
      runtimeImplemented: window.ROSTER &&
        window.ROSTER.map(character => Boolean(character.runtimeImplemented)),
    }));

    assert(partyArchitecture.rosterLength === 5, 'persistent roster does not contain five records');
    assert(partyArchitecture.activeLength === 3, 'active party does not contain three references');
    assert(partyArchitecture.rosterIds.join('|') === 'ender|lyra|ionia|reson|aepex',
      'persistent roster identity order is incorrect');
    assert(partyArchitecture.activeIds.join('|') === 'ender|lyra|ionia',
      'initial active party references are incorrect');
    assert(partyArchitecture.rosterRefs.every(Boolean),
      'ACTIVE_PARTY members are not the canonical ROSTER references');
    assert(partyArchitecture.worldLeadRef,
      'WORLD player is not the canonical Ender roster record');
    assert(partyArchitecture.legacyPartyAlias,
      'legacy window.party alias is not canonical ACTIVE_PARTY');
    assert(partyArchitecture.runtimeImplemented.join('|') === 'true|true|true|false|false',
      'runtime implementation boundary for roster records is incorrect');

    await page.keyboard.press('KeyC');
    await page.waitForFunction(() =>
      window.gameState === 'combat' &&
      window._combat &&
      window._combat.getState &&
      window._combat.getState().enemy
    , undefined, { timeout: 5000 });

    const combatStart = await page.evaluate(() => window._combat.getState());
    assert(combatStart.turn === 0, 'combat did not start at turn 0');

    // Level-1 progression must actually gate actions 6-8.
    await page.keyboard.press('6');
    const afterLockedAction = await page.evaluate(() => window._combat.getState());
    assert(afterLockedAction.turn === 0,
      'locked level-gated action consumed a turn');
    assert(afterLockedAction.log.some(line => line.includes('Locked action: Wind Ward')),
      'locked action rejection was not recorded');
    assert(afterLockedAction.eligibleActionIds.join('|') ===
      'staffStrike|uncoverTruth|sharedDream|mycelialLedger|hold',
      'level-1 eligible action set drifted');

    const affordabilityContract = await page.evaluate(() => {
      window._combat.init({
        vit: 13,
        scrap: 7,
        aether: { current: 0, max: 6 },
        heat: { current: 1, max: 3 },
        echoes: { current: 1, max: 3 },
        charges: 2,
        staffMax: 2,
        level: 1,
        xp: 0,
        xpToNext: 50,
        unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
      });
      window._combat.beginEncounter('skyPredator');
      const before = window._combat.getState();
      const result = window._combat.resolveTurn('uncoverTruth', null);
      const after = window._combat.getState();

      // Restore the normal world-backed combat session for the rest of smoke.
      if (typeof startCombat !== 'function') throw new Error('startCombat is unavailable');
      startCombat('skyPredator');

      return {
        result,
        beforeTurn: before.turn,
        afterTurn: after.turn,
        beforeEchoes: before.player.echoes.current,
        afterEchoes: after.player.echoes.current,
        beforeAether: before.player.aether.current,
        afterAether: after.player.aether.current,
        log: after.log,
      };
    });

    assert(affordabilityContract.result === false,
      'underfunded action was not rejected');
    assert(affordabilityContract.beforeTurn === 0 && affordabilityContract.afterTurn === 0,
      'underfunded action consumed a turn');
    assert(affordabilityContract.beforeEchoes === 1 && affordabilityContract.afterEchoes === 1,
      'underfunded action partially consumed echoes');
    assert(affordabilityContract.beforeAether === 0 && affordabilityContract.afterAether === 0,
      'underfunded action partially consumed aether');
    assert(affordabilityContract.log.some(line =>
      line.includes('Not enough resources') && line.includes('needs 2')),
      'underfunded action did not record the preflight rejection');

    const progressionReachability = await page.evaluate(() => {
      window._combat.init({
        vit: 13,
        scrap: 7,
        aether: { current: 4, max: 6 },
        heat: { current: 1, max: 3 },
        echoes: { current: 3, max: 3 },
        charges: 2,
        staffMax: 2,
        level: 2,
        xp: 74,
        xpToNext: 75,
        unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
      });
      const before = window._combat.getState();
      window._combat.awardXP(1);
      const after = window._combat.getState();

      if (typeof startCombat !== 'function') throw new Error('startCombat is unavailable');
      startCombat('skyPredator');

      return {
        beforeLevel: before.player.level,
        beforeXP: before.player.xp,
        afterLevel: after.player.level,
        afterXP: after.player.xp,
        afterXPToNext: after.player.xpToNext,
        unlockedAbilities: after.player.unlockedAbilities,
        eligibleActionIds: after.eligibleActionIds,
        log: after.log,
      };
    });

    assert(progressionReachability.beforeLevel === 2 &&
      progressionReachability.beforeXP === 74,
      'progression reachability fixture did not start at level-2 threshold');
    assert(progressionReachability.afterLevel === 3,
      'awardXP did not advance level 2 to level 3');
    assert(progressionReachability.afterXP === 0,
      'level-up did not consume the previous XP threshold');
    assert(progressionReachability.afterXPToNext === 112,
      'level-3 XP threshold drifted');
    assert(progressionReachability.unlockedAbilities.includes('windWard'),
      'level-3 progression did not unlock Wind Ward');
    assert(progressionReachability.eligibleActionIds.includes('windWard'),
      'newly unlocked Wind Ward did not become eligible');
    assert(progressionReachability.log.some(line =>
      line.includes('LEVEL 3: Wind Ward unlocked')),
      'level-3 unlock log is missing');

    const secondaryStateContract = await page.evaluate(() => {
      const originalRandom = window.random;
      try {
        window._combat.init({
          vit: 13,
          scrap: 7,
          aether: { current: 4, max: 6 },
          heat: { current: 1, max: 3 },
          echoes: { current: 3, max: 3 },
          charges: 2,
          staffMax: 2,
          level: 1,
          xp: 0,
          xpToNext: 50,
          unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
        });
        window._combat.beginEncounter('skyPredator');

        window.random = function() { return 6; };
        if (window._combat.roll2d6() !== 12) {
          throw new Error('deterministic random override did not reach combat rolls');
        }
        window._combat.resolveTurn('mycelialLedger', null);
        const afterSuccess = window._combat.getState();

        window.random = function() { return 1; };
        window._combat.resolveTurn('uncoverTruth', null);
        const afterFailure = window._combat.getState();

        return {
          afterSuccess: {
            secondaryAvailable: afterSuccess.secondaryAvailable,
            lastAbilityId: afterSuccess.lastAbilityId,
          },
          afterFailure: {
            secondaryAvailable: afterFailure.secondaryAvailable,
            lastAbilityId: afterFailure.lastAbilityId,
          },
        };
      } finally {
        window.random = originalRandom;
        if (typeof startCombat !== 'function') throw new Error('startCombat is unavailable');
        startCombat('skyPredator');
      }
    });

    assert(secondaryStateContract.afterSuccess.secondaryAvailable === true,
      'successful affordable ability did not open a secondary window');
    assert(secondaryStateContract.afterSuccess.lastAbilityId === 'mycelialLedger',
      'secondary window did not bind to the successful ability');
    assert(secondaryStateContract.afterFailure.secondaryAvailable === false,
      'failed later ability inherited a stale secondary window');
    assert(secondaryStateContract.afterFailure.lastAbilityId === 'uncoverTruth',
      'last ability identity did not advance on the later primary action');

    // Secondary input must be a safe no-op when no secondary is available.
    // This specifically guards against core reaching into AetherCombat's
    // private state.
    await page.keyboard.press('KeyS');
    const afterIdleSecondary = await page.evaluate(() => window._combat.getState());
    assert(afterIdleSecondary.turn === 0,
      'unavailable secondary action should not consume a turn');

    const enemyMetadataContract = await page.evaluate(() => {
      const ids = [
        'skyPredator',
        'corporateSalvager',
        'windShear',
        'aetherLeak',
        'engine_spirit',
        'child_prophet',
        'elder_farmer',
      ];
      const snapshots = ids.map(id => {
        window._combat.beginEncounter(id);
        const enemy = window._combat.getState().enemy;
        return {
          id,
          type: enemy && enemy.type,
          ability: enemy && enemy.ability,
          abilities: enemy && enemy.abilities,
          abilityDesc: enemy && enemy.abilityDesc,
          color: enemy && enemy.color,
          bodyShape: enemy && enemy.bodyShape,
        };
      });
      window._combat.beginEncounter('skyPredator');
      return snapshots;
    });

    assert(enemyMetadataContract.length === 7,
      'enemy metadata contract did not cover all current templates');
    for (const enemy of enemyMetadataContract) {
      assert(enemy.type === enemy.id,
        'enemy encounter lost type metadata for ' + enemy.id);
      assert(typeof enemy.ability === 'string' && enemy.ability.length > 0,
        'enemy encounter lost ability metadata for ' + enemy.id);
      assert(Array.isArray(enemy.abilities) &&
        enemy.abilities.length === 1 &&
        enemy.abilities[0] === enemy.ability,
        'enemy encounter ability list drifted for ' + enemy.id);
      assert(typeof enemy.abilityDesc === 'string' && enemy.abilityDesc.length > 0,
        'enemy encounter lost ability description for ' + enemy.id);
      assert(typeof enemy.color === 'string' && enemy.color.length > 0,
        'enemy encounter lost color metadata for ' + enemy.id);
      assert(typeof enemy.bodyShape === 'string' && enemy.bodyShape.length > 0,
        'enemy encounter lost body-shape metadata for ' + enemy.id);
    }

    const effectContract = await page.evaluate(() => {
      const vocabulary = window.AetherEffectVocabulary;
      const actions = window._combat.getState().actions;
      return {
        version: vocabulary && vocabulary.VERSION,
        validCoverage: Boolean(vocabulary && vocabulary.assertActionCoverage(actions)),
        kinds: vocabulary && Object.values(vocabulary.EFFECT_KIND),
        profileIds: actions.map(action => action.effectProfile),
        declaredNotApplied: vocabulary
          ? vocabulary.ACTION_EFFECT_PROFILES.uncoverTruth.success
              .filter(effect => effect.runtimeStatus === vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED)
              .map(effect => effect.kind + ':' + effect.key)
          : [],
      };
    });

    assert(effectContract.version === '0.1.0', 'effect vocabulary version is not loaded');
    assert(effectContract.validCoverage, 'current actions are not covered by effect profiles');
    assert(effectContract.kinds.join('|') ===
      'damage|restore|resource|modifier|status|reveal|movement',
      'effect vocabulary kinds drifted');
    assert(effectContract.profileIds.join('|') ===
      'staffStrike|uncoverTruth|sharedDream|mycelialLedger|hold|windWard|aetherSeal|rest',
      'combat action effect-profile bindings drifted');
    assert(effectContract.declaredNotApplied.includes('reveal:weakness'),
      'Uncover Truth reveal debt is no longer explicit');
    assert(effectContract.declaredNotApplied.includes('modifier:nextRoll'),
      'Uncover Truth modifier debt is no longer explicit');

    const registryContract = await page.evaluate(() => {
      const abilities = window.AetherAbilityDefs;
      const progression = window.AetherProgressionDefs;
      const actions = window._combat.getState().actions;
      return {
        abilityVersion: abilities && abilities.VERSION,
        progressionVersion: progression && progression.VERSION,
        validAbilities: Boolean(abilities && abilities.assertRuntimeActions(actions)),
        validProgression: Boolean(
          progression && progression.validateAgainstAbilityDefs(abilities)
        ),
        actionOrder: abilities && abilities.ACTION_ORDER.slice(),
        levelUnlocks: progression && Object.fromEntries(
          Object.entries(progression.LEVEL_UNLOCKS)
            .map(([level, entries]) => [level, entries.map(entry => entry.abilityId)])
        ),
      };
    });

    assert(registryContract.abilityVersion === '0.2.0',
      'ability registry version is not loaded');
    assert(registryContract.progressionVersion === '0.1.0',
      'progression registry version is not loaded');
    assert(registryContract.validAbilities,
      'runtime actions drifted from canonical ability definitions');
    assert(registryContract.validProgression,
      'progression unlocks do not resolve against canonical ability definitions');
    assert(registryContract.actionOrder.join('|') ===
      'staffStrike|uncoverTruth|sharedDream|mycelialLedger|hold|windWard|aetherSeal|rest',
      'ability action order drifted');
    assert(JSON.stringify(registryContract.levelUnlocks) ===
      JSON.stringify({ 3: ['windWard'], 4: ['aetherSeal'], 5: ['rest'] }),
      'legacy progression unlock mapping drifted');

    const resolverContract = await page.evaluate(() => {
      const vocabulary = window.AetherEffectVocabulary;
      const resolver = window.AetherEffectResolver;
      const context = {
        player: {
          vit: 10,
          maxVit: 13,
          scrap: 7,
          aether: { current: 4, max: 6 },
          heat: { current: 1, max: 3 },
          echoes: { current: 3, max: 3 },
          staffCharges: 2,
          maxStaffCharges: 2,
        },
        enemy: { hp: 12, maxHp: 12 },
        staffChargeMax: 2,
      };

      const results = resolver.applyEffects([
        resolver.createDamageEffect(vocabulary.TARGET.ENEMY, 3, 'emp'),
        resolver.createDamageEffect(vocabulary.TARGET.SELF, 2),
        resolver.createRestoreEffect(vocabulary.TARGET.SELF, 1),
        resolver.createResourceDeltaEffect(vocabulary.RESOURCE.HEAT, 5),
        resolver.createResourceDeltaEffect(vocabulary.RESOURCE.AETHER, -2),
      ], context);

      return {
        version: resolver.VERSION,
        playerVit: context.player.vit,
        enemyHp: context.enemy.hp,
        heat: context.player.heat.current,
        aether: context.player.aether.current,
        applied: results.map(result => result.applied),
      };
    });

    assert(resolverContract.version === '0.1.0',
      'effect resolver version is not loaded');
    assert(resolverContract.playerVit === 9,
      'effect resolver damage/restoration sequence drifted');
    assert(resolverContract.enemyHp === 9,
      'effect resolver enemy damage drifted');
    assert(resolverContract.heat === 3,
      'effect resolver heat clamp drifted');
    assert(resolverContract.aether === 2,
      'effect resolver resource decrease drifted');
    assert(resolverContract.applied.every(Boolean),
      'effect resolver unexpectedly skipped an implemented effect');

    await page.keyboard.press('1');
    await page.waitForFunction(() =>
      window._combat && window._combat.getState().turn >= 1
    , undefined, { timeout: 5000 });

    await page.keyboard.press('2');
    await page.waitForFunction(() =>
      window._combat && window._combat.getState().turn >= 2
    , undefined, { timeout: 5000 });

    const combatAfterActions = await page.evaluate(() => window._combat.getState());
    assert(combatAfterActions.turn >= 2, 'combat actions did not resolve');
    assert(combatAfterActions.resolverMutations > 0,
      'live combat actions did not route ordinary mutations through the effect resolver');
    assert(combatAfterActions.log.some(line =>
      line.includes('[Turn 1]') && line.includes('Resonator Staff')),
      'turn 1 action text was not logged correctly');
    assert(combatAfterActions.log.some(line =>
      line.includes('[Turn 2]') && line.includes('Uncover Truth')),
      'turn 2 action text was not logged correctly');

    // Deterministic state-transition check. We test real keyboard combat
    // actions above; direct finishCombat avoids making the smoke test depend on
    // random damage rolls reaching victory.
    await page.evaluate(() => {
      if (typeof finishCombat !== 'function') throw new Error('finishCombat is unavailable');
      finishCombat();
    });

    await page.waitForFunction(() => window.gameState === 'world', undefined, { timeout: 5000 });

    const worldAfterCombat = await page.evaluate(() => ({
      vit: window._world.player.vit,
      scrap: window._world.player.scrap,
      aether: window._world.player.aether,
      heat: window._world.player.heat,
      echoes: window._world.player.echoes,
      staffCharges: window._world.player.staffCharges,
      level: window._world.player.level,
      xp: window._world.player.xp,
    }));

    assert(worldAfterCombat.vit === combatAfterActions.player.vit,
      'combat vitality was not written back to WORLD');
    assert(worldAfterCombat.scrap === combatAfterActions.player.scrap,
      'combat scrap was not written back to WORLD');
    assert(worldAfterCombat.aether === combatAfterActions.player.aether.current,
      'combat aether was not written back to WORLD');
    assert(worldAfterCombat.heat === combatAfterActions.player.heat.current,
      'combat heat was not written back to WORLD');
    assert(worldAfterCombat.echoes === combatAfterActions.player.echoes.current,
      'combat echoes were not written back to WORLD');
    assert(worldAfterCombat.staffCharges === combatAfterActions.player.staffCharges,
      'combat staff charges were not written back to WORLD');

    const rosterAfterCombat = await page.evaluate(() => ({
      vit: window.ROSTER[0].vit,
      scrap: window.ROSTER[0].scrap,
      aether: window.ROSTER[0].aether,
      heat: window.ROSTER[0].heat,
      echoes: window.ROSTER[0].echoes,
      staffCharges: window.ROSTER[0].staffCharges,
      worldLeadRef: window._world.player === window.ROSTER[0],
      activeLeadRef: window.ACTIVE_PARTY[0] === window.ROSTER[0],
    }));

    assert(rosterAfterCombat.vit === worldAfterCombat.vit,
      'combat vitality did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.scrap === worldAfterCombat.scrap,
      'combat scrap did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.aether === worldAfterCombat.aether,
      'combat aether did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.heat === worldAfterCombat.heat,
      'combat heat did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.echoes === worldAfterCombat.echoes,
      'combat echoes did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.staffCharges === worldAfterCombat.staffCharges,
      'combat staff charges did not persist to canonical ROSTER[0]');
    assert(rosterAfterCombat.worldLeadRef && rosterAfterCombat.activeLeadRef,
      'canonical lead reference split after combat');

    if (errors.length) {
      throw new Error('browser errors:\n' + errors.join('\n'));
    }

    console.log('Aetherwake smoke test: PASS');
    console.log(JSON.stringify({
      party: review,
      partyArchitecture,
      enemyMetadataContract,
      affordabilityContract,
      progressionReachability,
      secondaryStateContract,
      effectContract,
      registryContract,
      resolverContract,
      worldBeforeCombat,
      combatTurns: combatAfterActions.turn,
      enemy: combatAfterActions.enemy && combatAfterActions.enemy.name,
      worldAfterCombat,
    }, null, 2));
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(err => {
  console.error('Aetherwake smoke test: FAIL');
  console.error(err.stack || err.message || String(err));
  process.exit(1);
});
