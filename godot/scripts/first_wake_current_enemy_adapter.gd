extends RefCounted
## Fail-closed bridge from current live enemy metadata into the native JRPG
## formula target shape. Only story-facing mappings that still match current
## Chapter I semantics are admitted.
##
## Source authority for Wind Shear:
## - aetherwake.js live enemy id: windShear
## - current Chapter I hazard id: wind_shear
## - current Chapter I hazard label: Wind Shear
##
## The renamed sky_predator -> Loose Cargo Sweep and corporate_intercept ->
## Dock Authority Hold are deliberately NOT mapped to combat here.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")

const VERSION := "0.2.0"
const ADAPTER_SOURCE := "aetherwake.js/current-live-enemy-metadata"

const HAZARD_TO_ENEMY := {
    "wind_shear": "windShear",
}

const CURRENT_ENEMIES := {
    "windShear": {
        "name": "Harmonic Shear Elemental",
        "goal": "Tear across the berth — harmonic shear strips stability from every exposed hull.",
        "hp": 14,
        "maxHp": 14,
        "might": 2,
        "presence": 0,
        "grace": 0,
        "wits": 1,
        "weakness": "Uncover Truth reveals the wind pattern — exposing it to EMP.",
        "status": "howling",
        "type": "windShear",
        "ability": "galeForce",
        "abilityDesc": "Gale Force — 2 damage, knocks you back",
        "abilityDamage": 2,
        "abilityKnockback": true,
        "color": "scioto",
        "bodyShape": "elemental",
    },
}

var stat_model = StatModel.new()

func supports_hazard(hazard_id: String) -> bool:
    return HAZARD_TO_ENEMY.has(hazard_id)

func enemy_id_for_hazard(hazard_id: String) -> String:
    return str(HAZARD_TO_ENEMY.get(hazard_id, ""))

func target_for_hazard(hazard_id: String) -> Dictionary:
    var enemy_id := enemy_id_for_hazard(hazard_id)
    if enemy_id.is_empty():
        return {}
    return target_for_enemy(enemy_id, hazard_id)

func target_for_enemy(enemy_id: String, hazard_id: String = "") -> Dictionary:
    if not CURRENT_ENEMIES.has(enemy_id):
        return {}

    var source: Dictionary = CURRENT_ENEMIES[enemy_id]
    var legacy_primary := {
        "might": int(source.get("might", 0)),
        "grace": int(source.get("grace", 0)),
        "wits": int(source.get("wits", 0)),
        "spirit": int(source.get("spirit", 0)),
        "presence": int(source.get("presence", 0)),
    }

    # The production stat model has a minimum primary value of 1. Preserve the
    # live legacy values as provenance, then normalize them through that model
    # rather than inventing separate defense/evasion constants.
    var production_primary := {}
    for stat in StatModel.PRIMARY_STATS:
        production_primary[stat] = int(stat_model.normalize_primary(legacy_primary.get(stat, 0)))

    var derived := stat_model.derive(production_primary, 1)
    if derived.is_empty():
        return {}

    return {
        "id": enemy_id,
        "hazardId": hazard_id,
        "name": str(source.get("name", enemy_id)),
        "goal": str(source.get("goal", "")),
        "hp": int(source.get("hp", 1)),
        "maxHp": int(source.get("maxHp", source.get("hp", 1))),
        "weakness": str(source.get("weakness", "")),
        "status": str(source.get("status", "")),
        "type": str(source.get("type", enemy_id)),
        "ability": str(source.get("ability", "")),
        "abilityDesc": str(source.get("abilityDesc", "")),
        "abilityDamage": int(source.get("abilityDamage", 0)),
        "abilityKnockback": bool(source.get("abilityKnockback", false)),
        "bodyShape": str(source.get("bodyShape", "")),
        "legacyPrimaryStats": legacy_primary.duplicate(true),
        "productionPrimaryStats": production_primary.duplicate(true),
        "productionDerivedStats": {
            "aetherDefense": int(derived.get("aetherDefense", 0)),
            "evasion": int(derived.get("evasion", 0)),
        },
        "encounterKind": "authored_hazard",
        "adapterVersion": VERSION,
        "adapterSource": ADAPTER_SOURCE,
    }

func validate_target(profile: Dictionary) -> bool:
    if profile.is_empty():
        return false
    if str(profile.get("encounterKind", "")) != "authored_hazard":
        return false
    if str(profile.get("adapterVersion", "")) != VERSION:
        return false
    if str(profile.get("adapterSource", "")) != ADAPTER_SOURCE:
        return false
    if not CURRENT_ENEMIES.has(str(profile.get("id", ""))):
        return false
    if not supports_hazard(str(profile.get("hazardId", ""))):
        return false
    if int(profile.get("hp", 0)) <= 0 or int(profile.get("maxHp", 0)) <= 0:
        return false
    if str(profile.get("name", "")).strip_edges().is_empty():
        return false
    if str(profile.get("weakness", "")).strip_edges().is_empty():
        return false
    if str(profile.get("ability", "")).strip_edges().is_empty():
        return false
    if int(profile.get("abilityDamage", 0)) <= 0:
        return false
    if not bool(profile.get("abilityKnockback", false)):
        return false
    var derived = profile.get("productionDerivedStats", {})
    if not (derived is Dictionary):
        return false
    if not derived.has("aetherDefense") or not derived.has("evasion"):
        return false
    return true
