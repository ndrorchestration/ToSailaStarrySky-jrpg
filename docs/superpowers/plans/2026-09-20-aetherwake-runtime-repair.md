# Aetherwake Runtime Reliability and Playable-Loop Repair Implementation Plan

> FOR AGENTIC WORKERS: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Make the live Aetherwake browser game reliable across both entrypoints by completing the approved runtime repair design, preserving the playable loop, and adding regression coverage for every confirmed failure.

**Architecture:** Keep aetherwake.js as the authoritative bundled runtime. Repair the World/core boundary with explicit result objects, expose the missing read-only and transactional APIs, and make combat round trips preserve the canonical World/ROSTER player record. Keep pure bridge/registry logic in modules/ and use browser smoke for p5-dependent behavior.

**Tech Stack:** Plain JavaScript, p5.js global mode, Node test scripts, Playwright, GitHub Actions, no new runtime dependencies.

**Spec:** docs/superpowers/specs/2026-09-20-aetherwake-bug-repair-design.md

## Global Constraints

- aetherwake.js remains the authoritative bundled gameplay runtime.
- Both index-embedded.html and index.html load the dependency-complete runtime in dependency order.
- World and core transitions are fail-closed: a failed domain action cannot enter a new state.
- All shop items use scrap and commit resource changes atomically.
- Combat preserves identity, primary stats, maxima, progression, unlocks, and equipment across the World → combat → World cycle.
- Airship one-shot transfers are consumed at most once and are not consumed before the player is eligible.
- The current three-container Dragonfly airship behavior and existing airship tests remain valid.
- No broad rewrite of inactive modules/world.js or modules/combat.js.
- No sky-route travel system, combat-balance redesign, new authored roster mechanics, or new audio assets in this plan.
- Changes remain on dev/progression-build; main is untouched.

## Review Focus

1. A fast movement tap must cross at most one valid tile immediately and must not wait for the repeat timer; test it in the browser through the production keyboard path.
2. A failed shop, dialogue, ledger, or encounter action must leave the game state, resources, and active overlay unchanged; test each failure result before its success path.
3. A World → combat → World round trip must preserve non-combat player fields and maxima; test name, class, age, primary stats, maxVit, resource maxima, staff max, level, XP, unlocks, and equipment.
4. Closing an overlay by the key shown in its prompt must clear domain state and return to the prior state; test dialogue, shop, ledger, quest log, character sheet, and airship.
5. Loading either HTML entrypoint must expose the same required runtime globals with no page errors and no visible debug overlay; test both URLs in Playwright.

## File Map

- Modify: aetherwake.js — live World/core/combat/UI implementation.
- Modify: index.html — preserve dependency-complete loading and fail-closed initialization behavior.
- Modify: index-embedded.html — preserve dependency-complete loading and fail-closed initialization behavior.
- Create: tests/runtime-contracts.test.js — Node-level source and API contract regressions that do not require a canvas.
- Modify: tests/smoke-playwright.js — both-entrypoint boot coverage and player-facing regression flow.
- Modify: package.json — register the runtime contract test and include it in test:all.
- Modify: docs/DEVELOPMENT.md — document the completed runtime boundary and dual-entrypoint smoke gate after verification.

### Task 1: Add red contract tests for the remaining runtime gaps

**Files:**
- Create: tests/runtime-contracts.test.js
- Modify: tests/smoke-playwright.js
- Modify: package.json

**Interfaces:**
- Consumes: the current source text from aetherwake.js and the HTTP-served entrypoints.
- Produces: failing assertions for the missing World exports, shop handler, overlay cleanup, complete combat snapshot, and second-entrypoint smoke coverage.

- [ ] Step 1: Create tests/runtime-contracts.test.js with source-contract assertions for the World and shop slice only. Later tasks add their own red assertions before their production changes.

    const assert = require('assert');
    const fs = require('fs');
    const path = require('path');

    const source = fs.readFileSync(
      path.resolve(__dirname, '..', 'aetherwake.js'),
      'utf8'
    );

    const worldStart = source.indexOf('World = {');
    assert(worldStart >= 0, 'World export is missing');
    const worldExport = source.slice(worldStart, worldStart + 1200);

    assert(worldExport.includes('getLedger'), 'World does not export getLedger');
    assert(worldExport.includes('getShopItems'), 'World does not export getShopItems');
    assert(worldExport.includes('purchaseItem'), 'World does not export purchaseItem');
    assert(worldExport.includes('closeShop'), 'World does not export closeShop');

    assert(source.includes('window.UI.shopBuyHandler'),
      'live shop purchase handler is missing');
    assert(source.includes('world.player.scrap'),
      'shop renderer has no persistent World scrap source');

    console.log('Aetherwake runtime contract tests: PASS');

