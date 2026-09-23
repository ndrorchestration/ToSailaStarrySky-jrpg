# Aetherwake AI-Assisted Production Contract

Status: **PRODUCTION PROCESS AUTHORITY / NOT STORY OR RUNTIME CANON**

This contract governs how AI-assisted work may enter Aetherwake. It does not replace creator-owned canon, GitHub runtime authority, the Visual Bible, or milestone acceptance evidence.

## Admission path

```text
design specification -> AI draft -> human review -> validation -> repository / SSOT
```

AI output is proposal material until it passes the applicable human and automated gates.

## Allowed high-leverage uses

AI may accelerate bounded work such as:
- implementation scaffolds for small, reviewable functions and tools;
- test generation and adversarial QA cases;
- structured data conversion against an existing schema;
- dialogue compression or variants that preserve creator-owned facts and scene intent;
- content options constrained by explicit IDs, budgets, roles, and authority;
- balancing hypotheses derived from actual exported data;
- linting, dependency checks, migration helpers, provenance reports, and production checklists.

## Prohibited authority shortcuts

AI must not autonomously:
- define or rewrite canonical setting, plot, cast identity, or character motivation;
- write directly into canonical save data, quest state, release authority, or final asset admission;
- perform broad uncontrolled gameplay refactors without bounded scope and regression coverage;
- admit key character art, title/logo assets, signature music, or other game-defining assets without explicit human approval and provenance;
- ship unrestricted runtime NPC dialogue as canonical story content.

Runtime dialogue remains deterministic and authored by default. Any future generative runtime text requires a separate explicit design decision, bounded fact access, non-canonical scope, hard limits, persistence where replay consistency requires it, safety review, and a deterministic fallback.

## Vertical-slice gate

Aetherwake advances concentrically. M0 / First Wake is the representative slice used to prove production readiness before content multiplication.

Do not scale regions, quests, enemies, items, abilities, or final assets merely because drafts can be generated quickly. Expansion requires evidence that the current representative slice:
- can be completed without live creator explanation;
- makes the next objective understandable;
- presents combat choices for intelligible tactical reasons;
- survives save/load, close/relaunch, and failure-path transitions;
- meets the approved visual/audio benchmark for representative surfaces;
- has traceable asset provenance;
- can be extended through repeatable production templates rather than one-off architecture.

## Data-driven production

Consequential content should use stable IDs and schema validation instead of freeform one-off definitions.

Required production registries:
1. **Canonical lore registry** — facts, terminology, unresolved questions, and source scenes.
2. **Content registry** — stable IDs for abilities, items, enemies, maps, NPCs, quests, dialogue nodes, music cues, and localization strings.
3. **Asset provenance registry** — source/license/creator or tool/model, transformations, approver, and shipped/not-shipped state.
4. **Decision log** — what changed, why, who approved it, build/commit admission, and supporting evidence.

The machine-readable registry contract lives at `docs/production-registries.json`.

## Combat admission rule

Combat depth is measured by readable tradeoffs, not move count. New actions, enemies, statuses, and formulas must introduce a testable tactical purpose such as a new decision, counter, timing question, resource tradeoff, or party interaction.

Before large combat-content expansion, each level band should define versioned balance budgets for:
- expected party HP and damage;
- expected turns to defeat a standard enemy;
- expected boss-phase duration;
- healing capacity per encounter;
- resource recovery assumptions;
- acceptable variance;
- maximum stacked damage multiplier.

AI-generated balance numbers are hypotheses until simulation and playtest evidence support them.

## State-space QA rule

Regression plans must cover transitions and permutations, not only the happy path. Representative adversarial cases include:
- save/load and attempted save around transient states;
- process close/relaunch restoration;
- corrupted or semantically invalid newest-save fallback;
- failed/escaped combat and return-state behavior;
- quest-order permutations and duplicate interactions;
- required resources becoming unavailable, consumed, or invalid;
- party wipe/recovery behavior once supported;
- full-inventory and reward overflow behavior once inventory exists;
- migration behavior across supported save versions.

Each consequential subsystem must add its state-space cases to the applicable milestone matrix before it is considered production-complete.

## Human ownership

Fluency is not acceptance. Creator review remains authoritative for story, character voice, visual identity, key asset selection, and player-facing emotional pacing. Automated validators decide structural admissibility; neither AI fluency nor test success alone can substitute for human acceptance where the milestone explicitly requires it.
