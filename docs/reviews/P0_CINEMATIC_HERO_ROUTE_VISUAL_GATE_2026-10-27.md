# P0 cinematic visual benchmark — coast to highland

**Scope:** Noncanon native Godot 4.7.2/GDScript art study, derived from the physically verified test-field flight branch (#382). Work-in-progress concept art does not prove Chapter I, full globe traversal or approved Aureate Wake art. See P0 issue #387.

## Current bounded art pass

- Atmospheric dome: calibrated dark upper blue, layered aerial haze near the horizon, warmer scattered light toward the existing sun direction, refined cloud lighting and delicate optional high wisps.
- Water: stronger oblique-angle sky reflection, synchronized directional sun glint, distinct foam roughness, ocean deep/shallow colors still governed by the **existing terrain height texture** and tile coverage.
- Sun alignment: the same `SUN_DIRECTION` parameter controls sky and water. No new independent time-of-day clock, physics, planet radius or landing rule.
- Motion and performance: shader clock continues to respect pause/reduced-motion; optional wisps and fine glitter omitted in low-quality mode. Existing 64 terrain tiles, native collider, tests and baseline remain unchanged.

**Visual acceptance is not implied.** Changes must be observed in actual GL-rendered frames at native size, not asserted from shader source.

## Shot list / acceptance

| Shot | Visual target | Reject if |
|---|---|---|
| Departure / sea horizon | Vessel silhouette readable against luminous atmospheric depth | Horizon is flat wash, ship lacks scale or placeholder reads as final art |
| Open ocean | Deep-water richness, restrained solar reflection | Plastic mirror, clipped glare, repetitious screen-wide foam |
| Coastal approach | Clear shallow-to-deep transition from actual terrain, no duplicated coast | Surf detached from shore, water/land intersections visibly broken |
| Forest traverse | Three readable depth planes, canopy variation, atmospheric separation | Repeated cones, fog destroys tree silhouettes |
| Highland vista | Strong terrain silhouettes with subtle far-distance haze | Mountains flatten into uniform color, popping tiles |
| Polar/auroral ascent | Distinct layered auroral height and navigation clarity | Unimplemented routes misrepresented as available |
| Lunar horizon | Beautiful but spoiler-safe moon composition | Canon lunar mechanics or Moon Bridge activation disclosed |
| Ship hero shot | **Aureate Wake** reads dragonfly-inspired and lived-in | Prototype 'Dragonfly' name reused as proof of identity; unapproved design presented as canon |

The last three shots are **future integration gates**, not deliverables of this shader PR. The current geometry/ship are procedural diagnostic assets.

## Native visual evidence procedure

1. Run existing Godot 4.7.2 native smoke tests, especially `tests/test_visuals.gd`, `tests/test_touchdown.gd` and `tests/test_contact_lifecycle.gd`.
2. Capture six established GL frames with `tests/capture_study.gd`; retain its existing test result markers.
3. Under software-OpenGL/Xvfb or supported graphics hardware, run `tests/capture_cinematic_review.gd` for **three HUD-free** review frames:
   ```bash
   godot --path godot/flight_slice --rendering-driver opengl3 --audio-driver Dummy --script res://tests/capture_cinematic_review.gd
   ```
4. Keep **before/after frames at identical poses and time**, side by side; inspect blown highlights, cloud repetition, wave artifacts, visible terrain/sea seams, and low-quality fallback.
5. Record renderer, platform, measured frame timings, exact commit and screenshot path; do not invent FPS/VRAM figures. Obtain creator art approval separately.
6. Do not promote this scene as authentic planetary curvature, Aureate Wake final artwork, gameplay completion or a public release.

## Next art integration

Once cinematic sky and ocean are stable, refine authored terrain composition, biome materials, distant fog, shoreline breakup, cloud strata and correct Aureate Wake art on a standalone, playable coast-to-highland hero route. Keep Frigate-class **Dragonfly** a separate entity with no assumed geometry or crew.