- [ ] Step 2: Extend tests/smoke-playwright.js with red assertions for World APIs and player-facing regressions.

    const worldContract = await page.evaluate(() => ({
      state: window.gameState,
      worldExports: {
        getLedger: typeof window._world.getLedger,
        getShopItems: typeof window._world.getShopItems,
        purchaseItem: typeof window._world.purchaseItem,
        closeShop: typeof window._world.closeShop,
      },
      ledger: window._world.getLedger ? window._world.getLedger() : null,
      shopItems: window._world.getShopItems ? window._world.getShopItems() : null,
    }));

    assert(worldContract.worldExports.getLedger === 'function',
      'World ledger API is not live');
    assert(worldContract.worldExports.getShopItems === 'function',
      'World shop listing API is not live');
    assert(worldContract.worldExports.purchaseItem === 'function',
      'World purchase API is not live');
    assert(worldContract.ledger.every(entry => typeof entry.text === 'string'),
      'ledger entries do not expose canonical text');
    assert(worldContract.shopItems.length >= 6,
      'Repair Cafe item list is incomplete');

- [ ] Step 3: Register the new test before the existing smoke command in package.json.

    "test:runtime-contracts": "node tests/runtime-contracts.test.js",
    "test:all": "npm run test:runtime-contracts && npm run test:effects && ... && npm run test:smoke"

    Preserve every existing test command in the current test:all chain; only prepend the new contract test.

- [ ] Step 4: Run the new test and confirm it fails for the expected missing contracts.

    Run: npm run test:runtime-contracts
    Expected: FAIL on the first missing World export, before any production implementation is changed.

- [ ] Step 5: Commit the red tests.

    git add tests/runtime-contracts.test.js tests/smoke-playwright.js package.json
    git commit -m "test: pin remaining runtime repair gaps"

### Task 2: Complete World APIs and make the shop transactional in the live bundle

**Files:**
- Modify: aetherwake.js: World export, World shop/ledger functions, drawShopOverlay, shop input wiring.
- Test: tests/runtime-contracts.test.js and tests/smoke-playwright.js.

**Interfaces:**
- Consumes: existing ledger, shop, quest, and player state.
- Produces: World.getLedger(), World.getShopItems(), World.purchaseItem(id), World.closeShop(), and a live numeric purchase handler.

- [ ] Step 1: Run the focused red tests from Task 1.

    Run: npm run test:runtime-contracts
    Expected: FAIL because the missing exports and live shop handler are not yet available.

- [ ] Step 2: Export the existing domain functions from World.

    World = {
      init, update, render,
      movePlayer, interact, toggleLayer,
      plantField, boardShip,
      openLedger, openShop, closeShop,
      openDialogue, nextDialogueLine, closeDialogue,
      getLedger, getShopItems, purchaseItem,
      getQuestState, advanceQuest
    };

    Do not expose the internal shop or ledger object directly.

- [ ] Step 3: Keep renderer-facing data isolated from mutable domain state.

    function getLedger() {
      return ledger.entries.map(entry => ({ ...entry }));
    }

    function getShopItems() {
      return shop.items.map(item => ({ ...item }));
    }

    function closeShop() {
      shop.open = false;
      window.UI.shopItems = [];
      window.UI.shopBuyHandler = null;
    }

    Every item returned by getShopItems() must contain id, name, desc, cost, kind, and the stable display order.

- [ ] Step 4: Wire shop opening to the live UI without bypassing the World result.

    function openShop() {
      const dist = Math.abs(player.tileX - shop.x) + Math.abs(player.tileY - shop.y);
      if (dist > 3) return { ok: false, reason: 'Merchant is too far away.' };

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
      window.UI.opening = true;
      window.UI.openness = 0;
      return { ok: true, items: getShopItems() };
    }

    The handler must use the current stable item ID, not a stale array index from a previous shop opening.

