extends SceneTree
## Native Godot 960x640 A/B at fixed source frame and world coordinates.
## Lyra selected boot polygon is review art, NOT an accepted gait stance.
const OUTPUT := "res://review-evidence/"
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    stage.set_lyra_source_contact_enabled(true)
    stage.start_all()
    for tick in range(41):
        await physics_frame
    var lyra = stage.get_actor("Lyra")
    if lyra.facing != "south" or float(stage.lyra_source_contact_guide.get_candidate_displacement()) <= 1.0:
        push_error("LYRA_SOLE_CAPTURE_FAIL: source contact probe not active during genuine south physics")
        quit(1)
        return
    var world := {}
    var poses := {}
    for name in NAMES:
        var actor = stage.get_actor(name)
        world[name] = actor.global_position
        poses[name] = actor.current_phase
        actor.set_physics_process(false)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("LYRA_SOLE_CAPTURE_FAIL: directory inaccessible")
        quit(2)
        return
    for mode in ["with-path-markers", "without-path-markers"]:
        stage.set_lyra_source_contact_enabled(mode == "with-path-markers")
        await process_frame
        await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame.is_empty() or frame.get_size() != Vector2i(960, 640):
            push_error("LYRA_SOLE_CAPTURE_FAIL: invalid real OpenGL framebuffer")
            quit(3)
            return
        var filename: String = OUTPUT + "lyra-south-source-contact-" + mode + "-native-960x640.png"
        if frame.save_png(filename) != OK:
            push_error("LYRA_SOLE_CAPTURE_FAIL: image save failure")
            quit(4)
            return
        print("LYRA_SOLE_NATIVE_PNG:" + mode + ":sha256=" + FileAccess.get_sha256(filename))
        var crop: Image = frame.get_region(Rect2i(175, 170, 270, 330))
        var bytes: PackedByteArray = crop.save_jpg_to_buffer(0.65)
        if bytes.is_empty() or bytes.size() > 85000:
            push_error("LYRA_SOLE_CAPTURE_FAIL: JPEG custody bound")
            quit(5)
            return
        print("LYRA_SOLE_NATIVE_CROP_JPEG_BASE64:" + mode + ":" + Marshalls.raw_to_base64(bytes))
        for name in NAMES:
            if stage.get_actor(name).global_position.distance_to(world[name]) > 0.0001 or stage.get_actor(name).current_phase != poses[name]:
                push_error("LYRA_SOLE_CAPTURE_FAIL: comparison mutated physics or source frame")
                quit(6)
                return
    if FileAccess.get_sha256(OUTPUT + "lyra-south-source-contact-with-path-markers-native-960x640.png") == FileAccess.get_sha256(OUTPUT + "lyra-south-source-contact-without-path-markers-native-960x640.png"):
        push_error("LYRA_SOLE_CAPTURE_FAIL: source contact overlay did not render")
        quit(7)
        return
    print("LYRA_SOLE_NATIVE_CAPTURE_PASS: real Godot pixels compared at identical physical coordinates with proposed source shoe point")
    quit(0)
