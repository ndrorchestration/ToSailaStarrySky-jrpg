extends RefCounted
## Native port of the authorized production formula subset.
## Parity target: modules/combat-formula.js v1.1.0 + ability-defs SSOT guards.
## Only generic jrpg-stat-formula actions are implemented here. Shared Dream
## and Wind Ward remain blocked; Commons/Aether-Seal remain separate contracts.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")

const VERSION := "1.1.0"
const AUTHORIZED_FORMULA_ACTIONS: Array[String] = [
    "staffStrike",
    "uncoverTruth",
    "hold",
    "rest",
]

const FORMULAS := {
    "staffStrike": {
        "id": "staffStrike",
        "model": "jrpg-stat-formula",
        "kind": "damage",
        "damageType": "emp",
        "power": 5,
        "scalingStat": "might",
        "scaling": 1.0,
        "defenseStat": "aetherDefense",
        "criticalChance": 0.10,
        "boundedVariance": true,
        "dedicatedCost": {"resource": "staffCharges", "amount": 1},
    },
    "uncoverTruth": {
        "id": "uncoverTruth",
        "model": "jrpg-stat-formula",
        "kind": "analysis",
        "reveal": "weakness",
        "nextDamageMultiplier": 1.15,
        "charges": 1,
    },
    "hold": {
        "id": "hold",
        "model": "jrpg-stat-formula",
        "kind": "resource",
        "resource": "staffCharges",
        "amount": 1,
        "maxResource": "maxStaffCharges",
    },
    "rest": {
        "id": "rest",
        "model": "jrpg-stat-formula",
        "kind": "recovery",
        "heatReduction": 2,
        "vitalityRestore": 1,
    },
}

var stat_model = StatModel.new()

func get_formula(action_id: String) -> Dictionary:
    if not FORMULAS.has(action_id):
        return {}
    return Dictionary(FORMULAS[action_id]).duplicate(true)

func resolve_action(action_id: String, actor: Dictionary, target: Dictionary = {}, rng_fn: Callable = Callable()) -> Dictionary:
    if not FORMULAS.has(action_id):
        return _error("COMBAT_FORMULA_UNKNOWN_ACTION:" + action_id)
    var formula: Dictionary = FORMULAS[action_id]
    match str(formula["kind"]):
        "damage":
            return _resolve_damage(action_id, actor, target, rng_fn)
        "analysis":
            return _resolve_analysis(action_id, target)
        "resource":
            return _resolve_resource(action_id, actor)
        "recovery":
            return _resolve_recovery(action_id, actor)
    return _error("COMBAT_FORMULA_KIND_NOT_RESOLVABLE:" + str(formula["kind"]))

func _resolve_damage(action_id: String, actor: Dictionary, target: Dictionary, rng_fn: Callable) -> Dictionary:
    if not rng_fn.is_valid():
        return _error("COMBAT_FORMULA_RANDOM_REQUIRED")
    var formula: Dictionary = FORMULAS[action_id]
    var variance_read := _next_random(rng_fn)
    if not bool(variance_read["ok"]):
        return variance_read
    var crit_read := _next_random(rng_fn)
    if not bool(crit_read["ok"]):
        return crit_read

    var primary: Dictionary = actor.get("productionStats", actor)
    var derived: Dictionary = target.get("productionDerivedStats", target)
    var defense := float(derived.get(str(formula["defenseStat"]), 0))
    var analysis_multiplier := 1.0
    var analysis: Dictionary = target.get("analysis", {})
    if int(analysis.get("charges", 0)) > 0:
        analysis_multiplier = float(analysis.get("nextDamageMultiplier", 1.0))

    var result := stat_model.resolve_damage({
        "attacker": primary,
        "scalingStat": str(formula["scalingStat"]),
        "power": float(formula["power"]),
        "scaling": float(formula["scaling"]),
        "defense": defense,
        "allowVariance": bool(formula["boundedVariance"]),
        "varianceRng": float(variance_read["value"]),
        "canCrit": true,
        "critRate": float(formula["criticalChance"]),
        "critRng": float(crit_read["value"]),
        "situationalMultiplier": analysis_multiplier,
    })
    if result.is_empty():
        return _error("COMBAT_FORMULA_DAMAGE_RESOLUTION_FAILED")

    return {
        "ok": true,
        "actionId": action_id,
        "model": str(formula["model"]),
        "kind": str(formula["kind"]),
        "damageType": str(formula["damageType"]),
        "hit": true,
        "hitChance": 1.0,
        "accuracyRoll": null,
        "damage": int(result["damage"]),
        "critical": bool(result["critical"]),
        "scalingStat": str(formula["scalingStat"]),
        "scalingValue": float(primary.get(str(formula["scalingStat"]), StatModel.PRIMARY_MIN)),
        "defenseStat": str(formula["defenseStat"]),
        "defenseValue": defense,
        "defenseMultiplier": float(result["defenseMultiplier"]),
        "varianceMultiplier": float(result["variance"]),
        "dedicatedCost": Dictionary(formula["dedicatedCost"]).duplicate(true),
        "consumedAnalysis": analysis_multiplier > 1.0,
        "analysisMultiplier": analysis_multiplier,
    }