- [ ] Step 5: Make all purchase effects use the persistent maxima and commit atomically.

    const changes = { scrap: -item.cost };
    if (item.id === 'solar_resonator_recharge') {
      if (player.aether >= player.aetherMax) return { ok: false, reason: 'Aether already at maximum.' };
      changes.aether = 1;
    } else if (item.id === 'staff_crystal_polish') {
      const maxCharges = player.maxStaffCharges || 2;
      if (player.staffCharges >= maxCharges) return { ok: false, reason: 'Staff charges already at maximum.' };
      changes.staffCharges = 1;
    } else if (item.id === 'mycelial_thread_sheaf') {
      if (player.echoesMax >= ECHO_MAX_CAP) return { ok: false, reason: 'Echo capacity already at maximum.' };
      changes.echoesMax = 1;
      changes.echoes = 1;
    } else if (item.id === 'hull_patch_kit') {
      const delta = Math.min(10, 100 - quest.hullIntegrity);
      if (delta <= 0) return { ok: false, reason: 'Hull already at maximum.' };
      changes.hullIntegrity = delta;
    } else if (item.id === 'heat_sink_fitting') {
      if (player.heatMax >= HEAT_MAX_CAP) return { ok: false, reason: 'Heat capacity already at maximum.' };
      changes.heatMax = 1;
    } else if (item.id === 'nav_line_compass') {
      if (quest.navLineCompassOwned) return { ok: false, reason: 'Nav-Line Compass already owned.' };
      changes.navLineCompassOwned = true;
    } else {
      return { ok: false, reason: 'Unsupported shop item.' };
    }

    player.scrap += changes.scrap;
    if (changes.aether) player.aether = Math.min(player.aetherMax, player.aether + changes.aether);
    if (changes.staffCharges) player.staffCharges += changes.staffCharges;
    if (changes.echoesMax) player.echoesMax += changes.echoesMax;
    if (changes.echoes) player.echoes = Math.min(player.echoesMax, (player.echoes || 0) + changes.echoes);
    if (changes.hullIntegrity) quest.hullIntegrity = Math.min(100, quest.hullIntegrity + changes.hullIntegrity);
    if (changes.heatMax) player.heatMax += changes.heatMax;
    if (changes.navLineCompassOwned) quest.navLineCompassOwned = true;

    addLedgerEntry('purchase', 'Bought ' + item.name + ' from Repair Cafe.');
    return { ok: true, item: { ...item }, changes };

    Commit only after every item-specific validation has passed. The existing pre-check for scrap remains before the effect checks so insufficient currency cannot mutate any resource.

- [ ] Step 6: Render persistent scrap and live item status.

    const scrap = world && world.player ? world.player.scrap : 0;
    const items = window.UI.shopItems || (world && world.getShopItems ? world.getShopItems() : []);

    Remove the combat.getScrap() fallback and literal 7. Keep the existing six-item layout and display a disabled color for insufficient scrap or maxed items.

- [ ] Step 7: Run focused tests.

    Run: npm run test:runtime-contracts
    Expected: PASS.

- [ ] Step 8: Commit the completed World/shop slice.

    git add aetherwake.js tests/runtime-contracts.test.js package.json
    git commit -m "fix: complete world ledger and shop contracts"

### Task 3: Repair state transitions, overlay routing, and dialogue cleanup

**Files:**
- Modify: aetherwake.js: interact/doTalk/openDialogue/nextDialogueLine/closeDialogue, handleWorldInput, handleInput, closeOverlay, keyTyped.
- Test: tests/runtime-contracts.test.js and tests/smoke-playwright.js.

**Interfaces:**
- Consumes: World structured action results and the existing STATE/openState/prevState model.
- Produces: deterministic World → overlay → World transitions with no stale dialogue or shop state.

