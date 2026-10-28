# First Wake — physically occlusion-aware zone camera and readable crew proxy

**2026-10-28 | Native Godot 4.7.2 | G3 opt-in walkthrough visual QA | Draft / unmerged**

This reversible follow-up is built directly on [draft PR #558](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/558), the first verified real 2D→3D→2D Godot scene. It improves only the **optional shipboard review**, not the native project's actual main Chapter I scene, save keys, crew canon or hidden vessel capabilities.

## Issue being addressed

Actual PR #558 native screenshots show the original lens positioned outside/behind the geodesic helm and at deck angles that overemphasize a giant dark sky or hull/rails in front of the character. The walking actor is an unrigged cream capsule that cannot convey movement or scale as a character.

## Implementation

`godot/scripts/first_wake_3d_zone_camera_review.gd` is a **separate 3D camera used exclusively by the opt-in wrapper**, with cabin/helm/deck-specific behind-character camera-arm positions, downward actor/foreground framing, a shoulder-level target, optional C-triggered elevated vantage, smooth follow and actual physics-ray arm shortening at opaque ship obstacles. The original `crew_camera` is explicitly inactive in this route, leaving earlier isolated 3D physics/camera tests unchanged.

`godot/scripts/first_wake_3d_crew_motion_proxy.gd` creates a simple *original and explicitly anonymous* clothed mannequin: separate tunic torso, neutral head, two arms and two legs with walking-speed-triggered mirrored limb swing and subtle bob. It is a **visual prototype only**, not Ender's official face, sprite style, skeletal animation asset, or endorsed character model. The old `CharacterBody3D` capsule collision remains fully active, while the prior full-height cream capsule mesh is hidden in the mixed-scene prototype.

The review-only `C` camera switch can be activated **only** once Ionia has been hired and the character is within the authorized opt-in ship scene. Pressing B restores the exact 2D engineering scene. WASD/E/F/G controls and the review-only observational helm remain unchanged. No new chapter checkpoint fields or party/Resonance privileges.

## Native QA contract

`godot/tests/first_wake_3d_zone_camera_crew_test.gd`: actual Godot physics walking cabin→helm→foredeck; checks switching between three real camera zones, two viewpoint presets, physically shortened camera arm when deliberately occluded by `StaticBody3D`, real motion tick animation and body-part scene nodes, old 3D camera exclusivity, disabled review outside Ionia-first eligible scene, and original unchanged validated v2 chapter checkpoint after exit.

`godot/tests/capture_first_wake_3d_zone_camera.gd`: four genuine 960×640 native Godot Compatibility GL frames of close cabin, helm, open deck follow and optional elevated deck. A/B camera shift must produce actual different pixels. Existing [PR #558](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/558) native 2D↔3D↔2D test is updated to assert the new camera and C behavior and must remain green. Separate [scoped workflow](../.github/workflows/godot-first-wake-zone-camera.yml) runs hash-pinned official Godot 4.7.2 import/physics/GL with actual SHA screenshot evidence.

## Production boundaries

- Actor is **not canon art, fully skeletal 3D or polished animation**. Do not credit this as a final protagonist implementation.
- The new camera does not establish cinematic camera directing, accessibility, performance on installed Windows, weather/water vessel simulation or full character cast frame coverage.
- All ship dimensions remain provisional. Existing physics gates prove isolated 3D game collision only, **not maritime child-safe construction or a sealed pressure hull**.
- The opt-in scene is **not the project's default `run/main_scene`**. This is not an installer, finished game, actual public release or production G3 admission.
- Preserve restricted moon/exosphere and alternate ship configurations off public source/Notion until creator approves disclosure.
- Record precise exact-head native run results before calling the new camera/actor verified; no automatic merge/release or mainline changes.

**Recommended next slice after review:** replace the placeholder with validated Ender look/animations, rebuild actual room geometry and improve high-quality lighting while preserving genuine camera clearance and story state.