func _resolve_analysis(action_id: String, target: Dictionary) -> Dictionary:
    var formula: Dictionary = FORMULAS[action_id]
    return {
        "ok": true,
        "actionId": action_id,
        "model": str(formula["model"]),
        "kind": str(formula["kind"]),
        "reveal": str(formula["reveal"]),
        "weakness": target.get("weakness", null),
        "modifier": {
            "key": "analyzed",
            "nextDamageMultiplier": float(formula["nextDamageMultiplier"]),
            "charges": int(formula["charges"]),
        },
    }

func _resolve_resource(action_id: String, actor: Dictionary) -> Dictionary:
    var formula: Dictionary = FORMULAS[action_id]
    var current := maxf(0.0, _current_resource(actor, str(formula["resource"]), 0.0))
    var maximum := maxf(current, _current_resource(actor, str(formula["maxResource"]), current))
    var requested := maxf(0.0, float(formula["amount"]))
    var delta := maxf(0.0, minf(requested, maximum - current))
    return {
        "ok": true,
        "actionId": action_id,
        "model": str(formula["model"]),
        "kind": str(formula["kind"]),
        "resource": str(formula["resource"]),
        "requestedAmount": requested,
        "delta": delta,
        "current": current,
        "max": maximum,
        "capped": delta < requested,
    }

func _resolve_recovery(action_id: String, actor: Dictionary) -> Dictionary:
    var formula: Dictionary = FORMULAS[action_id]
    var heat := maxf(0.0, _current_resource(actor, "heat", 0.0))
    var vitality := maxf(0.0, _current_resource(actor, "vit", 0.0))
    var max_vitality := maxf(vitality, _current_resource(actor, "maxVit", vitality))
    return {
        "ok": true,
        "actionId": action_id,
        "model": str(formula["model"]),
        "kind": str(formula["kind"]),
        "heatReduction": minf(float(formula["heatReduction"]), heat),
        "vitalityRestore": minf(float(formula["vitalityRestore"]), maxf(0.0, max_vitality - vitality)),
        "heatBefore": heat,
        "vitalityBefore": vitality,
        "vitalityMax": max_vitality,
    }

func _current_resource(actor: Dictionary, key: String, fallback: float) -> float:
    if not actor.has(key):
        return fallback
    var value = actor[key]
    if value is int or value is float:
        return float(value)
    if value is Dictionary:
        return float(value.get("current", fallback))
    return fallback

func _next_random(rng_fn: Callable) -> Dictionary:
    var value = rng_fn.call()
    if not (value is int or value is float):
        return _error("COMBAT_FORMULA_RANDOM_OUT_OF_RANGE")
    var numeric := float(value)
    if numeric < 0.0 or numeric >= 1.0 or is_nan(numeric) or is_inf(numeric):
        return _error("COMBAT_FORMULA_RANDOM_OUT_OF_RANGE")
    return {"ok": true, "value": numeric}

func _error(code: String) -> Dictionary:
    return {"ok": false, "error": code}

func validate() -> bool:
    if VERSION != "1.1.0":
        return false
    if AUTHORIZED_FORMULA_ACTIONS != ["staffStrike", "uncoverTruth", "hold", "rest"]:
        return false
    for action_id in AUTHORIZED_FORMULA_ACTIONS:
        if not FORMULAS.has(action_id):
            return false
        if str(FORMULAS[action_id]["model"]) != "jrpg-stat-formula":
            return false
    for blocked_id in ["sharedDream", "windWard", "mycelialLedger", "aetherSeal"]:
        if FORMULAS.has(blocked_id):
            return false
    return stat_model.validate()