- [ ] Step 1: Add red source and browser assertions for the actual overlay contracts.

    const source = fs.readFileSync(
      path.resolve(__dirname, '..', 'aetherwake.js'),
      'utf8'
    );
    assert(source.includes("return { ok: true, kind: 'dialogue'"),
      'dialogue interaction does not return a structured success result');
    assert(source.includes('world.closeDialogue()'),
      'overlay cleanup does not close World dialogue state');
    assert(source.includes('world.closeShop()'),
      'overlay cleanup does not close World shop state');

    const shopFailure = await page.evaluate(() => {
      const p = window._world.player;
      const saved = { tileX: p.tileX, tileY: p.tileY };
      p.tileX = 0;
      p.tileY = 0;
      const result = window._world.openShop();
      p.tileX = saved.tileX;
      p.tileY = saved.tileY;
      return { result, state: window.gameState };
    });
    assert(shopFailure.result.ok === false, 'out-of-range shop opened');
    assert(shopFailure.state === 'world', 'failed shop action changed state');

- [ ] Step 2: Make World interaction return an explicit domain result.

    function interact() {
      const nearest = findNearestNPC(2);
      if (nearest) return doTalk();
      return { ok: false, kind: 'none', reason: 'Nothing to interact with.' };
    }

    function doTalk() {
      const nearest = findNearestNPC(2);
      if (!nearest) return { ok: false, kind: 'dialogue', reason: 'No nearby NPC.' };

      const firstMeeting = !nearest.flags.met;
      const result = openDialogue(nearest);
      if (!result || result.ok === false) return result;

      if (firstMeeting) {
        nearest.flags.met = true;
        if (!quest.npcsMet.includes(nearest.id)) quest.npcsMet.push(nearest.id);
        if (quest.state === QUEST_STATES.CONTACT || quest.state === QUEST_STATES.CHOICE) {
          advanceQuest();
        }
      }
      if (quest.state === QUEST_STATES.SIGNAL) checkSignalHook(nearest);
      return result;
    }

    openDialogue() must prepare the dialogue data and return { ok: true, kind: 'dialogue', npcId, lineCount } without entering the global game state. The first-meeting decision is captured before setting met, so intro lines remain authoritative.

- [ ] Step 3: Let core own the dialogue state transition.

    if (keysPressed[69]) {
      if (gameState === STATE.DIALOGUE) {
        const advanced = world.nextDialogueLine();
        if (advanced === null) closeOverlay();
      } else {
        const result = world.interact();
        if (result && result.ok && result.kind === 'dialogue') {
          openState(STATE.DIALOGUE);
        }
      }
    }

    Preserve the existing F/Q/Tab behavior and the M result-based shop transition.

- [ ] Step 4: Route every prompt key while its overlay is open.

    if (gameState === STATE.DIALOGUE && keysPressed[69]) {
      world.nextDialogueLine();
    } else if (gameState === STATE.SHOP &&
      (keysPressed[77] || keysPressed[27])) {
      world.closeShop();
      closeOverlay();
    } else if (gameState === STATE.LEDGER &&
      (keysPressed[76] || keysPressed[27])) {
      closeOverlay();
    } else if (gameState === STATE.QUESTLOG &&
      (keysPressed[84] || keysPressed[27])) {
      closeOverlay();
    } else if (gameState === STATE.CHARSHEET &&
      (keysPressed[82] || keysPressed[27])) {
      closeOverlay();
    }

    Enter/Space remain valid generic close or advance keys where the current overlay has no conflicting action.

- [ ] Step 5: Make closeOverlay clear domain state before returning.

    function closeOverlay() {
      if (gameState === STATE.DIALOGUE && world && world.closeDialogue) {
        world.closeDialogue();
      }
      if (gameState === STATE.SHOP && world && world.closeShop) {
        world.closeShop();
      }
      if (gameState === STATE.AIRSHIP && world && world.player) {
        world.player.shipBoarded = false;
      }
      if (!prevState) return;
      gameState = prevState;
      window.gameState = gameState;
      prevState = null;
      if (VIS.fadeTransitions) startFade(100);
    }

    The function must not return to a stale non-world state after dialogue or shop closure.

- [ ] Step 6: Make numeric dialogue choices use keyPressed and prevent keyTyped duplication.

    Change handleChoiceInput to accept an optional character value and use the event value first:

    function handleChoiceInput(value) {
      if (quest.state !== QUEST_STATES.CHOICE || quest.choiceMade) return;
      const selected = value || (typeof key !== 'undefined' ? key : '');
      if (selected >= '1' && selected <= '3') {
        selectChoicePath(parseInt(selected, 10) - 1);
      }
    }

    In keyPressed(), call handleChoiceInput(String.fromCharCode(keyCode)) for keyCode 49 through 51 while the dialogue/choice state is active. In keyTyped(), call handleChoiceInput() only for the WORLD state when no overlay transition has consumed the event. The same key event must not select twice.

