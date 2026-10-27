# Chapter I magic VFX + camera integration study v0.5

**Authority:** IMPLEMENTED REVERSIBLE REVIEW CANDIDATE; source-tested in native Godot **4.7.2** at `a42fa46c57613191ce200a1f1d0e1993109575ad`. **NOT** playable spell execution, gameplay canon, approved character art, chapter-story change, or release authorization.

## What this experiment actually integrates

The isolated scene `res://scenes/magic_vfx_chapter1_camera_review.tscn` creates the **existing native Chapter I** scene (`first_wake_chapter1_player_preview.tscn`) and uses its exact authored dock background, foreground, Y-sorted actor group and Ender directional review sprites. A `Camera2D` starts at the native 960×640 framing with zoom 1.00; a deterministic close-up is available for A/B testing.

A `magic_vfx.gd` effect is scaled, anchored by Ender's actual world coordinates and inserted in the *existing actor group's* composition. VFX test z-indices -1/1 place geometry behind/in front of Ender's field sprite; the original dock foreground remains a separate z=8 layer. The existing `PointLight2D` review rig colors the scene using the five registered story-affinity appearances.

The wrapper turns off Chapter I's unhandled gameplay input, Ender's player-control flag and actor physics updates for **review only**. The original Chapter I scene/script, combat authorization, dialogue, initial stage, save encoding and release config are unmodified. It keeps Ionia's Chapter I reveal gate closed at Signal; all five profiles are previewable near Ender's sprite strictly as graphics, not as character party members or spellcasters.

## Interactions (standalone review, not runtime action controls)

1–5 select affinity; LEFT/RIGHT step cinematic phase; O toggles behind/front VFX order; L toggles native lighting; C toggles fixed-camera closeup; M toggles reduced motion; V hides/shows VFX and light; ESC quits. Reduced motion is **ON by default**, no autoplay or exposure/camera shake is introduced.

## Evidence receipts at source `a42fa46c57613191ce200a1f1d0e1993109575ad`

- [Godot headless import, native Chapter I and isolated integration assertions](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40597102715): **PASS**. Explicit `STARRY_SKY_CHAPTER1_MAGIC_COMPOSITE_PASS`; scene resource reuse, unchanged `chapter.snapshot()`, unchanged `export_save_snapshot()`, no actor movement, Ionia hidden as required, and reversible camera/light/front-layer checks.
- [Godot GL Compatibility renderer-based A/B](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40597102717): **PASS**. Explicit `STARRY_SKY_CHAPTER1_MAGIC_NATIVE_CAPTURE_PASS`; ten actual native **960×640** PNGs with SHA-256 recorded in the job logs.
- Native frames: original/no-VFX dock, five identity VFX profiles on the same dock, Ender foreground/behind composite, light-off composite and deterministic Camera2D closeup. Foreground/behind changed pixels inside Ender's sprite region; the light toggle changed real dock pixels; the camera actually changed the rendered framing.
- Original approved *Ender likeness* and current directional *candidate* are separate art authority levels. Here the native scene displays its existing directional field candidate only; this does not promote that candidate to an approved game atlas.
- Native captures are runner-local under existing artifact quota/custody. Logged hashes do **not** mean the full-resolution PNGs were externally reviewed.

## Known exclusions and next gate

This is **native 2D/2.5D layered-sprite composition**, *not* physical 3D occlusion, material-normal lighting, GPU volumetrics, actual terrain collider reactions, global navigation, battle activation, or a completed playable vertical slice. Further require real-scene captures for all phases, time-of-day contrast, camera-safe sprite legibility, at least one representative Windows GPU frame-time test, independent screenshot-based visual QA, and creator sign-off.

Windows exact-platform release/Defender security gate remains independent. A CI pass on native Linux does not release or merge the game.

## v0.5 environmental contrast and accessibility review candidate

The standalone Chapter I VFX wrapper now exposes three **cosmetic lighting QA presets** (`daylight`, `dusk`, `night`) through a Godot `CanvasModulate`, plus deterministic `clear`, `mist`, and `rain` overlays. They are **not** game weather or story canon. `T` cycles lighting contrast; `W` cycles overlay; `M` keeps reduced motion. Default is daylight/clear, with motion reduction ON. Mist/rain remain still strokes without strobing or sound. The original Chapter I scripts are not edited.

Capture test extends the real 960×640 dock evidence with daylight, dusk, night, night-mist, and night-rain images, proving distinct renderer pixels in a fixed region while the scene's actual actor position, chapter snapshot and exported save stay unchanged. It does **not** certify WCAG contrast, visual approval, day/night progression, or FPS. Every new capture remains under the same private runner evidence limit.

## v0.5 exact-source verification receipts (2026-10-27)

- **Verified executable source:** `aff5713096b542b2dd3e495ef61bef554a1e740b`, stacked on draft PR #411. No Chapter I gameplay script edits or granted spells.
- [Native Godot 4.7.2 scene/regression workflow](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40599651428): **PASS**. The five affinity overlays, noncanonical light/weather presets and unchanged Chapter I save/progression gates passed.
- [Native GL Compatibility framebuffer capture](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40599651312): **PASS**. 15 genuine 960×640 PNGs total (prior ten dock VFX frames plus five new lighting/weather frames). SHA-256 receipts in CI logs; full PNGs remain runner-local under existing artifact-custody limitations.
- Fixed native dock witness sample mean luminance: daylight **0.46007941663265**, dusk **0.34463138133287**, night **0.24313823878765**. The native regression demands strict downward ordering with a 0.015 minimum gap each. The samples are uncalibrated framebuffer brightness, not display luminance, WCAG text contrast or a claim that the art is professionally graded.
- Mist and rain both differ visibly from clear night, and from one another, in controlled native image regions. All overlays remain static deterministic review strokes. Weather/time changes are **proposals for visual stress testing**, not approved world/simulation mechanics.
- Separate Windows exact QA security status and any Defender preflight hold are not certified by these Linux visual results. No merging, release, or approved spell mechanic.

**Next QA gate:** independent full-frame artistic inspection, actor readability against the actual Chapter I dialogue/UI surfaces, representative Windows GPU timings and environmental-material integration without bypassing battle/story authorization.
