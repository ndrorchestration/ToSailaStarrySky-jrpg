extends SceneTree
## Actual configured Chapter I native entry scene. Frame hashes compare ON/OFF
## with identical default storyline/saves; not finished character art.
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String, code: int) -> void:
    push_error("CH1_CHARACTER_P01B_RENDER_FAIL: " + message)
    quit(code)

func _save_frame(mode: String) -> bool:
    await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame.is_empty() or frame.get_size() != Vector2i(960, 640):
        return false
    var path: String = OUTPUT + "ch1-character-p01b-" + mode + "-native-960x640.png"
    if frame.save_png(path) != OK:
        return false
    print("CH1_CHARACTER_P01B_NATIVE_PNG:" + mode + ":sha256=" + FileAccess.get_sha256(path))
    var crop: Image = frame.get_region(Rect2i(460, 220, 440, 325))
    var thumbnail: PackedByteArray = crop.save_jpg_to_buffer(0.64)
    if thumbnail.is_empty() or thumbnail.size() > 85000:
        return false
    print("CH1_CHARACTER_P01B_CROP_JPEG_BASE64:" + mode + ":" + Marshalls.raw_to_base64(thumbnail))
    return true

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage: Node = load("res://scenes/first_wake_chapter1_player_preview.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("review directory unavailable", 1)
        return
    if stage.call("is_character_visual_p01b_enabled"):
        _fail("injected Lyra sprite visible before explicit enable", 2)
        return
    var snapshot: String = JSON.stringify(stage.call("export_save_snapshot"))
    if not await _save_frame("off"):
        _fail("native baseline frame unavailable", 3)
        return
    stage.call("set_character_visual_p01b_enabled", true)
    var actor: CharacterBody2D = stage.call("get_character_visual_p01b_actor")
    if actor == null:
        _fail("no source actor during real configured Chapter I capture", 4)
        return
    for tick in range(42):
        await physics_frame
    if actor.get("facing") != "south" or actor.global_position.y < 460.0:
        _fail("south movement not actually measured", 5)
        return
    if not await _save_frame("south"):
        _fail("native south scene unavailable", 6)
        return
    for tick in range(77):
        await physics_frame
    if actor.get("facing") != "west" or actor.global_position.x > 713.0:
        _fail("west movement not actually measured", 7)
        return
    if not await _save_frame("west"):
        _fail("native west scene unavailable", 8)
        return
    stage.call("set_character_visual_p01b_enabled", false)
    await process_frame
    if stage.call("is_character_visual_p01b_enabled") or stage.call("get_character_visual_p01b_actor") != null:
        _fail("visual actor not removed for final native comparison", 9)
        return
    if not await _save_frame("restored"):
        _fail("native restored baseline unavailable", 10)
        return
    var off_hash: String = FileAccess.get_sha256(OUTPUT + "ch1-character-p01b-off-native-960x640.png")
    if off_hash != FileAccess.get_sha256(OUTPUT + "ch1-character-p01b-restored-native-960x640.png"):
        _fail("F6 OFF did not pixel-restore the actual Chapter I native scene", 11)
        return
    if off_hash == FileAccess.get_sha256(OUTPUT + "ch1-character-p01b-south-native-960x640.png"):
        _fail("opt-in sprite invisible in actual native Chapter I render", 12)
        return
    if JSON.stringify(stage.call("export_save_snapshot")) != snapshot:
        _fail("render-only fixture changed durable Chapter I save state", 13)
        return
    print("CH1_CHARACTER_P01B_RENDER_PASS: native configured First Wake Chapter I OFF/south/west/RESTORED, pixel-identical OFF/RESTORED")
    print("CH1_CHARACTER_P01B_GAIT_APPROVAL=NOT_CERTIFIED")
    quit(0)
