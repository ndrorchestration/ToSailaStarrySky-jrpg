extends SceneTree
## Real Godot framebuffer A/B receipts. Same battle, camera, route, stats
## and clock; only the equipped presentation changes between frames.
## Does not assert creator acceptance or production sprite integration.

const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const OUTPUT := "res://review-evidence/battle-equipment/"
const REGION := Rect2i(677, 170, 130, 160)
const TRIAL_BAG_REGION := Rect2i(405, 465, 398, 28)

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        return null
    var path := OUTPUT.path_join(name + ".png")
    if img.save_png(path) != OK:
        return null
    print("AETHERWAKE_EQUIPMENT_NATIVE_FRAME:" + name + ":" + FileAccess.get_sha256(ProjectSettings.globalize_path(path)))
    return img

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot create private review directory")
        return
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    if not world.start_formula_review():
        _fail("battle scene not opened")
        return
    await process_frame
    var original: Image = await _snapshot("staff-baseline-native-960x640")
    if original == null:
        _fail("original image missing")
        return
    if not world.equip_review_item("mainWeapon", "ender-staff-inlay-review"):
        _fail("staff inlay equip rejected")
        return
    await process_frame
    var weapon_swap: Image = await _snapshot("staff-inlay-native-960x640")
    if weapon_swap == null or original.get_region(REGION).get_data() == weapon_swap.get_region(REGION).get_data():
        _fail("real rendered weapon region did not change")
        return
    if original.get_region(TRIAL_BAG_REGION).get_data() == weapon_swap.get_region(TRIAL_BAG_REGION).get_data():
        _fail("owned weapon swap did not update the real inventory HUD pixels")
        return
    if not world.equip_review_item("bodyArmor", "ender-armor-overlay-review"):
        _fail("armor study equip rejected")
        return
    if not world.equip_review_item("accessory", "ender-charm-review"):
        _fail("accessory study equip rejected")
        return
    await process_frame
    var complete: Image = await _snapshot("armor-accessory-native-960x640")
    if complete == null or complete.get_region(REGION).get_data() == weapon_swap.get_region(REGION).get_data():
        _fail("real rendered armor/charm region did not change")
        return
    if complete.get_region(TRIAL_BAG_REGION).get_data() == weapon_swap.get_region(TRIAL_BAG_REGION).get_data():
        _fail("equipping owned armor/charm did not debit visible trial bag")
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized strike not playable with changed gear")
        return
    if world.battle_equipment_view.pose_id != "strike":
        _fail("strike did not update visual pose")
        return
    await process_frame
    var strike: Image = await _snapshot("staff-strike-pose-native-960x640")
    if strike == null or strike.get_region(REGION).get_data() == complete.get_region(REGION).get_data():
        _fail("real framebuffer did not move the wielded weapon with the attack pose")
        return
    if not world.toggle_training_pressure_review():
        _fail("opt-in practice armor pressure did not enable")
        return
    var hp_before_pressure: int = int(world.formula_encounter.player["vit"])
    if not world.take_formula_review_action("hold"):
        _fail("accepted Hold could not trigger optional practice pressure")
        return
    if int(world.formula_encounter.player["vit"]) != hp_before_pressure - 10:
        _fail("provisional chest armor did not mitigate real native scene VIT by 1")
        return
    await process_frame
    var pressure: Image = await _snapshot("armor-pressure-native-960x640")
    if pressure == null or pressure.get_region(Rect2i(160, 413, 490, 58)).get_data() == strike.get_region(Rect2i(160, 413, 490, 58)).get_data():
        _fail("native practice-pressure status did not change rendered UI")
        return
    print("AETHERWAKE_BATTLE_EQUIPMENT_NATIVE_RENDER_PASS: distinct weapon, outfit, pose and actual practice pressure HUD pixels; player/art acceptance pending")
    world.queue_free()
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_NATIVE_RENDER_FAIL: " + reason)
    quit(1)
