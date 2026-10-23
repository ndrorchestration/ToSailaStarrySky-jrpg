extends RefCounted
## Versioned fail-closed save codec for native First Wake Chapter I migration.
## Persists durable progression, bounded exploration position, and review resolver inputs.
## Transient UI/dialogue/combat cursor state is intentionally not persisted.
## player_position is a backward-compatible optional v1 field: older v1 saves
## remain readable and restore to LEGACY_PLAYER_POSITION.

const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")

const SCHEMA_VERSION := "aetherwake.first-wake.chapter1.v1"
const STAGE_KEYS: Array[String] = ["signal", "crossing", "contact", "choice", "wake", "done"]
const PLAYER_POSITION_BOUNDS := Rect2(Vector2(110, 404), Vector2(740, 118))
const LEGACY_PLAYER_POSITION := Vector2(360, 465)
const IONIA_CONTACT_ID := "elder_farmer"
const SIGNAL_CONTACT_BY_SIGNAL := {
    "harmonic_buoy": "engine_spirit",
    "below_frequency": "child_prophet",
    "sky_lane_warning": "corporate_salvager",
}

static func encode(chapter, stats: Dictionary = {}, player_position: Variant = null) -> Dictionary:
    var snapshot := {
        "schema": SCHEMA_VERSION,
        "stage": chapter.stage_key(),
        "signals_completed": chapter.completed_signals.duplicate(),
        "hazards_completed": chapter.completed_hazards.duplicate(),
        "contacts_met": chapter.contacts_met.duplicate(),
        "ionia_joined_for_choice": chapter.ionia_joined_for_choice,
        "choice_path": chapter.choice_path,
        "choice_variant": chapter.choice_variant,
        "epilogue_id": chapter.epilogue_id,
        "chapter_one_complete": chapter.chapter_one_complete,
        "resolver_stats": {
            "hull_integrity": int(stats.get("hull_integrity", 100)),
            "morale": int(stats.get("morale", 50)),
            "engine_integration": int(stats.get("engine_integration", 0)),
        },
    }
    if player_position is Vector2:
        snapshot["player_position"] = {
            "x": float(player_position.x),
            "y": float(player_position.y),
        }
    return snapshot

static func validate(snapshot: Dictionary) -> Dictionary:
    if str(snapshot.get("schema", "")) != SCHEMA_VERSION:
        return _invalid("unsupported schema")

    var stage_key := str(snapshot.get("stage", ""))
    if stage_key not in STAGE_KEYS:
        return _invalid("invalid stage")

    var signals = snapshot.get("signals_completed", [])
    var hazards = snapshot.get("hazards_completed", [])
    var contacts = snapshot.get("contacts_met", [])
    if not _is_valid_unique_subset(signals, ChapterState.SIGNAL_IDS):
        return _invalid("invalid signal set")
    if not _is_valid_unique_subset(hazards, ChapterState.HAZARD_IDS):
        return _invalid("invalid hazard set")
    if not _is_valid_unique_subset(contacts, ChapterState.CONTACT_IDS):
        return _invalid("invalid contact set")

    if not _signal_contact_evidence_matches(signals, contacts):
        return _invalid("signal/contact evidence contradiction")

    var ionia_contact_met := IONIA_CONTACT_ID in contacts
    if stage_key in ["signal", "crossing", "contact"] and ionia_contact_met:
        return _invalid("Ionia contact appears before authored Contact completion")

    var ionia_joined := bool(snapshot.get("ionia_joined_for_choice", false))
    var choice_path := str(snapshot.get("choice_path", ""))
    var choice_variant := str(snapshot.get("choice_variant", ""))
    var epilogue_id := str(snapshot.get("epilogue_id", ""))
    var chapter_complete := bool(snapshot.get("chapter_one_complete", false))

    if not choice_path.is_empty() and choice_path not in ChapterState.CHOICE_IDS:
        return _invalid("invalid choice path")
    if not choice_variant.is_empty() and choice_variant not in ChapterState.VALID_VARIANTS:
        return _invalid("invalid choice variant")

    var signals_complete: bool = signals.size() == ChapterState.SIGNAL_IDS.size()
    var hazards_complete: bool = hazards.size() == ChapterState.HAZARD_IDS.size()
    var contacts_complete: bool = contacts.size() == ChapterState.CONTACT_IDS.size()

    match stage_key:
        "signal":
            if signals_complete:
                return _invalid("signal-stage completion contradiction")
            if (
                not hazards.is_empty()
                or not choice_path.is_empty()
                or not choice_variant.is_empty()
                or not epilogue_id.is_empty()
                or ionia_joined
                or chapter_complete
            ):
                return _invalid("signal-stage progression contradiction")
        "crossing":
            if not signals_complete or hazards_complete:
                return _invalid("crossing-stage completion contradiction")
            if (
                not choice_path.is_empty()
                or not choice_variant.is_empty()
                or not epilogue_id.is_empty()
                or ionia_joined
                or chapter_complete
            ):
                return _invalid("crossing-stage progression contradiction")
        "contact":
            if not signals_complete or not hazards_complete:
                return _invalid("contact-stage prerequisite contradiction")
            if (
                not choice_path.is_empty()
                or not choice_variant.is_empty()
                or not epilogue_id.is_empty()
                or ionia_joined
                or chapter_complete
            ):
                return _invalid("contact-stage progression contradiction")
        "choice":
            if not signals_complete or not hazards_complete or not contacts_complete or not ionia_joined:
                return _invalid("choice-stage prerequisite contradiction")
            if (
                not choice_path.is_empty()
                or not choice_variant.is_empty()
                or not epilogue_id.is_empty()
                or chapter_complete
            ):
                return _invalid("choice-stage outcome contradiction")
        "wake":
            if not signals_complete or not hazards_complete or not contacts_complete or not ionia_joined:
                return _invalid("wake-stage prerequisite contradiction")
            if choice_path.is_empty() or choice_variant.is_empty() or not epilogue_id.is_empty() or chapter_complete:
                return _invalid("wake-stage outcome contradiction")
        "done":
            if not signals_complete or not hazards_complete or not contacts_complete or not ionia_joined:
                return _invalid("done-stage prerequisite contradiction")
            if choice_path.is_empty() or choice_variant.is_empty() or epilogue_id.strip_edges().is_empty() or not chapter_complete:
                return _invalid("done-stage completion contradiction")

    var stats_value: Variant = snapshot.get("resolver_stats", {})
    if not (stats_value is Dictionary):
        return _invalid("resolver stats missing")
    var stats: Dictionary = stats_value
    var hull: int = int(stats.get("hull_integrity", -1))
    var morale: int = int(stats.get("morale", -1))
    var engine: int = int(stats.get("engine_integration", -1))
    if hull < 0 or hull > 100:
        return _invalid("hull integrity out of range")
    if morale < 0 or morale > 100:
        return _invalid("morale out of range")
    if engine < 0 or engine > 100:
        return _invalid("engine integration out of range")

    if snapshot.has("player_position"):
        var position_verdict := _validate_player_position(snapshot["player_position"])
        if not bool(position_verdict.get("ok", false)):
            return position_verdict

    return {"ok": true, "error": ""}

