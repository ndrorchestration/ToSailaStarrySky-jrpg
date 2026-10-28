extends SceneTree
## Godot-rendered full frame proof for P-01 field/station/battle/return.
## This is a local review study; no final sprite or story location approval.

const SCENE = preload("res://scenes/equipment_lifecycle_study.tscn")
const OUTPUT := "res://review-evidence/battle-equipment/"
const FIELD_REGION := Rect2i(764, 338, 184, 115)
const INSPECTOR_REGION := Rect2i(434, 204, 358, 252)

func _initialize() -> void:
    call_deferred("_capture")

func _rng() -> float:
    return 0.5

func _frame(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image_result := root.get_texture().get_image()
    if image_result.is_empty() or image_result.get_size() != Vector2i(960, 640):
        return null
    var path := OUTPUT.path_join(name + ".png")
    if image_result.save_png(path) != OK:
        return null
    print("TSTSS_EQUIPMENT_LIFECYCLE_FRAME:" + name + ":" + FileAccess.get_sha256(ProjectSettings.globalize_path(path)))
    return image_result

func _fail(why: String) -> void:
    push_error("TSTSS_EQUIPMENT_LIFECYCLE_FRAME_FAIL: " + why)
    quit(1)

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot create local equipment review evidence directory")
        return
    var world = SCENE.instantiate()
    root.add_child(world)
    await process_frame
    world.formula_encounter.rng_source = Callable(self, "_rng")
    world.ender.position = Vector2(805, 465)
    await process_frame
    var baseline: Image = await _frame("lifecycle-field-baseline-native-960x640")
    if baseline == null or not world.interact_nearest():
        _fail("station interaction or field screenshot failed")
        return
    await process_frame
    var inspect_current: Image = await _frame("lifecycle-station-inspect-native-960x640")
    if inspect_current == null or not world.move_gear_inspector_item(1):
        _fail("station inspector or alternate staff preview failed")
        return
    await process_frame
    var preview: Image = await _frame("lifecycle-station-preview-native-960x640")
    if preview == null or preview.get_region(INSPECTOR_REGION).get_data() == inspect_current.get_region(INSPECTOR_REGION).get_data():
        _fail("uncommitted comparison did not change pixels")
        return
    if not world.confirm_gear_inspector_item():
        _fail("could not confirm legally owned alternate staff")
        return
    world.close_gear_inspector()
    await process_frame
    var equipped: Image = await _frame("lifecycle-field-equipped-native-960x640")
    if equipped == null or equipped.get_region(FIELD_REGION).get_data() == baseline.get_region(FIELD_REGION).get_data():
        _fail("field gear rig did not reflect confirmed ownership")
        return
    var confirmed_key: String = world.field_gear_display.visual_key()
    if not world.start_formula_review() or world.battle_equipment_view.visual_key() != confirmed_key:
        _fail("battle could not reuse same field-owned weapon visual")
        return
    await process_frame
    var battle: Image = await _frame("lifecycle-battle-equipped-native-960x640")
    if battle == null or battle.get_data() == equipped.get_data():
        _fail("native battle transition produced no visual change")
        return
    if not world.close_formula_review():
        _fail("could not return to review field")
        return
    await process_frame
    var returned: Image = await _frame("lifecycle-field-return-native-960x640")
    if returned == null or world.field_gear_display.visual_key() != confirmed_key:
        _fail("field return lost visually equipped gear")
        return
    if returned.get_region(FIELD_REGION).get_data() != equipped.get_region(FIELD_REGION).get_data():
        _fail("return changed field gear with same inventory/equipment")
        return
    print("TSTSS_EQUIPMENT_LIFECYCLE_NATIVE_RENDER_PASS: actual field, inspector, uncommitted preview, equipped rig, battle and return pixels; art acceptance pending")
    world.queue_free()
    quit(0)
