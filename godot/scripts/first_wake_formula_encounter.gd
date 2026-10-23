extends RefCounted
## Review-only playable controller around the authorized production formula subset.
## It intentionally does NOT mutate Chapter I progression or claim an authored
## enemy. The target is a formula-training fixture used to exercise native
## action/resource/UI behavior before canonical enemy adapters are admitted.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")
const Formula = preload("res://scripts/first_wake_combat_formula.gd")

const VERSION := "0.2.0"
const TARGET_ID := "formula_review_target"
const TARGET_NAME := "Formula Review Target"
const TARGET_MAX_HP := 26
const TARGET_AETHER_DEFENSE := 20
const TARGET_EVASION := 10
const TARGET_WEAKNESS := "EMP fractures the exposed harmonic seam."

var stat_model = StatModel.new()
var formula = Formula.new()
var rng_source: Callable
var local_rng := RandomNumberGenerator.new()

var active: bool = false
var completed: bool = false
var player_defeated: bool = false
var encounter_kind: String = "formula_review"
var turns: int = 0
var enemy_turns: int = 0
var player: Dictionary = {}
var target: Dictionary = {}
var log: Array[String] = []

func _init(injected_rng: Callable = Callable()) -> void:
    rng_source = injected_rng
    if not rng_source.is_valid():
        local_rng.randomize()
        rng_source = _next_local_rng
    reset()

func _next_local_rng() -> float:
    return local_rng.randf()

func reset() -> void:
    var production_stats := stat_model.get_primary_stats("ender", 1)
    var derived := stat_model.derive(production_stats, 1)
    var max_vit := int(derived.get("maxHp", 1))
    player = {
        "id": "ender",
        "level": 1,
        "productionStats": production_stats,
        "productionDerivedStats": derived,
        "staffCharges": 2,
        "maxStaffCharges": 2,
        "heat": {"current": 1, "max": 3},
        "vit": max_vit,
        "maxVit": max_vit,
    }
    target = {
        "id": TARGET_ID,
        "name": TARGET_NAME,
        "hp": TARGET_MAX_HP,
        "maxHp": TARGET_MAX_HP,
        "weakness": TARGET_WEAKNESS,
        "productionDerivedStats": {
            "aetherDefense": TARGET_AETHER_DEFENSE,
            "evasion": TARGET_EVASION,
        },
        "analysis": {},
    }
    active = false
    completed = false
    player_defeated = false
    encounter_kind = "formula_review"
    turns = 0
    enemy_turns = 0
    log = []

func start() -> bool:
    if active:
        return false
    active = true
    completed = false
    if encounter_kind == "authored_hazard":
        log.append("Crossing encounter started: " + str(target.get("name", "Hazard")) + ".")
    else:
        log.append("Formula review started. Production formulas; noncanonical target.")
    return true

func start_with_target(profile: Dictionary) -> bool:
    if active or not _valid_target_profile(profile):
        return false
    reset()
    encounter_kind = str(profile.get("encounterKind", "configured"))
    target = {
        "id": str(profile.get("id", "")),
        "name": str(profile.get("name", "")),
        "hp": int(profile.get("hp", 0)),
        "maxHp": int(profile.get("maxHp", profile.get("hp", 0))),
        "weakness": str(profile.get("weakness", "")),
        "productionDerivedStats": Dictionary(profile.get("productionDerivedStats", {})).duplicate(true),
        "analysis": {},
        "hazardId": str(profile.get("hazardId", "")),
        "goal": str(profile.get("goal", "")),
        "type": str(profile.get("type", "")),
        "ability": str(profile.get("ability", "")),
        "abilityDesc": str(profile.get("abilityDesc", "")),
        "abilityDamage": int(profile.get("abilityDamage", 0)),
        "abilityKnockback": bool(profile.get("abilityKnockback", false)),
        "bodyShape": str(profile.get("bodyShape", "")),
        "adapterVersion": str(profile.get("adapterVersion", "")),
        "adapterSource": str(profile.get("adapterSource", "")),
    }
    return start()

func _valid_target_profile(profile: Dictionary) -> bool:
    if profile.is_empty():
        return false
    if str(profile.get("id", "")).strip_edges().is_empty():
        return false
    if str(profile.get("name", "")).strip_edges().is_empty():
        return false
    if int(profile.get("hp", 0)) <= 0 or int(profile.get("maxHp", 0)) <= 0:
        return false
    if str(profile.get("weakness", "")).strip_edges().is_empty():
        return false
    if str(profile.get("encounterKind", "")) == "authored_hazard":
        if str(profile.get("ability", "")).strip_edges().is_empty():
            return false
        if int(profile.get("abilityDamage", 0)) <= 0:
            return false
    var derived = profile.get("productionDerivedStats", {})
    if not (derived is Dictionary):
        return false
    return derived.has("aetherDefense") and derived.has("evasion")

func close() -> bool:
    if not active:
        return false
    active = false
    return true

