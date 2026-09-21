# Aetherwake Spec Conformance Audit — gap_analysis.md

> **Current audit:** 2026-09-21  
> **Branch:** `dev/progression-build`  
> This document supersedes the 2026-09-19 snapshot. Historical claims remain
> available in git history; they should not be treated as current project state.

## 0. Current verified baseline

Aetherwake now has a verified playable desktop/browser baseline with:

- dual playable entrypoints (`index-embedded.html` and `index.html`);
- fixed authored onboarding for Ender, Lyra, and Ionia;
- canonical `ROSTER[5]` and reference-based `ACTIVE_PARTY[3]`;
- player-facing schema-v2 F2/F3 save/load;
- Ender combat with eight stable action slots and level-gated unlocks;
- World/quest/dialogue/shop/ledger/airship vertical-slice systems;
- Mastery Phase A code-owned facts;
- a shared preservation field-role registry for temporary companion mechanics;
- a read-only five-character roster browser on the character sheet;
- a verified Windows desktop package built from a minimal staged runtime payload.

Recent authority checkpoints include:

| Checkpoint | Runtime commit | Gameplay smoke | Windows package |
|---|---|---:|---:|
| Mastery Phase A | `aa8e0aa4f098d8272a8a4fc539ed90f7ef181c47` | `35548707900` PASS | `35548707894` PASS |
| Canonical character sheet | `94556dabfc56d26b139731c8ee6d8c15e5d54698` | `35549081375` PASS | `35549081367` PASS |
| Read-only authored roster browser | `a6a5056e9ef927530f23067b1a9fcee32b205d67` | `35549345673` PASS | `35549345668` PASS |
| Shared field-role registry | `7dcd741279589e02a99a8eeb835710115edc43f9` | `35567099503` PASS | `35567099421` PASS |
| Minimal desktop runtime packaging | `93908e2b0fa8b05e69f7c4095dca419e77cc07a3` | `35567486492` PASS | `35567486498` PASS |

The lean packaging checkpoint stages **25 runtime files / 2,858,504 bytes**
inside `package.nw` and reduced the uploaded Windows artifact from
664,432,820 bytes to 219,915,613 bytes while preserving the same runtime gates.

---

## 1. Runtime architecture — current truth

The old claim that `modules/` is a dead tree is no longer correct.

### Live modular authorities

These modules are loaded by both playable entrypoints and are part of the
current runtime contract:

- `modules/effect-vocabulary.js`
- `modules/effect-resolver.js`
- `modules/ability-defs.js`
- `modules/progression-defs.js`
- `modules/mastery-defs.js`
- `modules/field-role-defs.js`
- `modules/party-state.js`
- `modules/save-state.js`
- `modules/airship-state.js`
- `modules/airship-combat-bridge.js`
- `modules/airship-ui.js`
- `modules/audio.js`
- `modules/char-create.js`

`aetherwake.js` remains the integrated preservation runtime and current combat
executor. Some older mirrors such as `modules/core.js`, `modules/world.js`,
`modules/combat.js`, and `modules/ui.js` may still diverge from the live
integrated implementation and should not be assumed authoritative without
entrypoint/test evidence.

Generated desktop outputs are no longer maintained as independent source trees.
The Windows package is generated from a minimal runtime staging directory.

---

## 2. Roster / onboarding / party

| Requirement | Current status | Evidence boundary |
|---|---|---|
| Five stable authored identities | ✅ Established | Ender, Lyra, Ionia, Reson, Aepex in canonical order |
| Three active references | ✅ Established | `ACTIVE_PARTY = [Ender, Lyra, Ionia]` as direct roster references |
| Ender World identity | ✅ Established | `world.player === ROSTER[0] === ACTIVE_PARTY[0]` |
| Authored onboarding | ✅ Established | Lyra/Ionia are fixed identities, not renamable generic slots |
| Temporary companion mechanics | ✅ Centralized | Shared `field-role-defs.js` registry |
| Companion canonical jobs/affinities | ⚪ UNKNOWN by design | No values fabricated |
| Reson/Aepex runtime mechanics | 🔴 Not implemented | Identity/schema shells only |
| Formation mutation | 🔴 Not implemented | Current implemented trio is already the fixed active party |
| True three-character combat | 🔴 Not implemented | Current encounter executor still resolves Ender only |

### Important distinction

Sky-Sailor, Engine-Wright, and Aether-Weaver are **temporary preservation
mechanics templates**. They are not canonical native jobs for Lyra or Ionia.

The shared registry defines enough metadata for onboarding and future migration
(stats, two ability descriptions, synergy text), but it does **not** define a
complete executable PbtA outcome table for all companion actions. Therefore
promoting those descriptions directly into full companion combat would require
inventing unresolved mechanics.

---

## 3. Combat / effects / progression

### Established

- 2D6 + stat with 10+ / 7–9 / 6− outcome bands;
- eight stable Ender action slots;
- Staff Strike and Hold baseline availability;
- level-gated Wind Ward / Aether Seal / Rest;
- centralized use eligibility and pooled Echo/Aether affordability;
- transactional rejection before turn/resource consumption;
- ordinary damage/restoration/resource mutations routed through the effect resolver;
- normal victory XP reaches level-up/unlock logic;
- secondary-action state is one-shot and cannot leak between abilities;
- combat state writes persistent Ender fields back to the canonical roster-backed World record.