static func restore(snapshot: Dictionary) -> Dictionary:
    var verdict := validate(snapshot)
    if not bool(verdict.get("ok", false)):
        return {
            "ok": false,
            "error": str(verdict.get("error", "invalid snapshot")),
            "chapter": null,
            "resolver_stats": {},
        }

    var chapter = ChapterState.new()
    chapter.stage = _stage_from_key(str(snapshot["stage"]))
    chapter.completed_signals = _string_array(snapshot["signals_completed"])
    chapter.completed_hazards = _string_array(snapshot["hazards_completed"])
    chapter.contacts_met = _string_array(snapshot["contacts_met"])
    chapter.ionia_joined_for_choice = bool(snapshot["ionia_joined_for_choice"])
    chapter.choice_path = str(snapshot["choice_path"])
    chapter.choice_variant = str(snapshot["choice_variant"])
    chapter.epilogue_id = str(snapshot["epilogue_id"])
    chapter.chapter_one_complete = bool(snapshot["chapter_one_complete"])

    var has_player_position := snapshot.has("player_position")
    var player_position := LEGACY_PLAYER_POSITION
    if has_player_position:
        var raw_position: Dictionary = snapshot["player_position"]
        player_position = Vector2(float(raw_position["x"]), float(raw_position["y"]))

    return {
        "ok": true,
        "error": "",
        "chapter": chapter,
        "resolver_stats": snapshot["resolver_stats"].duplicate(true),
        "player_position": player_position,
        "player_position_present": has_player_position,
    }

static func _validate_player_position(raw: Variant) -> Dictionary:
    if not (raw is Dictionary):
        return _invalid("player position must be an object")
    var position: Dictionary = raw
    if not position.has("x") or not position.has("y"):
        return _invalid("player position coordinates missing")
    if typeof(position["x"]) not in [TYPE_INT, TYPE_FLOAT] or typeof(position["y"]) not in [TYPE_INT, TYPE_FLOAT]:
        return _invalid("player position coordinates must be numeric")
    var x := float(position["x"])
    var y := float(position["y"])
    if not is_finite(x) or not is_finite(y):
        return _invalid("player position coordinates must be finite")
    var point := Vector2(x, y)
    var min_point := PLAYER_POSITION_BOUNDS.position
    var max_point := PLAYER_POSITION_BOUNDS.end
    if point.x < min_point.x or point.x > max_point.x or point.y < min_point.y or point.y > max_point.y:
        return _invalid("player position outside Chapter I deck bounds")
    return {"ok": true, "error": ""}

static func _stage_from_key(stage_key: String) -> int:
    match stage_key:
        "signal":
            return ChapterState.Stage.SIGNAL
        "crossing":
            return ChapterState.Stage.CROSSING
        "contact":
            return ChapterState.Stage.CONTACT
        "choice":
            return ChapterState.Stage.CHOICE
        "wake":
            return ChapterState.Stage.WAKE
        "done":
            return ChapterState.Stage.DONE
    return ChapterState.Stage.SIGNAL

static func _signal_contact_evidence_matches(signals: Array, contacts: Array) -> bool:
    var expected_contacts: Dictionary = {}
    for signal_id in signals:
        var contact_id := str(SIGNAL_CONTACT_BY_SIGNAL.get(str(signal_id), ""))
        if contact_id.is_empty():
            return false
        expected_contacts[contact_id] = true

    for contact_id in contacts:
        var normalized := str(contact_id)
        if normalized == IONIA_CONTACT_ID:
            continue
        if not expected_contacts.has(normalized):
            return false

    for expected_contact in expected_contacts.keys():
        if str(expected_contact) not in contacts:
            return false
    return true

static func _is_valid_unique_subset(values, allowed: Array[String]) -> bool:
    if not values is Array:
        return false
    var seen: Dictionary = {}
    for raw in values:
        var value := str(raw)
        if value not in allowed or seen.has(value):
            return false
        seen[value] = true
    return true

static func _string_array(values: Array) -> Array[String]:
    var result: Array[String] = []
    for value in values:
        result.append(str(value))
    return result

static func _invalid(message: String) -> Dictionary:
    return {"ok": false, "error": message}
