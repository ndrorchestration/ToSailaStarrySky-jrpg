# First Wake revised-opening v2 checkpoint — opt-in gameplay review

**Status:** native Godot 4.7.2 implementation candidate, draft-only, **NOT** legacy-save migration, full playable Chapter I or production entitlement.

## Reason for separate version and slot

The current `first_wake_chapter1_state.gd` + `first_wake_chapter1_save_codec.gd` implement the historical Lyra-first Crossing and late Ionia entrance, and their v1 save identifies stages `signal/crossing/contact/choice/wake/done`. The creator's revised Chapter I story explicitly requires **Ender alone → Ionia first for paid engineering work → safe flight and ocean splashdown → Lyra after safe reunion**. It is unsafe to reinterpret an existing `aetherwake.first-wake.chapter1.v1` snapshot into that new sequence without a mapping approved for scene/story locations and player saves. **No automatic migration is attempted**.

The small, reversible checkpoint in this PR supports the **already playable isolated job/flyer/Ionia hiring/engineering scene** only, because that scene stops at preflight and does not include flight, splashdown or Lyra's safe reunion yet.

## Implemented behavior

- `first_wake_revised_checkpoint_codec.gd`: explicit `tstss.first-wake.revised-opening.review.v2` schema and separate `user://first_wake_revised_opening_review_v2.json` single slot. Persists only `step`, `flyer_read`, `room`, completed engineering observation IDs and bounded on-scene player coordinates. Strictly rejects unknown/future stage, invalid room, premature engineering evidence, incomplete preflight, duplicate/unknown clues, malformed position, extra fields, saved party IDs, a magical/Resonance unlock or turn authority.
- Restore reconstructs a **new** `first_wake_revised_opening_contract.gd` model using only its established `accept_ionia_job` and `complete_engineering_checks` progression. The active roster is **derived from the story**, never copied from an untrusted save; no Lyra/Talen pre-reunion or Art entitlement can be introduced by this format.
- Existing `first_wake_chapter1_save_store.gd` now accepts an **optional external validation script** through `save_snapshot/load_snapshot/has_valid_save` and its internal read checks; default caller signatures, path and v1 validator remain unchanged. The same existing temp-file, hash and previous-valid backup protocol is reused; there is **no parallel or weakened save writer**.
- `first_wake_job_preview.gd` opt-in scene now has **K: save** and **L: load** with human-readable status feedback. Export is refused while dialogue is open. On restore the scene rebuilds the exact party/roster, dock-vs-engineering room backdrop, collision/movement bounds, player position, inspected stations, current objective and LOCKED Resonance hint; no live chapter combat resolver touched. Invalid input is checked before any scene mutation.

## Native QA

- `first_wake_revised_checkpoint_codec_test.gd`: stage-by-stage roundtrip, old-schema cross-rejection, pre-recruitment evidence rejection, impossible future stages, malformed/duplicate inspection, bogus coordinates, forged Art fields, true noncanonical character rejection.
- `first_wake_revised_checkpoint_scene_test.gd`: real 960×640 playable opening scene, flyer and employment dialogues, gangway, engineering station; new save file and multiple backup generations; corrupt primary restored from an earlier valid saved checkpoint. Confirms legacy v1 file SHA unaffected and old codec cannot reinterpret new snapshot; wrong-stage/forged-grant restores are zero-mutation refusals.
- The pinned native Godot 4.7.2 workflow runs the new two tests alongside unchanged original v1 codec/store/real-scene tests, revised-opening chronology, composite Resonance gate and graphical capture. All outcomes must be bound to the new exact source SHA.
- **Explicitly not claimed:** proper scene migration after preflight, a real fluid-surface splashdown, Lyra/Talen live gameplay reunion, save-data conversion from old Chapter I, multiplayer or sustained game-loop compatibility, final visuals/sound, Windows Defender verification, release/installer or creator-approved combo unlock.

## Next integration threshold

Finish the physical first test flight → water contact → postflight safe recovery scene while recording deterministic stage/position/station/quest evidence and testing save/load before adding those stages to the v2 schema. Preserve previous v1 saves and provide opt-in migration mapping only once old/new playable scenes have been reconciled. Future story Art unlock requires creator-approved plot timing, external live combat authority, permanent progression schema, balance and accessibility QA. No merge/release is authorized.
