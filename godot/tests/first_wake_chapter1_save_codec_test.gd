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
    var saved_position := Vector2(444, 476)
    var partial := SaveCodec.encode(initial, {
        "hull_integrity": 92,
        "morale": 54,
        "engine_integration": 12,
    }, saved_position)
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
    if not bool(partial_restore.get("player_position_present", false)):
        _fail("new save did not mark player position present")
        return
    if partial_restore.get("player_position", Vector2.ZERO) != saved_position:
        _fail("player position did not round-trip")
        return

    var legacy := partial.duplicate(true)
    legacy.erase("player_position")
    var legacy_restore := SaveCodec.restore(legacy)
    if not legacy_restore.get("ok", false):
        _fail("legacy v1 snapshot without position was rejected")
        return
    if bool(legacy_restore.get("player_position_present", true)):
        _fail("legacy snapshot falsely claimed persisted position")
        return
    if legacy_restore.get("player_position", Vector2.ZERO) != SaveCodec.LEGACY_PLAYER_POSITION:
        _fail("legacy snapshot did not resolve to deterministic safe spawn")
        return

    var edge_snapshot := SaveCodec.encode(initial, {
        "hull_integrity": 92,
        "morale": 54,
        "engine_integration": 12,
    }, SaveCodec.PLAYER_POSITION_BOUNDS.end)
    if not SaveCodec.validate(edge_snapshot).get("ok", false):
        _fail("inclusive deck edge was rejected")
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

    var completed_signal_stage := partial.duplicate(true)
    completed_signal_stage["signals_completed"] = ChapterState.SIGNAL_IDS.duplicate()
    completed_signal_stage["contacts_met"] = ["engine_spirit", "child_prophet", "corporate_salvager"]
    if SaveCodec.restore(completed_signal_stage).get("ok", true):
        _fail("Signal stage admitted after all Signal hooks were already complete")
        return

    var completed_crossing_stage := _crossing_snapshot()
    completed_crossing_stage["hazards_completed"] = ChapterState.HAZARD_IDS.duplicate()
    if SaveCodec.restore(completed_crossing_stage).get("ok", true):
        _fail("Crossing stage admitted after all hazards were already complete")
        return

    var premature_choice_variant := partial.duplicate(true)
    premature_choice_variant["choice_variant"] = "10+"
    if SaveCodec.restore(premature_choice_variant).get("ok", true):
        _fail("choice outcome variant admitted before Choice")
        return

    var premature_epilogue := partial.duplicate(true)
    premature_epilogue["epilogue_id"] = "epiline_1"
    if SaveCodec.restore(premature_epilogue).get("ok", true):
        _fail("epilogue identity admitted before Wake completion")
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

    var missing_signal_contact := partial.duplicate(true)
    missing_signal_contact["contacts_met"] = []
    if SaveCodec.restore(missing_signal_contact).get("ok", true):
        _fail("completed signal admitted without corresponding contact evidence")
        return

    var orphan_signal_contact := partial.duplicate(true)
    orphan_signal_contact["contacts_met"] = ["engine_spirit", "child_prophet"]
    if SaveCodec.restore(orphan_signal_contact).get("ok", true):
        _fail("contact evidence admitted without corresponding completed signal")
        return

    var early_ionia_contact := partial.duplicate(true)
    early_ionia_contact["contacts_met"] = ["engine_spirit", "elder_farmer"]
    if SaveCodec.restore(early_ionia_contact).get("ok", true):
        _fail("Ionia contact evidence admitted before authored Contact boundary")
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

    var bad_position := partial.duplicate(true)
    bad_position["player_position"] = {"x": 9999.0, "y": 476.0}
    if SaveCodec.restore(bad_position).get("ok", true):
        _fail("out-of-bounds player position admitted")
        return

    var malformed_position := partial.duplicate(true)
    malformed_position["player_position"] = {"x": "444", "y": 476.0}
    if SaveCodec.restore(malformed_position).get("ok", true):
        _fail("nonnumeric player position admitted")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_SAVE_PASS: versioned progression/position round-trip, legacy fallback and fail-closed tamper rejection")
    quit(0)

func _crossing_snapshot() -> Dictionary:
    var crossing = ChapterState.new()
    for contact_id in ["engine_spirit", "child_prophet", "corporate_salvager"]:
        crossing.meet_contact(contact_id)
    for signal_id in ChapterState.SIGNAL_IDS:
        crossing.complete_signal(signal_id)
    return SaveCodec.encode(crossing, {
        "hull_integrity": 88,
        "morale": 52,
        "engine_integration": 18,
    }, Vector2(480, 470))

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
