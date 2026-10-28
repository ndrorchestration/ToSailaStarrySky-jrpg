extends SceneTree
## Actual First Wake dock native-render baseline vs opt-in review at 960x640.
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String, code: int) -> void:
    push_error("FIRST_WAKE_CHARACTER_P01_CAPTURE_FAIL: " + message)
    quit(code)

func _write_frame(stage: Node, name: String) -> bool:
    await RenderingServer.frame_post_draw
    var screenshot: Image = root.get_texture().get_image()
    if screenshot.is_empty() or screenshot.get_size() != Vector2i(960, 640):
        return false
    var path: String = OUTPUT + "first-wake-character-p01-" + name + "-native-960x640.png"
    if screenshot.save_png(path) != OK:
        return false
    print("FIRST_WAKE_CHARACTER_P01_NATIVE_PNG:" + name + ":sha256=" + FileAccess.get_sha256(path))
    var crop: Image = screenshot.get_region(Rect2i(550, 250, 350, 295))
    var jpg: PackedByteArray = crop.save_jpg_to_buffer(0.65)
    if jpg.is_empty() or jpg.size() > 85000:
        return false
    print("FIRST_WAKE_CHARACTER_P01_JPEG_BASE64:" + name + ":" + Marshalls.raw_to_base64(jpg))
    return true

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage: Node = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot write native review folder", 1)
        return
    if stage.call("is_character_visual_p01_enabled"):
        _fail("First Wake did not start in production-safe off state", 2)
        return
    if not await _write_frame(stage, "off"):
        _fail("native OFF frame missing", 3)
        return
    stage.call("set_character_visual_p01_enabled", true)
    var fixture: CharacterBody2D = stage.call("get_character_visual_p01_actor")
    if fixture == null:
        _fail("opt-in actor absent from actual scene", 4)
        return
    for tick in range(42):
        await physics_frame
    if fixture.get("facing") != "south" or fixture.global_position.y < 460.0:
        _fail("no actual southbound physics travel", 5)
        return
    if not await _write_frame(stage, "south-moving"):
        _fail("southbound native frame missing", 6)
        return
    for tick in range(77):
        await physics_frame
    if fixture.get("facing") != "west" or fixture.global_position.x > 715.0:
        _fail("no actual westbound physics travel", 7)
        return
    if not await _write_frame(stage, "west-moving"):
        _fail("westbound native frame missing", 8)
        return
    stage.call("set_character_visual_p01_enabled", false)
    await process_frame
    if stage.call("is_character_visual_p01_enabled"):
        _fail("fixture did not opt out", 9)
        return
    if not await _write_frame(stage, "restored"):
        _fail("native restored frame missing", 10)
        return
    if FileAccess.get_sha256(OUTPUT + "first-wake-character-p01-off-native-960x640.png") != FileAccess.get_sha256(OUTPUT + "first-wake-character-p01-restored-native-960x640.png"):
        _fail("disabled review did not restore real First Wake pixels", 11)
        return
    if FileAccess.get_sha256(OUTPUT + "first-wake-character-p01-off-native-960x640.png") == FileAccess.get_sha256(OUTPUT + "first-wake-character-p01-south-moving-native-960x640.png"):
        _fail("review actor did not visibly render", 12)
        return
    print("FIRST_WAKE_CHARACTER_P01_NATIVE_CAPTURE_PASS: real First Wake default-off restored pixel-identically after moving south/west opt-in")
    quit(0)
