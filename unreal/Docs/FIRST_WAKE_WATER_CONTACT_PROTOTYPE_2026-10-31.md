# Unreal First Wake: physics-backed sea-contact observer (prototype, October 31, 2026)

**Code status:** source authored on draft branch, **Unreal 5.8 native compile/automation/map integration not verified**. Do not promote to playable Chapter I, cinematic approval, or final buoyancy. Based on PR #615's manual interaction guard and the existing First Wake state/save contracts in PR #608.

## Reused contracts
- Godot #547: actual sea contact before flotation, no arbitrary narrative shortcut.
- Godot #562: sustained physics overlap/settling is useful evidence for later berth choreography, not direct proof for the ocean.
- Unreal #608: `UTSTSSFirstWakeState` holds the existing ordered `Launched -> SeaContact -> FlotationConfirmed` beats, and `ATSTSSExplorerCharacter` owns state.
- Unreal #615: generic player E interaction cannot grant physical sea events. No extra story engine or new save schema introduced.

## Prototype implementation
`ATSTSSWaterContactObserver` is a world-placed actor with a query-only `UBoxComponent` volume, an explicitly assigned `UPrimitiveComponent` vessel body and an assigned explorer. Contact only advances when a *real overlapping simulating physics primitive* is observed after `Launched`. It accumulates continuous dwell while vertical rigid-body speed stays within a configurable limit; exiting the volume or exceeding the limit resets dwell. After sufficient stable dwell it may advance `FlotationConfirmed`. Default values **1.5 seconds and 35 cm/s are provisional** and do not constitute balanced physics.

## Minimal native-editor setup (not yet executed)
1. Compile pinned UE 5.8 `unreal/ToSailTheStarrySky.uproject` and run `TSTSS.FirstWake.WaterEvidencePolicy` and `TSTSS.FirstWake.WaterBeatSequence`.
2. Create a test map with a *separate real simulating rigid-body ship collision primitive*, a water collision/overlap box (not merely a material), and a spawned `ATSTSSExplorerCharacter`.
3. Place `ATSTSSWaterContactObserver`, assign **VesselBody**, **Explorer**, and configure actual water volume bounds. Ensure overlap events and compatible collision responses are enabled on both components.
4. Perform the source-authentic Ionia-first preflight path before launch. The gameplay collision—not a manually activated milestone actor—must initiate water-contact.
5. Record exact-head Windows build logs, automation results, Unreal Insights/stats, and genuine full-route captures. Test airborne above volume, outside volume, unassigned body, non-simulating decorative body, high-velocity impact, interrupted dwell, slow overlap, reload, and the unrelated land/berth scene.

## Known weaknesses / next implementation gates
- This is an **overlap + velocity proxy**, not a buoyancy solver. It does not establish displaced volume, righting torque, water surface normals, afloat depth, lateral motion limits, or genuinely sea-worthy hull balance. A heavily sinking body with a momentarily small vertical speed might satisfy the proxy.
- State's `AdvanceTo` remains callable from other gameplay code and can be misused; enforce trusted event provenance at the state-machine boundary before release.
- No real ship body/collision volume or UE map has been imported/verified. The preview ship in #610 is intentionally noncanonical placeholder geometry.
- No gameplay dialogue, HUD feedback, splash VFX, camera, animation, save integration or character art acceptance comes from these files.
- Continuous stable dwell is frame-duration based; require native physics stepping, pause behavior and variable-frame-rate tests before accepting thresholds.
- Current tests evaluate decision policy and beat ordering but not actual Unreal overlap events, physics or tick-driven dwell. Only a native integration test can close this gap.

**No merge or release authorized.** Art and narrative remain governed by creator-approved cast/ship/Five Lights. Original playable Godot reference remains intact.
