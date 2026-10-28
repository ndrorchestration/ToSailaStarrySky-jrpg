# Character Visual P-01B — Native Chapter I entry-point, save-safe pilot

**Status:** engineering review-only, NOT creator-approved art, recruitment, sprite pack, merge or release.

## Exact integration target

This experiment is built from **`feat/godot-first-wake-revised-checkpoint-v2-20261027` at `46e15dbd94cedf964fdc008dad8528d8140dcbb6`**. It changes `godot/scripts/first_wake_chapter1_review.gd`, used by the project's actual configured `res://scenes/first_wake_chapter1_player_preview.tscn`. The original dock-only [#515](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/515) was already verified; this **P-01B** tests the newer scene with actual versioned Chapter I save and party state. The separate opt-in **v2 revised playable Ionia-first opening**, any physics-flight/splashdown handoff, and full gameplay production are still distinct branches and untested here.

## Exact source custody

Four independent Lyra six-frame, four-direction original SVG candidate files and the two minimal native movement/alpha probe dependencies were copied **byte-for-byte** from [#487](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/487) into this branch only; no existing sprite was replaced. Lyra's long red hair and current visual costume are *unapproved source studies*. The copied `CharacterBody2D` lab is used solely for walking/visual source proof, not the playable Chapter I actor controller.

`first_wake_chapter1_visual_p01b.gd`: F6 installs a read-only visual-only character in the existing `ChapterOneMigrationActors` y-sort parent at (728,410), with a 400px four-direction path within `SaveCodec.PLAYER_POSITION_BOUNDS`. F6 OFF removes the visual actor fully. **Default OFF**; no loading, joining, class, unlock, equipment, resonance or story callback. The character's appearance must not influence `ChapterState`, `PartyCombatAuthority`, inventory or SaveCodec.

## Native acceptance and safety tests

- `tests/first_wake_chapter1_visual_p01b_test.gd`: actually loads the configured main preview, checks F6 event path, original 4 × 6 imported source art, bounded physical movement, untouched Ender actor/world coordinates and unchanged `ChapterState.desired_active_party_ids()`. Verifies `export_save_snapshot()` exact JSON equivalence throughout active use, **real `save_progress_to_disk` and `load_progress_from_disk`** on a uniquely scoped user:// QA slot while the review actor exists, and no Lyra/fixture bytes in the save. All files are deleted using the existing `SaveStore.delete_slot` contract after success.
- `tests/capture_first_wake_chapter1_visual_p01b.gd`: real 960×640 Godot OpenGL framebuffer in default OFF, moving south, moving west, restored OFF. Native PNG SHA-256 receipts and bounded local JPEG crops in CI logs. **OFF and RESTORED native frames must match exactly**; on frames must differ and original chapter save snapshot must not change.
- Existing native tests on this branch cover revised checkpoint v2, Chapter I save/state/party, resonance preflight and battle inventory separately. Re-run all on the precise P-01B branch head; earlier successful runs cannot be inherited.

## Unmet gates / no implied approvals

This configured main preview remains an **earlier Chapter I migration presentation**, distinct from the separately authored Ionia-first v2 revised story checkpoint. Its flat dock art remains drawn imagery without a proven permanent physical dock collider. P-01B does not demonstrate 2.5D ship deck or planet terrain collision, slope/occlusion, equipment field-to-battle bindings, 1440×960 source-fidelity, Windows installed GPU performance, accessibility motion, facial expressions, or artist-approved foot plants. The known Lyra original south-source 24.33/24.74px candidate stance drift is unresolved; it is not improved by integrating the source. No player story, magic, skills, save schema or recruitable party member changes.

The broader [P0–P6 character-production admission draft](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/502) continues to require an opt-in fixture on the **exact current revised gameplay branch** with real authored deck/terrain physics and explicit creator approval. No merge/release authorization.