- [ ] Step 7: Run focused browser smoke and commit.

    Run: npm run test:smoke
    Expected: the current flow plus dialogue/shop/overlay assertions pass.

    git add aetherwake.js tests/smoke-playwright.js tests/runtime-contracts.test.js
    git commit -m "fix: make dialogue and overlay transitions deterministic"

### Task 4: Preserve the full player snapshot and harden combat encounters

**Files:**
- Modify: aetherwake.js: startCombat, finishCombat, AetherCombat.init, levelUp, beginEncounter, transient-state reset.
- Test: tests/runtime-contracts.test.js and tests/smoke-playwright.js.

**Interfaces:**
- Consumes: canonical World player/ROSTER[0] data and existing AetherAbilityDefs/AetherProgressionDefs contracts.
- Produces: a complete combat snapshot, deterministic transient reset, multi-level XP progression, and fail-closed encounter setup.

- [ ] Step 1: Add red source and browser assertions for complete snapshot round trips.

    const requiredSnapshotFields = [
      'name', 'age', 'class', 'wits', 'presence', 'spirit',
      'might', 'grace', 'maxVit', 'aetherMax', 'heatMax',
      'echoesMax', 'maxStaffCharges', 'level', 'xp',
      'xpToNext', 'unlockedAbilities', 'equipment',
    ];
    for (const field of requiredSnapshotFields) {
      assert(source.includes('options.' + field) || source.includes(field + ': world.player.' + field),
        'combat snapshot field is missing: ' + field);
    }

    const roundTrip = await page.evaluate(() => {
      const p = window._world.player;
      const before = {
        name: p.name,
        age: p.age,
        className: p.class,
        wits: p.wits,
        presence: p.presence,
        spirit: p.spirit,
        might: p.might,
        grace: p.grace,
        maxVit: p.maxVit,
        aetherMax: p.aetherMax,
        heatMax: p.heatMax,
        echoesMax: p.echoesMax,
        maxStaffCharges: p.maxStaffCharges,
        level: p.level,
        xp: p.xp,
        xpToNext: p.xpToNext,
        unlockedAbilities: p.unlockedAbilities.slice(),
        equipment: JSON.parse(JSON.stringify(p.equipment)),
      };
      startCombat('skyPredator');
      const combatPlayer = window._combat.getState().player;
      finishCombat();
      const after = window._world.player;
      return { before, combatPlayer, after };
    });

    for (const field of requiredSnapshotFields) {
      const afterField = field === 'class' ? roundTrip.after.class : roundTrip.after[field];
      assert.deepStrictEqual(afterField, roundTrip.before[field === 'class' ? 'className' : field],
        'round-trip lost ' + field);
    }

- [ ] Step 2: Copy and clamp all persistent fields in AetherCombat.init(options).

    const maxVit = Math.max(1, Number(options.maxVit ?? 13));
    state.player.name = options.name ?? 'Young Ender';
    state.player.age = options.age ?? 28;
    state.player.class = options.class ?? 'Rift Scholar + Dreamwright';
    state.player.vit = Math.min(maxVit, Math.max(1, Number(options.vit ?? maxVit)));
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
    state.maxStaffCharges = Math.max(0, Number(options.staffMax ?? options.maxStaffCharges ?? 2));
    state.player.maxStaffCharges = state.maxStaffCharges;
    state.player.staffCharges = Math.min(
      state.maxStaffCharges,
      Math.max(0, Number(options.charges ?? options.staffCharges ?? state.maxStaffCharges))
    );

    Resource normalization must guarantee current values are within [0, max] and must preserve object-shaped and numeric-shaped callers.

- [ ] Step 3: Reset all per-encounter fields in init and beginEncounter.

    state._totalDamageDealt = 0;
    state._victoryStats = null;
    state._lastDamageNum = null;
    state._critFlashTurn = 0;
    state._playerHitTurn = 0;
    state._dodgeTurn = 0;
    state._defeatTurn = 0;
    state._enemyAbilityFlash = 0;
    state._lastTurnCrit = false;
    state._airshipOpeningDamage = 0;
    state._secondaryAvailable = false;
    state._lastAbilityId = null;

    beginEncounter(enemyId) must validate the enemy before any encounter state is changed. The unknown-ID branch returns { ok: false, reason } directly without calling log(), because logging would mutate the previous encounter. A known ID then resets the encounter fields and starts its fresh log.

