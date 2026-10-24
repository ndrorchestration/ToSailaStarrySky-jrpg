# Planetary globe visual study (noncanonical)

A standalone, browser-viewable rendering experiment: `experiments/planetary-globe-preview.html`.

## What this proves and does not prove

- Demonstrates orthographic globe projection with drag rotation and camera zoom; day/night shading; deterministic land/ocean/biome color distributions; polar ice; layered atmosphere; adjustable cloud cover; and auroral ribbons confined to upper altitudes.
- Uses a deliberately procedural, **unapproved** landmass seed. No generated location is canonical. No story secrets, routes, moon-alignment puzzle, quests, unlock conditions, or economic effects are represented.
- This is **not** the production Godot globe, a usable progression map, or proof of player or visual acceptance. No Godot/runtime engine migration is implied.

## Visual acceptance criteria for the next pass

1. A small player-centric curved horizon at surface altitude, with planet-scale continuity when flying; do not replace gameplay with a miniature global overview.
2. Ocean/land area ratios, plausible continental shelves and coastlines, authored or curated silhouette hierarchy; remove procedural noise artifacts before admission.
3. Distinct continental biomes, elevation/snow lines, islands, polar regions and weather systems with consistent lighting, cloud shadow and atmospheric scattering.
4. Legible Dragonfly altitude and scale, docking approaches, distance cues and terrain silhouettes at 960×640 logical resolution.
5. Physically coherent globe coordinates: longitude wraps, latitude clamps at poles, no discontinuity at the antimeridian, and routes traverse great circles where appropriate.
6. Story stages, crew requirements, geographic discoveries and plot locks attach to a **separate** canonical data registry, never to generated color noise.
7. Surface/cruise/high/auroral traversal conveys speed, wind/weather effects and route discovery. Secret pathways must remain hidden without explicit reveal conditions.
8. Capture matched screenshots at equator/poles/coasts/day/night and all altitude tiers; inspect on actual target hardware and at the game's logical pixel scale.
9. Validate accessible controls, reduced-motion alternatives, keyboard/gamepad traversal, no navigation-induced nausea and frame-time budgets.

## Recommended engineering boundary

Keep the existing `modules/world.js` 32×32 local map and `modules/air-navigation.js` 48×32 flight-state contract intact for Chapter 1. Introduce a separate canonical planetary coordinate model, regional streaming/LOD, and an engine-independent navigation API before connecting any renderer. Godot 3D globe rendering is a candidate for production; an HTML canvas is only an easily reviewed comparison study.

## Inspection / controls

Open the HTML file locally; drag to rotate, wheel to zoom, use sliders for altitude/cloud cover/sun direction. Capture images for human visual critique before integration. The study has no external dependencies, telemetry or network calls.

**Status:** exploratory study; technical runtime verification and creator visual acceptance pending.
