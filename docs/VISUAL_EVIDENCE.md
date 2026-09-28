# Aetherwake Visual Evidence Capture

Status: **CAPTURE HARNESS ESTABLISHED / EXACT-HEAD VISUAL REVIEW PENDING**

This lane exists to turn the Visual Bible's propagation gates plus title/opening/aerial-context surfaces into exact-head rendered evidence. It does **not** decide visual quality automatically.

## Required evidence set

A complete bundle currently contains **14 rendered frames plus `manifest.json`**:

1. `00-title-screen.png` — shared-authority title screen.
2. `00-prologue-page.png` — opening prologue text/visual page.
3. `00a-opening-world-reveal.png` — opening sky-world establishing reveal.
4. `00b-first-wake-ionia-arrival.png` — First Wake arrival composition with Ionia dialogue treatment.
5. `01-first-wake-dock-walk.png` — First Wake Sequence 02 mid-walk.
6. `01b-first-wake-cabin.png` — authored cabin substrate and berth interaction.
7. `01c-first-wake-lyra-family.png` — Lyra-family/free-roam interior identity beat.
8. `01c-first-wake-wrong-song.png` — Wrong Song dramatic interior beat.
9. `02-dragonfly-dusk-dock.png` — benchmark dock scene.
10. `03-dialogue-ionia.png` — representative authored-portrait dialogue scene.
11. `04-combat-sky-predator.png` — representative combat scene.
12. `05-dragonfly-flight.png` — representative Dragonfly flight scene.
13. `06-sky-combat-crosswind.png` — aerial combat inheriting Crosswind/altitude/wake-pressure context.
14. `07-character-identity-lineup.png` — non-gameplay identity diagnostic showing all five authored portraits and provisional field silhouettes.
15. `manifest.json` — source SHA, working-tree state, viewport/canvas dimensions, capture boundary, performance samples, and SHA-256 for every screenshot.

The gameplay acceptance set and the non-gameplay identity diagnostic remain distinguishable in the manifest/review procedure; adding diagnostic coverage does not silently substitute it for a gameplay visual gate.

## Capture contract

Run:

```
npm run capture:visual-evidence
```

The harness:

- boots the real embedded runtime through Playwright;
- follows the authored First Wake path to the live world;
- uses canonical runtime objects already exercised by smoke tests;
- captures at a 1440×960 browser viewport while preserving the 960×640 logical canvas;
- binds the evidence bundle to `GITHUB_SHA` when executed in Actions;
- hashes every screenshot;
- records 90-frame timing samples for title, benchmark dock, representative combat, and flight;
- fails if page/runtime errors are observed.

The PR smoke workflow now checks out the exact pull-request head, verifies that checkout against the supplied head SHA, captures the same bundle, and uploads it as an Actions artifact. The manual workflow remains available after it is present on the default branch.

## Acceptance boundary

**A successful capture is not a visual PASS.**

A human review must compare the exact-head screenshots against:

- `docs/VISUAL_BIBLE.md`;
- `docs/VISUAL_BENCHMARK_SCENE.md`.

At minimum, verify:

- silhouettes and focal hierarchy read immediately;
- at least three depth planes are visible;
- lighting materially improves composition;
- repeated tile/procedural patterns do not dominate;
- title, First Wake, character, Dragonfly, dialogue, combat, and flight treatments feel like one game;
- no debug/prototype visual dominates the frame;
- the benchmark screenshot could plausibly serve as a store-page image without retouching.

Only after that review may a gate be recorded as **VISUAL PASS**.

## Character identity diagnostic ? V8
- `07-character-identity-lineup.png` is a non-gameplay diagnostic frame showing all five protagonist portrait + field-silhouette authorities on one isolated p5 canvas.
- It is **not** substituted for any gameplay acceptance frame or blind same-game test input by default.
- It exists to expose cross-character scale, silhouette, hair, accessory, and costume-authority drift that may be invisible when only one protagonist is present in a scene.
