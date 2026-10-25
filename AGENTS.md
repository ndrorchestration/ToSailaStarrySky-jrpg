# To Sail the Starry Sky — contributor/agent instructions

Effective 2026-10-24 by explicit creator decision: **Godot 4.7.2 Standard and GDScript are the sole targets for new game engine, gameplay, UI, map, flight, rendering, combat and persistence work.** Do not add, extend or generate new HTML/Canvas, p5.js, Three.js, NW.js, JavaScript or TypeScript game prototypes. Python tools may be used for offline asset processing/test orchestration but MUST NOT become the gameplay runtime.

## Source of truth and coordination
- `godot/project.godot` is the native project. Do not invent a second disconnected Godot runtime when a native Chapter I system already exists.
- Root `index*.html`, `aetherwake.js`, `modules/*.js`, legacy packaging and old JS tests are **frozen migration references**; preserve for parity and legal/provenance traceability until native cutover is explicitly authorized.
- Main remains a historical browser engine branch until admitted Godot work reaches feature, visual, save/recovery, security and player-acceptance gates. Work in reviewed branches/PRs; do not force-merge, overwrite or silently delete legacy content.
- Existing native stack is in unmerged PRs #306–#347 (particularly Chapter I, combat, save codec/store and party authority). The new planetary work lives in draft PR #364, stacked on native PR #347. Legacy planetary research is in draft PR #349; visual experiment #363 and original renderer-review artifact issue #350 are separate evidence, NOT automatically canon.
- A second external agent has a **local only** Godot UI/test branch. Do not claim it is pushed, inspected, merged or retested unless its actual patch is supplied.

## Required implementation gates
1. Port behavior to GDScript with deterministic fixture comparisons against currently documented JavaScript rules; do not import/execute JS from Godot.
2. Keep all five authored protagonists, First Wake order/outcomes, approved artistic specifications, music and Dragonfly identity.
3. Do not promote non-canon planet radius, landmass shape, ship physics, decorative aurora, private atlas or Moon Bridge reveal as game canon. The secret bridge requires full-moon clue, nearest auroral approach, and rare gravity/magnetic alignment.
4. Maintain save compatibility only by explicit, versioned and tested codecs; back up player data, reject unknown schemas, never silently change historical save IDs when renaming display titles.
5. Native tests MUST run in actual Godot 4.7.2, with import/script/compiler-clean receipts. Screenshot claims require actual Godot captures, not synthetic images. Performance claims require target hardware GPU timings and VRAM. Human/creator acceptance is distinct from automated green checks.
6. No release or merger solely on a working prototype. Preserve changes as a draft PR until the appropriate checks pass.

Migration details and verified scope: `docs/GODOT_MIGRATION.md`.
