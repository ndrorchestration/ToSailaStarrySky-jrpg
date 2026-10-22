extends SceneTree
## Contract for fail-closed native First Wake Chapter I save serialization.

const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var initial = ChapterState.new()
    initial.meet_contact("engine_spirit")
    initial.complete_signal("harmonic_buoy")
    var partial := SaveCodec.encode(initial, {
        "hull_integrity": 92,
        "morale": 54,
        "engine_integration": 12,
    })
    if partial.get("schema", "") != SaveCodec.SCHEMA_VERSION:
        _fail("schema version missing")
        return
    if partial.has("dialogue") or partial.has("dialogue_index") or partial.has("ui"):
        _fail("transient dialogue/UI state leaked into durable save")
        return

    var partial_restore := SaveCodec.restore(partial)
    if not partial_restore.get("ok", false):
        _fail("valid partial Signal snapshot rejected: " + str(partial_restore.get("error", "")))
        return
    var partial_chapter = partial_restore["chapter"]
    if partial_chapter.stage_key() != "signal":
        _fail("partial Signal stage changed on restore")
        return
    if partial_chapter.completed_signals != ["harmonic_buoy"]:
        _fail("partial signal set changed on restore")
        return
    if partial_chapter.contacts_met != ["engine_spirit"]:
        _fail("Signal-phase contact evidence changed on restore")
        return
    if int(partial_restore["resolver_stats"]["hull_integrity"]) != 92:
        _fail("resolver stats did not round-trip")
        return

    var complete = _completed_path_c()
    var done_snapshot := SaveCodec.encode(complete, {
        "hull_integrity": 50,
        "morale": 50,
        "engine_integration": 60,
    })
    var done_restore := SaveCodec.restore(done_snapshot)
    if not done_restore.get("ok", false):
        _fail("valid Done snapshot rejected: " + str(done_restore.get("error", "")))
        return
    var done_chapter = done_restore["chapter"]
    if done_chapter.snapshot() != complete.snapshot():
        _fail("completed Chapter I state did not round-trip exactly")
        return
    if done_chapter.desired_active_party_ids() != ["ender", "lyra", "ionia"]:
        _fail("restored active-party target lost Ionia")
        return

    var wrong_schema := done_snapshot.duplicate(true)
    wrong_schema["schema"] = "unknown"
    if SaveCodec.restore(wrong_schema).get("ok", true):
        _fail("unsupported schema admitted")
        return

    var impossible_crossing := partial.duplicate(true)
    impossible_crossing["stage"] = "crossing"
    if SaveCodec.restore(impossible_crossing).get("ok", true):
        _fail("Crossing admitted without all Signal hooks")
        return

    var duplicate_signal := partial.duplicate(true)
    duplicate_signal["signals_completed"] = ["harmonic_buoy", "harmonic_buoy"]
    if SaveCodec.restore(duplicate_signal).get("ok", true):
        _fail("duplicate signal IDs admitted")
        return

    var unknown_contact := partial.duplicate(true)
    unknown_contact["contacts_met"] = ["engine_spirit", "invented_contact"]
    if SaveCodec.restore(unknown_contact).get("ok", true):
        _fail("unknown contact admitted")
        return

    var incomplete_done := done_snapshot.duplicate(true)
    incomplete_done["epilogue_id"] = ""
    if SaveCodec.restore(incomplete_done).get("ok", true):
        _fail("Done admitted without epilogue identity")
        return

    var bad_stats := partial.duplicate(true)
    bad_stats["resolver_stats"]["morale"] = 101
    if SaveCodec.restore(bad_stats).get("ok", true):
        _fail("out-of-range resolver stats admitted")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_SAVE_PASS: versioned partial/done round-trip and fail-closed tamper rejection")
    quit(0)

func _completed_path_c():
    var chapter = ChapterState.new()
    for contact_id in ["engine_spirit", "child_prophet", "corporate_salvager"]:
        chapter.meet_contact(contact_id)
    for signal_id in ChapterState.SIGNAL_IDS:
        chapter.complete_signal(signal_id)
    for hazard_id in ChapterState.HAZARD_IDS:
        chapter.complete_hazard(hazard_id)
    chapter.meet_contact("elder_farmer")
    chapter.choose_path("path_c", "10+")
    chapter.complete_wake("epiline_6")
    return chapter

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_SAVE_FAIL: " + reason)
    quit(1)
