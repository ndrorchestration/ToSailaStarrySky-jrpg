# Aetherwake Visual Evidence Capture

Status: **CAPTURE HARNESS ESTABLISHED / VISUAL ACCEPTANCE HUMAN-REVIEWED**

This lane exists to turn the Visual Bible's propagation gates plus title/opening/aerial-context surfaces into exact-head rendered evidence. It does **not** decide visual quality automatically.

## Required evidence set

A complete bundle contains:

1. `00-title-screen.png` — shared-authority title screen.
2. `01-first-wake-dock-walk.png` — First Wake Sequence 02 mid-walk.
3. `02-dragonfly-dusk-dock.png` — benchmark dock scene.
4. `03-dialogue-ionia.png` — representative dialogue scene.
5. `04-combat-sky-predator.png` — representative combat scene.
6. `05-dragonfly-flight.png` — representative Dragonfly flight scene.
7. `06-sky-combat-crosswind.png` — aerial combat inheriting Crosswind/altitude/wake-pressure context.
8. `manifest.json` — source SHA, viewport/canvas dimensions, capture boundary, and SHA-256 for every screenshot.

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
- fails if page/runtime errors are observed.

The manual `Aetherwake visual evidence` workflow performs the same capture and uploads the bundle as an Actions artifact when a hosted runner is available.

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
