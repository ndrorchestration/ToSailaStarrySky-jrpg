extends SceneTree
## Deterministic action/resource contract for the native production-formula review encounter.

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
    var sequence = Sequence.new([0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99])
    var encounter = Encounter.new(sequence.next)

    if Encounter.VERSION != "0.1.0":
        _fail("encounter version drifted")
        return
    if not encounter.start() or not encounter.active:
        _fail("encounter did not start")
        return
    if encounter.take_action("sharedDream"):
        _fail("blocked action entered review encounter")
        return

    if not encounter.take_action("uncoverTruth"):
        _fail("Uncover Truth rejected")
        return
    if not encounter.weakness_revealed():
        _fail("analysis modifier not stored")
        return
    if encounter.last_log().find("EMP fractures") < 0:
        _fail("weakness copy not exposed")
        return

    var hp_before := int(encounter.target["hp"])
    var charges_before := int(encounter.player["staffCharges"])
    if not encounter.take_action("staffStrike"):
        _fail("analyzed Staff Strike rejected")
        return
    if int(encounter.target["hp"]) >= hp_before:
        _fail("Staff Strike did not damage target")
        return
    if int(encounter.player["staffCharges"]) != charges_before - 1:
        _fail("Staff Strike did not consume dedicated staff charge")
        return
    if encounter.weakness_revealed():
        _fail("analysis charge was not consumed by Staff Strike")
        return

    encounter.player["staffCharges"] = 0
    if encounter.take_action("staffStrike"):
        _fail("Staff Strike succeeded with zero charges")
        return
    if not encounter.take_action("hold") or int(encounter.player["staffCharges"]) != 1:
        _fail("Hold did not restore one staff charge")
        return

    encounter.player["heat"] = {"current": 3, "max": 3}
    encounter.player["vit"] = int(encounter.player["maxVit"]) - 2
    if not encounter.take_action("rest"):
        _fail("Rest rejected")
        return
    var heat: Dictionary = encounter.player["heat"]
    if int(heat["current"]) != 1:
        _fail("Rest heat reduction drifted")
        return
    if int(encounter.player["vit"]) != int(encounter.player["maxVit"]) - 1:
        _fail("Rest vitality restoration drifted")
        return

    # Finish the fixture using only authorized actions, restoring charges via Hold.
    var guard := 0
    while not encounter.completed and guard < 20:
        if int(encounter.player["staffCharges"]) == 0:
            if not encounter.take_action("hold"):
                _fail("Hold failed during completion loop")
                return
        else:
            if not encounter.take_action("staffStrike"):
                _fail("Staff Strike failed during completion loop")
                return
        guard += 1

    if not encounter.completed or int(encounter.target["hp"]) != 0:
        _fail("review target did not complete")
        return
    if encounter.take_action("hold"):
        _fail("completed encounter accepted another turn")
        return

    var snap := encounter.snapshot()
    if not bool(snap["completed"]) or int(snap["turns"]) <= 0:
        _fail("encounter snapshot missing completion state")
        return
    if not encounter.close() or encounter.active:
        _fail("encounter did not close")
        return

    print("AETHERWAKE_GODOT_FORMULA_REVIEW_ENCOUNTER_PASS: production Staff Strike/Uncover Truth/Hold/Rest run through deterministic playable controller")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_FORMULA_REVIEW_ENCOUNTER_FAIL: " + reason)
    quit(1)
