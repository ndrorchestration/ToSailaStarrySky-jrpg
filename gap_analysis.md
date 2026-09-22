> **Historical prototype audit — not current runtime SSOT.** This document records earlier preservation-era implementation checks, including 2D6/PbtA combat. Current runtime authority is `aetherwake.js` plus the loaded contract modules and current Notion SSOT. Do not treat the “delivered” labels below as current production semantics.

> **Current desktop/release overlay — 2026-09-22.** The player-facing launcher has since been restructured around a clean RPG Maker MV/NW.js-style deployment: root launcher manifest → `www/index-embedded.html` → isolated `www/` payload. The correction is merged at `304835c12555e35061870a54d61f7c95996d0bdd`. Hosted verification is presently blocked before runner allocation (`runner_id: 0`, zero steps), so no fresh installer is currently promoted as verified. Any older packaging conclusions below are historical audit evidence only.

# Aetherwake Spec Conformance Audit — gap_analysis.md
> Status as of 2026-09-19. The `aetherwake.js` monolith has been expanded from 6,798 lines (when
> this document was first authored) to 7,523 lines through three agent expansion squads (combat §6-§7,
> character creation wiring, quest UI + Memories polish). Re-read cited regions before trusting any
> claim below — line numbers shifted during expansion.

## §0 — Historical structural note — superseded

**Historical finding at the time of this audit:** the entrypoint loaded a much smaller runtime surface centered on `aetherwake.js` and char-create. This is **superseded**. Current executable authority is the present `index-embedded.html` load order plus the integrated `aetherwake.js` runtime and its loaded contract modules. Do not use this old structural description to route current edits.

---

## §6 — Combat Actions (8 wired + 3 unlockable) — HISTORICAL SNAPSHOT

**SPEC requirement (lines 17–30, 25–29):** *Turn-based 2D6 PbtA. Ender abilities: Uncover Truth,
Shared Dream, Mycelial Ledger, Resonator Staff. 3 unlockable: wind ward, aether seal, rest.*

| Requirement | Status | Detail |
|---|---|---|
| 2D6 resolution with 10+/7-9/6- outcomes | ✅ Delivered | `roll2d6Plus(stat)`: returns `{dice, stat, total, outcome}`. |
| Initiative: Grace + Wits | ✅ Delivered | `state.initiative = state.player.wits + state.player.grace`. |
| Staff Strike (EMP 1d6+2, 2 charges) | ✅ Delivered | `staffStrike`, attack, might, cost 0, tier 0. |
| Uncover Truth (2D6+Wits, reveal weakness, +1 next roll) | ✅ Delivered | `uncoverTruth`, tier 1. Sets `nextRollBonus = 1` on success. |
| Shared Dream (2D6+Spirit, heal 1-2 Vit OR +1 next action) | ✅ Delivered (both branches) | `sharedDream`, tier 1. 50/50 split via `random(0,2) < 1`: heal `floor(random(1,3))` Vit OR set `nextRollBonus = 1`. |
| Mycelial Ledger (2D6+Presence, gain scrap or aether) | ✅ Delivered | `mycelialLedger`, tier 0. |
| Hold (regain 1 staff charge) | ✅ Delivered | `hold`, tier 0. |
| Wind Ward (unlockable, level 3) | ✅ Delivered | `windWard`, tier 1. `levelUp()` unlocks at level 3. |
| Aether Seal (unlockable, level 4) | ✅ Delivered | `aetherSeal`, tier 2. `levelUp()` unlocks at level 4. |
| Rest (unlockable, level 5) | ✅ Delivered | `rest`, tier 0. `levelUp()` unlocks at level 5. |
| All 8 actions shown in combat panel | ✅ Delivered | Combat panel action grid shows all 8 actions with number keys 1–8. |
| Action cost resource system (echoes/aether) | ✅ Delivered | `resourceCost = (action.tier || 0) + action.cost` echoes (or aether fallback). |
| Heat generation on actions | ✅ Delivered | Actions increment `heat.current`. |
| Enemy turn with type-specific abilities | ✅ Delivered | 4 original + 3 new enemy types, each with type-specific ability. |
| Combat UI: dice display, turn log, action panel | ✅ Delivered | Full combat panel, log, dice roll, die rendering. |
| Secondary action mechanic (S-key) | ✅ Delivered | After 10+ on ability with 2+ echoes, S-key re-runs last ability, consuming 1 echo. |

