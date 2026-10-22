extends SceneTree
## Parity checks for the native production JRPG stat model.

const StatModel = preload("res://scripts/jrpg_stat_model.gd")

func _initialize() -> void:
    var model = StatModel.new()
    if StatModel.VERSION != "0.1.0" or not model.validate():
        _fail("model version or validation drifted")
        return
    if StatModel.LEVEL_CAP != 175 or StatModel.PRIMARY_HARD_CAP != 75:
        _fail("level/stat caps drifted")
        return

    var ids := ["ender", "lyra", "ionia", "reson", "aepex"]
    for character_id in ids:
        var profile := model.get_profile(character_id)
        if profile.is_empty():
            _fail("missing profile: " + character_id)
            return
        if model.get_primary_stats(character_id, 1) != profile["level1"]:
            _fail("level-one profile drifted: " + character_id)
            return
        if model.get_primary_stats(character_id, 175) != profile["capstone"]:
            _fail("capstone profile drifted: " + character_id)
            return
        var previous := model.get_primary_stats(character_id, 1)
        for level in range(2, 176):
            var current := model.get_primary_stats(character_id, level)
            for stat in StatModel.PRIMARY_STATS:
                if int(current[stat]) < int(previous[stat]):
                    _fail("%s %s regressed at level %d" % [character_id, stat, level])
                    return
                if int(current[stat]) < 1 or int(current[stat]) > 75:
                    _fail("%s %s escaped hard bounds" % [character_id, stat])
                    return
            previous = current

    if int(model.get_primary_stats("ender", 1)["wits"]) != 8:
        _fail("Ender level-one Wits drifted")
        return
    if int(model.get_primary_stats("ender", 1)["spirit"]) != 12:
        _fail("Ender level-one Spirit drifted")
        return
    if int(model.get_primary_stats("lyra", 1)["spirit"]) != 9:
        _fail("Lyra level-one Spirit drifted")
        return
    if int(model.get_primary_stats("ionia", 1)["presence"]) != 9:
        _fail("Ionia level-one Presence drifted")
        return
    if int(model.get_primary_stats("reson", 1)["might"]) != 9:
        _fail("Reson level-one Might drifted")
        return
    if int(model.get_primary_stats("aepex", 1)["wits"]) != 9:
        _fail("Aepex level-one Wits drifted")
        return

    var ender := model.derive(model.get_primary_stats("ender", 70), 70)
    var lyra := model.derive(model.get_primary_stats("lyra", 70), 70)
    var ionia := model.derive(model.get_primary_stats("ionia", 70), 70)
    var reson := model.derive(model.get_primary_stats("reson", 70), 70)
    var aepex := model.derive(model.get_primary_stats("aepex", 70), 70)
    if int(ender["technicalPower"]) <= int(reson["technicalPower"]):
        _fail("Ender technical role identity drifted")
        return
    if int(lyra["aetherAttack"]) <= int(reson["aetherAttack"]):
        _fail("Lyra aether role identity drifted")
        return
    if int(ionia["supportPotency"]) <= int(ender["supportPotency"]):
        _fail("Ionia support role identity drifted")
        return
    if int(reson["physicalAttack"]) <= int(ender["physicalAttack"]):
        _fail("Reson physical role identity drifted")
        return
    if int(aepex["technicalPower"]) < int(ender["technicalPower"]):
        _fail("Aepex technical role identity drifted")
        return

    if not is_equal_approx(model.defense_multiplier(0), 1.0):
        _fail("zero defense multiplier drifted")
        return
    if not model.defense_multiplier(50) > model.defense_multiplier(100):
        _fail("defense no longer diminishes smoothly")
        return
    if not is_equal_approx(model.variance_multiplier(0), 0.95):
        _fail("minimum variance drifted")
        return
    if model.variance_multiplier(0.999999) >= 1.051:
        _fail("maximum variance escaped bound")
        return

    var normal := model.resolve_damage({
        "attacker": {"might": 30},
        "scalingStat": "might",
        "power": 40,
        "scaling": 1.4,
        "equipmentPower": 20,
        "defense": 50,
        "canCrit": true,
        "critRate": 0.1,
        "critRng": 0.9,
        "varianceRng": 0.5,
    })
    var critical := model.resolve_damage({
        "attacker": {"might": 30},
        "scalingStat": "might",
        "power": 40,
        "scaling": 1.4,
        "equipmentPower": 20,
        "defense": 50,
        "canCrit": true,
        "critRate": 0.1,
        "critRng": 0.05,
        "varianceRng": 0.5,
    })
    if bool(normal["critical"]) or not bool(critical["critical"]) or int(critical["damage"]) <= int(normal["damage"]):
        _fail("critical damage parity drifted")
        return
    if not is_equal_approx(model.resolve_hit_chance({"baseAccuracy":0.95,"attackerAccuracy":100,"defenderEvasion":0}), 0.995):
        _fail("upper hit chance bound drifted")
        return
    if not is_equal_approx(model.resolve_hit_chance({"baseAccuracy":0.8,"attackerAccuracy":0,"defenderEvasion":100}), 0.6):
        _fail("lower hit chance bound drifted")
        return
    if model.resolve_break_damage({"breakPower":20,"breakResistance":100,"power":1}) != 0:
        _fail("break damage floor drifted")
        return
    if model.resolve_healing({"actor":{"presence":20},"scalingStat":"presence","power":30,"scaling":1.5,"supportBonus":10}) != 70:
        _fail("healing parity drifted")
        return

    print("AETHERWAKE_GODOT_JRPG_STAT_MODEL_PASS: level 175 profiles, derived roles, bounded RNG math and damage/healing parity")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_JRPG_STAT_MODEL_FAIL: " + reason)
    quit(1)
