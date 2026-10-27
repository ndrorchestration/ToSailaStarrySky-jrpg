extends SceneTree
## Verifies actual Node2D slot attachments, hand/socket pose binding,
## source identity and non-authoritative combat/appearance separation.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Rig = preload("res://scripts/battle_equipment_visual.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var loadout = Loadout.new("ender")
    var rig = Rig.new()
    # Pre-tree binding must survive _ready attachment construction.
    rig.set_appearance(loadout.appearance())
    root.add_child(rig)
    await process_frame

    if rig.get_node_or_null("WeaponAttachment") == null:
        _fail("no independent weapon CanvasItem")
        return
    if rig.get_node_or_null("ArmorAttachment") == null or rig.get_node_or_null("AccessoryAttachment") == null:
        _fail("independent armor/accessory layers missing")
        return
    if rig.get_node_or_null("GripHandAttachment") == null:
        _fail("hand occlusion layer missing")
        return
    if rig.weapon_attachment == rig.armor_attachment or rig.hand_attachment == rig.weapon_attachment:
        _fail("gear shares a canvas attachment instead of separate nodes")
        return
    if rig.armor_attachment.visible or rig.accessory_attachment.visible:
        _fail("empty accessory slots leaked visible parts")
        return
    if rig.pose_id != "idle" or rig.weapon_attachment.position != rig.hand_attachment.position:
        _fail("idle grip did not bind to the weapon socket")
        return

    var idle_socket: Vector2 = rig.socket_position()
    if not rig.set_pose("strike") or rig.socket_position() == idle_socket:
        _fail("strike pose did not move the hand socket")
        return
    if rig.weapon_attachment.position != rig.hand_attachment.position:
        _fail("hand is no longer attached to weapon during strike")
        return
    if not is_equal_approx(rig.weapon_attachment.rotation, -0.83):
        _fail("strike pose did not rotate the held weapon")
        return
    var established_pose: String = rig.pose_id
    if rig.set_pose("unapproved_magic_combo") or rig.pose_id != established_pose:
        _fail("unknown pose was admitted")
        return

    var original_key: String = rig.visual_key()
    if not loadout.equip("mainWeapon", "ender-staff-inlay-review"):
        _fail("alternate visual equip failed")
        return
    rig.set_appearance(loadout.appearance())
    if rig.visual_key() == original_key or rig.pose_id != "strike":
        _fail("visual swap changed nothing or reset the actor pose")
        return
    if str(rig.weapon_attachment.appearance.get("weaponVisual", "")) != "staff-silver-inlay":
        _fail("wielded node is out of sync with loadout")
        return
    if not loadout.equip("bodyArmor", "ender-armor-overlay-review"):
        _fail("review armor equip failed")
        return
    if not loadout.equip("accessory", "ender-charm-review"):
        _fail("review charm equip failed")
        return
    rig.set_appearance(loadout.appearance())
    if not rig.armor_attachment.visible or not rig.accessory_attachment.visible:
        _fail("newly equipped armor/accessory not mounted")
        return
    if rig.weapon_attachment.position != rig.hand_attachment.position:
        _fail("equip swap broke hand contact")
        return

    var expected_held: String = loadout.item_id_for("mainWeapon")
    if loadout.equip("mainWeapon", "reson-starter-sword") or loadout.item_id_for("mainWeapon") != expected_held:
        _fail("foreign actor weapon accepted")
        return
    if Authority.new().can_use_formula_action("reson", "staffStrike"):
        _fail("gear visual work changed actor combat authority")
        return

    var reson_loadout = Loadout.new("reson")
    var reson_rig = Rig.new()
    root.add_child(reson_rig)
    reson_rig.set_appearance(reson_loadout.appearance())
    if str(reson_rig.weapon_attachment.appearance.get("weaponFamily", "")) != "sword":
        _fail("Reson starting sword not visible on weapon socket")
        return
    if not reson_loadout.hold_weapon_slot("secondaryWeapon"):
        _fail("Reson cannot switch to previously locked secondary")
        return
    reson_rig.set_appearance(reson_loadout.appearance())
    if str(reson_rig.weapon_attachment.appearance.get("weaponFamily", "")) != "rifle":
        _fail("Reson rifle not attached after slot switch")
        return
    if not reson_rig.set_pose("guard") or reson_rig.weapon_attachment.position != reson_rig.hand_attachment.position:
        _fail("Reson rifle failed to follow hand in guard pose")
        return
    for actor_id in ["lyra", "ionia", "aepex"]:
        var starter = Loadout.new(actor_id)
        var actor_rig = Rig.new()
        root.add_child(actor_rig)
        actor_rig.set_appearance(starter.appearance())
        if not actor_rig.weapon_attachment.visible:
            _fail("starter weapon/unarmed pose missing for " + actor_id)
            return
        if str(actor_rig.weapon_attachment.appearance.get("actorId", "")) != actor_id:
            _fail("visual actor binding drifted for " + actor_id)
            return
        actor_rig.queue_free()

    print("AETHERWAKE_BATTLE_EQUIPMENT_SOCKET_PASS: detachable nodes, five actor IDs, hand grip poses, foreign-equip blocking and Reson rifle switch")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_SOCKET_FAIL: " + reason)
    quit(1)
