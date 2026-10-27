extends SceneTree
## Genuine 960x640 Godot OpenGL moving-actor frames. NOT authored illustration.
## PNGs retained on runner; size-bounded review JPEGs go to the CI log only.
const OUTPUT := "res://review-evidence/"
const TARGET_TICKS: Array[int] = [30, 100, 165, 235]
const FACINGS: Array[String] = ["south", "west", "north", "east"]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("THREE_PHYSICS_CAPTURE_FAIL: review directory unavailable")
        quit(1)
        return
    stage.start_all()
    var captures := 0
    for tick in range(260):
        await physics_frame
        if not TARGET_TICKS.has(tick):
            continue
        var expected: String = FACINGS[TARGET_TICKS.find(tick)]
        for character_id in ["Lyra", "Aepex", "Reson"]:
            var actor = stage.get_actor(character_id)
            if actor == null or actor.get("facing") != expected or not actor.get("review_enabled"):
                push_error("THREE_PHYSICS_CAPTURE_FAIL: native facing out of phase " + character_id + " " + expected)
                quit(2)
                return
        await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame.is_empty() or frame.get_width() != 960 or frame.get_height() != 640:
            push_error("THREE_PHYSICS_CAPTURE_FAIL: no real 960x640 framebuffer")
            quit(3)
            return
        var filename: String = OUTPUT + "three-physics-walk-" + expected + "-native-960x640.png"
        if frame.save_png(filename) != OK:
            push_error("THREE_PHYSICS_CAPTURE_FAIL: cannot save original frame " + expected)
            quit(4)
            return
        print("THREE_PHYSICS_CAPTURE_NATIVE_PNG:" + expected + ":sha256=" + FileAccess.get_sha256(filename))
        var thumb: Image = frame.duplicate()
        thumb.resize(480, 320, Image.INTERPOLATE_LANCZOS)
        var bytes: PackedByteArray = thumb.save_jpg_to_buffer(0.63)
        if bytes.is_empty() or bytes.size() > 85000:
            push_error("THREE_PHYSICS_CAPTURE_FAIL: inspection thumbnail exceeds custody bound")
            quit(5)
            return
        print("THREE_PHYSICS_CAPTURE_JPEG_BASE64:" + expected + ":" + Marshalls.raw_to_base64(bytes))
        captures += 1
    if captures != 4:
        push_error("THREE_PHYSICS_CAPTURE_FAIL: incomplete four-facing real movement screenshots")
        quit(6)
        return
    print("THREE_PHYSICS_CAPTURE_PASS: original Godot frames during true physical movement; foot plants/art acceptance NOT CERTIFIED")
    quit(0)
