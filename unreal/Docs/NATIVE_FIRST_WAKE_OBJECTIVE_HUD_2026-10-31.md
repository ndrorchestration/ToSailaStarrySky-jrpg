# Native First Wake HUD slice — 2026-10-31

## Implementation
The Unreal 5.8 C++ `ATSTSSFirstWakeHUD` renders the existing `UTSTSSFirstWakeState::GetCurrentObjective()` on the in-game Canvas using a dark contrast panel and tunable text scale. `ATSTSSGameMode` selects this HUD and preserves `ATSTSSExplorerCharacter` as the pawn. The HUD only reads state; no second narrative authority, save schema, or new Blueprint art dependencies.

The overlay is a temporary native gameplay-proving display, **not** an artistically approved cinematic JRPG UI. It deliberately avoids a bespoke quest framework while still giving early users clear First Wake objectives.

## Acceptance gates
- C++ `TSTSS.FirstWake.DefaultHUDWiring` checks default GameMode HUD/pawn selection and readable initial HUD settings.
- Native UE 5.8 **not executed here**. Compile the exact draft stack, run all `TSTSS.*` automation tests and retain individual result IDs and logs.
- In a real UE First Wake map, confirm spawned Explorer/GameMode, viewport text after flyer/hire/boarding/each inspection, after sea contact and flotation, on save/load, and after HUD reset.
- Evaluate 720p, 1080p, 1440p and 4K for long localized objectives, text clipping, high DPI/safe area, UI scaling, controller accessibility and legibility.
- Replace the Canvas overlay with a source-bound UMG/Slate design only after the underlying state and true scene are proven. Evaluate visual identity against the approved cast/ship, and include narration/subtitles/accessibility.
- Render a genuine native screenshot/video, measure frame times, and test packaged Windows build before any visual-quality or playable claim.

**Known UX limitations:** Current Canvas drawing does not wrap long strings, lacks platform safe-area handling and localized line layout, and reads the objective during HUD drawing. These are quality gates, not accepted final behaviors. Never call this final cinematic UI.

No canon, Five Lights, first-party character art, Godot playable files, merges, or releases were changed.
