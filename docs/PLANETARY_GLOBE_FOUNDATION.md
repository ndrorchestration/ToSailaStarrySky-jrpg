# Planetary globe foundation — isolated prototype (2026-10-23)

## Current project identity — 2026-10-24

This work belongs to **To Sail the Starry Sky** (formerly Aetherwake). Canonical repository: `ndrorchestration/ToSailtheStarrySky-jrpg`, stable repository ID `1372641872`, visibility **PUBLIC**. Historical prototype ZIP names, source filenames, hashes and receipts retain the Aetherwake name and must not be rewritten. Public repository visibility is not release, canon, renderer or integration approval.

**Status:** Prototype code / draft implementation. This is not integrated into a playable planetary map, not creator-approved world cartography, and not a migration of the existing save format. See issue [#348](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/348).

## Why this exists

The creator requires an immense **spherical world** for **To Sail the Starry Sky**, not a small 2D/2.5D map with distant continents visible during low-altitude flight. Horizons must limit world view. Large ocean basins separate continents; high-latitude polar regions and diverse biomes exist on both hemispheres. A globe planning view may reveal a broader planet without disclosing undiscovered route details.

Existing `modules/world.js` (local 32×32) and `modules/air-navigation.js` (48×32 bounded air map) remain **unchanged**. So does the private, owner-only 2.5D atlas described in issue #302. No implicit assumption that the first-region map constitutes the whole planet.

## Coordinate contract

- Positions: `{latDeg, lonDeg, altitudeKm}`; latitude/longitude in **degrees**, altitude above a spherical reference surface in **kilometres**.
- Planet radius: **explicit `radiusKm` argument**, never a hidden canonical constant. The test fixture uses 6371 km *solely as a familiar numerical reference*: Aetherwake's planet radius is open.
- Longitude: half-open `[-180,180)`, with antimeridian wrap. Pole-crossing latitude normalization mirrors latitude and rotates longitude rather than clamping movement.
- Heading: clockwise degrees from north (`0=N, 90=E`). Geodesic heading for coincident and antipodal points is undefined and fails closed.
- Geometry: great-circle distance, destination after distance/bearing, spherical-separation angle, radial Cartesian coordinates, local east/north azimuthal-equidistant mapping.
- Local projection permits only the near hemisphere; planetary routes must **not** be squeezed into an unbounded flat local XY grid.
- Spherical horizon: visible central angle from altitude h is `acos(R/(R+h))` radians. Two points have unobstructed spherical line of sight only if angular separation <= the sum of their individual horizon angles. Terrain, cloud, fog, atmospheric refraction and discovery status require additional independent layers.
- All pure methods validate finite values, do not mutate inputs, and reject invalid radii and negative altitudes.

## Provisional biomes and map LOD (not yet built)

- **Level A, navigation globe:** rotating sphere, known geopolitical/biome areas, weather belts, separate discovery/route overlays; fog of *knowledge* is distinct from *geometric visibility*.
- **Level B, regional flight:** stream only visible nearby low/high-sky terrain chunks, floating islands and coastlines; real horizon culling as camera altitude changes.
- **Level C, local instance:** shipboard, dock, ground, cave and settlement gameplay remain existing local-space maps, anchored to a global coordinate when migration is eventually approved.
- Polar ice and tundra, boreal/temperate forests, wet/dry subtropics, deserts, grasslands, savannas, rainforest, wetlands and reef archipelagos should follow latitude, elevation, prevailing winds, mountains and currents first; aetheric phenomena are bounded modifiers, not random-color biome paint.
- Mainland ocean crossings should carry meaningful travel time before trunk sky lanes; late-game Auroral Rings provide hemispheric fast transit while maintaining geography.

## Automated proof

Run `node --test tests/planetary-geometry.test.js`. The focused tests assert 12 behaviors: coordinate wrapping, distance, bearing, antimeridian travel, north-pole crossing, altitude-dependent visibility, mutual airborne visibility, Cartesian reversibility, regional coordinate reversibility, out-of-range rejection, invalid input rejection and deterministic output.

**Local test evidence (not hosted GitHub CI):** 12/12 Node tests passed; 3000 additional deterministic local-projection round trips passed with worst observed distance error below 2e-11 km. The remote Windows/Desktop Commander quota was exhausted during this change. This evidence does not certify the published GitHub head, Windows builds or a live playable renderer; exact-head verification remains required.

## Integration sequence and release guardrails

1. Review independent geometry contract and choose a **provisional**, not canonized, planet radius plus target first-person/flight visibility envelope.
2. Add a separate experimental globe UI and actual test terrain, not part of the current Chapter I package. Confirm low-sky versus high-sky horizon from screenshots on target renderer.
3. Build geographic data/LOD, seam-safe texture/chunk indices, polar handling and camera; benchmark actual hardware.
4. Define explicit adapter between globe location and local scene instance; do not silently replace existing `x,y` in `modules/world.js` or `modules/air-navigation.js`.
5. After separately approved persistence design, use a **versioned, downgrade-safe migration** (coordinates, altitude, heading, discovery, route rights, landing state) with save/restore/restart regression tests.
6. Perform human visual/gameplay review and **only then** consider runtime or canon promotion.

**Release priority:** Do not block First Wake / Preview 0.1's one-click Windows build, exact-head tests, or current release gates. This branch remains draft and isolated until those release dependencies are resolved.

Related Notion source: [Planetary Macro-Map](https://app.notion.com/p/3ebf5bad238b8141a22ad84a67b45eed), [World Geography](https://app.notion.com/p/3ebf5bad238b8154a273e3096e98ed44).

## Continuation QA — 2026-10-23

Six-face `modules/planetary-tiles.js` defines a prototype cubed-sphere tile-key/neighbor contract (levels 0–12); it is neither production globe geometry streaming nor biome assets. Eight additional local Node tests passed, for 20/20 total. The experimental Canvas globe now shows the selected site's horizon as a circle on the full globe and displays example L6 tile candidate metadata.

Desktop/320/390/768/1280px Chromium sandbox verification (inlined script harness) reported no JavaScript errors or horizontal overflow. Median interactive Canvas redraw decreased from 60.2ms to 37.7ms in that environment; target game hardware/renderer profiling has **not** been performed. Github-hosted PR #349 workflow at head `5912676160ff97b4ea64e3b763ba2a58049cb99b` has no runnable job steps (`steps: null`) and is not evidence of test regression. Mainline gameplay and save format remain untouched.

## 2026-10-23 — v0.3 isolated geodesic flight and bounded terrain payloads

- `modules/planetary-flight.js` adds a pure state model for prototype speed, throttle, climb, heading and kilometer-scale geodesic motion. **Heading is parallel-transported after each step** using the endpoint's reverse bearing: an unchanged compass heading otherwise bounces back across a pole.
- `modules/planetary-streaming.js` plans tiles over the physical horizon using adjacency on the six-face cubed sphere, an intentionally conservative angular tile bound and LOD downgrade to remain within a fixed budget. It provides a bounded LRU of generated payloads; it does **not** implement network asset streaming, scene meshes, GPU textures, region persistence, visibility due to atmospheric weather, or actual in-game navigation.
- `docs/prototypes/planetary-flight.html` is a **separate, local, north-up 2D flight viewport**. It renders sampled terrain into tiny chunk payloads on demand and depicts no geography beyond the spherical horizon. Preset locations test an ocean coast, date line and both poles. The full planet remains a distinct tiny route-chart reference, not the low-sky view. Controls are experimental and simulation time is compressed **240×** to make motion visible.
- `tests/planetary-flight.test.js` and `tests/planetary-streaming.test.js` add **11** new deterministic tests for seam/polar flight, movement rules, bounded cache, horizontal candidate coverage, conservative LOD and invalid input. Current local suite: **31/31 passing**. Additional deterministic sample stress: 100 geographic centers (latitudes, longitudes, altitudes) × 120 horizon samples each, **0 tiles missing**, max tile candidates 255 (256 budget).
- Headless Chromium local-candidate QA passed at desktop and viewport widths 320 / 390 / 768 / 1280 with no JavaScript errors or horizontal overflow. At the reference radius 6371 km the observed 2→20 km altitude horizon was 160→504 km; initial flight view populated 69 candidate tiles, no cached evictions. QA screenshots and JSON are in the downloadable prototype evidence folder. **These results are not exact GitHub PR head, Windows GPU, human visual acceptance, or packaged First Wake verification.**

**Next gate:** Verify exact committed PR head, introduce an optimized GPU-backed spatial renderer (including terrain elevation and clouds in occlusion) and independent versioned conversion between local gameplay and planet coordinates only after creator review. Preserve all Preview 0.1 delivery gates.


## Cinematic Godot renderer handoff — issue #350

The spherical geometry/streaming prototype in this branch and the cinematic Godot art-direction prototype are deliberately separate layers. Geometry authority must not silently inherit presentation units, proxy asset scale, non-canon coastlines, or visual set dressing from the cinematic study.

The latest isolated renderer handoff recorded in issue #350 is:

- review kit: `Aetherwake_Godot_Native_Review_Kit_v0.6.1_2026-10-23.zip`
- review-kit ZIP SHA-256: `bba6ee4f6b0271be3d3f73e187aaf1354937d8de6c3626f6198a777805c19c42`
- underlying v0.6.1 cinematic archive SHA-256: `359817e3cf284825cd6aa64ab30d2f4ab805c9a2ae2c6b66264ad030c4f1c0d9`
- scoped 29-file source/test/tool manifest SHA-256: `75742f2edff21a071acada35cc7f9b81d18b00d4d0bc084bf9de39f563979341`
- current renderer source status: **conversation artifact only; not committed to this repository**
- current engine status: **native Godot 4.7.2 execution not established**
- current art status: **no real Godot renderer screenshots, GPU timings, or creator visual acceptance established**

The exact source archive is not available on the current Project/Library file surfaces. Do **not** recreate Godot source from issue comments, screenshots, prose descriptions, or remembered snippets. Repository admission requires the exact artifact bytes or another source package whose identity can be independently checked against the recorded manifest.

When those exact bytes are available on an authorized machine, the first native review command is:

```powershell
python tools/run_native_review.py --godot "<trusted Godot 4.7.2 editor/console executable>" --render --renderer gl_compatibility --expected-source-manifest-sha256 75742f2edff21a071acada35cc7f9b81d18b00d4d0bc084bf9de39f563979341
```

Then repeat separately with `--renderer forward_plus` on Vulkan-capable target hardware. Required evidence before any renderer-source import or gameplay bridge:

1. exact source-manifest match;
2. successful Godot 4.7.2 import;
3. native flight-math and scene-contract tests;
4. three distinct real Godot captures for orbital mode 1, globe-scale chase mode 4 and local sea-flight mode 5;
5. no GDScript/shader compile errors;
6. measured frame time/VRAM on representative Windows hardware;
7. creator visual review of scale, atmosphere, ocean, coast, cloud and Dragonfly composition;
8. explicit separation between non-canon art-direction proxies and approved world/cartography data.

Only after those gates should renderer code be considered for a dedicated repository branch. Even then, integration with Chapter I, save schema, canonical planet radius/geography, and protected main remains a separate reviewed decision. Issue #348 supplies world-scale requirements; issue #350 supplies cinematic fidelity gates; this document remains the geometry/streaming bridge between them.


## 2026-10-23 — v0.3.1 streaming-bound correction

A focused cubed-sphere audit found no sampled seam/pole holes in the cardinal-neighbor BFS, but did identify an avoidable LOD-quality loss: the prior tile-center padding used `atan(2*sqrt(2)/2^level)`, approximately twice the necessary linear margin at useful LODs.

The planner now uses the tighter conservative bound `atan(sqrt(2)/2^level)`. For a gnomonic cubed-sphere tile, `1/2^level` is the half-width in face UV space, so `sqrt(2)/2^level` bounds center-to-corner displacement. This retains conservative horizon admission while reducing false-positive tile candidates.

Regression coverage now:
- samples all six cube faces at representative edge/center tile coordinates and levels 0, 1, 2, 4, 8 and 12;
- verifies every sampled tile corner lies within `angularPadding(level)`;
- proves the new padding is smaller than the legacy 2× bound;
- locks the existing 200 km altitude / 25-tile-budget stress case to L3 rather than merely asserting some unspecified downgrade below requested L11.

An independent exhaustive/property audit over tractable LODs found the neighbor graph connected and the BFS candidate set equal to brute-force center-distance selection for the sampled caps/positions. Additional randomized corner checks through L12 found no padding violation. These are same-session engineering checks, not hosted CI or native-renderer evidence.

No world geometry, flight speed, save data, canon radius, cartography, Chapter I scene or renderer asset changed. Exact-head Node/hosted execution remains separately required.


## 2026-10-23 — cinematic Godot v0.7.2 native-handoff pin repair

Exact v0.7.1 bytes became available from the project Library and were independently materialized for audit. The archived Godot source itself matched the recorded v0.7.1 ZIP and 33-file source-manifest identities, but the Windows review handoff contained a concrete stale-pin defect:

- `SOURCE_MANIFEST_SHA256.txt` correctly named v0.7.1 source manifest `65f5a3e8bb960ad5b2bdef6ff49bb44c27c4d349681bdbcbf59d44c1aa3d4c57`;
- `tools/run_native_review_windows.ps1`, `README.md`, and `NATIVE_REVIEW_KIT_README.md` still pinned the older v0.7 source manifest `1071e1343d0c6a29328987f39fcdd55c979ff87b7a39df1513dc483a794a1536`;
- therefore the v0.7.1 Windows launcher would fail closed on a source-manifest mismatch before Godot could execute, even when the v0.7.1 source was correct.

A distinct repaired Library artifact was produced rather than silently replacing v0.7.1:

- artifact: `Aetherwake_Godot_Georeferenced_Flight_v0.7.2_2026-10-23.zip`
- size: **1,765,301 bytes**
- ZIP SHA-256: `8550d57c7c8cc62cb17e6c426cde211998622c608f9c8c744845c81841298cd6`
- ZIP members: **49**
- underlying Godot source/test/tool manifest: unchanged **33 files**
- source-manifest SHA-256: unchanged `65f5a3e8bb960ad5b2bdef6ff49bb44c27c4d349681bdbcbf59d44c1aa3d4c57`

The repair changes only non-manifest handoff files: the Windows PowerShell launcher and two READMEs. Recomputed source-manifest identity remains exact. Running the Python native-review gate with the repaired expected manifest and a deliberately nonexistent Godot binary now reaches the intended `Godot executable missing; no native QA attempted` result rather than a manifest mismatch. Static/source validators remain PASS; declaration-boundary self-tests are 3/3 PASS; all 12 synthetic receipt-gate tests were observed passing across bounded grouped/individual executions. These are QA-harness checks only.

Native Godot 4.7.2 import, GDScript/shader compilation, modes 1/4/5 renderer captures, GPU frame time/VRAM and creator visual acceptance remain **NOT VERIFIED**. Do not admit the cinematic source into runtime/main or claim renderer fidelity until those native gates execute.


## 2026-10-23 — cinematic Godot v0.7.3 native scene/runtime repair

A real creator-run Windows Godot 4.7.2 Compatibility gate was executed against v0.7.2 using official engine version `4.7.2.stable.official.ed1daf0bf` (engine SHA-256 `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`).

Observed native evidence:
- engine-version gate: PASS;
- native project import: PASS, exit 0, no logged error marker;
- native geodesic flight math: PASS with `AETHERWAKE_CINEMATIC_FLIGHT_MATH=PASS`;
- native scene contract: FAIL, exit 1;
- graphical capture did not run because the scene gate failed first.

The scene failure exposed three concrete issues:
1. `scripts/planetarium.gd` status text used a literal `30%` inside a `%` formatting expression, producing `String formatting error: unsupported format character`.
2. `scripts/planetarium.gd` assigned nonexistent Godot 4 `Node3D.rotation_y`, producing an invalid property assignment.
3. The georeferenced return-to-coordinate assertion captured its baseline after live mode-4 flight had already advanced slightly, then compared that moving baseline against an explicit `(19.0,-115.0)` reset.

A distinct repaired Library artifact was produced:

- artifact: `Aetherwake_Godot_Georeferenced_Flight_v0.7.3_2026-10-23.zip`
- ZIP members: **51**
- size: **1,769,797 bytes**
- ZIP SHA-256: `91235a52e82c726a0471e2e178a77905c66f49c57d7c8413fa16d600b281b986`
- scoped 33-file source-manifest SHA-256: `60a37861343dfec295b248f88b78c51ac7c9fec13a6fcce2179679df6ab8f6c9`

v0.7.3 repairs only those observed scene/runtime defects:
- status line now uses concatenation rather than the fragile percent formatter while retaining literal `30%`;
- globe rotation reset assigns a valid `rotation` Vector3;
- the scene test explicitly establishes `(19.0,-115.0)` before recording the out-and-back baseline;
- static validator assertions lock all three repairs.

Post-repair static/source validation remains PASS, declaration-boundary self-tests are 3/3 PASS, and synthetic native-runner receipt-gate cases are accounted for across bounded runs. A manifest-pinned negative runner check reaches the intended missing-Godot failure, proving the v0.7.3 handoff pin matches the repaired source.

**v0.7.3 has not yet been rerun in native Godot.** Required next evidence is another real Compatibility run. It must pass the scene marker before graphical capture can establish authentic modes 1/4/5 frames; Forward+ and GPU/visual acceptance remain separate gates.


## 2026-10-23 — v0.7.3 proof-kit rebase supersedes lightweight package

A parallel v0.7.2 **Native Scene Proof Kit** was discovered in the project Library after the first v0.7.3 repair package was prepared. It contains the same authored Godot scene source defects exposed by the creator's Windows run, but has a stronger QA harness: Windows launchers are source-manifest-covered, screenshot center-region content is analyzed rather than relying only on file hashes, and dedicated PNG-decoder plus launcher-pin regression tests are included.

The three real-native repairs were therefore rebased onto that stronger proof kit. This final v0.7.3 package supersedes the earlier lightweight `Aetherwake_Godot_Georeferenced_Flight_v0.7.3...` artifact, which is retained in the Library under an explicit `SUPERSEDED_BY_NATIVE_SCENE_PROOF_KIT` name for provenance.

Current artifact:
- `Aetherwake_Godot_Native_Scene_Proof_Kit_v0.7.3_2026-10-23.zip`
- ZIP members: **55**
- size: **1,777,376 bytes**
- ZIP SHA-256: `b8153ce43f59c3efc10a38b882282f31970fdb30c8ecf927fa20cf6d0f0579bf`
- source manifest: **39 files**
- source-manifest SHA-256: `734969c447f0af38ccf36135430a2f56ef34634428cfdea39808f98f47d8b596`

The final proof kit retains all three native fixes:
1. removes the fragile percent formatter from the status line while preserving literal `30%`;
2. replaces invalid `Node3D.rotation_y` with a valid explicit `rotation` Vector3 assignment;
3. establishes an explicit `(19.0,-115.0)` baseline before the local georeference out-and-back assertion.

Verification of the rebased package:
- 10/10 standalone static/source/asset/launcher validators PASS;
- declaration-boundary tests 3/3 PASS;
- PNG decoder/filter tests 3/3 PASS;
- Windows launcher-pin tests 3/3 PASS;
- synthetic native receipt-gate tests 14/14 PASS across bounded grouped/individual execution;
- manifest-pinned negative native runner correctly returns exit 2 / `NOT_VERIFIED` only because the local authoring environment lacks Godot.

The final v0.7.3 proof kit still requires the creator's real Windows Godot 4.7.2 Compatibility rerun. No native v0.7.3 scene PASS, renderer frames, GPU timings, or creator visual acceptance is claimed yet.


## 2026-10-23 — v0.7.4 native QA receipt custody hardening

A focused audit of the final v0.7.3 proof-kit capture path found no additional authored Godot scene defect, but did identify one evidence-custody weakness: every native run wrote the receipt to the same `evidence/native/NATIVE_QA_RECEIPT.json` path. A later Forward+ run could therefore overwrite the earlier Compatibility receipt even though screenshots were already run-ID-scoped.

The QA harness now writes both:
- `NATIVE_QA_RECEIPT_<run_id>.json` — immutable run-specific receipt; and
- `NATIVE_QA_RECEIPT.json` — compatibility/latest pointer with identical content.

No authored scene, shader, texture, georeference, flight, Chapter I, save, canon or visual-content behavior changed from the final v0.7.3 proof kit.

Current artifact:
- `Aetherwake_Godot_Native_Scene_Proof_Kit_v0.7.4_2026-10-23.zip`
- ZIP members: **66**
- size: **1,781,779 bytes**
- ZIP SHA-256: `816b188640ef7289088817c11ad26826c9a863a002b37a85b3521b9ecc71c086`
- source manifest: **39 files**
- source-manifest SHA-256: `e14659e4200b38a4b4f5923a5dda4c66fd80c43601363ec2a893ecaac026bf01`

Verification after the custody change:
- all 14 synthetic receipt-gate cases accounted for PASS across bounded runs, including the new assertion that run-specific and latest receipts are byte-equivalent JSON and both paths are emitted;
- standalone static/source/asset/launcher validators PASS;
- declaration-boundary tests 3/3 PASS;
- PNG decoder/filter tests 3/3 PASS;
- Windows launcher-pin tests 3/3 PASS;
- exact source-manifest recomputation matches the packaged pin;
- manifest-pinned negative runner reaches the expected missing-Godot `NOT_VERIFIED` state and creates both receipt paths.

The v0.7.4 proof kit is the preferred next native-review package. It still requires a real Windows Godot 4.7.2 Compatibility rerun; no v0.7.4 native scene PASS, renderer frames, GPU timings or creator visual acceptance is claimed.


## 2026-10-23 — v0.7.5 consolidated native-proof + physical-horizon handoff

A parallel Library artifact was reconciled after v0.7.4: `Aetherwake_Georeferenced_Flight_v0.7.3_with_Realism_Study_2026-10-23.zip` (ZIP SHA-256 `8abe740643b60423ff70a484053757d1edd7326d3d45cd0c1e64626d3ad70e0f`). That branch contained a substantive improvement—altitude-dependent spherical surface-horizon culling for local sky-garden proxies—but also reintroduced all three real-native defects already repaired after the creator's Windows v0.7.2 run:

- invalid `Node3D.rotation_y`;
- fragile percent-format status text containing literal `30%`;
- moving georeference round-trip baseline captured after live flight had advanced.

The parallel artifact also lacked v0.7.4's immutable per-run native receipt custody. It is therefore **not** the preferred handoff.

v0.7.5 selectively consolidates the valid horizon feature into the stronger v0.7.4 Native Scene Proof Kit while preserving every established native repair and QA gate.

Current preferred artifact:
- `Aetherwake_Godot_Native_Scene_Proof_Kit_v0.7.5_2026-10-23.zip`
- ZIP members: **62**
- size: **1,790,699 bytes**
- ZIP SHA-256: `854adb22a44292cfa6284d6f44a3d38ddec7859bdbcec02350e400185883af80`
- source manifest: **41 files**
- source-manifest SHA-256: `2dd4797c41a31bdaff0ae26fc9490c0758e7e6cb388003aebcaa6d6066579d80`

Consolidated source behavior:
- local sky-garden proxies are culled to `min(500 km, R*acos(R/(R+h)))`, using the explicitly non-canon 6371 km reference radius and current flight altitude;
- Dragonfly local-presentation updates pass altitude on activation and every navigation tick;
- invalid/non-finite or negative local altitude fails closed;
- the model intentionally treats proxies as surface-arc anchors; elevated island-top line of sight, refraction, true streamed terrain and canonical planet radius remain outside scope;
- v0.7.4's valid `rotation` Vector3 repair, safe status string, deterministic georeference baseline, center-scene screenshot proof, manifest-covered Windows launchers and immutable per-run receipts are all retained.

Verification of the exact v0.7.5 source/archive:
- 11 standalone static/source/asset/launcher validators PASS;
- declaration-boundary self-tests **3/3 PASS**;
- PNG decoder/filter tests **3/3 PASS**;
- local-horizon self-tests **6/6 PASS** plus 6,000 randomized altitude/position monotonicity probes;
- Windows launcher-pin self-tests **3/3 PASS**;
- all **14/14** synthetic native receipt-gate tests accounted for PASS across bounded runs;
- exact source-manifest recomputation after extraction PASS;
- ZIP CRC and every member byte identity PASS;
- manifest-pinned negative native runner accepts the exact source pin, writes both run-specific/latest receipts, then returns exit 2 / `NOT_VERIFIED` solely because this authoring environment lacks Godot.

The first archive attempt was discarded because Python validation regenerated `__pycache__` files; the preferred ZIP above was rebuilt cleanly with bytecode disabled and independently verified to contain no cache artifacts.

**Native status:** v0.7.5 has not yet run on real Godot. The authoritative next gate remains the creator's Windows Godot 4.7.2 Compatibility run, followed separately by Forward+ if Compatibility passes. No v0.7.5 native scene PASS, genuine modes 1/4/5 frames, GPU timings, or visual acceptance is claimed.


## 2026-10-24 — exact hosted planetary regression gate

Current draft branch head before this documentation-only checkpoint: `aafcb84b939064cf6d96222c750ff02158fc9f94`.

Hosted GitHub Actions now provides exact execution evidence for the engine-neutral planetary foundation:

- dedicated workflow run `40064143275`, job `120783719360`;
- Node `22.23.3`;
- `tests/planetary-geometry.test.js`;
- `tests/planetary-tiles.test.js`;
- `tests/planetary-flight.test.js`;
- `tests/planetary-streaming.test.js`;
- result: **32 tests / 32 PASS / 0 FAIL / 0 SKIP**;
- same-head generic Aetherwake smoke run `40064143257`: **SUCCESS** through the ordinary runtime contracts and browser smoke.

The branch-local CI additions are verification-only: a read-only dedicated planetary workflow and an equivalent planetary Node step in the draft branch's smoke workflow. They do not grant package, release, deployment, save-migration, canon or runtime-integration authority.

This closes the previous exact-head Node execution gap. It does **not** verify the separate v0.7.5 Godot proof-kit archive, native modes 1/4/5, GPU timing/VRAM, creator visual acceptance, canonical planet radius/geography, or Chapter I integration.
