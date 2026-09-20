# Aetherwake — First Wake Vertical Slice Design

**Status:** Approved direction; design for review  
**Date:** 2026-09-20  
**Branch:** `design/first-wake-vertical-slice-2026-09-20`

## 1. Decision summary

Aetherwake will be developed around a polished, replayable vertical slice called **First Wake**. The slice is the quality bar for the larger JRPG: a player should be able to launch the game, understand the premise, meet an authored early party, confront the failing core, make a meaningful choice, and see a consequence in one coherent session.

The target experience is approximately **15–30 minutes** for a first playthrough, with three materially different choices and a short replay path.

The implementation will preserve the current working runtime while introducing narrow boundaries around party state, combat, content, saving, and verification. The project will not be rewritten wholesale while the playable loop is being improved.

## 2. Authority and provenance

Aetherwake has two related but different sources of truth:

- **GitHub is implementation authority.** Current runtime files, exact commits, tests, package configuration, and actual behavior are determined by the repository.
- **Notion is design/canon and interpreted-project authority.** Creator decisions, character dossiers, narrative material, architecture proposals, and unresolved design questions are maintained there.
- **This document is the bridge.** It defines the implementation target for First Wake without silently promoting adaptation residue into final canon.

The design was reconciled against these Notion records:

- [Aetherwake JRPG — Operational Control Center](https://app.notion.com/p/3e0f5bad238b81f1be63d6f8e961612c)
- [Aetherwake — Protagonist Roster & Party Structure](https://app.notion.com/p/3e0f5bad238b817b9ad4da4a2c0cb40f)
- [Aetherwake — Magic System & Character Integration](https://app.notion.com/p/3e0f5bad238b817c8285edc9b15e8cd7)
- [Character Dossier — Lyra](https://app.notion.com/p/3e0f5bad238b81b09790ef8604c8b75f)
- [Character Dossier — Ionia](https://app.notion.com/p/3e0f5bad238b81e4a73aeca801a363c3)
- [Concept Tree — Progression Refactor Roadmap](https://app.notion.com/p/3e0f5bad238b81849b80e7dc9689b30a)
- [Concept Tree — Code Reality & Source Reconciliation](https://app.notion.com/p/3e0f5bad238b81a297f9d7250070d9b1)
- [Concept Tree — Effect Vocabulary, Ability Schema & Resolver](https://app.notion.com/p/3e0f5bad238b8157954bd2963b549abe)
- [Concept Tree — Ability Registry & Combat Execution](https://app.notion.com/p/3e0f5bad238b81adaa2be15ef24b3bc7)

These pages explicitly distinguish creator canon, working interpretation, adaptation residue, and open design. Their unresolved character jobs, school identities, resource semantics, and chronology remain unresolved by this slice. The First Wake implementation may use provisional role labels and mechanics, but it must not represent them as final canon.

The Notion Operational Control Center contains historical implementation claims bound to earlier commits. Those claims are useful as project history but do not override the currently observed GitHub branch. Any commit or test claim must be re-read from GitHub before being reported as current.

## 3. Player promise

First Wake should make the following promise and deliver it without qualification:

> You are Ender, aboard the last airship that can still hear the sky-lanes. The Wake's core is failing. You will meet the people who depend on it, learn what the core is trying to say, survive one immediate threat, and decide what kind of future the ship is allowed to carry.

The first session should answer:

1. What is the Aureate Wake?
2. Who is Ender in relation to it?
3. Why do Lyra and Ionia matter?
4. What is wrong with the Core?
5. How does Aetherwake's 2D6/PbtA combat feel?
6. What does the player's decision change?

## 4. Scope

### 4.1 Launch and first-run experience

The supported player path is:

`extract ZIP → double-click Aetherwake.exe → title → new game → play`

The browser-served path remains the development and fallback path.

Requirements:

- normal launch hides all debug overlays;
- diagnostics remain available only through an explicit debug opt-in;
- startup failures are visible and actionable rather than leaving a blank or indefinite loading screen;
- the title screen exposes New Game, Continue when a valid save exists, and Restart/Reset where appropriate;
- the game runs offline from bundled assets;
- the Windows package is verified as an artifact, not inferred from source configuration alone.

### 4.2 Authored onboarding and roster

The creator canon establishes five playable roster identities:

1. Ender
2. Lyra
3. Ionia
4. Reson
5. Aepex

First Wake uses the early party **Ender + Lyra + Ionia**. Reson and Aepex remain canonical playable characters who join later; they are not treated as disposable placeholders or erased from the roster model.

The old prototype flow that lets the player name two generic companions and assign prototype jobs is not the canonical onboarding design. It may remain temporarily as migration scaffolding only if it is clearly isolated and does not overwrite authored identities.

First Wake onboarding must:

- begin with Ender as the player-facing protagonist;
- introduce Lyra as the young dream/frequency-sensitive receiver;
- introduce Ionia as the veteran captain/navigator;
- preserve stable identity IDs and direct roster references;
- make the active trio explicit;
- retain persistent records for all five roster slots;
- avoid assigning final jobs, schools, or metaphysical resource meanings that Notion still marks as open.

For this slice, the party roles are provisional mechanical roles, not final lore:

- **Ender — Reader:** investigates patterns, reads the weave, and makes flexible risk/reward plays.
- **Lyra — Receiver:** detects frequency anomalies and supports or redirects the party.
- **Ionia — Anchor:** protects the party, understands routes, and stabilizes the Wake through practical expertise.

### 4.3 Three-character combat

First Wake establishes the player-facing shape of the final combat model:

- exactly three active combatants;
- combat reads from `ROSTER` records through `ACTIVE_PARTY` references;
- combat-local damage, statuses, turn state, and temporary modifiers do not replace persistent character records;
- no in-battle party swapping in the first slice;
- the existing 2D6 + stat outcome bands remain authoritative;
- learn eligibility, use eligibility, resource affordability, targeting, and effect execution remain separate checks;
- ordinary effects continue moving toward the data-driven resolver boundary;
- every actor has a distinct role and at least one meaningful choice that another actor cannot simply duplicate;
- combat feedback shows whose turn it is, what was rolled, what changed, and what the next decision is.

The first slice does not require final school trees, final job names, Dual Arts, Triple Arts, or the complete higher-order effect vocabulary. It does require interfaces that can support those systems later without creating a second disconnected progression scope.

### 4.4 First Wake story route

The slice uses a compact route rather than adding a large new map:

1. **Arrival / Deck:** establish Ender, the Wake, and the immediate social context.
2. **Signal / Core:** introduce Lyra's perception and the Core's wrong song.
3. **Contact / Route:** let Ionia frame the practical stakes and the cost of failure.
4. **Crossing / Threat:** resolve one traversal hazard or combat encounter using the active trio.
5. **Choice:** select one of three approaches to the Core.
6. **Wake / Consequence:** show a distinct short outcome and preserve the choice in save state.

The current prototype's three core directions are a suitable starting point:

- sing the core down / scatter the people;
- sell the core / evacuate the ship;
- drive the core up / find what is above.

These labels and exact dialogue remain revisable narrative material. The implementation requirement is stable: each option must change at least one persistent story consequence and produce a visibly different closing beat.

### 4.5 Save, continue, and restart

First Wake uses one local save slot for the initial implementation.

Save points occur only at safe, validated state boundaries:

- after authored onboarding;
- after entering the main world;
- after combat write-back;
- after the Core choice;
- after the closing beat.

The save snapshot must contain:

- schema version;
- roster records and stable IDs;
- active-party IDs;
- story/quest state;
- choice and consequence state;
- safe player/world position;
- current progression and equipment fields required to resume.

A malformed or incompatible save must fail closed to New Game with a visible recovery message. It must never partially hydrate a live session.

### 4.6 Visual, audio, and interaction quality

The existing visual identity remains the foundation:

- dark navy, teal, amber, soil, and parchment palette;
- pixel borders, scanlines, glow, grid, islands, day/night atmosphere, and the Wake interior;
- readable typography at the supported window sizes;
- color is not the only indicator of locked, active, successful, or dangerous states;
- menus and combat actions remain keyboard-operable, with clickable menu/action targets added where practical.

Existing synthesized SFX remain useful. First Wake should add reliable cues for:

- confirming a choice;
- entering combat;
- successful, partial, and failed rolls;
- damage, restoration, resource change, and victory;
- saving and resuming.

Dialogue TTS is not a release blocker for this slice. If optional voice files are absent, the game must continue silently and must not emit misleading load errors.

## 5. Runtime architecture

### 5.1 Current-authority rule

The current live browser build is loaded by `index-embedded.html` and is centered on `aetherwake.js`, with the explicitly loaded supporting modules. The existing monolith remains the runtime authority until replacement behavior has parity tests.

Dead or historical modular mirrors must not be edited as if they changed the player-facing build. Any new module must be explicitly loaded and covered by the browser path.

### 5.2 State ownership

The runtime will preserve these boundaries:

- `ROSTER[5]`: canonical persistent character records;
- `ACTIVE_PARTY[3]`: selected direct references or IDs into the roster;
- combat state: encounter-local values, temporary effects, turn order, targets, and logs;
- world state: position, environmental state, NPC interaction state, and quest progress;
- save state: a validated serialization of persistent and resumable safe-state data;
- UI state: selection, focus, transition animation, and display-only state.

A combat copy may be used internally for resolution only if the copy has an explicit write-back contract and cannot become an accidental second source of truth.

### 5.3 Content and ability boundaries

New First Wake content should be represented as data where possible:

- authored character metadata;
- provisional slice-role kits;
- encounter metadata;
- choice definitions;
- consequence definitions;
- save schema;
- ability effect profiles.

The effect vocabulary should grow only when an executable mechanic requires it. A rare bespoke hook is acceptable for a story-defining event; repeated hooks for ordinary damage, restoration, resource, status, reveal, movement, or field behavior indicate a missing reusable effect type.

### 5.4 Transition contract

The verified state sequence is:

`BOOT → MENU → ONBOARDING → WORLD → COMBAT → WORLD → CHOICE → WAKE → SAVE/TITLE`

Each transition must:

- validate the state required by the destination;
- preserve identity and persistent progression;
- leave an observable failure record if it cannot complete;
- avoid silently falling through to a debug or blank state.

## 6. Verification contract

### 6.1 Unit and contract tests

Add or extend tests for:

- five stable roster identities;
- three active-party references;
- authored onboarding and staggered availability;
- no duplicate progression scope;
- provisional role kit metadata;
- action learn/use/resource eligibility;
- party combat turn resolution;
- ordinary effect resolver routing;
- combat result write-back;
- save serialization and round-trip hydration;
- invalid-save rejection;
- choice-to-consequence mapping;
- debug overlay hidden during normal launch;
- package manifest and entry-point contract.

### 6.2 Canonical browser smoke

The browser smoke must use the real player-facing input path and verify:

1. `index-embedded.html` loads;
2. canvas reaches 960×640;
3. normal launch exposes no debug overlay;
4. New Game reaches authored onboarding;
5. Ender, Lyra, and Ionia retain canonical IDs;
6. `ACTIVE_PARTY` contains the expected early trio by reference;
7. WORLD preserves the canonical lead record;
8. combat starts from the real UI path;
9. each early actor can take an admitted action;
10. at least one success, partial, or failure result is rendered and logged;
11. combat state writes back to the roster;
12. the game reaches the Core choice;
13. a selected choice changes the closing state;
14. a save can be reloaded through Continue;
15. no page errors or unhandled promise rejections occur.

Randomness must be controllable in tests through a deterministic test seam. Normal play may remain variable.

### 6.3 Packaged-build verification

The Windows workflow must:

- install dependencies from the repository manifest;
- run the desktop package contract;
- create the package;
- verify the expected executable and entry point are present;
- upload the resulting ZIP;
- record the exact workflow run and artifact identity.

The development report must distinguish “package built by CI” from “package manually launched on Windows.” The latter is not claimed until it has been performed and recorded.

### 6.4 Manual acceptance

A fresh user acceptance pass must cover:

- download or clone;
- extract the ZIP;
- double-click launch;
- New Game;
- onboarding;
- exploration;
- combat;
- each of the three choices;
- Continue after closing and reopening;
- Reset/New Game after a saved session.

## 7. Milestone sequence

This design is intentionally staged:

1. **Source and launch baseline:** reconcile current GitHub and Notion records, verify normal launch, close any remaining startup/package gaps.
2. **Authored early party:** replace generic companion onboarding with authored Ender/Lyra/Ionia presentation while retaining the five-slot roster.
3. **Party combat seam:** implement the three-actor combat contract with provisional role kits and explicit write-back.
4. **First Wake content:** connect the route, threat, three choices, consequences, save points, and closing beat.
5. **Polish and hardening:** improve feedback, sound cues, accessibility basics, package verification, and regression coverage.
6. **Scale outward:** only after the slice is stable, add Reson, Aepex, formation selection, progression trees, Dual Arts, Triple Arts, and broader campaign content.

Every milestone must leave the game playable.

## 8. Explicit non-claims

This design does not claim:

- that the full Aetherwake campaign is complete;
- that all five characters are currently fully implemented;
- that Lyra's or Ionia's final jobs, schools, resource semantics, or chronology are resolved;
- that Reson and Aepex can already participate in combat;
- that Dual Arts or Triple Arts exist;
- that TTS voice files are present;
- that a Windows package has been manually launched successfully;
- that the current monolith has been fully replaced;
- that adaptation residue from Memories is final Aetherwake canon.

## 9. Definition of done for First Wake

First Wake is complete only when a fresh player can launch the verified package, understand the opening premise without developer explanation, play the authored early party through one readable combat encounter, make any of the three Core choices, see a distinct consequence, close the game, resume from a valid save, and complete the path without a blank screen, exposed diagnostics, silent state loss, or unverified claims in the documentation.
