# First Wake: actual open-water horizon from the inhabited foredeck — 2026-10-28

**Draft-only G3 cinematic environment feasibility, not released or canonical production art.** Stacks on the [PR #570](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/570) actual procedural sky/ocean implementation and unchanged fully physical 2D→3D→2D First Wake scene. The original PR #570 screenshot proved an ocean shader existed but its camera stared down at the deck and did not show a convincing waterline.

## Implementation

In this narrowly scoped opt-in review only, the **default foredeck Camera3D** now aims toward the ordinary open water beyond the bow, while C still selects the independently tested elevated view for inspection of deck guards. The scene now has draw distance through the modeled ocean instead of truncating at 70m; neither collision ray masking nor actor/helm/hatch processing is changed. At the visual-only sea plane, low-frequency wave geometry uses 112×112 subdivisions of a 480m × 480m PlaneMesh, while higher-frequency waves are represented by procedural world-position-driven normals, crossing ripples, crests, distant color haze and specular light. This is an artistic impression, **not** physically accurate fluid dynamics.

The procedural sky palette is blended to give a distinct water/sky boundary. A camera ray through the screen center must intersect the actual water geometry inside the far clipping plane while a ray through its upper quadrant sees sky; this is verified as real 3D geometry and view optics, not fabricated horizon pixels.

## Evidence requirements

- `godot/tests/first_wake_visible_ocean_horizon_test.gd`: actual Ionia-first reviewed save eligibility; authentic `CharacterBody3D` walk onto open deck, actual `Camera3D` forward vs sky rays and bounded sea intersection, water mesh subdivisions, real shader, preserved hatch & rail collision, return to identical strict v2 checkpoint and still-locked Resonance.
- `godot/tests/capture_first_wake_visible_ocean_horizon.gd`: **five real 960×640 native Godot frames**: cabin, geodesic helm with read-only F inspection, forward foredeck **water visible**, exact same camera **water temporarily hidden** (controlled A/B) and elevated deck. The controlled A/B must show a quantitatively significant **water-only rendering difference** in the image, including behind the bow, not simply accept a shader asset existing. This is a review-only script toggle, not an in-game ocean-disappearing power.
- Dedicated hash-pinned official Godot 4.7.2 CI gate; inherited camera, character walking, 2D↔3D↔2D, Ionia/First Wake native and smoke must remain green at exact commit. Native screenshots must be visually inspected after green test; no automatic artistic approval.

## Explicit blockers

The sea-plane is neither a planetary ocean globe nor oceanic-depth hull design; no physical buoyancy, ocean wave forces, real water contact or ship flight. Climate is not canon, wave speed is visual-only. Actor is an anonymous stand-in, not the approved Ender look or final skeletal motion. Environmental animation and color need art-direction, eye-level player navigation, accessibility and platform FPS/VRAM review. **No production admission, no default Godot launch replacement, no Windows installer, no canon/secret vessel disclosure, no merge or release.**
