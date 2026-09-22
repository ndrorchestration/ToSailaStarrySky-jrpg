# Opening Title → End of First Chapter: Fixability Analysis

## Verified working (green light)

These all pass in the current build (verified via headless browser test):

| Step | Status | Note |
|------|--------|------|
| Boot → Title screen | ✅ | 1.2s loading + 9s preamble, Enter skips, NEW GAME prompt visible |
| Title → Char-create | ✅ | NEW GAME → char-create module, 3-phase flow (title→class→name→review) |
| Char-create → World | ✅ | On phase='done', gameState→WORLD, World.init() runs, player spawns at (16,16) |
| World rendering | ✅ | Ground layer, sky layer, player sprite, NPC sprites, quest markers, HUD all draw |
| NPC dialogue | ✅ | Walk near NPC + E/Interact → dialogue overlay opens, lines advance, close on ESC |
| Signal hooks | ✅ | First talk to engine_spirit/corporate_salvager/lyra auto-completes the 3 SIGNAL hooks |
| NPC meeting | ✅ | First talk marks NPC.met=true, adds to quest.npcsMet, advances CONTACT if ≥4 met |
| Hazard proximity | ✅ | Walking into hazard zones triggers `completeHazard()` with 8-15% chance per step |
| Quest state transitions | ✅ | SIGNAL→CROSSING→CONTACT→CHOICE→WAKE→DONE all functional |
| Choice menu | ✅ | Auto-appears in CHOICE state, 3 paths, 2D6 roll, advances to WAKE |
| Epilogue → DONE | ✅ | resolveEpilogue() picks best matching ending, drawEpilogueScreen() shows it |
| Restart (R key) | ✅ | Epilogue screen shows "[ R ] to begin again" |

## What's broken or missing

### 1. Hazards don't trigger combat (the big one)

**The narrative promise:** The Core's dialogue (line 2669) says: *"Three hazards on the way to my chamber. Sky-predator first — it hunts heat signatures. Harmonic shear next — it strips the grace from men who haven't earned it. Then the corporate intercept..."*

**The code reality:** `completeHazard(index)` at line 3454-3458 just marks the hazard `done=true`, increments `hazardsCompleted`, and calls `advanceQuest()`. There is **no combat encounter** triggered. The player walks through a zone, gets a 10% random roll, and the hazard is "completed" with no fight.

**What this means:** The crossing phase is a fetch-quest walk, not a combat gauntlet. The 4 hazard zone markers draw on the ground (faint orange ellipses, lines 5189-5213) but they're just location markers, not encounter triggers.

**What needs to happen:** Either (a) make `completeHazard` trigger a `startCombat(enemyId)` for the corresponding enemy type, OR (b) admit the hazards are exploration milestones and rewrite the Core's dialogue to not promise fights. Option (a) is the fix that matches the design intent.

### 2. No in-world onboarding

When the player enters WORLD state after char-create, they're dropped at (16,16) with:
- The control hints from the title screen (WASD/E/Q/F/Tab/V/L/M/R/T) — but those are on the BOOT/TITLE screen, not in-world
- A quest HUD in the top-right showing "SIGNAL / 0/3 hooks"
- No text explaining what to do

The player has to already know: WASD to move, E to talk, that talking to NPCs progresses the quest. There's no "walk to the glowing marker" hint, no first-step direction.

**What needs to happen:** A brief in-world onboarding toast or first-step prompt when entering WORLD for the first time. Something like "Talk to the crew to learn what's wrong with the Wake" or a visible arrow/ highlight pointing to the nearest quest NPC.

### 3. Quest log (T key) accessibility unverified in WORLD state

The title screen shows "T quest log" in the control hints. The `drawQuestLogOverlay` function exists (line 2171). But I haven't verified that pressing T in WORLD state actually opens a readable quest journal. The quest state is tracked (SIGNAL/0-3 hooks, etc.) but the player may not be able to read what the quest actually is.

**What needs to happen:** Verify T opens a quest log in WORLD state. If it doesn't, wire it up. The quest log should show the current objective (e.g., "Speak to the crew" / "Discover the signal hooks" / "Cross the hazards" / "Meet the four voices").

### 4. Missing first-step direction after char-create

