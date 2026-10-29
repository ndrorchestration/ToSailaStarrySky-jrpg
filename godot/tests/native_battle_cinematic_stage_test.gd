extends SceneTree
const Stage = preload("res://scripts/combat/battle_cinematic_stage.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var stage = Stage.new()
    root.add_child(stage)
    await process_frame
    var roster := {
        "ender": {"hp": 35}, "ionia": {"hp": 40}, "foe": {"hp": 18}
    }
    var state := {"order": ["ender", "ionia", "foe"], "roster": roster, "cursor": 0}
    var factions := {"ender": "crew", "ionia": "crew", "foe": "opponent"}
    var original: Dictionary = state.duplicate(true)
    if not stage.present_snapshot(state, factions):
        _fail("valid stage snapshot")
        return
    var view: Dictionary = stage.review_snapshot()
    if view["actor_count"] != 3 or view["active_actor_id"] != "ender":
        _fail("actors and turn projection")
        return
    if not view["visual_only"] or view["authoritative_combat"] or view["creator_art_approved"]:
        _fail("review bounds")
        return
    if not stage.present_event({"actor_id": "ender", "target_id": "foe", "kind": "damage", "amount_applied": 6}):
        _fail("valid combat event projection")
        return
    if stage.present_event({"actor_id": "lyra", "target_id": "foe", "kind": "damage", "amount_applied": 6}):
        _fail("unknown actor rejected")
        return
    var bad_factions := factions.duplicate(true)
    bad_factions["foe"] = "crew"
    if stage.present_snapshot(state, bad_factions) or stage.review_snapshot()["actor_count"] != 3:
        _fail("invalid projection rejected without state change")
        return
    if state != original:
        _fail("battle state mutation")
        return
    print("NATIVE_BATTLE_CINEMATIC_STAGE_PASS")
    quit(0)

func _fail(message: String) -> void:
    push_error("NATIVE_BATTLE_CINEMATIC_STAGE_FAIL: " + message)
    quit(1)
