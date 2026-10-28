extends RefCounted
## Standalone opt-in Chapter I SALVAGE review v3 checkpoint.
## Never migrates v1, v2, midflight physics, actual geographic authority,
## combat entitlements, or workshop/phase-lock state.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const SCHEMA := "tstss.first-wake.salvage.review.v3"
const SLOT_PATH := "user://first_wake_salvage_review_v3.json"
const QUAY := "quay_review"
const DEPOT := "depot_review"
const BOUNDS := Rect2(Vector2(113, 411), Vector2(750, 110))
const KEYS := ["schema", "step", "clues", "region", "player_position", "custody"]
const RECEIPT_KEYS := ["item_id", "area_id", "custodian", "source"]

static func encode(story: Variant, core: Variant, area: String, receipts: Array, pos: Vector2) -> Dictionary:
    if not (story is RefCounted) or story.get_script() != Opening:
        return {}
    if not (core is RefCounted) or core.get_script() != Core or core.authorized_story != story:
        return {}
    if core.snapshot().get("phase", "") not in ["recover", "install"]:
        return {}
    var data: Dictionary = {
        "schema": SCHEMA,
        "step": story.step_key(),
        "clues": story.clues.duplicate(),
        "region": area,
        "player_position": {"x": pos.x, "y": pos.y},
        "custody": receipts.duplicate(true),
    }
    if not bool(validate(data).get("ok", false)):
        return {}
    var recovered: Array = core.snapshot().get("recovered", [])
    if recovered.size() != receipts.size():
        return {}
    for receipt in receipts:
        if str(receipt["item_id"]) not in recovered:
            return {}
    return data

static func validate(raw: Variant) -> Dictionary:
    if not (raw is Dictionary):
        return _invalid("root_not_object")
    var data: Dictionary = raw
    if data.size() != KEYS.size():
        return _invalid("wrong_number_of_fields")
    for key in KEYS:
        if not data.has(key):
            return _invalid("missing_field_" + key)
    if not (data["schema"] is String) or data["schema"] != SCHEMA:
        return _invalid("wrong_schema")
    if not (data["step"] is String) or data["step"] != "working_theory":
        return _invalid("wrong_story_step")
    if not (data["clues"] is Array):
        return _invalid("clues_not_array")
    var clues: Array = data["clues"]
    if clues.size() < 2 or clues.size() > Opening.CLUE_IDS.size():
        return _invalid("insufficient_independent_evidence")
    var seen_clues: Dictionary = {}
    for clue in clues:
        if not (clue is String) or clue not in Opening.CLUE_IDS or seen_clues.has(clue):
            return _invalid("unrecognized_or_duplicate_clue")
        seen_clues[clue] = true
    if not (data["region"] is String) or data["region"] not in [QUAY, DEPOT]:
        return _invalid("wrong_salvage_region")
    if not (data["player_position"] is Dictionary):
        return _invalid("position_not_object")
    var coords: Dictionary = data["player_position"]
    if coords.size() != 2 or not coords.has("x") or not coords.has("y"):
        return _invalid("position_fields")
    if typeof(coords["x"]) not in [TYPE_INT, TYPE_FLOAT] or typeof(coords["y"]) not in [TYPE_INT, TYPE_FLOAT]:
        return _invalid("position_not_numeric")
    var px: float = float(coords["x"])
    var py: float = float(coords["y"])
    if not is_finite(px) or not is_finite(py):
        return _invalid("nonfinite_position")
    var at := Vector2(px, py)
    if not BOUNDS.has_point(at) and at != BOUNDS.end:
        return _invalid("out_of_walk_bounds")
    if not (data["custody"] is Array):
        return _invalid("custody_not_array")
    var receipts: Array = data["custody"]
    if receipts.size() > Core.ITEM_IDS.size():
        return _invalid("too_many_receipts")
    var seen_items: Dictionary = {}
    for receipt in receipts:
        if not (receipt is Dictionary):
            return _invalid("receipt_not_object")
        var entry: Dictionary = receipt
        if entry.size() != RECEIPT_KEYS.size():
            return _invalid("receipt_field_count")
        for key in RECEIPT_KEYS:
            if not entry.has(key):
                return _invalid("missing_receipt_field_" + key)
        for key in RECEIPT_KEYS:
            if not (entry[key] is String):
                return _invalid("receipt_field_not_string")
        var item: String = entry["item_id"]
        var region: String = entry["area_id"]
        if item not in Core.ITEM_IDS or seen_items.has(item):
            return _invalid("unknown_or_duplicate_item")
        if region != (QUAY if item == "recovered_supply" else DEPOT):
            return _invalid("item_source_mismatch")
        if entry["custodian"] != "ender" or entry["source"] != "walkable_scene_interaction":
            return _invalid("forged_custody_marker")
        seen_items[item] = true
    return {"ok": true, "reason": "valid_salvage_review_v3"}

static func restore(raw: Variant) -> Dictionary:
    var verdict: Dictionary = validate(raw)
    if not bool(verdict.get("ok", false)):
        return verdict
    var data: Dictionary = raw
    # Replay only deterministic narrative prerequisites from explicit vetted
    # claim fields. This does NOT reproduce physics evidence on a new launch.
    var story = Opening.new()
    if not story.accept_ionia_job() or not story.complete_engineering_checks():
        return _invalid("story_reconstruction_failed")
    if not story.begin_test_flight() or not story.record_engine_failure(true, true, true):
        return _invalid("flight_story_reconstruction_failed")
    if not story.complete_ocean_splashdown(true, true) or not story.inspect_postflight_reserve(true):
        return _invalid("postflight_story_reconstruction_failed")
    if not story.introduce_lyra_and_talen(true):
        return _invalid("family_reconstruction_failed")
    for clue in data["clues"]:
        if not story.record_clue(clue):
            return _invalid("evidence_replay_failed")
    if not story.form_working_fuel_theory():
        return _invalid("theory_replay_failed")
    var core = Core.new()
    if not core.begin(story):
        return _invalid("core_rebuild_failed")
    for receipt in data["custody"]:
        if not core.take_world_item(str(receipt["item_id"]), "world_pickup"):
            return _invalid("salvage_replay_failed")
    if story.step_key() != "working_theory" or core.snapshot()["phase"] not in ["recover", "install"]:
        return _invalid("checkpoint_state_inconsistent")
    var coords: Dictionary = data["player_position"]
    return {
        "ok": true,
        "opening": story,
        "core": core,
        "region": data["region"],
        "custody": data["custody"].duplicate(true),
        "player_position": Vector2(float(coords["x"]), float(coords["y"])),
        "reviewOnly": true,
        "prior_physical_water_reverified": false,
        "production_inventory": false,
        "can_launch": false,
        "can_execute_art": false,
    }

static func _invalid(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
