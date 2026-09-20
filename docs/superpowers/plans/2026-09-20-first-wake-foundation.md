# Aetherwake First Wake Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans) when implementing this plan.

**Goal:** Ship the first independently playable First Wake slice: launch, authored Ender/Lyra/Ionia onboarding, one readable three-actor encounter, three Core choices with distinct closing beats, one safe save slot, Continue, and clean recovery from invalid state.

**Architecture:** Keep the current p5 global runtime, 960×640 canvas, and aetherwake.js orchestration authority. Add explicitly loaded modules for provisional kits, party-combat state, route content, save serialization, and optional audio cues. ROSTER[5] is the persistent identity source; ACTIVE_PARTY[3] contains direct references into it. Existing resolver/effect contracts remain authoritative. GitHub is implementation authority; Notion is canon/design authority.

**Tech Stack:** Vanilla JavaScript, p5.js global mode, Node contract tests, Playwright browser smoke, NW.js/NW Builder, GitHub Actions.

**Spec:** docs/superpowers/specs/2026-09-20-first-wake-vertical-slice-design.md on branch design/first-wake-vertical-slice-2026-09-20.

## Global Constraints

- index-embedded.html must load every new runtime module before aetherwake.js.
- Preserve identity order ender|lyra|ionia|reson|aepex and initial active order ender|lyra|ionia.
- Lyra and Ionia use only provisional mechanical roles receiver and anchor; unresolved Notion jobs, schools, resource semantics, and chronology remain unresolved.
- Ender remains the world lead; window.party remains an alias of window.ACTIVE_PARTY.
- Combat-local state writes back explicitly and never replaces the persistent roster.
- Preserve 2D6 bands and separate learn, use, resource, targeting, and effect-resolution checks.
- No party swapping, formation editor, final job/school trees, Dual Arts, Triple Arts, TTS dependency, or manual Windows launch claim.
- Invalid saves fail closed before live mutation. Normal debug overlays remain hidden; test hooks require an explicit query.
- Every implementation step below is test-first and leaves a playable runtime.

## Review Focus

Review launch with optional assets absent, legacy/malformed saves, direct roster identity and write-back, rejected actions without turn/resource consumption, and all three Core choices across save/reload.

## Task 1: Baseline and contract harness

**Files:** modify package.json; create tests/first-wake-test-helpers.js.

**Interfaces:**

~~~js
loadBrowserModule(relativePath, globals) -> vmContext
fakeStorage(initialEntries) -> Storage-shaped object
~~~

**Steps:**

1. Run the existing effects, registries, resolver, resolver integration, enemy metadata, combat input, resource eligibility, progression reachability, secondary action, desktop package, and browser smoke commands. Record pre-existing failures.
2. Implement a VM loader with fake window/module/globalThis and an in-memory string-only Storage.
3. Add test:first-wake-contract and a helper test that loads modules/effect-vocabulary.js and round-trips one storage value.
4. Commit: test: add First Wake contract harness.

**Verification:** Baseline is known and the helper passes without p5 or a browser.

## Task 2: Authored onboarding and canonical five-slot party

**Files:** modify modules/party-state.js, modules/char-create.js, aetherwake.js, tests/smoke-playwright.js, package.json; create tests/first-wake-party-contract.test.js.

**Interfaces:**

~~~js
AetherPartyState.commitFirstWakeParty({
  storyFlags: { lyraJoined: true, ioniaJoined: true }
}) -> { roster: ROSTER, activeParty: ACTIVE_PARTY }

AetherPartyState.hydrateFirstWakeParty(serializedParty) -> {
  roster: ROSTER,
  activeParty: ACTIVE_PARTY
}

AetherCharCreate.start({ mode: 'authored' });
AetherCharCreate.getSnapshot() -> {
  mode, phase: 'intro' | 'roster' | 'confirm' | 'done',
  partyIds, activeIds
};
~~~

**Steps:**

1. Write the party contract first. Assert five canonical IDs, three active direct references, Ender/world object identity, authored Lyra/Ionia names and roles, no final Lyra/Ionia job fields, retained Reson/Aepex shells, and idempotent repeated commit.
2. Add frozen authored metadata. Make commitFirstWakeParty the normal commit; keep commitPrototypeParty only behind explicit migration/debug mode. Make hydrateFirstWakeParty validate IDs, order, required numeric fields, and active IDs before mutation.
3. Change char-create’s normal flow to authored intro → roster → confirm. Enter advances and Escape backs up. Present Ender, Lyra’s frequency/dream sensitivity, Ionia’s captain/navigator stakes, and the active trio. Request no names or prototype jobs.
4. Update aetherwake.js to use public state onboarding and preserve window._charcreate for tests. Update smoke to prove normal onboarding never uses the prototype adapter.
5. Run party, existing registry/resolver/progression contracts, and smoke. Commit: feat: establish authored First Wake onboarding.

