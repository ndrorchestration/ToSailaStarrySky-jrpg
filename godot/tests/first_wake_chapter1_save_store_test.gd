extends SceneTree
## Filesystem contract for the native Chapter I single-slot store.

const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const SaveStore = preload("res://scripts/first_wake_chapter1_save_store.gd")

const TEST_PATH := "user://aetherwake-tests/first-wake-save-store.json"

func _initialize() -> void:
    var store = SaveStore.new()
    store.delete_slot(TEST_PATH)

    var chapter_a = ChapterState.new()
    var snapshot_a := SaveCodec.encode(chapter_a, {
        "hull_integrity": 100,
        "morale": 50,
        "engine_integration": 0,
    })
    var first := store.save_snapshot(snapshot_a, TEST_PATH)
    if not bool(first.get("ok", false)):
        _fail("first valid save failed: " + str(first.get("error", "")))
        return
    var first_primary_sha := FileAccess.get_sha256(TEST_PATH)
    if first_primary_sha.is_empty() or str(first.get("primary_sha256", "")) != first_primary_sha:
        _fail("first save did not custody-bind exact primary bytes")
        return
    if not str(first.get("backup_sha256", "")).is_empty():
        _fail("first save falsely reported a previous-generation backup")
        return

    var load_a := store.load_snapshot(TEST_PATH)
    if not bool(load_a.get("ok", false)) or bool(load_a.get("recovered", true)):
        _fail("primary initial load failed")
        return
    if str(load_a["snapshot"]["stage"]) != "signal":
        _fail("initial stage changed on disk")
        return

    var chapter_b = ChapterState.new()
    var signal_contacts := {
        "harmonic_buoy": "engine_spirit",
        "sky_lane_warning": "corporate_salvager",
        "below_frequency": "child_prophet",
    }
    for signal_id in ChapterState.SIGNAL_IDS:
        var contact_id: String = signal_contacts[signal_id]
        if not chapter_b.meet_contact(contact_id):
            _fail("could not construct crossing contact evidence: " + contact_id)
            return
        if not chapter_b.complete_signal(signal_id):
            _fail("could not construct crossing snapshot: " + signal_id)
            return
    var snapshot_b := SaveCodec.encode(chapter_b, {
        "hull_integrity": 88,
        "morale": 61,
        "engine_integration": 12,
    })
    var second := store.save_snapshot(snapshot_b, TEST_PATH)
    if not bool(second.get("ok", false)):
        _fail("second valid save failed")
        return
    if not FileAccess.file_exists(TEST_PATH + ".bak"):
        _fail("second save did not preserve previous valid primary")
        return
    if FileAccess.file_exists(TEST_PATH + ".bak.next"):
        _fail("verified backup candidate was not consumed after rotation")
        return
    var backup_text := FileAccess.get_file_as_string(TEST_PATH + ".bak")
    var backup_parsed = JSON.parse_string(backup_text)
    if not (backup_parsed is Dictionary) or not SaveCodec.validate(backup_parsed).get("ok", false):
        _fail("second save left a backup that was not semantically valid")
        return
    if str(backup_parsed["stage"]) != "signal":
        _fail("backup did not preserve the exact previous generation")
        return
    var backup_sha := FileAccess.get_sha256(TEST_PATH + ".bak")
    if backup_sha.is_empty() or backup_sha != first_primary_sha:
        _fail("backup bytes did not match the exact previous primary generation")
        return
    if str(second.get("backup_sha256", "")) != backup_sha:
        _fail("second save did not receipt the exact backup generation hash")
        return
    var second_primary_sha := FileAccess.get_sha256(TEST_PATH)
    if second_primary_sha.is_empty() or str(second.get("primary_sha256", "")) != second_primary_sha:
        _fail("second save did not receipt the exact new primary hash")
        return

    var load_b := store.load_snapshot(TEST_PATH)
    if not bool(load_b.get("ok", false)) or str(load_b["snapshot"]["stage"]) != "crossing":
        _fail("second primary snapshot did not load")
        return
    var stats_b: Dictionary = load_b["snapshot"]["resolver_stats"]
    if int(stats_b["hull_integrity"]) != 88 or int(stats_b["morale"]) != 61 or int(stats_b["engine_integration"]) != 12:
        _fail("resolver stats drifted through filesystem save")
        return

    var invalid := snapshot_b.duplicate(true)
    invalid["schema"] = "aetherwake.invalid"
    var rejected := store.save_snapshot(invalid, TEST_PATH)
    if bool(rejected.get("ok", true)):
        _fail("invalid snapshot was written")
        return
    var after_reject := store.load_snapshot(TEST_PATH)
    if not bool(after_reject.get("ok", false)) or str(after_reject["snapshot"]["stage"]) != "crossing":
        _fail("rejected save mutated current valid primary")
        return

    # Corrupt the primary. The valid previous generation must recover from .bak.
    var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not corrupt test primary")
        return
    corrupt.store_string("{ definitely-not-json")
    corrupt.close()

    var recovered := store.load_snapshot(TEST_PATH)
    if not bool(recovered.get("ok", false)) or not bool(recovered.get("recovered", false)):
        _fail("corrupt primary did not recover from backup")
        return
    if str(recovered["snapshot"]["stage"]) != "signal":
        _fail("backup recovery did not return previous valid generation")
        return

    # A valid save over a corrupt primary must not destroy the known-good backup.
    var repaired := store.save_snapshot(snapshot_b, TEST_PATH)
    if not bool(repaired.get("ok", false)):
        _fail("valid save could not repair corrupt primary")
        return
    var load_repaired := store.load_snapshot(TEST_PATH)
    if not bool(load_repaired.get("ok", false)) or str(load_repaired["snapshot"]["stage"]) != "crossing":
        _fail("repaired primary did not load")
        return

    # The repair path intentionally keeps the pre-existing known-good backup
    # because the corrupt primary was not eligible to replace it.
    var corrupt_again := FileAccess.open(TEST_PATH, FileAccess.WRITE)
    if corrupt_again == null:
        _fail("could not corrupt repaired primary for backup-retention check")
        return
    corrupt_again.store_string("{ corrupt-primary-again")
    corrupt_again.close()
    var recovered_again := store.load_snapshot(TEST_PATH)
    if not bool(recovered_again.get("ok", false)) or not bool(recovered_again.get("recovered", false)):
        _fail("known-good backup did not survive corrupt-primary repair")
        return
    if str(recovered_again["snapshot"]["stage"]) != "signal":
        _fail("repair path replaced the known-good previous-generation backup")
        return

    store.delete_slot(TEST_PATH)
    if (
        FileAccess.file_exists(TEST_PATH)
        or FileAccess.file_exists(TEST_PATH + ".bak")
        or FileAccess.file_exists(TEST_PATH + ".bak.next")
        or FileAccess.file_exists(TEST_PATH + ".tmp")
    ):
        _fail("test slot cleanup failed")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_SAVE_STORE_PASS: verified temp write, previous-generation backup, fail-closed rejection and corrupt-primary recovery")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_SAVE_STORE_FAIL: " + reason)
    quit(1)
