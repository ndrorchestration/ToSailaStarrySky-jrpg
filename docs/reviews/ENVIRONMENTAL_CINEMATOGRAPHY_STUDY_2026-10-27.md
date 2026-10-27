# Environmental atmosphere & cinematography — visual review candidate

**2026-10-27 | IMPLEMENTED CANDIDATE / NON-CANON / ART NOT APPROVED**

## Scope and authority
Source branch `study/environment-weather-magic-light-20261027` stacks on #407
(`a632b466517cd4c754a0302b81bfc3a2e67b6e5c`), which itself stacks on
#404/#403/#402. This adds **presentation-only** elements to the isolated
Godot 4.7.2 Compatibility `godot/flight_slice` coastal flight art study.
It does **not** merge competing biome PRs (#405/#406), ship silhouette work
(#408), or Chapter I magic assets (#411), and it does **not** touch the JS legacy
runtime or the creator's private full-world build.

## Look-development implementation
- **B — time-of-day lighting grade:** golden hour (original default),
  cool clear midday, blue hour, and dim moonlit-style night. The scene retains
  the original fixed sun vector: these are ***art-directed color/light grades***,
  not timekeeping, rotating suns, physically accurate astronomy or a moon-phase
  system. The night look suppresses the drawn solar disk; no celestial plot
  clues are introduced. The ocean shader also attenuates the golden solar
  reflection at night, using the same explicit sun visibility parameter.
- **N — weather study:** clear (original default), mist, rain and storm fronts.
  The shared sky shader deepens cloud cover, desaturates storm light, and
  uses bounded, distinct fog densities. Rain and storm optionally add 112
  local, phase-staggered, translucent rain quads as **one** MultiMesh draw
  group following the existing camera. It is a visual impostor, not
  precipitation physics, wetness, wind forces or navigation modifiers.
- **G — magical atmosphere:** optional low-luminance teal/lilac ribbons high
  in the dome, moving slowly with the established scene clock. This is
  decorative ambience, **not a navigable auroral pathway, spell effect,
  resonance event, Moon Bridge clue or plot reveal**. The Five Lights'
  fundamental character energies remain authoritative and unaffected.
- **C — cinematography:** the previously reviewed 37 s coast–forest–highland
  shot rig remains unchanged. All environment looks use that same camera
  and ship choreography. No screen shake, forced zooms, flashing lights or
  new gameplay cameras have been introduced.
- **M — reduced motion:** suppresses local rain completely, freezes the
  sky/foliage procedural clock, and preserves the established static camera
  staging behavior; atmospheric color/fog still communicates the look.
- **V — low detail:** omits local rain and the expensive decorative sky
  ribbon branch, preserving existing lower-cost sky and foliage paths.
  Both switches can be reversed. **P** continues to freeze the scene clock.

## Implementation and review acceptance
No new terrain sampler, shadow-casting weather geometry, physics bodies,
colliders, routes, saved data, abilities or canon. The default golden/clear/
magic-off material values and established cloud depth/camera/terrain behaviors
are preserved.

The new `environment_mood.gd` is a pure four-by-four preset sampler;
`weather_streaks.gd` is a bounded local decoration; `rain.gdshader`
implements smooth phase-staggered falling streaks without unbounded
particle spawning; `visuals.gd` alone binds the palette to shared
light/fog/sky materials. The sky retains the existing shared solar direction.

### Native verification gates
1. Godot 4.7.2 editor import and full headless smoke; no shader/script errors.
2. `test_environment_mood.gd`: 16 deterministic variants, bounded fog and
   weather geometry, no gameplay/time mutation, toggles, reduced-motion and
   low-detail assertions, and restoration of default values.
3. Existing native terrain, landing physics, camera, atmospheric and performance
   smoke checks must remain green at this exact commit.
4. `capture_environment_mood.gd` uses software GL to capture five *matched*
   HUD-free 960×640 frames at the **same** timestamp and camera pose:
   `golden-clear`, `midday-mist`, `blue-hour-rain`, `storm-night`,
   and `storm-night-magic`. A separate night magic-on/off pixel comparison
   verifies the decorative effect is genuinely visible in native rendering.
   A coarse pixel delta only establishes rendered differences, **not**
   improved visual quality. Native captures require CI verification.

### Human art and accessibility gate
Inspect readable ship/terrain silhouettes against cloud and storm darkness,
avoid clipping at the horizon and dense forest, ensure magical sky ribbons
are not mistaken for an auroral travel route, and compare M/V variants.
Rain quads should not create distracting screen-space noise or appear to
float during camera sweeps. Verify color distinction without relying only
on hue. Profile target GPUs and inspect frame-to-frame stability in motion
before accepting any of these looks for the game.

**Unverified until separate evidence:** graphical correctness, artistic
quality, target-hardware FPS, frame-time variance, temporal continuity, and
suitability for seamless world transitions. This is no claim of final
production weather, planetary atmospheric scattering or a Chapter I release.

**Provenance:** all shaders, palettes and rain geometry in this change are
original in-repository procedural study code; no external asset or music
licenses are introduced.
