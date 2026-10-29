# Native 3D Battle Stage — isolated visual review (2026-10-29)

This branch builds on the isolated encounter-permit PR #604 and combat foundation PR #601. It introduces a genuine Godot Node3D stage and camera with warm/cool environmental lighting, a temporary floor and capsule stand-ins. **These are deliberately temporary review markers, not the approved character art, and are not presented as cinematic-quality final visuals.**

The `present_snapshot` method reads a turn-state dictionary, copies no authority back into gameplay, validates up to three crew with at least one opponent, and places actor markers in stable lanes. `present_event` validates a completed combat event and retains a read-only presentation copy. The scene has no input controller, combat resolver, auto encounter launch, save writes, story transitions, or character recruitment.

Run on Godot 4.7.2:

```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/native_battle_cinematic_stage_test.gd
```

The test asserts valid actor projection, a valid event, rejection of unknown actors and invalid factions, plus source immutability. **Not executed in this environment.** Separate native screenshots, lighting review, actual approved character mesh imports, performance, accessibility, encounter authorization, and source-of-truth integration remain required. Do not merge or treat this as a playable production battle system.
