extends RefCounted
## Versioned, standalone revised-opening checkpoint for the opt-in playable
## employment/engineering study ONLY. Never reinterpret legacy Chapter I v1.
## Does NOT serialize art grants, combat rights, story theories or future stages.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")

const SCHEMA := "tstss.first-wake.revised-opening.review.v2"
const SLOT_PATH := "user://first_wake_revised_opening_review_v2.json"
const STAGES := ["job_search", "engineering", "preflight"]
const ENGINEERING_ITEMS := ["reference", "containment", "fuel"]
const DOCK_BOUNDS := Rect2(Vector2(145, 410), Vector2(670, 112))
const ENGINEERING_BOUNDS := Rect2(Vector2(110, 405), Vector2(735, 119))
const REQUIRED := ["schema", "step", "flyer_read", "room", "inspections", "player_position"]

static func encode(opening: Variant, flyer_read: bool, room: String, inspections: Array, position: Vector2) -> Dictionary:
    if not (opening is RefCounted) or opening.get_script() != Opening:
        return {}
    var state: Dictionary = opening.snapshot()
    var result := {
        "schema": SCHEMA, "step": state.get("step", ""),
        "flyer_read": flyer_read, "room": room,
        "inspections": inspections.duplicate(),
        "player_position": {"x": position.x, "y": position.y},
    }
    return result if bool(validate(result).get("ok", false)) else {}

static func validate(raw: Variant) -> Dictionary:
    if not (raw is Dictionary):
        return _invalid("snapshot_must_be_object")
    var snapshot: Dictionary = raw
    if snapshot.size() != REQUIRED.size():
        return _invalid("field_count_mismatch")
    for field in REQUIRED:
        if not snapshot.has(field):
            return _invalid("missing_" + field)
    if not (snapshot["schema"] is String) or snapshot["schema"] != SCHEMA:
        return _invalid("schema_mismatch")
    if not (snapshot["step"] is String) or snapshot["step"] not in STAGES:
        return _invalid("unsupported_review_step")
    if not (snapshot["flyer_read"] is bool):
        return _invalid("invalid_flyer_status")
    if not (snapshot["room"] is String) or snapshot["room"] not in ["dock", "engineering"]:
        return _invalid("invalid_room")
    if not (snapshot["inspections"] is Array):
        return _invalid("invalid_inspection_list")

    var step: String = snapshot["step"]
    var room: String = snapshot["room"]
    var flyer: bool = snapshot["flyer_read"]
    var items: Array = snapshot["inspections"]
    var seen: Dictionary = {}
    for item in items:
        if not (item is String) or item not in ENGINEERING_ITEMS or seen.has(item):
            return _invalid("invalid_inspection_evidence")
        seen[item] = true
    if step == "job_search":
        if room != "dock" or not items.is_empty():
            return _invalid("unhired_engineering_evidence")
    else:
        if not flyer:
            return _invalid("missing_employment_flyer")
        if room == "dock" and not items.is_empty():
            return _invalid("engineering_evidence_while_ashore")
        if step == "preflight" and (room != "engineering" or items.size() != ENGINEERING_ITEMS.size()):
            return _invalid("preflight_without_all_checks")

    var coords = snapshot["player_position"]
    if not (coords is Dictionary) or coords.size() != 2 or not coords.has("x") or not coords.has("y"):
        return _invalid("invalid_player_position")
    if typeof(coords["x"]) not in [TYPE_FLOAT, TYPE_INT] or typeof(coords["y"]) not in [TYPE_FLOAT, TYPE_INT]:
        return _invalid("nonnumeric_player_position")
    var px: float = float(coords["x"])
    var py: float = float(coords["y"])
    if not is_finite(px) or not is_finite(py):
        return _invalid("nonfinite_player_position")
    var bounds: Rect2 = DOCK_BOUNDS if room == "dock" else ENGINEERING_BOUNDS
    if not bounds.has_point(Vector2(px, py)) and Vector2(px, py) != bounds.end:
        return _invalid("player_out_of_room_bounds")

    return {"ok": true, "reason": "valid_revised_opening_review_checkpoint"}

static func restore(raw: Variant) -> Dictionary:
    var verdict: Dictionary = validate(raw)
    if not bool(verdict.get("ok", false)):
        return {"ok": false, "reason": verdict.get("reason", "invalid_snapshot")}
    var saved: Dictionary = raw
    var story = Opening.new()
    var step: String = saved["step"]
    if step in ["engineering", "preflight"] and not story.accept_ionia_job():
        return {"ok": false, "reason": "failed_reconstruct_ionia_recruitment"}
    if step == "preflight" and not story.complete_engineering_checks():
        return {"ok": false, "reason": "failed_reconstruct_preflight"}
    # Story party is reconstructed from validated sequence; never trusted from
    # a user-supplied roster, old v1 save, narrative Light, or learned ability.
    var expected: Array = ["ender"] if step == "job_search" else ["ender", "ionia"]
    if story.step_key() != step or story.active_party_ids != expected:
        return {"ok": false, "reason": "story_reconstruction_mismatch"}
    var coords: Dictionary = saved["player_position"]
    return {
        "ok": true, "reason": "revised_checkpoint_restored",
        "opening": story,
        "flyer_read": saved["flyer_read"],
        "room": saved["room"],
        "inspections": Array(saved["inspections"]).duplicate(),
        "player_position": Vector2(float(coords["x"]), float(coords["y"])),
        "reviewOnly": true,
    }

static func _invalid(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
