# Aetherwake Comprehensive Runtime Bug-Repair Design

**Date:** 2026-09-20  
**Branch:** `dev/progression-build`  
**Status:** Design for review; no production-code changes are authorized until this document is approved.

## 1. Goal and success criteria

Repair the live Aetherwake runtime comprehensively enough that the existing playable loop is reliable across both shipped HTML entrypoints:

- world movement and interaction;
- dialogue and overlays;
- ledger/lore and quest progression;
- shop access and purchases;
- combat initialization, logging, and return flow;
- airship-to-combat handoff;
- visual state-dependent rendering.

The repair must preserve the existing airship feature and its current intended smoke-test behavior while eliminating confirmed regressions and fail-open paths. The finished branch must pass the existing test suite plus regression coverage for every repaired behavior, and both `index-embedded.html` and `index.html` must boot without page or console errors.

Sky-route travel, a combat-balance redesign, a broad rewrite of inactive mirror modules, new authored content, and new audio assets are explicitly outside this repair pass.

## 2. Runtime authority and boundaries

- `aetherwake.js` remains the authoritative bundled runtime for gameplay behavior.
- Pure rule modules under `modules/` remain the preferred home for reusable definitions, resolvers, and bridge logic.
- Existing mirror files such as `modules/world.js` and `modules/combat.js` will not be rewritten wholesale merely to make them resemble the bundle. They are updated only when an entrypoint or tested public contract requires it.
- Both HTML entrypoints must load the dependency-complete runtime set. `char-create.js` remains after `aetherwake.js` because it depends on the runtime namespace.
- Changes are limited to `dev/progression-build`; `main` is not modified.

The repair uses small, explicit interfaces between the core state machine and the bundled world/combat systems. A failed lookup or invalid action must not silently advance game state.

## 3. Design

### 3.1 Entry-point parity and boot safety

Make `index.html` and `index-embedded.html` load the same required gameplay modules in dependency order, including the live audio module when the runtime references it. Preserve the existing embedded entrypoint’s working module order and apply its missing dependencies to the legacy entrypoint.

The legacy debug overlay is hidden by default. If retained for development, it is enabled only by an explicit debug query flag and reads the live `_world`/`_combat` instances rather than stale placeholders.

Boot behavior is fail-closed:

- missing required modules produce one clear initialization error;
- the page does not claim to be playable when the runtime is incomplete;
- browser smoke tests assert that both entrypoints create a canvas, load the runtime, and produce no uncaught page errors.

### 3.2 Input routing, overlays, and dialogue

Input routing is made event-order safe. The active interaction key is assigned before the state handler runs, and it is cleared or replaced after dispatch so `E/Q/F` actions cannot consume the previous key’s value.

World movement handles the first keydown immediately, then applies the existing repeat interval. A quick tap therefore moves once before keyup, while held movement retains the current repeat behavior.

Overlay input matches the prompts shown to the player:

- the documented state-specific close/action keys are routed while the overlay is open;
- Enter/Escape remain universal close/advance fallbacks where appropriate;
- numeric dialogue choices are handled through the keydown path as well as text input, so browser/key-layout differences cannot leave choices inert;
- an overlay action that is invalid for the current overlay is ignored without changing state.

Dialogue becomes a real state-machine transition:

1. `doTalk()` identifies the nearest NPC.
2. It opens the NPC’s introduction before setting the NPC’s `met` flag.
3. `openDialogue()` sets the active NPC/line and transitions to `STATE.DIALOGUE`.
4. `nextDialogueLine()` advances the current line or resolves the selected choice.
5. `closeDialogue()` clears active dialogue and any associated audio/choice state before returning to the prior world state.

The World public API exports `nextDialogueLine` and `closeDialogue`; core code no longer calls an undefined method. Closing any overlay also clears stale dialogue references.

### 3.3 World state, lore, quest progression, and ledger

World data uses separate storage for tile identity and lore metadata. Lore text is stored in a `loreLayer[y][x]` sidecar, never as a property on a numeric tile value. Lore lookup and rendering read the sidecar and return no lore only when the cell genuinely has no entry.

Initialization publishes the final quest object after `initQuest()` has completed, so `World.quest` and the internal quest state cannot diverge.

Player coordinates have one synchronization point: movement updates the current tile coordinates, pixel coordinates, and the legacy `player.x/y` representation together.

Crossing completion is data-driven. `advanceCrossing()` requires every configured crossing hazard to be complete, using the hazard-list length rather than the current hard-coded threshold. Empty or malformed hazard lists fail closed and do not advance the quest.

The ledger API is complete and read-only from the renderer’s perspective. `getLedger()` returns the current discovered entries and quest facts without exposing mutable internal arrays. The ledger overlay renders the returned data rather than an undefined method or a hard-coded placeholder.

### 3.4 Shop contract and transactional purchases

The core opens the shop only through the World shop API. `world.openShop()` performs the merchant-distance check, initializes the current item list, and returns whether the shop actually opened. Directly forcing `STATE.SHOP` from a keyboard branch is removed.

The World API exposes:

- `getShopItems()` for a fresh display-safe item list;
- `purchaseItem(id)` for one validated purchase;
- `closeShop()` or the equivalent state-cleanup path.