**Tier assignments (SPEC line 24: +1/+2/+3 resource spend):**
| Action | Tier | Resource cost |
|---|---|---|
| staffStrike | 0 | free |
| uncoverTruth | 1 | 1 echo |
| sharedDream | 1 | 1 echo |
| mycelialLedger | 0 | free |
| hold | 0 | free |
| windWard | 1 | 1 echo |
| aetherSeal | 2 | 2 echoes |
| rest | 0 | free |

**Gaps resolved by §6 expansion (2026-09-18):** Shared Dream both branches; Aether Seal L4 gating;
ENEMY_ABILITIES definition + population; keys 1–8; secondary action S-key; tiered resource spend;
3 new enemy types (engine_spirit, child_prophet, elder_farmer).

**Remaining gaps in §6:** None. All combat action requirements delivered.

---

## §7 — Enemy Types — HISTORICAL SNAPSHOT

**SPEC requirement (lines 25–29, combat context):** *6 enemy types: sky predator, harmonic shear,
corporate intercept, engine spirit, child prophet, elder farmer*

| Enemy Type | Status | Detail |
|---|---|---|
| Sky Predator | ✅ Delivered | `skyPredator` enemy + crossing hazard `sky_predator` (stat: might). |
| Harmonic Shear | ✅ Delivered (as "windShear") | `windShear` enemy + crossing hazard `wind_shear` (stat: grace). |
| Corporate Intercept | ✅ Delivered (as "corporateSalvager") | `corporateSalvager` enemy + crossing hazard `corporate_intercept` (stat: presence). |
| Aether Leak | ✅ Delivered | `aetherLeak` combat enemy + `aether_leak` crossing hazard (stat: wits). |
| Engine Spirit | ✅ Delivered | `engine_spirit` NPC + combat enemy. HP 10, `harmonic_pulse` ability (2D6+presence, drains 1 aether on 7-9+). |
| Child Prophet | ✅ Delivered | `child_prophet` NPC + combat enemy. HP 8, `prophecy_voice` ability (2D6+grace, lowers enemy confidence). |
| Elder Farmer (Ionia) | ✅ Delivered | `elder_farmer` NPC + combat enemy. HP 16, `soil_anchor` ability (2D6+might, roots enemy in place). |

**Gap summary:** All 6 SPEC enemy types now have both world NPC presence AND combat encounter
counterparts. Each enemy type has a `draw{NPCName}Body()` function for rendering.

---

## §8 — Visual Aesthetic

**SPEC requirement (lines 45–50):** *Palette, fonts, effects, background.*

| Requirement | Status | Detail |
|---|---|---|
| 8-color palette | ✅ Delivered | `C` object (RGB) + `PAL` object (hex). |
| VT323 font | ✅ Delivered | Google Fonts base64 in `index-embedded.html`. |
| Press Start 2P font | ✅ Delivered | Used in boot, title, dialogue, overlays. |
| Scanlines | ✅ Delivered | `drawScanlines()` at end of `draw()`. |
| Teal glow on text | ✅ Delivered | `drawGlowText()`. |
| Pixel borders | ✅ Delivered | `drawPixelBorder()` on every overlay panel. |
| Subtle teal grid overlay | ✅ Delivered | `drawBackgroundGrid()` every frame. |
| Dark navy background | ✅ Delivered | `background(C.navy)` every frame. |
| 14 falling-upward islands | ✅ Delivered | `drawFallingIslands()` renders all 14. |
| Vignette (intensifies at night) | ✅ Delivered | `drawVignette()` with night/day alpha. |
| Quest-state atmospheric tint | ✅ Delivered | `drawQuestWorldReactions()` + `drawWorldAmbient()`. |
| Player visual evolution | ✅ Delivered | Heat shimmer + solar shimmer. |
| Ship interior (Unfinished Song) | ✅ Delivered | `drawShipInterior()` renders top-down deck view when `player.shipBoarded`. |

**Gap summary:** Visual spec fully delivered. No gaps.

---

## §9 — Audio / TTS Module

| Requirement | Status | Detail |
|---|---|---|
| Web Audio SFX | ✅ Delivered | `modules/audio.js`: full synthesized SFX module. |
| `ensureAudio()` / `resumeAudio()` | ✅ Delivered | Called in `keyPressed()`. |
| NPC dialogue TTS audio | ⚠️ Optional / no canonical clips present | The runtime retains the TTS hook but now fails closed **before networking** unless an explicit `AetherDialogueTTSManifest` admits the exact clip. Missing optional TTS therefore does not generate 404s or block dialogue. |
| SFX wiring from combat to audio | ✅ Delivered | `triggerCombatHitFeedback()` + `triggerAbilityFeedback()` after each `resolveTurn`. |

