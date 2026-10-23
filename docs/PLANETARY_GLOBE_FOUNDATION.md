# Planetary globe foundation — isolated prototype (2026-10-23)

**Status:** Prototype code / draft implementation. This is not integrated into a playable planetary map, not creator-approved world cartography, and not a migration of the existing save format. See issue [#348](https://github.com/ndrorchestration/aetherwake-jrpg/issues/348).

## Why this exists

The creator requires an immense **spherical world**, not a small 2D/2.5D map with distant continents visible during low-altitude flight. Horizons must limit world view. Large ocean basins separate continents; high-latitude polar regions and diverse biomes exist on both hemispheres. A globe planning view may reveal a broader planet without disclosing undiscovered route details.

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
