extends SceneTree
## Read-only cohesion gate. Flags SSOT conflicts without changing gameplay.
const Stats = preload("res://scripts/jrpg_stat_model.gd")
const Combat = preload("res://scripts/first_wake_party_combat_authority.gd")
const Abilities = preload("res://scripts/combat_ability_contract.gd")
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Roster = preload("res://scripts/first_wake_resonance_roster_gate.gd")
var faults: Array[String] = []

func _initialize() -> void:
    call_deferred("_audit")

func _audit() -> void:
    var stats = Stats.new()
    var combat = Combat.new()
    var abilities = Abilities.new()
    var roster = Roster.new()
    if not combat.validate():
        faults.append("combat metadata does not meet its current source contract")
    var actor_ids: Array[String] = ["ender", "ionia", "lyra", "reson", "aepex"]
    for actor_id in actor_ids:
        var profile: Dictionary = stats.get_profile(actor_id)
        if profile.is_empty():
            faults.append("missing Five Lights profile: " + actor_id)
            continue
        for level in [1, 50, Stats.LEVEL_CAP]:
            var primary: Dictionary = stats.get_primary_stats(actor_id, level)
            var derived: Dictionary = stats.derive(primary, level)
            for stat_id in Stats.PRIMARY_STATS:
                var v: float = float(primary.get(stat_id, -1))
                if v < Stats.PRIMARY_MIN or v > Stats.PRIMARY_HARD_CAP:
                    faults.append("primary stat out of bounds: " + actor_id + "/" + stat_id)
            if int(derived.get("maxHp", 0)) <= 0:
                faults.append("derived HP not positive: " + actor_id)
    for action_id in ["staffStrike", "uncoverTruth", "hold", "rest"]:
        var definition: Dictionary = abilities.for_formula(action_id)
        if definition.is_empty() or definition.get("canExecute", true):
            faults.append("ability metadata must not grant combat: " + action_id)
    for action_id in ["sharedDream", "windWard"]:
        if combat.can_use_formula_action("ender", action_id):
            faults.append("blocked magic exposed as executable: " + action_id)
    var opening = Opening.new()
    var snapshot: Dictionary = opening.snapshot()
    if snapshot.get("active_party_ids", []) != ["ender"]:
        faults.append("First Wake must begin with Ender only")
    var early: Dictionary = roster.evaluate(opening, ["ender", "lyra"])
    if early.get("rosterEligible", true) or early.get("canExecute", true):
        faults.append("future party member granted in First Wake opening")
    if combat.CURRENT_CROSSING_PARTY != ["ender", "lyra"]:
        faults.append("legacy combat crossing contract unexpectedly changed")
    if faults.is_empty():
        print("TSTSS_CH1_COHESION_PASS actors=5 formulas=4 grant=false visual_authority=false")
        quit(0)
    else:
        for fault in faults:
            push_error("TSTSS_CH1_COHESION_FAIL: " + fault)
        quit(1)