### Remaining semantic debt

The generic resolver still does **not** own:

- PbtA outcome selection;
- action-specific branching;
- durable modifier/reveal/status semantics;
- movement/spatial semantics;
- XP/level orchestration;
- companion turns;
- Dual/Triple Arts.

Uncover Truth reveal/+1-next-roll and Shared Dream's +1-next-action branch remain
partly local/narrative rather than fully generalized durable effect state.

---

## 4. Mastery / jobs / schools

### Established Phase A

- major domain families: Elemental, Arcane, Psychic, Spirit;
- Ender special affinities: Aether, Resonance, Correspondence, Lumen;
- Ender native job: Rift Scholar;
- unresolved companion affinities/native jobs remain explicit **UNKNOWN**.

### Open

- mastery rank/XP scale;
- mastery award rules;
- school/tree structure beyond established families;
- companion canonical jobs and affinities;
- hybrid/cross-school unlock rules;
- mutable mastery state.

Because save schema v2 is already player-facing, the first mutable mastery state
must enter through an explicit **save schema v3** migration. Phase A facts remain
code-owned and should not be rewritten by save documents.

---

## 5. Save / persistence

### Current player-facing boundary — schema v2

Schema v2 persists:

- canonical party/progression/resource state;
- active-party IDs;
- World position/layer;
- quest state;
- ledger state;
- bounded Dragonfly state.

Controls:

- **F2** — Quick Save from normal WORLD state only;
- **F3** — Quick Load from safe menu/onboarding/WORLD states.

The load path preserves canonical references and re-synchronizes combat from the
restored World/roster lead record.

Intentionally excluded:

- encounter-local combat state;
- presentation/UI state;
- mutable mastery (not implemented yet).

Released schema v1 is supported only as an explicit migration source to v2.

---

## 6. World / quest / UI vertical slice

The current vertical slice includes:

- ground/sky exploration and layer toggle;
- day/night behavior;
- Covenant Field interaction;
- NPC dialogue;
- shop;
- ledger;
- quest log;
- character sheet;
- authored roster browser;
- Dragonfly/Wake console;
- environmental hazards;
- multiple enemy types;
- Signal → Crossing → Contact → Choice → Wake quest structure.

This is a **vertical slice**, not the full campaign.

Remaining low/medium gaps:

- some preservation-era signal-hook labels still differ from later spec wording;
- campaign breadth, recruitment arcs, regions, bosses, relationship systems, and
  full character arcs remain future content.

---

## 7. Audio

| Area | Status |
|---|---|
| Synthesized Web Audio SFX | ✅ Implemented and wired |
| Combat/UI sound hooks | ✅ Implemented |
| Dialogue TTS wiring | ⚠️ Present but optional |
| Prerecorded TTS asset library | 🔴 Not present |

Missing prerecorded dialogue audio is a content gap, not a boot/runtime blocker.

---

## 8. Desktop distribution

The prior claim that deploy targets must be manually re-synced is obsolete.

Current Windows packaging:

1. stages only required runtime assets;
2. writes a pruned runtime manifest;
3. validates all local HTML references;
4. rejects development-only directory leakage;
5. enforces a 20 MiB application-payload ceiling;
6. builds NW.js from that staging directory;
7. verifies `Aetherwake.exe`, manifest, entrypoint, and package payload;
8. publishes the complete verified Windows artifact.

Current verified application payload: **2,858,504 bytes**.

Current verified uploaded Windows artifact: **219,915,613 bytes**.

---

## 9. Remaining prioritized gaps

| Priority | Gap | Why it remains open |
|---:|---|---|
| P1 | True three-character combat | Read-only context and admission gate are established; Wind-Shear Dance now has an evidence-bound but incomplete draft, while all six companion actions still lack admitted complete contracts and execution authorization |
| P1 | Companion canonical progression | Native jobs/affinities/mastery remain intentionally unknown |
| P1 | Mutable mastery + save schema v3 | Requires explicit design and migration, not silent v2 extension |
| P2 | Generic durable modifiers/status/reveal | Effect vocabulary exists; full semantics do not |
| P2 | Reson/Aepex implementation | Identity shells exist, mechanics/canon unresolved |
| P2 | Formation switching | Not useful until >3 runtime-implemented characters exist |
| P2 | Campaign expansion | Current content is a vertical slice |
| P3 | TTS asset production | Wiring exists, files do not |
| P3 | Monolith decomposition | Must be incremental to preserve the playable baseline |
| P3 | Installer/signing/release hardening | Verified portable Windows artifact exists; production release work remains |

## Current conclusion

The prior “character creation is the single critical gap” conclusion is obsolete.

Aetherwake now has a smoke-green authored onboarding/roster/save/desktop baseline.
The highest-impact remaining engineering boundary is **party combat/progression
without fabricating unresolved companion canon**. A read-only three-character
encounter context and a fail-closed companion-action admission/completeness gate
are established. Wind-Shear Dance is now the first evidence-bound contract
draft, but it remains incomplete and non-executable. The next safe work is to
preserve another action's known semantics or resolve an explicit Wind-Shear
Dance blocker through an authored design decision, while keeping runtime
companion turns unauthorized until complete contracts and required effect
semantics exist.
