extends RefCounted
## Native port of Aetherwake's approved production JRPG stat model.
## Source parity target: modules/jrpg-stat-model.js v0.1.0.
## No player-facing dice or PbtA outcome bands; RNG remains injected/bounded.

const VERSION := "0.1.0"
const LEVEL_MIN := 1
const LEVEL_CAP := 175
const PRIMARY_MIN := 1
const PRIMARY_SOFT_CAP := 60
const PRIMARY_HARD_CAP := 75
const LEVEL_ONE_BASELINE_BUDGET := 25

const PRIMARY_STATS: Array[String] = [
    "might",
    "grace",
    "wits",
    "spirit",
    "presence",
]

const PROFILES := {
    "ender": {
        "role": "analyst-controller",
        "level1": {"might": 3, "grace": 4, "wits": 8, "spirit": 12, "presence": 4},
        "capstone": {"might": 22, "grace": 30, "wits": 60, "spirit": 42, "presence": 36},
    },
    "lyra": {
        "role": "perceptive-support",
        "level1": {"might": 2, "grace": 6, "wits": 5, "spirit": 9, "presence": 3},
        "capstone": {"might": 18, "grace": 42, "wits": 36, "spirit": 66, "presence": 30},
    },
    "ionia": {
        "role": "captain-support",
        "level1": {"might": 5, "grace": 5, "wits": 4, "spirit": 3, "presence": 9},
        "capstone": {"might": 40, "grace": 36, "wits": 30, "spirit": 24, "presence": 60},
    },
    "reson": {
        "role": "durable-weapon-specialist",
        "level1": {"might": 9, "grace": 4, "wits": 3, "spirit": 4, "presence": 5},
        "capstone": {"might": 68, "grace": 34, "wits": 24, "spirit": 34, "presence": 40},
    },
    "aepex": {
        "role": "technical-specialist",
        "level1": {"might": 4, "grace": 5, "wits": 9, "spirit": 3, "presence": 4},
        "capstone": {"might": 32, "grace": 40, "wits": 64, "spirit": 28, "presence": 36},
    },
}

const POLICY := {
    "damage_variance_min": 0.95,
    "damage_variance_max": 1.05,
    "critical_multiplier": 1.5,
    "default_crit_rate": 0.05,
    "crit_rate_min": 0.0,
    "crit_rate_max": 0.5,
    "default_accuracy": 0.95,
    "hit_chance_min": 0.6,
    "hit_chance_max": 0.995,
    "status_chance_min": 0.05,
    "status_chance_max": 0.95,
    "defense_constant": 100.0,
    "defense_weight": 1.5,
    "min_damage": 1,
}

func normalize_level(level_value) -> int:
    var n := LEVEL_MIN
    if level_value is int or level_value is float:
        n = int(floor(float(level_value)))
    return clampi(n, LEVEL_MIN, LEVEL_CAP)

func normalize_primary(value) -> float:
    var n := float(PRIMARY_MIN)
    if value is int or value is float:
        n = float(value)
    return clampf(n, float(PRIMARY_MIN), float(PRIMARY_HARD_CAP))

func growth_progress(level_value) -> float:
    var level := normalize_level(level_value)
    var t := float(level - LEVEL_MIN) / float(LEVEL_CAP - LEVEL_MIN)
    return pow(t, 1.08)

func get_profile(character_id: String) -> Dictionary:
    if not PROFILES.has(character_id):
        return {}
    return Dictionary(PROFILES[character_id]).duplicate(true)

func get_primary_stats(character_id: String, level_value) -> Dictionary:
    var profile := get_profile(character_id)
    if profile.is_empty():
        push_error("UNKNOWN_CHARACTER_PROFILE:" + character_id)
        return {}
    var progress := growth_progress(level_value)
    var result := {}
    var level_one: Dictionary = profile["level1"]
    var capstone: Dictionary = profile["capstone"]
    for stat in PRIMARY_STATS:
        var start := float(level_one[stat])
        var finish := float(capstone[stat])
        result[stat] = int(round(normalize_primary(round(start + (finish - start) * progress))))
    return result

