extends SceneTree
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Gate = preload("res://scripts/combat/encounter_permit_preview.gd")

func _initialize() -> void:
    var opening = Opening.new()
    if not opening.accept_ionia_job():
        _fail("Ionia hire setup")
        return
    var roster := {}
    for id in ["ender", "ionia", "foe"]:
        roster[id] = {"hp": 40, "max_hp": 40, "mp": 8, "max_mp": 8, "stamina": 6, "max_stamina": 6}
    var crew: Array[String] = ["ender", "ionia"]
    var foes: Array[String] = ["foe"]
    var snapshot: Dictionary = opening.snapshot()
    var permit := {
        "encounter_id": "test_fixture_only",
        "story_step": snapshot["step"],
        "crew_ids": ["ender", "ionia"],
        "opponent_ids": ["foe"],
        "approved_for_review": true
    }
    if Gate.validate_permit(opening, roster, crew, foes, {}).get("ok", true):
        _fail("missing permit")
        return
    var wrong := permit.duplicate(true)
    wrong["story_step"] = "waterborne"
    if Gate.validate_permit(opening, roster, crew, foes, wrong).get("ok", true):
        _fail("wrong story step")
        return
    wrong = permit.duplicate(true)
    wrong["crew_ids"] = ["ender"]
    if Gate.validate_permit(opening, roster, crew, foes, wrong).get("ok", true):
        _fail("wrong participants")
        return
    wrong = permit.duplicate(true)
    wrong["approved_for_review"] = false
    if Gate.validate_permit(opening, roster, crew, foes, wrong).get("ok", true):
        _fail("missing approval")
        return
    var result := Gate.validate_permit(opening, roster, crew, foes, permit)
    if not result.get("ok", false) or result["production_encounter_authorized"]:
        _fail("review admission")
        return
    if opening.snapshot() != snapshot or result["preview"]["state"]["roster"] != roster:
        _fail("state must not mutate")
        return
    print("NATIVE_ENCOUNTER_PERMIT_PREVIEW_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_ENCOUNTER_PERMIT_PREVIEW_FAIL: " + reason)
    quit(1)