**Verification:** Fresh WORLD state contains all five identities and canonical Ender/Lyra/Ionia references.

## Task 3: Provisional kits and three-actor combat

**Files:** create modules/first-wake-kits.js, modules/party-combat.js, tests/first-wake-kits.test.js, tests/party-combat-contract.test.js; modify modules/ability-defs.js, modules/effect-vocabulary.js, the smallest required cases in modules/effect-resolver.js, index-embedded.html, aetherwake.js, tests/combat-input-contract.test.js, tests/smoke-playwright.js, package.json.

**Interfaces:**

~~~js
window.AetherFirstWakeKits = Object.freeze({
  version: 1,
  roles: {
    reader: { id: 'reader', label: 'Reader', canonStatus: 'provisional' },
    receiver: { id: 'receiver', label: 'Receiver', canonStatus: 'provisional' },
    anchor: { id: 'anchor', label: 'Anchor', canonStatus: 'provisional' }
  },
  actors: {
    ender: { roleId: 'reader', actionIds: ['staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold'] },
    lyra: { roleId: 'receiver', actionIds: ['frequencyRead', 'echoRedirect', 'hold'] },
    ionia: { roleId: 'anchor', actionIds: ['braceTheWake', 'routeCommand', 'hold'] }
  }
});

AetherPartyCombat.createEncounter({ activeParty, enemy, rng }) -> {
  schemaVersion: 1,
  actors: [{ id, character, actionIds, vit, maxVit, temporary }],
  activeActorId: 'ender',
  turnOrder: ['ender', 'lyra', 'ionia', 'enemy'],
  turnIndex: 0,
  enemy,
  log: []
};
AetherPartyCombat.validate(state) -> true;
AetherPartyCombat.writeBack(state) -> true;
~~~

**Steps:**

1. Write tests first for distinct roles, registry/profile coverage, exactly-three validation, deterministic order, no canonical mutation before write-back, identity-preserving write-back, and rejection without turn/resource changes.
2. Add the kit data. Keep Ender’s existing actions; add Lyra frequencyRead/echoRedirect and Ionia braceTheWake/routeCommand.
3. Preserve the current eight-action compatibility API. Add PARTY_ACTION_ORDER, actor-pool-aware eligibility, and four new definitions with stable stats/costs/tiers. Add vocabulary profiles using existing effect kinds. Make the minimum effects executable: enemy reveal plus one-use next-roll modifier, ally restoration, next-hit damage reduction, and one-use ally next-roll modifier. Modifiers are consumed once and do not stack.
4. Implement party-combat.js as the adapter for actor order, encounter copies, validation, and write-back. Extend AetherCombat with { party, enemyId, rng }, state.party, activeActorId, turnOrder, turnIndex, and state.player as an Ender compatibility alias. Render actor/target/roll/outcome/effects/next actor and rotate Ender → Lyra → Ionia → enemy.
5. Start normal combat from ACTIVE_PARTY; retain C only for explicit debug/test mode. Update input contracts and smoke so all three actors use unique actions and write back.
6. Add test:first-wake-combat. Run all combat/effect/eligibility/progression tests. Commit: feat: ship three-actor First Wake combat.

**Verification:** Three actors are playable with distinct decisions and current Ender contracts remain green.

## Task 4: Route, choices, and validated save/resume

**Files:** create modules/first-wake-content.js, modules/save-state.js, tests/first-wake-content.test.js, tests/save-state-contract.test.js; modify modules/party-state.js, aetherwake.js, index-embedded.html if recovery text needs a node, tests/smoke-playwright.js, package.json.

**Interfaces:**

~~~js
window.AetherFirstWakeContent = Object.freeze({
  routeId: 'first-wake',
  createState() -> ({
    routeId: 'first-wake',
    nodeId: 'arrival',
    choiceId: null,
    consequenceId: null,
    completed: false
  }),
  getNode(nodeId) -> node,
  getChoice(choiceId) -> choice,
  applyChoice(state, choiceId) -> nextState
});

AetherSaveState.createSnapshot({ party, activeIds, world, firstWake }) -> plainObject;

window.AetherSaveState = Object.freeze({
  VERSION: 1,
  KEY: 'aetherwake.firstWake.save',
  createSnapshot,
  validateSnapshot(snapshot) -> { ok: true, snapshot } | { ok: false, code },
  write(snapshot, storage) -> true,
  read(storage) -> { ok: true, snapshot } | { ok: false, code },
  clear(storage) -> true
});
~~~

**Steps:**

