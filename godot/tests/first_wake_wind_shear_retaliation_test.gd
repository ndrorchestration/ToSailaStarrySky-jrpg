extends SceneTree
## Deterministic authored-hazard retaliation contract for current Wind Shear.

const Adapter = preload("res://scripts/first_wake_current_enemy_adapter.gd")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")

class Sequence:
    extends RefCounted
    var values: Array
    var index: int = 0

    func _init(next_values: Array) -> void:
        values = next_values.duplicate()

    func next():
        if index >= values.size():
            return 0.5
        var value = values[index]
        index += 1
        return value

func _initialize() -> void:
    var adapter = Adapter.new()
    var target := adapter.target_for_hazard("wind_shear")
    var sequence = Sequence.new([
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
        0.5, 0.99, 0.5, 0.99,
    ])
    var encounter = Encounter.new(sequence.next)

    if not encounter.start_with_target(target):
        _fail("authored Wind Shear encounter did not start")
        return
    if encounter.encounter_kind != "authored_hazard":
        _fail("authored encounter kind missing")
        return

    var starting_vit := int(encounter.player["vit"])
    if not encounter.take_action("uncoverTruth"):
        _fail("Uncover Truth rejected")
        return
    if int(encounter.player["vit"]) != starting_vit - 2:
        _fail("Gale Force did not retaliate for exactly 2 damage")
        return
    if encounter.enemy_turns != 1:
        _fail("enemy turn counter did not advance")
        return
    if encounter.last_log().find("Gale Force") < 0:
        _fail("retaliation log did not surface Gale Force")
        return

    # Defeat is fail-closed: no more player turns are admitted, but the player
    # can still close/cancel the transient encounter without progression.
    encounter.player["vit"] = 2
    if not encounter.take_action("hold"):
        _fail("Hold rejected before defeat")
        return
    if not encounter.player_defeated or int(encounter.player["vit"]) != 0:
        _fail("Gale Force did not produce deterministic player defeat")
        return
    if encounter.take_action("rest"):
        _fail("defeated player was allowed another combat turn")
        return
    if not encounter.active or encounter.completed:
        _fail("player defeat incorrectly cleared the authored hazard")
        return
    if not encounter.close():
        _fail("defeated transient encounter could not be closed")
        return

    # A killing blow ends the encounter before retaliation; cleared targets
    # cannot deal a post-defeat hit.
    encounter = Encounter.new(sequence.next)
    if not encounter.start_with_target(target):
        _fail("second authored encounter did not start")
        return
    encounter.target["hp"] = 1
    var before_kill_vit := int(encounter.player["vit"])
    if not encounter.take_action("staffStrike"):
        _fail("killing Staff Strike rejected")
        return
    if not encounter.completed or int(encounter.target["hp"]) != 0:
        _fail("killing Staff Strike did not clear target")
        return
    if encounter.enemy_turns != 0:
        _fail("cleared Wind Shear retaliated after defeat")
        return
    if int(encounter.player["vit"]) != before_kill_vit:
        _fail("player took damage after clearing Wind Shear")
        return

    print("AETHERWAKE_GODOT_WIND_SHEAR_RETALIATION_PASS: authored Gale Force deals exact 2 damage, defeat fails closed, and cleared target cannot retaliate")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_WIND_SHEAR_RETALIATION_FAIL: " + reason)
    quit(1)
