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