All shop items use scrap as their purchase currency. A purchase is transactional: the item is validated, the player has enough scrap, the effect can be applied, and only then are the effect and scrap deduction committed. Unknown items, insufficient scrap, missing prerequisites, and already-maxed resources return a failure result and leave all state unchanged.

The existing item identities are retained with concrete effects:

- Solar Resonator Recharge restores one current aether, clamped to its maximum.
- Staff Crystal Polish restores one current staff charge, clamped to its maximum.
- Mycelial Thread Sheaf increases the echo capacity by one and grants the corresponding current echo, subject to the existing cap model.
- Hull Patch Kit restores ten hull points, clamped to maximum hull.
- Heat Sink Fitting increases heat capacity by one and keeps current heat within the new bounds.
- Nav-Line Compass records ownership in quest state and the ledger as a stable route signature; it does not invent a new combat modifier in this repair pass.

The shop UI is populated from the World API and refreshed after a successful purchase. Its scrap count comes from persistent World player state, never from a combat-only accessor or a literal fallback. Number-key purchase handlers operate on item IDs from the current shop list.

### 3.5 Combat initialization, logging, and airship handoff

Combat receives a complete player snapshot from persistent World state, including identity/class fields, primary stats, current and maximum vitality, aether, staff charges, level, XP, unlocks, and equipment. Combat initialization clamps values to valid maxima and synchronizes both the encounter state’s staff maximum and the nested player snapshot’s staff maximum.

Every encounter resets transient fields, including accumulated damage, victory statistics, animation flashes, action queues, and per-encounter log data. A previous encounter cannot leak its log or victory state into the next one.

The combat renderer consumes the authoritative combat state log. The live path no longer depends on an unpopulated `window.UI.combatLog` array. The log is updated after player actions, enemy actions, and resolution, and the renderer handles an empty log without throwing.

Unknown enemy IDs and invalid encounter setup fail closed before entering `STATE.COMBAT`; they do not strand the player in an unusable combat screen.

Airship modifiers are applied only when the player is eligible:

- a boarded player may use the ship’s active/passive combat transfer;
- a player on the ground does not consume the ship’s default Guard/Shield transfer;
- a one-shot transfer explicitly armed before disembarking remains eligible for the next combat and is consumed exactly once;
- an ineligible or already-consumed transfer leaves airship state unchanged.

This preserves the existing pending Phase-Slip/Lance handoff while preventing the default airship transfer from being consumed before the player has ever boarded.

### 3.6 Small visual correctness fixes

Use the canonical night-state function when drawing the vignette so day/night values do not depend on an unassigned global.

Set a visible stroke before drawing grass-wind lines, preserving the current fill/style afterward. These changes are intentionally limited to confirmed rendering defects and do not alter art direction.

## 4. Error handling and invariants

The following invariants are enforced and tested:

- state transitions occur only after their prerequisite API call succeeds;
- invalid shop, dialogue, encounter, and overlay actions do not partially mutate state;
- currency and resource deductions are atomic;
- current resources never exceed their maxima or fall below zero;
- dialogue cannot remain active after leaving the dialogue state;
- combat logs and transient combat statistics belong to exactly one encounter;
- airship one-shot transfers are consumed at most once;
- quest progression cannot skip an incomplete hazard;
- both entrypoints expose the same gameplay capabilities.

## 5. Test-first implementation strategy

Each repair slice begins with a failing regression test, followed by the smallest implementation that makes it pass, then the relevant full suite.

Coverage will include:

1. Pure/state tests for input ordering, immediate movement, dialogue transitions, first-meeting text, quest hazard thresholds, lore sidecars, ledger reads, shop transactions, combat snapshot normalization, transient reset, and airship-transfer eligibility.
2. Existing unit and integration suites for effect resolution, progression, combat input/resources, enemies, and airship behavior.
3. Browser smoke coverage for both HTML entrypoints:
   - dependency-complete boot and canvas creation;
   - no uncaught page/console errors;
   - debug overlay hidden by default;
   - world movement on a quick key tap;
   - dialogue opening, introduction text, advancement, and close;
   - ledger contents and shop distance gating;
   - successful and rejected purchases;
   - crossing completion only after all hazards;
   - non-empty combat log after an action;
   - no pre-boarding airship transfer and correct consumption of an armed transfer.

The browser tests use observable public behavior rather than private implementation details wherever possible.

## 6. Implementation order

The later implementation plan will use these isolated slices:

1. Add red tests and repair entrypoint/module parity.
2. Repair input ordering, immediate movement, overlay routing, and dialogue APIs.
3. Repair world initialization, lore storage, coordinates, ledger, and hazard completion.
4. Repair shop wiring and transactional item effects.
5. Repair combat snapshot/reset/logging and airship-transfer eligibility.
6. Apply the two confirmed visual fixes.
7. Run all unit, integration, and browser gates, then perform a final diff and branch-scope review.

No production implementation begins until this design is approved and converted into an implementation plan.

## 7. Acceptance criteria

The repair is complete only when:

- all existing tests pass;
- all new regression tests pass;
- both HTML entrypoints boot under browser smoke without uncaught errors;
- the confirmed bugs above have observable regression coverage;
- existing intended airship handoff behavior remains covered;
- no debug overlay is visible by default;
- no changes are made to `main`;
- the final report identifies any intentionally deferred defects or non-goals.