1. Write content tests first. Require nodes arrival, signal, contact, crossing, choice, wake; valid transitions; exactly three immutable choices; and stable unknown-choice errors. Use choice IDs scatter, evacuate, ascend with distinct closingBeatId values and slice-only crewOutcome/coreOutcome fields.
2. Define the compact route and connect it through existing world/dialogue presentation. The route introduces Ender, Lyra’s wrong-frequency observation, Ionia’s practical stakes, one crossing hazard, combat, choice, and wake. Validate source state before each transition and remove normal KeyC dependence.
3. Write save tests first with fake Storage. Cover JSON round-trip, stripping functions/p5/combat data, five IDs/three active IDs, safe position, every invalid schema case, invalid JSON, exact-key clear, and no partial hydration.
4. Implement strict save-state validation and guarded party/world/route hydration. Save after onboarding, WORLD entry, combat write-back, choice, and wake. Add New Game, Continue only for valid data, Restart/Reset, and visible invalid-save recovery.
5. Update smoke to enter combat from the route, run each choice in isolated contexts, assert distinct closing states, save/reload/Continue, and malformed-save recovery. Add test:first-wake-content and test:save-state. Commit: feat: connect First Wake route and save flow.

**Verification:** A fresh player completes the route without developer controls; valid state resumes exactly; invalid state starts cleanly.

## Task 5: Feedback, audio fallback, package, and docs

**Files:** create modules/audio-cues.js and tests/audio-cues-contract.test.js; modify index-embedded.html, aetherwake.js, tests/desktop-package-contract.test.js, .github/workflows/smoke.yml, .github/workflows/desktop-package.yml, package.json, README.md, docs/DEVELOPMENT.md, SPEC.md.

**Interface:**

~~~js
window.AetherAudioCues = Object.freeze({
  IDS: ['confirm', 'combat-enter', 'roll-success', 'roll-partial', 'roll-failure',
        'damage', 'restore', 'resource', 'victory', 'save', 'resume'],
  play(id) -> true | false,
  resetForTest() -> true
});
~~~

**Steps:**

1. Test cue registration, unknown-ID safety, and no AudioContext fallback before implementation. Use lazy Web Audio after a user gesture; no voice files or network assets.
2. Add non-color feedback for active actor, target, roll/outcome, exact changes, next actor, and rejection reasons. Add cues for confirmation, combat, roll bands, damage, restoration, resource, victory, save, and resume.
3. Add actionable startup failure text while keeping debug overlays hidden. Keep test=1 hooks invisible and separate from debug=1.
4. Extend desktop contract to check every new module exactly once and before aetherwake.js, package main/size unchanged, and workflow package/upload behavior. Add all contracts and First Wake smoke to CI.
5. Update docs only with verified behavior, exact test commands, and the CI-package-versus-manual-launch distinction. Add test:audio-cues. Run the complete matrix. Commit: chore: harden First Wake feedback and packaging.

**Verification:** Launch is actionable, absent audio is silent, package entry is tested, and feedback is readable.

## Task 6: Final verification and Notion reconciliation

**Files:** no runtime changes unless a named test fails; correct README.md/docs/DEVELOPMENT.md/SPEC.md only for verified drift; update the Notion Operational Control Center after implementation.

**Steps:**

1. Run First Wake party, combat, content, save, audio, all existing effect/registry/resolver/input/eligibility/progression contracts, desktop package, and browser smoke.
2. Use a clean browser profile to complete all three choices, Continue, and Reset/New Game. Record automated results and distinct closing IDs.
3. Verify five roster IDs, three direct active references, no normal commitPrototypeParty call, no normal C combat entry, state.player only as an alias, and no partial invalid-save hydration.
4. Inspect CI package artifacts by exact run/artifact identity when available. Do not claim manual Windows launch without a manual launch.
5. Update Notion with final branch/commit, exact test results, GitHub-vs-Notion authority boundary, unresolved canon questions, and explicit non-claims. Commit documentation reconciliation only when a verified correction is needed.

**Verification:** Every handoff claim maps to a test, observed GitHub state, or explicitly labeled manual acceptance.

## Execution Order and Commit Boundaries

1. test: add First Wake contract harness
2. feat: establish authored First Wake onboarding
3. feat: ship three-actor First Wake combat
4. feat: connect First Wake route and save flow
5. chore: harden First Wake feedback and packaging
6. verification/documentation reconciliation

Do not merge this design branch into main until the complete matrix is green and automated package creation is distinguished from manual package launch.

## Self-Review Checklist

- [x] Exact files and interfaces are named.
- [x] Every new runtime module is explicitly loaded by index-embedded.html.
- [x] Tests precede each dependent implementation.
- [x] Existing compatibility contracts are preserved while party behavior is added.
- [x] Direct roster references and all-or-nothing save hydration are protected.
- [x] Notion’s unresolved canon remains unresolved and provisional roles are labeled.
- [x] Launch, package, browser, regression, and manual verification are included.
- [x] No unowned placeholder work or silent future claims are included.
- [x] This is one coherent independently shippable vertical-slice foundation.