- [ ] Step 4: Make awardXP process all earned levels deterministically.

    this.levelUp = function() {
      const p = state.player;
      let leveled = false;
      while (p.xp >= p.xpToNext) {
        p.xp -= p.xpToNext;
        p.level++;
        p.xpToNext = Math.floor(50 * Math.pow(1.5, p.level - 1));
        p.echoes.max = Math.min(6, p.echoes.max + 1);
        const levelUnlocks = window.AetherProgressionDefs.getUnlocksForLevel(p.level);
        levelUnlocks.forEach(unlock => {
          if (!p.unlockedAbilities.includes(unlock.abilityId)) {
            p.unlockedAbilities.push(unlock.abilityId);
            log(unlock.log);
          }
        });
        leveled = true;
      }
      if (leveled) log('── LEVEL UP! You are now level ' + p.level + '. ──');
      return leveled;
    };

    Keep the current XP formula and unlock registry.

- [ ] Step 5: Write back all persistent fields in finishCombat.

    const persistentFields = [
      'name', 'age', 'class', 'wits', 'presence', 'spirit',
      'might', 'grace', 'maxVit', 'level', 'xp', 'xpToNext',
      'unlockedAbilities', 'equipment',
    ];
    persistentFields.forEach(field => {
      if (field === 'class') world.player.class = p.class;
      else if (p[field] !== undefined) world.player[field] = Array.isArray(p[field])
        ? p[field].slice()
        : (p[field] && typeof p[field] === 'object'
          ? JSON.parse(JSON.stringify(p[field]))
          : p[field]);
    });

    Write current resources and maxima from p.aether, p.heat, p.echoes, and p.maxStaffCharges after the field loop. World and ROSTER[0] remain the same object reference.

- [ ] Step 6: Run focused tests and commit.

    Run: npm run test:runtime-contracts && npm run test:smoke
    Expected: full snapshot checks, multi-level progression checks, combat log checks, and existing airship flow pass.

    git add aetherwake.js tests/runtime-contracts.test.js tests/smoke-playwright.js
    git commit -m "fix: preserve player state across combat"

### Task 5: Exercise both entrypoints and make initialization failure visible

**Files:**
- Modify: index.html
- Modify: index-embedded.html
- Modify: tests/smoke-playwright.js
- Modify: docs/DEVELOPMENT.md

**Interfaces:**
- Consumes: the current script order and setup contract.
- Produces: equivalent boot behavior, visible failure state for missing dependencies, and smoke coverage for both entrypoints.

- [ ] Step 1: Add a reusable Playwright entrypoint runner.

    async function bootEntrypoint(entrypoint) {
      const entryPage = await browser.newPage({ viewport: { width: 960, height: 640 } });
      const entryErrors = [];
      entryPage.on('pageerror', error => entryErrors.push('PAGE: ' + error.message));
      entryPage.on('console', message => {
        if (message.type() === 'error') entryErrors.push('CONSOLE: ' + message.text());
      });

      const response = await entryPage.goto(
        baseUrl + '/' + entrypoint,
        { waitUntil: 'domcontentloaded', timeout: 20000 }
      );
      assert(response && response.ok(), entrypoint + ' did not load successfully');
      await entryPage.waitForSelector('canvas', { timeout: 15000 });
      await entryPage.waitForFunction(() =>
        window._world && window._combat && window._charcreate &&
        document.querySelector('canvas')
      , undefined, { timeout: 15000 });

      return { page: entryPage, errors: entryErrors };
    }

    Use the embedded page for the full gameplay flow and use the legacy page for boot, debug-overlay, and one real Enter transition. Close both pages in a finally block.

- [ ] Step 2: Assert identical required script sets in both HTML files.

    const requiredScripts = [
      'modules/effect-vocabulary.js',
      'modules/effect-resolver.js',
      'modules/ability-defs.js',
      'modules/progression-defs.js',
      'modules/party-state.js',
      'modules/airship-state.js',
      'modules/airship-combat-bridge.js',
      'modules/airship-ui.js',
      'modules/audio.js',
      'aetherwake.js',
      'modules/char-create.js',
      'p5.min.js',
    ];

    The smoke test reads both HTML files from the local server and asserts each required script appears once and in the same relative order.

