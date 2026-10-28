# Chapter One — Feathered Environmental Material Bridge

**Status:** isolated Godot 4.7.2 Compatibility **review candidate**. Not canon, production art, planetary geography, gameplay or release authority. Stacked on exact-source transfer draft PR #494, and native Chapter I draft PR #480. Source original PNG bytes/manifest unchanged.

## What this fixes

The first real Chapter I texture intake established independent source Git blob provenance and native scene integration, but displayed obvious hard rectangular marks in the water channels. Those were valid pipeline receipts yet poor environment art. This successor implements a **reusable CanvasItem shader** (`godot/shaders/environment_material_adapter.gdshader`) with UV-anchored, softly irregular four-edge fades and two source-domain families. One material family uses the original water ripple texture for the dock's actual side-water channels; the other uses original foliage detail in the existing two planters. Both take the unmodified original regional biome PNG as additional appearance input. Original terrain PNG remains imported and preserved for later real terrain use, not spuriously painted on the wooden deck.

A reusable adapter owns exactly four input-inert `TextureRect` children, using the same shader with distinct original texture bindings, tint palettes and masks. No new gameplay input, global shader, coastline data, 3D world meshes, ocean depth, renderer switches or physics bodies. Patch rectangles have expanded **presentation-only** footprints to allow alpha to reach zero at the edge. The original background/foreground staging remains authoritative for visible ocean and dock structures; this is a subtle material tint layer, not a replacement render. No animation clock, particle emitter, noise RNG or new assets.

## Prototype acceptance

1. Native Chapter I scene preserves exact story snapshots, Ender location, dialogue/actor layering, input focus, walking bounds, collision bitmasks and child count while material variant changes.
2. Original four Git blobs and the original intake manifest remain byte-identical, verified at CI time; the four assets remain in `godot/art-staging/environment-study/`.
3. `legacy` variant gives the first PR #494 rectangular marks **for comparison only**; `blended` is the current experimental presentation. The entire adapter remains **hidden by default** (no new player key). The low-quality mode hides all four child draw calls.
4. `godot/tests/environment_material_adapter_test.gd` tests actual Godot imported shader, both sampler bindings, four bounded/no-input children, toggles, low-quality bypass and scene invariants.
5. `godot/tests/capture_environment_material_adapter.gd` captures three identical-pose genuine native Godot frames: existing Chapter One scene, legacy rectangles, and new blended masks. Requires genuine localized visible changes, distinguishability from legacy, no new edge marks at outer frame boundaries, unchanged protected playable deck and Chapter I UI.
6. Existing native Chapter I source-intake test and two-frame capture, Chapter I migration tests, and project smoke remain valid. Current pixel-delta checks prove integration, **not** high-quality art, likeness, player acceptance or target hardware performance.
7. Release/merge and visual acceptance remain **HOLD**, as does creator artwork admission. Separate Windows CI security/Defender gates are unaffected.

## Design scaling without conflating local and global

Next phase should test this same *material adapter contract* inside a **representative approved geography** or a planetary local tile in isolation. Its input should be authored world surface masks and existing world coordinates, not hardcoded Chapter I screen rectangles. Do **not** reinterpret the small planar flight-lab height field as a planet; do not overlay planet coastline material on arbitrary lowlands. For world tiles, a signed shoreline distance requires actual tile terrain height data; for 2D Chapter I, the adapter deliberately binds to existing stage regions without pretending it owns ocean physics.

This milestone is a **pipeline-to-playable-scene** prototype, not the visual benchmark completion. The `Dragonfly Dusk Dock` benchmark still needs creator-accepted silhouettes, meaningful environment layering, actual ship, motion and a clear foreground/midground/horizon relationship.