func derive(stats: Dictionary, level_value, equipment: Dictionary = {}) -> Dictionary:
    var normalized := {}
    for key in PRIMARY_STATS:
        normalized[key] = normalize_primary(stats.get(key, PRIMARY_MIN))
    var level := normalize_level(level_value)
    var armor := float(equipment.get("armorDefense", 0))
    var ward := float(equipment.get("aetherDefense", 0))
    var accuracy_bonus := float(equipment.get("accuracy", 0))
    var evasion_bonus := float(equipment.get("evasion", 0))
    var weapon_attack := float(equipment.get("weaponAttack", 0))
    var tech_power := float(equipment.get("techPower", 0))
    var support_power := float(equipment.get("supportPower", 0))

    return {
        "maxHp": int(round(45.0 + float(level) * 4.5 + normalized["might"] * 7.0 + normalized["spirit"] * 2.5)),
        "physicalAttack": int(round(normalized["might"] * 2.0 + normalized["grace"] * 0.35 + weapon_attack)),
        "aetherAttack": int(round(normalized["spirit"] * 1.8 + normalized["wits"] * 0.65)),
        "technicalPower": int(round(normalized["wits"] * 2.0 + normalized["grace"] * 0.25 + tech_power)),
        "supportPotency": int(round(normalized["presence"] * 1.65 + normalized["spirit"] * 0.65 + support_power)),
        "physicalDefense": int(round(normalized["might"] * 1.25 + normalized["grace"] * 0.25 + armor)),
        "aetherDefense": int(round(normalized["spirit"] * 1.25 + normalized["presence"] * 0.35 + ward)),
        "accuracy": int(round(70.0 + normalized["wits"] * 0.85 + normalized["grace"] * 0.35 + accuracy_bonus)),
        "evasion": int(round(normalized["grace"] * 0.8 + normalized["wits"] * 0.2 + evasion_bonus)),
        "initiative": int(round(normalized["grace"] * 1.5 + normalized["wits"] * 0.5)),
        "breakPower": int(round(normalized["might"] * 1.45 + normalized["wits"] * 0.2)),
        "resolve": int(round(normalized["spirit"] * 0.9 + normalized["presence"] * 0.9)),
        "critRate": clampf(
            float(POLICY["default_crit_rate"]) + (normalized["grace"] + normalized["wits"]) * 0.0008,
            float(POLICY["crit_rate_min"]),
            float(POLICY["crit_rate_max"])
        ),
    }

func defense_multiplier(defense_value) -> float:
    var defense := maxf(0.0, float(defense_value))
    return float(POLICY["defense_constant"]) / (
        float(POLICY["defense_constant"]) + defense * float(POLICY["defense_weight"])
    )

func variance_multiplier(rng_value) -> float:
    var rng := clampf(float(rng_value), 0.0, 0.999999)
    return float(POLICY["damage_variance_min"]) + (
        float(POLICY["damage_variance_max"]) - float(POLICY["damage_variance_min"])
    ) * rng