- [ ] Step 3: Add an initialization failure surface that is not a false playable screen.

    The page must contain one hidden initialization-status node:

    <div id="aetherwake-init-error" role="alert" hidden></div>

    setup() calls showInitializationFailure(message) when a required runtime object is missing. The helper sets the node text, removes hidden, adds a stable aetherwake-init-failed class, and stops normal state progression. Normal startup leaves the node hidden.

    Do not use a fixed timeout to reveal a canvas or advance into the game when setup has failed.

- [ ] Step 4: Run the two-entrypoint smoke.

    Run: npm run test:smoke
    Expected: index-embedded.html and index.html both load, expose World/combat/char-create, hide debug UI, and emit no page/console errors.

- [ ] Step 5: Update docs/DEVELOPMENT.md with the verified dual-entrypoint smoke contract.

    Document that both entrypoints are tested, that a missing required module produces the initialization-status error, and that aetherwake.js remains the runtime authority.

- [ ] Step 6: Commit the entrypoint slice.

    git add index.html index-embedded.html tests/smoke-playwright.js docs/DEVELOPMENT.md
    git commit -m "test: verify both playable entrypoints"

### Task 6: Verify visual correctness and the complete repair gate

**Files:**
- Modify: tests/runtime-contracts.test.js
- Modify: tests/smoke-playwright.js
- Modify: docs/DEVELOPMENT.md only if the command list changes.

**Interfaces:**
- Consumes: all repaired APIs and entrypoint behavior.
- Produces: a fresh, reproducible verification record.

- [ ] Step 1: Add source assertions for the confirmed visual fixes.

    assert(source.includes('const nightFactor = isNight()'),
      'vignette does not use canonical night state');
    assert(source.includes('stroke(color(80, 120, 60, 80))'),
      'grass wind does not set a visible stroke');

- [ ] Step 2: Run the complete local gate.

    Run: npm run test:all
    Expected: every existing registry/resolver/progression/combat/airship test, runtime-contract test, and Playwright smoke test passes.

- [ ] Step 3: Run the smoke test again from a clean process.

    Run: node tests/smoke-playwright.js
    Expected: PASS with both entrypoints and no browser errors.

- [ ] Step 4: Run the repository’s CI-equivalent commands individually to identify the first failure precisely.

    Run:
      npm run test:runtime-contracts
      npm run test:effects
      npm run test:registries
      npm run test:resolver
      npm run test:resolver-integration
      npm run test:enemy-metadata
      npm run test:combat-input
      npm run test:resource-eligibility
      npm run test:progression-reachability
      npm run test:secondary-action
      npm run test:airship
      npm run test:airship-combat-bridge
      npm run test:smoke

    Expected: every command exits with status 0.

- [ ] Step 5: Perform the final branch-scope review.

    Confirm:
    - the branch is dev/progression-build;
    - main has not been modified;
    - every changed production file is in the File Map;
    - no temporary test artifacts or generated desktop outputs are added;
    - the runtime contract and smoke tests fail closed rather than silently skipping unavailable features.

- [ ] Step 6: Commit the final verification/documentation adjustment.

    git add tests/runtime-contracts.test.js tests/smoke-playwright.js docs/DEVELOPMENT.md
    git commit -m "test: close the comprehensive runtime repair gate"

## Completion Criteria

The plan is complete only when all of the following are true:

- tests/runtime-contracts.test.js passes.
- Existing unit and integration tests pass unchanged unless a test directly encoded the repaired behavior.
- Both index-embedded.html and index.html boot with the same required runtime dependencies.
- Dialogue, ledger, shop, combat, and airship paths have observable regression coverage.
- Shop purchases use persistent World scrap and cannot partially mutate state on failure.
- Combat preserves the canonical player record across a complete handoff.
- A missing runtime dependency produces a visible initialization failure instead of a false playable state.
- No debug overlay is visible during normal startup.
- No change is made to main.
- The final response reports fresh command output, changed commits, and any intentionally deferred non-goals.
