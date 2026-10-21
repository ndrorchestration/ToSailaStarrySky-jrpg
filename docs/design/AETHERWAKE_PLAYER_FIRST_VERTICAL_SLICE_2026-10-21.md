# Aetherwake — Player-First Vertical Slice (review proposal)

Status: **design hypothesis, not approved canon or shipped implementation**. This proposal is deliberately isolated from character-art acceptance and security/release decisions.

## Creative north star
A beautiful, hopeful journey in which repairing the bonds between people and places makes the world visibly and audibly respond. Each small act of attention should create a playable consequence. Original characters, environments, music and mechanics only; no direct imitation of other JRPG intellectual property.

## Ten-minute playable loop
1. **Arrival (0–1 min):** Player can move immediately on a compact, readable dock. One optional contextual interaction establishes a local mystery; never trap movement behind an opening exposition dump.
2. **Discovery (1–3 min):** Follow two contrasting environmental clues (visual light pattern and audible signal). Both paths converge on the same actionable discovery; optional dialogue adds character context.
3. **Connection (3–5 min):** Meet Ionia and Ender in a brief, skippable, expressive exchange. Dialogue pauses both actors; movement resumes predictably. A choice determines whom the player helps first, not a punitive hidden morality score.
4. **Challenge (5–8 min):** A single tutorial encounter or nonviolent equivalent teaches one understandable action, one readable enemy/environment telegraph, and one team synergy. Keep failure recovery quick; no grind.
5. **Payoff (8–10 min):** Return to the dock and see one persistent visual change, one NPC response, and one short music-layer change reflecting the earlier choice. Offer a clear next objective.

## Prototype acceptance checklist
- [ ] Native Godot 4 scene launches in review build without runtime errors.
- [ ] Player obtains agency within 60 seconds on first playthrough.
- [ ] Objective and interaction affordances understood by 4 of 5 new testers without coaching (hypothesis; adjust after evidence).
- [ ] At least 4 of 5 testers can explain the challenge telegraph and consequence of their choice.
- [ ] Dialogue pause/resume does not shift actor routes or leave inputs stuck.
- [ ] Text can be advanced and revisited; no essential information conveyed by color or audio alone.
- [ ] Support adjustable text speed, remappable inputs, reduced motion and readable contrast before external playtesting.
- [ ] No regression to approved Ender appearance; Ionia remains provisional and requires creator review.
- [ ] Record exact commit, Godot version, platform, test steps, crash logs and screenshots for each playtest.
- [ ] Installer Defender alert #293 and branch/release security holds remain unresolved unless separately verified.

## First engineering increments
**P0 — Observability:** Add an opt-in, local-only, anonymized review trace for timestamps of first control, interaction, dialogue start/end, encounter comprehension prompt and choice payoff. No telemetry upload or personal data.
**P0 — Interaction clarity:** Add a reusable interaction prompt that reports keyboard/controller binding and remains legible over varied backgrounds.
**P0 — State-driven consequence:** Add a tiny deterministic quest-state resource and automated tests for branching choice and dock-return change; keep authored canon out of fixtures.
**P1 — Dialogue comfort:** Add text-speed and reduced-motion settings, and verify pause/resume on both actors.
**P1 — Encounter sandbox:** Prototype one readable telegraph + team action, measured by new-player comprehension, before expanding combat content.
**P1 — Audio/visual response:** Use placeholder original effects to prototype choice-driven lighting and music stems, without claiming final art or audio approval.

## Research integration gate
Deep Research was requested to review acclaimed JRPGs, Reddit player feedback, game-dev postmortems and accessibility practice. **Results are pending.** Add sourced findings, alternative directions, tradeoffs and ranked backlog only after reviewing the delivered report; avoid unsupported claims that any mechanic is universally beloved.

## Review boundaries
This branch starts from the existing #326 visual review branch and must not be treated as a production merge base. #328 and #329 separately examine gait motion. Preserve creator-confirmed identities (Ionia, Ender, Aepex, Lyra, Reson), creator approvals, exact evidence provenance and malware hold. No auto-merge or release.

## Implemented prototype (draft PR #330, unapproved)

Standalone playable Godot scene: `godot/scenes/vertical_slice_review.tscn`, backed by `vertical_slice_review.gd`, `vertical_slice_choice_state.gd`, and `vertical_slice_encounter.gd`. The scene is intentionally **not** the default pilot scene and does not rewrite its input or character sprites. Launch via Godot 4.7.2 editor by opening this scene and selecting **Run Current Scene**, or run the project with the scene path explicitly. This is a mechanical review fixture, not final narrative, world map, audio, or art.

**Controls:** arrow keys move; E interacts near the labeled SIGNAL / IONIA / CHALLENGE markers; 1/2 choose an exclusive path and then strike/guard during the tutorial challenge; Escape cancels conversation or exits challenge without permanent penalty. M toggles reduced motion (on by default), +/- changes story text size, and P opts into ephemeral local review events (off by default; turning off clears events). No network calls, persistent analytics, saves, or personal data. All critical cues are accompanied by text, not color alone.

**Native tests:** `res://tests/vertical_slice_choice_state_test.gd` covers clue/choice/payoff gates; `res://tests/vertical_slice_review_test.gd` instantiates the real scene and checks dialogue movement pause/resume, challenge telegraph, recovery and both outcome branches. Both are invoked in the pinned native Godot pilot CI workflow. Their presence is not proof of a passing run; cite an exact successful workflow before claiming verification.

**Not yet implemented:** full battle-system integration, remappable bindings/controller accessibility, text backlog, screen-reader support, commissioned/approved art, authored music, narrative canon, persistent quest saves, full external playtest study and production release. These remain tracked hypotheses, not achieved acceptance criteria. Research findings from the requested Deep Research study remain pending.