func resolve_damage(input: Dictionary) -> Dictionary:
    if not input.has("attacker") or not (input["attacker"] is Dictionary):
        push_error("DAMAGE_ATTACKER_REQUIRED")
        return {}
    var attacker: Dictionary = input["attacker"]
    var scaling_stat := str(input.get("scalingStat", "might"))
    var stat_value := normalize_primary(attacker.get(scaling_stat, PRIMARY_MIN))
    var power := maxf(0.0, float(input.get("power", 0)))
    var scaling := maxf(0.0, float(input.get("scaling", 1)))
    var equipment_power := maxf(0.0, float(input.get("equipmentPower", 0)))
    var defense := maxf(0.0, float(input.get("defense", 0)))
    var element_multiplier := maxf(0.0, float(input.get("elementMultiplier", 1)))
    var situational_multiplier := maxf(0.0, float(input.get("situationalMultiplier", 1)))
    var variance := 1.0
    if bool(input.get("allowVariance", true)):
        variance = variance_multiplier(input.get("varianceRng", 0.5))
    var crit_rate := clampf(
        float(input.get("critRate", POLICY["default_crit_rate"])),
        float(POLICY["crit_rate_min"]),
        float(POLICY["crit_rate_max"])
    )
    var crit_rng := clampf(float(input.get("critRng", 0.999999)), 0.0, 0.999999)
    var critical := bool(input.get("canCrit", true)) and crit_rng < crit_rate
    var critical_multiplier := float(POLICY["critical_multiplier"]) if critical else 1.0

    var pre_defense := (
        power + stat_value * scaling + equipment_power
    ) * variance * critical_multiplier * element_multiplier * situational_multiplier
    var damage := maxi(
        int(POLICY["min_damage"]),
        int(round(pre_defense * defense_multiplier(defense)))
    )
    return {
        "damage": damage,
        "critical": critical,
        "statValue": stat_value,
        "variance": variance,
        "defenseMultiplier": defense_multiplier(defense),
        "preDefense": pre_defense,
    }

func resolve_healing(input: Dictionary) -> int:
    if not input.has("actor") or not (input["actor"] is Dictionary):
        push_error("HEAL_ACTOR_REQUIRED")
        return 0
    var actor: Dictionary = input["actor"]
    var scaling_stat := str(input.get("scalingStat", "presence"))
    var stat_value := normalize_primary(actor.get(scaling_stat, PRIMARY_MIN))
    var power := maxf(0.0, float(input.get("power", 0)))
    var scaling := maxf(0.0, float(input.get("scaling", 1)))
    var support_bonus := maxf(0.0, float(input.get("supportBonus", 0)))
    var situational := maxf(0.0, float(input.get("situationalMultiplier", 1)))
    return maxi(0, int(round((power + stat_value * scaling + support_bonus) * situational)))

func resolve_hit_chance(input: Dictionary) -> float:
    var base := float(input.get("baseAccuracy", POLICY["default_accuracy"]))
    var attacker_accuracy := float(input.get("attackerAccuracy", 0))
    var defender_evasion := float(input.get("defenderEvasion", 0))
    return clampf(
        base + (attacker_accuracy - defender_evasion) * 0.005,
        float(POLICY["hit_chance_min"]),
        float(POLICY["hit_chance_max"])
    )

func resolve_status_chance(input: Dictionary) -> float:
    var base := float(input.get("baseChance", 0.5))
    var potency := float(input.get("potency", 0))
    var target_resolve := float(input.get("resolve", 0))
    return clampf(
        base + (potency - target_resolve) * 0.005,
        float(POLICY["status_chance_min"]),
        float(POLICY["status_chance_max"])
    )

func resolve_break_damage(input: Dictionary) -> int:
    var attack := maxf(0.0, float(input.get("breakPower", 0)))
    var resistance := maxf(0.0, float(input.get("breakResistance", 0)))
    var power := maxf(0.0, float(input.get("power", 1)))
    return maxi(0, int(round(attack * power - resistance * 0.5)))

func validate() -> bool:
    for character_id in PROFILES.keys():
        var profile: Dictionary = PROFILES[character_id]
        var level_one: Dictionary = profile["level1"]
        var capstone: Dictionary = profile["capstone"]
        var budget := 0
        for stat in PRIMARY_STATS:
            budget += int(level_one[stat])
            if int(level_one[stat]) < PRIMARY_MIN:
                return false
            if int(capstone[stat]) > PRIMARY_HARD_CAP:
                return false
            if int(capstone[stat]) < int(level_one[stat]):
                return false
        if budget < LEVEL_ONE_BASELINE_BUDGET:
            return false
    if float(POLICY["damage_variance_min"]) < 0.9 or float(POLICY["damage_variance_max"]) > 1.1:
        return false
    if float(POLICY["critical_multiplier"]) > 2.0:
        return false
    return true
