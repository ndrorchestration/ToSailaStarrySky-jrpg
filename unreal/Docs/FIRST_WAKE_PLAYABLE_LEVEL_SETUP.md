# First Wake native level assembly — not yet tested in editor

The C++ project now provides an explorer pawn with spring-arm follow camera, keyboard movement and camera mouse axes. Press E to line-trace from the camera to a milestone actor within 300 Unreal units. An interaction advances only its exact next ordered beat.

1. Compile Unreal 5.8 editor target and run the automation suite, recording the exact branch SHA.
2. Create a persistent coastal level in Unreal Editor, configure a PlayerStart on traversable collision, and verify the project's default TSTSSGameMode spawns TSTSSExplorerCharacter.
3. Place TSTSSMilestoneActor instances and give each a collidable StaticMesh. Assign the milestones in narrative order: flyer, hire Ionia, board, engineering, launch, sea contact, flotation, reserve inspection, berth return.
4. Early proof uses distinctly positioned objects; *do not call these objects the final characters, ship, or cinematic art*. Actual Ionia conversation, physically verified sea contact and launch animation require authored levels and new logic; the milestone actor is just a progression gate.
5. Validate camera tracing, blocked obstacles, ordered advancement, reset behavior, save/load state, and Windows input before claiming playable First Wake.
6. Replace proxy milestone triggers with game actions and real collision/physics/interaction evidence. Do not auto-award sea contact or flotation through a camera cut.
7. Import artistically approved character assets separately; verify hair silhouette, facial design, costume and materials via native renderer captures against approved references.

No maps, characters, meshes or binaries have been committed by this text-only milestone. Native compile and gameplay verification are outstanding.
