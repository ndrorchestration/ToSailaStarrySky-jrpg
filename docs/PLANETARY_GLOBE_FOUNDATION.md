# Planetary globe foundation — isolated prototype (2026-10-23)

**Status:** Prototype geometry, not live planetary gameplay or approved cartography. Tracks [#348](https://github.com/ndrorchestration/aetherwake-jrpg/issues/348).

## Creator requirement

Aetherwake must ultimately navigate an immense **spherical planet**, with physically meaningful horizons at ground and ordinary airship altitudes, continents across large oceans, northern and southern polar regions, and climate-based biomes. A rotatable overview globe is a separate chart mode, not permission to reveal far-away land during ordinary flight.

## Coordinate and geometry contract

- Position shape: `latDeg`, `lonDeg`, and optional `altitudeKm`; angles in degrees and altitude in kilometres.
- Every distance/curvature method requires an explicit `radiusKm`. The 6371 km reference radius in tests is **not** an Aetherwake canon decision.
- Longitude wraps to `[-180,180)`; polar crossings reflect latitude and rotate longitude, not clamp movement.
- Bearings are clockwise from north (north = 0 degrees, east = 90 degrees); exact coincident/antipodal bearings fail closed.
- Great-circle distance, destination, Cartesian conversion, and near-hemisphere local east/north conversion are pure helpers.
- The spherical horizon angle at altitude h is `acos(R/(R+h))`; mutual geometric visibility uses the sum of two horizon angles and their central separation.
- Terrain, weather, fog, discovery status, sky lanes and route permissions remain independent and are **not** simulated by this module.
- Local XY coordinates explicitly reject planet-spanning projections, preventing one flat region from impersonating the entire planet.

## Layers planned — not yet implemented

1. **Planetary globe:** world-space sphere with optional knowledge/route overlays; undiscovered locations stay hidden.
2. **Regional flight:** streamed local terrain chunks with altitude-dependent horizon occlusion, coastlines, floating islands and airship navigation.
3. **Local scenes:** ship interiors, dock, ground, caves and settlement instances anchored to global coordinates after review.
4. **World generation:** multiple ocean-separated continents, ice-covered poles, tropical/temperate/boreal zones, mountain rain shadows, currents and plausible biome transitions. Aetheric geography modifies physical systems instead of replacing them.
5. **Travel progression:** local low-sky flight, long-distance trunk sky lanes, and late-game Auroral hemispheric travel.

## Evidence and tests

Run `node --test tests/planetary-geometry.test.js`. Twelve focused Node tests passed locally, covering antimeridian travel, great-circle distance, pole crossing, reciprocal local projections, altitude-dependent horizon and geometric line of sight, Cartesian round trips, invalid input and determinism. A 3000-case local-coordinate round-trip property sweep also passed with worst observed error below 2e-11 km.

**Verification boundary:** These are local candidate tests, not exact published-branch CI, Windows renderer proof, user acceptance or in-game save/load testing. Remote Desktop Commander was unavailable because of its monthly quota.

## Release and migration protection

Current `modules/world.js` uses a 32x32 local scene; `modules/air-navigation.js` uses bounded 48x32 air coordinates. The owner-private 2.5D Atlas prototype remains separate (#302). **None of these are replaced in this branch.** Chapter 1/Preview 0.1 packaging and exact-head verification have priority. Any conversion to live globe navigation requires independent visual review, physical travel-time tuning, explicit renderer performance measurements, and a separately approved versioned downgrade-safe save migration.

Related Notion: [Planetary Macro-Map](https://app.notion.com/p/3ebf5bad238b8141a22ad84a67b45eed) and [World Geography](https://app.notion.com/p/3ebf5bad238b8154a273e3096e98ed44).


## 2026-10-23 — Cubed-sphere address and visual validation checkpoint

- `modules/planetary-tiles.js` adds six-face cubed-sphere indexing with prototype levels 0–12, stable tile keys, center lookup and local adjacency across face/polar/date-line seams. It is **metadata addressing only**; it does not create terrain assets, instantiate gameplay chunks, or stream geometry.
- `tests/planetary-tiles.test.js` adds eight focused Node regressions: six faces, seams, poles, directional/UV round trips, neighbor keys, candidate neighborhoods and malformed input. Local geometry + tile suite is **20/20 passing**.
- `docs/prototypes/planetary-globe.html` now draws a surface-horizon footprint on the chart and displays a sample L6 tile identifier and nearby candidate count. These are *illustrative diagnostics*, not a production biome or chunk layout.
- Chromium headless browser QA executed in a sandbox by inlining the local prototype scripts (direct `file:` / localhost navigation blocked by host policy). Verified desktop and 390px mobile view, named polar/altitude preset responses, globe drag, no JavaScript page errors, and no horizontal mobile overflow. **This is not a claim of direct local-file navigation testing, GPU/Windows target performance, native player review, or exact-PR-head browser approval.**
- The latest standalone ZIP includes a local functional candidate, test code and QA screenshots; repository files may differ in nonsemantic formatting. Keep draft status and explicit review gates.

**Next real implementation:** conservative horizon-aware candidate selection, bounded quadtree/texture loading and an actual globe flight camera under native renderer profiling; route discovery and save migrations must be separately reviewed. Nothing in this prototype changes First Wake, installed game, release package, lore/canon or saves.
