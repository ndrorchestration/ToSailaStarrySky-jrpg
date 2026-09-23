# First Wake benchmark acceptance contract

This document is the human-readable companion to `docs/first-wake-benchmark.json`.

The benchmark is not a list of every feature Aetherwake will eventually contain. It is the smallest representative slice that must remain coherent while the project grows.

## Promotion rule

A gate may be described as:

- **automated** — there is a concrete executable/static verification owner.
- **partial** — some behavior is covered, but a meaningful player path remains unproved.
- **manual** — acceptance is intentionally visual/editorial and must be reviewed in the live runtime.
- **gap** — the production requirement is known but the implementation/verification lane does not yet exist.

A gate being labelled automated does **not** mean its current branch has executed green. Exact-head workflow execution remains a separate verification state.

## Current benchmark path

1. Installed desktop launch.
2. Title → New Game / Continue.
3. Authored First Wake Sequences 00–09.
4. Stable WORLD handoff with Ender + Lyra.
5. Clear first objective and quest journal.
6. Three signal contacts.
7. Four combat-backed Crossing hazards.
8. Four contact voices.
9. Choice → deliberate WAKE resolution.
10. Manual save/load + Continue.
11. Combat return to stable WORLD.
12. Dragonfly flight and stable navigation.
13. Representative input/accessibility, visual, and audio acceptance.
14. At least one uncoached external-player completion pass before content scale-out.

## Why this exists

New systems and content should extend this benchmark rather than silently replacing its assumptions. If a future feature adds consequential state, UI complexity, or a new transition, it should either:

- extend an existing benchmark gate;
- add a new gate with an explicit owner and acceptance result; or
- remain outside the representative slice until its upstream architecture is ready.

This keeps future regions, enemies, quests, menus, and assets from multiplying faster than the shared production pipelines can support them.

## External-player scale-out gate

Automated contracts prove determinism and state integrity; they do not prove that a new player understands the game. Before broad content scale-out, require at least one player who was not coached live by the creator/developer to complete the representative slice. The pass should establish that the player can understand the current objective, choose combat actions for intelligible reasons, use save/load, recover from at least one non-happy-path state, and finish the bounded First Wake experience without repository or browser knowledge.

This is intentionally a **manual production gate**. A passing developer smoke test or local M0 run cannot substitute for it.
