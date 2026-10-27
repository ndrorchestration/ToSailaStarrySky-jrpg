extends RefCounted
## Provisional, noncanonical equipment math for the optional Formula Review
## target ONLY. These numbers are QA fixtures, not final item balance,
## progression, inventory, enemy retaliation, or any character's magic.
##
## The other four starter families remain zero-impact until their
## own authorized combat turns and item permissions are established.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")
const Formula = preload("res://scripts/first_wake_combat_formula.gd")

const VERSION := "0.1.0-review"
const MAX_EQUIPMENT_POWER := 20.0
const FIXTURE_EFFECTS := {
    "ender-staff-inlay-review": {"equipmentPower": 4.0},
    "ender-armor-overlay-review": {"armorDefense": 8.0},
    "ender-charm-review": {"aetherDefense": 6.0},
}
const STAT_KEYS := ["equipmentPower", "armorDefense", "aetherDefense"]

var stat_model = StatModel.new()
var formula = Formula.new()

func bonuses_for(loadout) -> Dictionary:
    if loadout == null or not loadout.validate() or loadout.actor_id != "ender":
        return {}
    var result := {
        "equipmentPower": 0.0,
        "armorDefense": 0.0,
        "aetherDefense": 0.0,
    }
    # Count the currently wielded weapon, not a stowed secondary slot.
    for slot_id in ["mainWeapon", "bodyArmor", "accessory"]:
        var item_id := loadout.item_id_for(slot_id)
        if slot_id == "mainWeapon" and loadout.held_slot != "mainWeapon":
            continue
        var item: Dictionary = loadout.item_for(slot_id)
        if item.is_empty() or str(item.get("owner", "")) != "ender":
            return {}
        if not FIXTURE_EFFECTS.has(item_id):
            continue
        var fixture: Dictionary = FIXTURE_EFFECTS[item_id]
        for key in STAT_KEYS:
            result[key] = float(result[key]) + float(fixture.get(key, 0.0))
    if float(result["equipmentPower"]) > MAX_EQUIPMENT_POWER:
        return {}
    return result

func project(loadout, primary_stats: Dictionary, level: int = 1) -> Dictionary:
    var bonuses := bonuses_for(loadout)
    if bonuses.is_empty() or primary_stats.is_empty() or level < 1:
        return {}
    var baseline := stat_model.derive(primary_stats, level)
    var equipped := stat_model.derive(primary_stats, level, {
        "armorDefense": float(bonuses["armorDefense"]),
        "aetherDefense": float(bonuses["aetherDefense"]),
    })
    var target := {
        "productionDerivedStats": {"aetherDefense": 20, "evasion": 10},
    }
    var plain_actor := {"productionStats": primary_stats}
    var practice_actor := {
        "productionStats": primary_stats,
        "isNoncanonicalEquipmentReview": true,
        "reviewEquipmentPower": float(bonuses["equipmentPower"]),
    }
    var plain := formula.resolve_action("staffStrike", plain_actor, target, _midpoint_rng)
    var practice := formula.resolve_action("staffStrike", practice_actor, target, _midpoint_rng)
    if not bool(plain.get("ok", false)) or not bool(practice.get("ok", false)):
        return {}
    return {
        "status": "noncanonical-training-only",
        "baselineDamage": int(plain["damage"]),
        "equippedDamage": int(practice["damage"]),
        "physicalDefense": int(equipped["physicalDefense"]),
        "physicalDefenseDelta": int(equipped["physicalDefense"]) - int(baseline["physicalDefense"]),
        "aetherDefense": int(equipped["aetherDefense"]),
        "aetherDefenseDelta": int(equipped["aetherDefense"]) - int(baseline["aetherDefense"]),
        "bonuses": bonuses.duplicate(true),
    }

func _midpoint_rng() -> float:
    return 0.5
