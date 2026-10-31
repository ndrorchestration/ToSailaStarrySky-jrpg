# Unreal water contact adapter (prototype)

New `ATSTSSWaterContactAdapter` implements observation wiring to `UTSTSSWaterLandingGate`. This is not the final Aureate Wake model or buoyancy simulation.

Setup in the *native* level:
1. Set a properly licensed hull mesh and physics collision to `Hull`, enable Simulate Physics and Generate Overlap Events.
2. Make a water-contact volume with collidable overlap geometry, actor tag `TSTSSWaterVolume`; configure collision channels so hull overlap events are actually generated.
3. Bind an owned, living `UTSTSSFirstWakeState` to `BindStory` (e.g. from the player story controller) before flight. An unbound story cannot advance.
4. Capture actual hull/world collision-overlap and `GetPhysicsLinearVelocity().Z` at the correct physics/update cadence. Tick-based observation is a provisional adapter; adjust to fixed physics substeps if stability varies with frame rate.
5. The 2-second stable-contact threshold and 25 cm/s vertical speed threshold are uncalibrated. This adapter **does not create buoyancy forces**, so a sinking hull cannot count as correct seaworthiness merely because a scripted water plane renders.
6. Required tests: enter/exit overlaps, ignored tagged actors without real overlap, overlapping false positives (e.g. water volume above the surface), vertical velocity, substeps, collision-channel mismatch, resumed saves and high-speed impact.
7. SeaContact and FlotationConfirmed are not triggered by generic milestone actors; audit any other direct calls to `AdvanceTo` before claiming anti-bypass guarantees.

Evidence gate: exact SHA native Windows compile and a recorded physics-backed sea landing with hull waterline / contact logs and creator scene review. Do not close CH1-05 based on these source files.
