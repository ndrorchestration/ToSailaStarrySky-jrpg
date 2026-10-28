# Native Chapter I environmental asset intake — P0 prototype pipeline

**Authority:** REVIEW-ONLY / NONCANON / DRAFT / UNMERGED. No creative canon, gameplay, map, save, Windows release or production material admission.

## Why this matters

The 960×640 `godot/flight_slice` coastal flight lab demonstrates real Godot shader art, but it is an independently isolated local planar terrain experiment. The `godot/` Godot 4.7.2 project on the Chapter I branch is the **actual forward native story pilot**, with Ender, staged dialogue, dock, UI, collision, and save contracts. `main` remains the legacy JS/p5 historical reference. Direct merging of the flight lab onto the Chapter I line would overwrite dependencies and falsely equate study geography with canonical gameplay.

This P0 pipeline transfers **exactly four original PNG Git blobs** at source draft PR [#476](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/476), commit `02fad39dbc1238ddb146ae5b8ae7d67cf7b03f52`. It deliberately does **not** copy the independent flight lab's world, sky, coastline, physics, trees, engine, ship or gameplay.

## Intake contract

1. **SOURCE:** original `terrain_microdetail.png`, `foliage_microdetail.png`, `water_ripple_detail.png`, `biome_macrodetail.png`, all original 128×128 RGBA. Copied as exact Git blobs, not regenerated, resampled or converted. `godot/art-staging/environment-study/intake-manifest.json` maps source paths, immutable Git blob identities, target staging and approval gates.
2. **HASH/FORMAT:** `node tests/godot-environment-art-intake-contract.test.js` validates the exact Git **blob SHA-1** content identity, fixed PNG dimensions/type, complete whitelist, source SHA and restrictive metadata. Git blob SHA is not a statement of independent SHA-256 assurance; this is source-to-destination byte preservation within the repository.
3. **NATIVE IMPORT:** `godot/scripts/ch1_environment_art_intake.gd` preloads all four actual `Texture2D` resources in the **Chapter I project**. No external texture conversion, network fetch, new third-party art, or additional copyright license.
4. **LIVE SCENE OPT-IN:** `godot/scripts/first_wake_chapter1_review.gd` inserts a hidden-by-default `Node2D` between existing dock background (z -2) and real actors (z 0). A review-only method toggles subtle original ocean/foliage texture patches strictly over the existing dock's two side-water channels and two planters. No new gameplay key, NPC, ship, collision body, safe-path region, save field, dialogue change or global animation.
5. **NATIVE TEST:** `godot/tests/environment_art_intake_test.gd` checks import/dimensions and the actual First Wake scene for unchanged story snapshot, Ender position, walk bounds, collision bitmasks, and stable node count across repeated toggles. Default OFF is mandatory.
6. **GL SCREENSHOT:** `godot/tests/capture_environment_art_intake.gd` captures two actual matched 960×640 frames of the **same** First Wake scene and fails if water and planter samples did not change or gameplay dock/UI pixels unexpectedly changed. The pixel delta is **integration proof**, not artist approval or 3D PBR reproduction.
7. **CI:** `.github/workflows/godot-environment-intake.yml` uses SHA-256 digest-pinned original Godot 4.7.2 Standard, imports the native project, executes tests and renders both images in Linux software GL. The artifact upload is best-effort due to prior quota blockers; log hashes do not substitute for retrieved image inspection.

## Direct reuse vs future adaptation

| Study component | Chapter I prototype intake | Forward production assessment |
| --- | --- | --- |
| Original source PNGs and provenance | **Exact-source asset intake** | Promote only after visual quality/compatibility review and versioned asset library |
| Deterministic generation / texture byte checks | **Source blob equality check** | Generalize manifest and build preflight for approved assets |
| Terrain/foliage/ripple channel interpretation | **Conservative 2D overlay only** | Author scene-appropriate CanvasItem/material shader (not wholesale 3D shader copy) |
| Signed shoreline distance bake | **Not ported** | Adapt to worldmap/local terrain elevation when one authoritative coastline exists |
| 3D faceted rock and canopy geometry | **Not ported** | Requires mesh/LOD/render pipeline and real lighting acceptance |
| Weather/dusk crossfades, reduced motion | **No behavior changed** | Later shared visual policy for field, flight, and cinematic scenes |
| Aureate Wake ship flight/landing prototype | **Not ported** | Preserve independently verified physical systems in a separate world/ship adapter |
| Globe, moon routes, native party, progression | **Untouched** | Remain under respective design/canon/release authorities |

## Result status

At draft authoring: `NATIVE_IMPORT=PENDING`, `SOURCE_BLOB_PROOF=PENDING`, `RENDERED_COMPARE=PENDING`, `ARTISTIC_ACCEPTANCE=PENDING`, `PRODUCTION_MERGE=HOLD`.

**After technical proof**, the next reversible experiment is to bind an approved palette/material adapter to a representative **actual** Chapter I ground/water surface while keeping current coordinates, collision, and dialogue unchanged. The canonical Dragonfly Dusk Dock benchmark, representative dialogue, combat and flight scenes still require creator-reviewed near-final art before wider propagation.