The transition from char-create (phase='done') → WORLD is abrupt. The player's character sheet closes and they're standing on a grass tile with no context. There's no "You wake up on the Aureate Wake" text, no initial camera framing, no "your first move" cue.

**What needs to happen:** A brief opening text overlay when first entering WORLD (only once per save, not on reload). Something like: *"You stand on the Aureate Wake. The ship hums underneath you, but the song is slipping. Find the crew and learn what's happening."*

### 5. NPC quest markers are subtle

The quest markers are small teal ellipses (8×4 pixels) pulsing above NPC heads (line 4613-4619). At 960×640 canvas with 16px tiles, that's a tiny indicator. The markers pulse faster as more NPCs are met (line 5227-5236), which is a nice touch, but the initial visibility is low.

**What needs to happen:** Either enlarge the markers, add a subtle glow, or add a "nearby quest NPC" indicator when the player is within a few tiles. The markers exist and work, but they're easy to miss.

### 6. The 4th hazard (corporate_intercept) zone overlaps with other zones

Looking at the hazard zone definitions:
- `sky_predator`: x≥28, y 4-8 (triggers at 15%)
- `wind_shear`: the code checks `tx >= 10 && tx <= 20 && ty >= 8 && ty <= 14` (10%)
- `aether_leak`: `ty <= 5 && tx >= 15 && tx <= 25` (8%)
- `corporate_intercept`: `tx >= 4 && tx <= 12 && ty >= 9 && ty <= 16` (12%)

But in `drawQuestWorldReactions`, the drawn markers use different coordinates than the trigger zones:
- wind_shear marker: drawn at xs=[28,29], y=6*16 — but the trigger zone is x 10-20, y 8-14
- aether_leak marker: drawn at xs=[13,14,15], y=11*16 — but the trigger zone is y≤5, x 15-25
- corporate_intercept marker: drawn at xs=[17,18], y=17*16 — but the trigger zone is x 4-12, y 9-16

**The visual markers don't match the trigger zones.** A player who sees the marker and walks to it may never trigger the hazard because the actual trigger zone is elsewhere. This is a coordinate mismatch bug.

### 7. No "continue" from save demonstrated

The title screen only shows "NEW GAME" in `getTitleMenuCommands()` (line 928). There's no CONTINUE option, even though the world has a full persistence system (`exportPersistentState`, `restorePersistentState`, `validatePersistentState`). The save system exists but the title screen doesn't offer it.

**What needs to happen:** Either add a CONTINUE button that loads the last save, or document that saves are only accessible in-world (via the ledger or a save toggle).

### 8. The "end of first chapter" is the choice/epilogue, but the epilogue is abrupt

After choosing a path, `advanceChoice()` → `resolveEpilogue()` → `advanceWake()` → `gameOver=true` → `drawEpilogueScreen()`. The epilogue screen shows the ending name and text, then "[ R ] to begin again."

There's no intermediate "chapter complete" beat. The player goes from choosing a path to the ending screen in one frame. For a first chapter, a brief "the ship responds to your choice" animation or text before the epilogue would land better.

## Summary: priority order

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| 1 | Hazards don't trigger combat | Medium | High — biggest narrative/code mismatch |
| 2 | Hazard marker/trap zone coordinate mismatch | Small | Medium — player confusion |
| 3 | No in-world onboarding / first-step cue | Small | High — player gets dropped with no direction |
| 4 | Quest log (T key) may not be accessible in WORLD | Small | Medium — player can't read objectives |
| 5 | NPC quest markers too subtle | Small | Low — markers exist, just small |
| 6 | No "continue" from save on title screen | Medium | Medium — persistence system is built but unused |
| 7 | Abrupt epilogue transition | Small | Low — nice-to-have polish |

The single biggest fixable item is **#1: hazards don't trigger combat**. The design intent (per the Core's dialogue and the quest structure) is a combat gauntlet, but the implementation is a proximity-based auto-complete. Fixing this means wiring `completeHazard` to call `startCombat(enemyId)` for the corresponding enemy type, and ensuring the combat system can handle the 4 hazard enemy types (skyPredator, windShear, aetherLeak, corporateIntercept — all defined in the combat enemy catalog around line 5623+).
