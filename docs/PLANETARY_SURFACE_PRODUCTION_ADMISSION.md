# Planetary surface — prototype-to-production admission ledger

**Status:** ISOLATED DRAFT PROTOTYPE, not admitted to the shipped game.
**Owner authority:** Canonical geography, authored encounter sites, save schema, ship traversal, Five Lights, story discoveries and Moon Bridge reveal remain separately creator-controlled.
**Source branch:** draft PR [#489](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/489), based on the spherical prototype PR [#349](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/349).
**Art input:** noncanonical Godot studies [#418](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/418), [#448](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/448), [#460](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/460), [#470](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/470), and [#485](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/485). These are *reference implementations and QA evidence*, not canonical map tiles or shipped production assets.

## What can be reused now

| Demonstrated capability | Reusable production **pattern** | What must NOT be promoted |
| --- | --- | --- |
| Single deterministic height sampler in the local art scene | One authoritative elevation service shared by render mesh, physics and flight clearance | The planar sampler's numeric heights, coast, mountain layout and landing pad |
| Terrain mixed-LOD stitching / surface normals | Spherical edge continuity and real normal QA at variable detail levels | A hardwired 24:6 ratio, 64-tile local budget or planar skirt assumptions |
| Slope-aware cliff projection / layered snow and rock | Visual material-family vocabulary and shader acceptance criteria | Literal alpine shader uniforms or elevations without native local normals/height |
| Deterministic foliage, stones, talus and weather | Reproducible biome detail that respects reduced-detail and motion settings | Fixed art-study scatter coordinates, biome ownership or canonical species |
| Native touchdown physics admission and recovery | Fail-closed collision contact and consistency checks between mesh and gameplay surface | Current test-field single-ray authorization as planet-wide landability |
| Godot native fixed-camera A/B screenshot captures | Repeatable art reviews with matching clock, camera, sun, weather and quality tier | Treating passing pixel deltas or hosted software GL timing as art/GPU approval |
| Planetary geometry, cubed-face tiles, horizon streaming (#349) | Seam/pole-safe tile identity and bounded visibility from ship altitude | The test radius of 6371 km, fictional continents or disclosed locked routes |

## Implemented bridge: planetary tile → material request → Godot admission

The **isolated, documented data path** is:

1. `modules/planetary-geometry.js` validates latitude, longitude and altitude (degrees/degrees/km).
2. `modules/planetary-streaming.js` selects a bounded list of horizon-relevant cubed-sphere tile addresses, using `modules/planetary-tiles.js`.
3. `modules/planetary-cartography.js` supplies noncanonical biome and color hints to `modules/planetary-surface-handoff.js`.
4. `scripts/build-planetary-surface-fixture.js` exports four representative, fixture-only planetary tile cases to `planetary-surface-admission/v1` JSON.
5. `godot/planetary_handoff/tests/test_manifest.gd` consumes **the actual Node-generated JSON** in native Godot 4.7.2. It checks the full tile count, provenance, material family, LOD, quality, color channels, geographic coordinates and forbidden gameplay authority; it independently reconstructs each cubed-face tile center in mathematical Z-polar coordinates, and runs hostile mutation tests.
6. `.github/workflows/planetary-handoff-native.yml` installs the same exact Godot version as the separate terrain visual lab and executes the admission checks. `tests/planetary-surface-handoff.test.js` guards upstream Node semantics, while `planetary-visual.yml` checks the browser globe and flight telemetry across desktop/mobile widths.

**Explicit negative contract:** JSON surface requests must say `elevation`, `collision`, `landable`, `discovery`, `route` and `story` are `UNSPECIFIED`; they may never be silently interpreted as gameplay facts. An alpine cliff material request `REQUIRES_LOCAL_NORMAL` and snow mask `REQUIRES_LOCAL_ELEVATION` are inert hints until an independently authorized native renderer supplies those measurements. A unitless `reliefColorHint` is *not* a displacement magnitude or collision elevation.

**Proof scope:** The first generated fixture exercised 190 tiles in four cases (coast, antimeridian, north pole, south pole). The native run [#40615194937](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615194937) passed six admission/mutation checks at the earlier receipt head. A subsequent tightening of independent cube-face center validation increases the required checks to seven; **rebind all later claims to the current exact-head run**. Neither the earlier result nor the next native manifest PASS proves spherical mesh shading, landing or player-accessible world integration.

## Production gates — independent acceptance, no implied promotion

| Gate | Required proof | Status |
| --- | --- | --- |
| P0 — Globe geometry and deterministic cartography | Pole, antimeridian, horizon and tile-budget coverage, shared color and biome sampling | Verified in prototype CI only; #349 unmerged |
| P1 — Cross-engine surface receipt | Node fixture → versioned JSON → Godot 4.7.2 parse + precise tile address/center + explicit authority denial; intentionally corrupted cases rejected | Implemented in draft #489; final exact-head CI required |
| P2 — Actual native spherical material patch | One 3D cube-face tile with local tangent-frame mapping, normals and materials; high/low A/B screenshots and face-neighbor seam proof | **OPEN; no spherical mesh in this PR** |
| P3 — Physical terrain truth | A real accepted heightfield or authored surface, shared renderer/collider/clearance sampling, robust multi-contact landing tests and loss-of-support recovery | **OPEN** |
| P4 — World progression + story boundary | Save/world coordinate migrations, explored vs visible vs charted separation, biome authority review and explicit story reveal gates (including Moon Bridge/auroral pathways) | **OPEN; creator decision** |
| P5 — Art and performance | Approved visual benchmark at full/reduced resolution, real GPU frame-time/memory budgets, accessibility, weather/time of day and quality tiers | **OPEN; target hardware and creator acceptance** |
| P6 — Merge/release admission | Independent exact-head tests, code review, provenance, dependency/license check, playable build/QA, authority and release approval | **OPEN** |

## Next smallest reversible vertical slice

Build **one noncanonical spherical patch** in a separately reviewable Godot prototype that consumes the admitted tile receipt. Use a single cubed-face patch plus one adjacent neighbor crossing a face seam; choose an explicit **lat/lon/km → Godot Y-up/metres** frame rather than assuming the data's Z-axis is the engine's up-axis. Implement geometry and collision authority as separate validated dependencies; do not synthesize collision from colors or permit landing merely because a tile says `land`. Check the cube-face edge vertices and normals, LOD transition, horizon culling at two altitudes, high/low visual quality, fixed-camera framebuffer pairs and numeric world units. Then test a rejected missing collider and recover safely.

Only after this can the team evaluate porting a **material design**, not a static map layout, into the gameplay renderer. Production integration also requires asset budgets, documented seed ownership, save migrations, story spoiler review, player traversal, pause/reduced-motion behavior and real Windows GPU measurements.

## Documentation authority and synchronization

- **Updated in this branch:** `docs/PLANETARY_SURFACE_PRODUCTION_ADMISSION.md` (this ledger), `docs/PLANETARY_GLOBE_FOUNDATION.md` (planetary design/prototype source), `docs/DEVELOPMENT.md` (branch-scoped development checkpoint), `godot/planetary_handoff/README.md` (native reproduction).
- **Needs review before production promotion:** `docs/GODOT_MIGRATION_COORDINATION.md` (on a separate/main-line lineage; reconcile rather than blindly copy), `docs/VISUAL_BIBLE.md` and `docs/VISUAL_BENCHMARK_SCENE.md` (visual acceptance after creator review), `docs/CANON_AND_REVEAL_POLICY.md` and world/ship documents (only if authoritatively approved), `SPEC.md` / `README.md` / release notes (only after integration/merge). Notion development/prototype index should link this ledger and distinguish draft code from verified game content.
- Never automatically promote a draft PR status, illustrative coastlines, reference radius, lore secrets or unmerged code to the current-main source of truth.

## Reproduction

Run the planetary Node suite:
`node --test tests/planetary-geometry.test.js tests/planetary-tiles.test.js tests/planetary-flight.test.js tests/planetary-streaming.test.js tests/planetary-cartography.test.js tests/planetary-surface-handoff.test.js`.

Generate native fixture:
`node scripts/build-planetary-surface-fixture.js --out /tmp/planetary-surface-manifest.json`.

With Godot 4.7.2, import `godot/planetary_handoff/` then run:
`godot --headless --path godot/planetary_handoff --script res://tests/test_manifest.gd -- /tmp/planetary-surface-manifest.json`.

For reproducible hosted evidence prefer the exact-head **Planetary Surface Native Admission** workflow; review JSON artifact and native log, not only the green badge.
