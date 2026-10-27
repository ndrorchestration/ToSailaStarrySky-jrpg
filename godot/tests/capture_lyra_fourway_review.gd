extends SceneTree
## Four actual Godot OpenGL 960x640 rendered screenshots, captured for visual review.
## Log-delivered JPEGs are bounded inspection crops; unmodified screenshots remain local.

const FACINGS := ["south", "west", "north", "east"]
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    world.set_character_lineup_review_enabled(true)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("LYRA_FOURWAY_CAPTURE_FAIL: review directory inaccessible")
        quit(1)
        return
    for facing in FACINGS:
        world.character_lineup_review.set_lyra_direction(facing)
        world.character_lineup_review.set_walk_phase(2)
        await process_frame
        await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame.is_empty() or frame.get_width() != 960 or frame.get_height() != 640:
            push_error("LYRA_FOURWAY_CAPTURE_FAIL: non-native framebuffer " + facing)
            quit(2)
            return
        var filename := OUTPUT + "lyra-" + facing + "-native-960x640.png"
        if frame.save_png(filename) != OK:
            push_error("LYRA_FOURWAY_CAPTURE_FAIL: screenshot could not be saved " + facing)
            quit(3)
            return
        print("LYRA_FOURWAY_NATIVE_PNG:" + facing + ":sha256=" + FileAccess.get_sha256(filename))
        # The inspection tile is a *crop of the actual Godot screenshot*,
        # not a synthesized illustration or production texture.
        var crop: Image = frame.get_region(Rect2i(577, 224, 176, 222))
        crop.resize(352, 444, Image.INTERPOLATE_NEAREST)
        var preview_bytes: PackedByteArray = crop.save_jpg_to_buffer(0.62)
        if preview_bytes.is_empty() or preview_bytes.size() > 90000:
            push_error("LYRA_FOURWAY_CAPTURE_FAIL: bounded crop unusable " + facing)
            quit(4)
            return
        print("LYRA_FOURWAY_NATIVE_CROP_JPEG_BASE64:" + facing + ":" + Marshalls.raw_to_base64(preview_bytes))
    print("LYRA_FOURWAY_NATIVE_CAPTURE_PASS: four authentic views, creator visual review pending")
    quit(0)
