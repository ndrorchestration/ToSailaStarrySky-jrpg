# First Wake objective text — Unreal UX integration (October 31, 2026)

## Implementation
`UTSTSSFirstWakeState::GetCurrentObjective()` is a read-only BlueprintPure, localized `FText` projection of the *existing* First Wake story progress. It provides unstarted flyer guidance, Ionia hiring, boarding, stepwise lift/pressure/reserve inspections, launch, physics-derived sea settling, depleted reserve inspection and berth return. A fresh save, mid-progress restore and reset use the same authority; calling the method never advances story or inspections.

This removes the need for per-scene duplicated objective rules when a HUD, journal, controller, or accessibility layer is connected. The objective strings are provisional UX copy and **do not replace the creator-approved dialogue/script**.

## Quality boundaries
- **Implemented:** C++ objective projection and `TSTSS.FirstWake.ObjectivesTrackStoryAndInspections` automation case; source committed.
- **Not yet implemented:** production HUD widget, journal, objective markers, narration, screen-reader affordances or in-game font layout.
- **Not verified:** native UE 5.8 compiler, automation run, Blueprint UI binding, localization capture, player usability or packaged Windows build.
- The test checks state/inspection changes and reset without locking assertions to exact English display words, preserving localization options.

## Integration checklist
1. Native-build UE 5.8 and execute all `TSTSS.*` automation at the exact commit SHA.
2. Bind a single HUD TextBlock to `GetCurrentObjective` from the explorer's owned First Wake state; update on meaningful state/inspection changes rather than expensive per-frame polling.
3. Keep objective guidance readable with scaling, contrast, subtitle/accessibility options and reduced-motion menus; test keyboard/controller navigation.
4. Compare in-game objective wording against the Ionia-first story script and creator-approved final dialogue.
5. Verify save/reload, chapter progression and genuine water/ship physics events before calling First Wake playable.

Preserve main, native Godot playable reference and approved Five Lights/cast art. This is a draft UX code improvement, not final presentation.