func take_action(action_id: String) -> bool:
    if not active or completed or player_defeated:
        return false
    if action_id not in Formula.AUTHORIZED_FORMULA_ACTIONS:
        return false

    var accepted := false
    match action_id:
        "staffStrike":
            accepted = _staff_strike()
        "uncoverTruth":
            accepted = _uncover_truth()
        "hold":
            accepted = _hold()
        "rest":
            accepted = _rest()

    if accepted and encounter_kind == "authored_hazard" and not completed:
        _resolve_enemy_retaliation()
    return accepted

func _staff_strike() -> bool:
    if int(player.get("staffCharges", 0)) <= 0:
        log.append("Staff Strike unavailable: no staff charges.")
        return false

    var result := formula.resolve_action("staffStrike", player, target, rng_source)
    if not bool(result.get("ok", false)):
        log.append("Staff Strike rejected: " + str(result.get("error", "unknown error")))
        return false

    var cost: Dictionary = result.get("dedicatedCost", {})
    var cost_amount := int(cost.get("amount", 0))
    player["staffCharges"] = maxi(0, int(player["staffCharges"]) - cost_amount)

    var damage := int(result.get("damage", 0))
    target["hp"] = maxi(0, int(target["hp"]) - damage)

    if bool(result.get("consumedAnalysis", false)):
        var analysis: Dictionary = target.get("analysis", {})
        var charges := maxi(0, int(analysis.get("charges", 0)) - 1)
        if charges == 0:
            target["analysis"] = {}
        else:
            analysis["charges"] = charges
            target["analysis"] = analysis

    turns += 1
    var suffix := " CRITICAL" if bool(result.get("critical", false)) else ""
    log.append("Staff Strike: %d damage%s." % [damage, suffix])

    if int(target["hp"]) == 0:
        completed = true
        if encounter_kind == "authored_hazard":
            log.append(str(target.get("name", "Hazard")) + " cleared.")
        else:
            log.append("Formula review target cleared.")
    return true

func _uncover_truth() -> bool:
    var result := formula.resolve_action("uncoverTruth", player, target)
    if not bool(result.get("ok", false)):
        log.append("Uncover Truth rejected: " + str(result.get("error", "unknown error")))
        return false
    target["analysis"] = Dictionary(result.get("modifier", {})).duplicate(true)
    turns += 1
    log.append("Uncover Truth: " + str(result.get("weakness", "No weakness exposed.")))
    return true

func _hold() -> bool:
    var result := formula.resolve_action("hold", player)
    if not bool(result.get("ok", false)):
        return false
    var delta := int(round(float(result.get("delta", 0.0))))
    player["staffCharges"] = mini(int(player["maxStaffCharges"]), int(player["staffCharges"]) + delta)
    turns += 1
    log.append("Hold: +%d staff charge." % delta)
    return true

func _rest() -> bool:
    var result := formula.resolve_action("rest", player)
    if not bool(result.get("ok", false)):
        return false

    var heat: Dictionary = player.get("heat", {"current": 0, "max": 3})
    heat["current"] = maxi(0, int(heat.get("current", 0)) - int(round(float(result.get("heatReduction", 0.0)))))
    player["heat"] = heat
    player["vit"] = mini(
        int(player["maxVit"]),
        int(player["vit"]) + int(round(float(result.get("vitalityRestore", 0.0))))
    )
    turns += 1
    log.append("Rest: heat %d / %d, VIT %d / %d." % [
        int(heat["current"]),
        int(heat.get("max", 3)),
        int(player["vit"]),
        int(player["maxVit"]),
    ])
    return true

func _resolve_enemy_retaliation() -> bool:
    if encounter_kind != "authored_hazard" or completed or player_defeated:
        return false
    var damage := int(target.get("abilityDamage", 0))
    var ability_id := str(target.get("ability", ""))
    if damage <= 0 or ability_id.is_empty():
        log.append("Enemy retaliation unavailable; authored metadata is incomplete.")
        return false

    player["vit"] = maxi(0, int(player.get("vit", 0)) - damage)
    enemy_turns += 1
    var ability_label := "Gale Force" if ability_id == "galeForce" else ability_id
    log.append("%s: %d damage." % [ability_label, damage])

    if int(player["vit"]) == 0:
        player_defeated = true
        log.append("Ender is down. Close the encounter; Crossing progress remains unchanged.")
    return true

func last_log() -> String:
    if log.is_empty():
        return ""
    return log[log.size() - 1]

func weakness_revealed() -> bool:
    var analysis: Dictionary = target.get("analysis", {})
    return int(analysis.get("charges", 0)) > 0

func snapshot() -> Dictionary:
    return {
        "version": VERSION,
        "active": active,
        "completed": completed,
        "playerDefeated": player_defeated,
        "encounterKind": encounter_kind,
        "turns": turns,
        "enemyTurns": enemy_turns,
        "player": player.duplicate(true),
        "target": target.duplicate(true),
        "log": log.duplicate(),
    }
