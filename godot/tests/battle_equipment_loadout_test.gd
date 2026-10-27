extends SceneTree
## Pure contract: verified weapon identities, review variants, invalid equip and
## combat authority do not bleed into each other.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    var expected := {
        "ender": ["staff", "mainWeapon"],
        "lyra": ["chakram", "mainWeapon"],
        "ionia": ["mace", "mainWeapon"],
        "reson": ["sword", "mainWeapon"],
        "aepex": ["unarmed", "mainWeapon"],
    }
    for actor_id in expected.keys():
        var item = Loadout.new(actor_id)
        if not item.validate():
            _fail("invalid starter loadout: " + actor_id)
            return
        if str(item.appearance()["weaponFamily"]) != expected[actor_id][0]:
            _fail("starting martial family drift: " + actor_id)
            return
        if item.hold_weapon_slot("secondaryWeapon") and actor_id != "reson":
            _fail("unapproved secondary weapon: " + actor_id)
            return
    var reson = Loadout.new("reson")
    if not reson.hold_weapon_slot("secondaryWeapon") or str(reson.appearance()["weaponFamily"]) != "rifle":
        _fail("Reson rifle does not switch held visual from sword")
        return
    var ender = Loadout.new("ender")
    var first_key := str(ender.appearance()["weaponVisual"])
    if not ender.cycle_ender_review("mainWeapon"):
        _fail("Ender staff appearance could not cycle")
        return
    if str(ender.appearance()["weaponVisual"]) == first_key:
        _fail("equipment change did not change visual key")
        return
    if not ender.cycle_ender_review("bodyArmor") or str(ender.appearance()["armorVisual"]) != "brass-plate":
        _fail("armor overlay not reflected in appearance")
        return
    if not ender.cycle_ender_review("accessory") or str(ender.appearance()["accessoryVisual"]) != "small-charm":
        _fail("accessory overlay not reflected in appearance")
        return
    var signature := ender.appearance().duplicate(true)
    for invalid in [
        ["mainWeapon", ""],
        ["mainWeapon", "reson-starter-sword"],
        ["secondaryWeapon", "reson-starter-rifle"],
        ["bodyArmor", "reson-starter-sword"],
        ["accessory", "unlisted"],
        ["unknownSlot", "ender-starter-staff"],
    ]:
        if ender.equip(invalid[0], invalid[1]):
            _fail("unauthorized equipment change accepted: " + str(invalid))
            return
    if ender.appearance() != signature or not ender.validate():
        _fail("rejected equip altered active loadout")
        return
    if Loadout.new("unknown").validate():
        _fail("unknown actor received equipment")
        return
    var authority = Authority.new()
    if authority.can_use_formula_action("reson", "staffStrike") or authority.can_use_formula_action("lyra", "staffStrike"):
        _fail("equipment identity granted unapproved combat turns")
        return
    if not ender.reset_to_starter() or ender.appearance()["weaponVisual"] != first_key:
        _fail("transient review cosmetics do not reset")
        return
    print("AETHERWAKE_BATTLE_EQUIPMENT_LOADOUT_PASS: five starting families, Reson secondary, Ender live cosmetic slots, failed invalid equips")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_LOADOUT_FAIL: " + reason)
    quit(1)