**Gap:** NPC dialogue TTS wired but no `.mp3` files on disk. SFX fully implemented and wired.

---

## §10 — Additional gaps not tied to a specific spec line — HISTORICAL SNAPSHOT

| # | Gap | Location | Severity | Status |
|---|---|---|---|---|
| G1 | **Historical: no authored roster/onboarding system at audit time.** | preservation-era bootstrap | Superseded | ✅ RESOLVED IN CURRENT MAIN — authored First Wake, `ROSTER[5]`, and validated `ACTIVE_PARTY[1..5]` are current authority. |
| G2 | **Choice path selection UI** — `advanceChoice()` fires only when `quest.choiceMade` already set. | `advanceChoice()` | High | ✅ RESOLVED — `drawChoiceMenu()` + keyboard selection wired into `render()` + `advanceChoice()` |
| G3 | **ENEMY_ABILITIES was undefined** | Was `aetherwake.js:3949` | Resolved | ✅ RESOLVED |
| G4 | **5-action key binding only** | Was `aetherwake.js:410–415` | Resolved | ✅ RESOLVED — keys 1–8 |
| G5 | **Shared Dream lacks +1 alternate** | Was `aetherwake.js:3740–3743` | Resolved | ✅ RESOLVED |
| G6 | **Aether Seal not level-gated** | Was `levelUp()` | Resolved | ✅ RESOLVED — L4 |
| G7 | **Crossing hazard naming/mapping diverges from SPEC** | `crossingHazards` | ⚠️ PARTIAL | ✅ LARGELY RESOLVED — aether_leak added, sky_predator stat corrected to might, corporate_intercept label improved |
| G8 | **Signal hook labels don't match SPEC** | `signalHooks` | Low | ⚠️ RETAINED — labels differ but mechanic identical |
| G9 | **Ship has no interior** | `boardShip()` | Medium | ✅ RESOLVED — `drawShipInterior()` renders deck view, L/Esc disembark |
| G10 | **`drawDayNightIndicator` not wired into HUD** | Was `aetherwake.js:2377–2394` | Resolved | ✅ RESOLVED |
| G11 | **No TTS audio files on disk** | `playDialogueAudioLine()` | Medium | ⚠️ RETAINED |
| G12 | **`modules/` files are dead ends** | `modules/` directory | Informational | ✅ DOCUMENTED |

---

## §11 — Summary table — HISTORICAL SNAPSHOT

| Spec area | Status | Count of gaps |
|---|---|---|
| Historical character-creation / party gap | ✅ Superseded by authored First Wake + five-character roster architecture | 0 current critical gaps from this historical row |
| Sky layer + 14 islands + Tab toggle | ✅ Delivered | 0 |
| Quest: Signal (3 hooks) | ⚠️ Partial | 1 low (G8: label mismatch) |
| Quest: Crossing (3 hazards) | ✅ Delivered (aether_leak added) | 0 |
| Quest: Contact (4 NPCs, full dialogue) | ✅ Delivered | 0 |
| Quest: Choice (3 paths, 10+/7-9) | ✅ Delivered (drawChoiceMenu wired) | 0 |
| Quest: Wake (6–10 epilogues) | ✅ Delivered (10/6) | 0 |
| Day-night 120s cycle → solar charge | ✅ Delivered | 0 |
| Covenant field (Q, 1 aether) | ✅ Delivered | 0 |
| 5 combat actions + 3 unlockable | ✅ Delivered | 0 |
| Action economy (+1/+2/+3 spend) | ✅ Delivered (tiered: 0/1/1/0/0/1/2/0) | 0 |
| Enemy types (6 requested) | ✅ Delivered | 0 |
| Visual (scanlines, teal glow, pixel borders, grid, 14 islands, ship interior) | ✅ Delivered | 0 |
| Audio/TTS | ✅ Delivered (SFX) / ⚠️ Partial (TTS files missing) | 1 medium (G11) |

**Historical overall assessment (2026-09-19):** At the time of this audit, the then-running monolith was estimated at ~85% of that historical SPEC fully delivered, ~10% partial, and ~5% missing. The cited character-creation gap and deploy-target synchronization problem are **superseded** by current `main`: normal New Game now routes through authored First Wake, party state is `ROSTER[5] → ACTIVE_PARTY[1..5]`, and desktop packaging now stages an isolated `.desktop-runtime/www/` payload rather than synchronizing the old deploy mirrors. G11 remains only as an optional-content gap: no canonical TTS clip set is present, and current runtime fails closed before networking unless an explicit TTS manifest admits a clip.
