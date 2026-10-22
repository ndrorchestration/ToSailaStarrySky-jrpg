extends SceneTree
## Parity checks for the authorized native JRPG formula subset.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")
const Formula = preload("res://scripts/first_wake_combat_formula.gd")

class Sequence:
    extends RefCounted
    var values: Array
    var index: int = 0

    func _init(next_values: Array) -> void:
        values = next_values.duplicate()

    func next():
        if index >= values.size():
            return 1.0
        var value = values[index]
        index += 1
        return value

func _initialize() -> void:
    var stat_model = StatModel.new()
    var formula = Formula.new()
    if Formula.VERSION != "1.1.0" or not formula.validate():
        _fail("formula version or validation drifted")
        return
    if Formula.AUTHORIZED_FORMULA_ACTIONS != ["staffStrike", "uncoverTruth", "hold", "rest"]:
        _fail("authorized formula action set drifted")
        return
    for blocked_id in ["sharedDream", "windWard", "mycelialLedger", "aetherSeal"]:
        if Formula.FORMULAS.has(blocked_id):
            _fail("blocked/separate action leaked into formula authority: " + blocked_id)
            return

    var actor := {
        "productionStats": {"might":3, "grace":4, "wits":8, "spirit":12, "presence":4},
        "productionDerivedStats": stat_model.derive(
            {"might":3, "grace":4, "wits":8, "spirit":12, "presence":4}, 1
        ),
        "staffCharges": 2,
        "maxStaffCharges": 2,
        "heat": {"current":2, "max":3},
        "vit": 10,
        "maxVit": 13,
    }
    var target := {
        "productionDerivedStats": {
            "aetherDefense": 20,
            "evasion": 10,
        },
    }

    var normal_rng := Sequence.new([0.5, 0.99])
    var normal := formula.resolve_action("staffStrike", actor, target, normal_rng.next)
    if not bool(normal.get("ok", false)) or not bool(normal["hit"]) or bool(normal["critical"]):
        _fail("normal Staff Strike resolution drifted")
        return
    if int(normal["damage"]) != 6 or int(normal["scalingValue"]) != 3:
        _fail("normal Staff Strike numeric parity drifted")
        return
    if str(normal["defenseStat"]) != "aetherDefense":
        _fail("Staff Strike defense binding drifted")
        return

    var critical_rng := Sequence.new([0.5, 0.01])
    var critical := formula.resolve_action("staffStrike", actor, target, critical_rng.next)
    if not bool(critical.get("ok", false)) or not bool(critical["critical"]) or int(critical["damage"]) <= int(normal["damage"]):
        _fail("critical Staff Strike parity drifted")
        return

    var analysis := formula.resolve_action(
        "uncoverTruth",
        actor,
        {"weakness":"EMP fractures the exposed harmonic seam."}
    )
    if not bool(analysis.get("ok", false)) or str(analysis["weakness"]) != "EMP fractures the exposed harmonic seam.":
        _fail("Uncover Truth weakness reveal drifted")
        return
    var modifier: Dictionary = analysis["modifier"]
    if not is_equal_approx(float(modifier["nextDamageMultiplier"]), 1.15) or int(modifier["charges"]) != 1:
        _fail("Uncover Truth modifier drifted")
        return

    var analyzed_target := {
        "productionDerivedStats": {"aetherDefense":20, "evasion":10},
        "analysis": {"nextDamageMultiplier":1.15, "charges":1},
    }
    var analyzed_rng := Sequence.new([0.5, 0.99])
    var analyzed := formula.resolve_action("staffStrike", actor, analyzed_target, analyzed_rng.next)
    if not bool(analyzed.get("ok", false)) or not bool(analyzed["consumedAnalysis"]):
        _fail("analyzed Staff Strike did not consume analysis")
        return
    if not is_equal_approx(float(analyzed["analysisMultiplier"]), 1.15) or int(analyzed["damage"]) <= int(normal["damage"]):
        _fail("analyzed Staff Strike multiplier parity drifted")
        return

    var hold := formula.resolve_action("hold", {"staffCharges":1, "maxStaffCharges":2})
    if not bool(hold.get("ok", false)) or not is_equal_approx(float(hold["delta"]), 1.0):
        _fail("Hold resource parity drifted")
        return

    var rest := formula.resolve_action("rest", actor)
    if not bool(rest.get("ok", false)) or not is_equal_approx(float(rest["heatReduction"]), 2.0) or not is_equal_approx(float(rest["vitalityRestore"]), 1.0):
        _fail("Rest recovery parity drifted")
        return

    var invalid_rng := Sequence.new([1.0])
    var rejected := formula.resolve_action("staffStrike", actor, target, invalid_rng.next)
    if bool(rejected.get("ok", true)) or str(rejected.get("error", "")) != "COMBAT_FORMULA_RANDOM_OUT_OF_RANGE":
        _fail("out-of-range RNG did not fail closed")
        return

    var missing_rng := formula.resolve_action("staffStrike", actor, target)
    if bool(missing_rng.get("ok", true)) or str(missing_rng.get("error", "")) != "COMBAT_FORMULA_RANDOM_REQUIRED":
        _fail("missing RNG did not fail closed")
        return

    var blocked := formula.resolve_action("sharedDream", actor)
    if bool(blocked.get("ok", true)) or not str(blocked.get("error", "")).begins_with("COMBAT_FORMULA_UNKNOWN_ACTION"):
        _fail("blocked Shared Dream leaked into native formula authority")
        return

    print("AETHERWAKE_GODOT_COMBAT_FORMULA_PASS: Staff Strike, Uncover Truth, Hold, Rest and fail-closed RNG/SSOT guards")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_COMBAT_FORMULA_FAIL: " + reason)
    quit(1)
