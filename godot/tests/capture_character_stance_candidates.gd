extends SceneTree
## Original Godot OpenGL A/B at identical frozen actor world transforms.
## Orange tether is a provisional screen-half candidate, not a planted foot.
const OUTPUT := "res://review-evidence/"
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    stage.set_stance_guides_enabled(true)
    stage.start_all()
    for tick in range(40):
        await physics_frame
    var frozen := {}
    for character_id in NAMES:
        var actor = stage.get_actor(character_id)
        if actor == null or not actor.review_enabled:
            push_error("STANCE_CANDIDATE_CAPTURE_FAIL: no physical movement")
            quit(1)
            return
        if float(stage.stance_guides[character_id].get_candidate_displacement()) < 1.0:
            push_error("STANCE_CANDIDATE_CAPTURE_FAIL: no actual measured visible tether")
            quit(2)
            return
        frozen[character_id] = actor.global_position
        actor.set_physics_process(false)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("STANCE_CANDIDATE_CAPTURE_FAIL: output directory unavailable")
        quit(3)
        return
    for mode in ["with-guides", "without-guides"]:
        stage.set_stance_guides_enabled(mode == "with-guides")
        await process_frame
        await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame.is_empty() or frame.get_size() != Vector2i(960, 640):
            push_error("STANCE_CANDIDATE_CAPTURE_FAIL: invalid native framebuffer")
            quit(4)
            return
        var filename: String = OUTPUT + "stance-candidate-" + mode + "-native-960x640.png"
        if frame.save_png(filename) != OK:
            push_error("STANCE_CANDIDATE_CAPTURE_FAIL: PNG write failure")
            quit(5)
            return
        print("STANCE_CANDIDATE_NATIVE_PNG:" + mode + ":sha256=" + FileAccess.get_sha256(filename))
        var preview: Image = frame.get_region(Rect2i(145, 185, 680, 315))
        var jpg: PackedByteArray = preview.save_jpg_to_buffer(0.62)
        if jpg.is_empty() or jpg.size() > 95000:
            push_error("STANCE_CANDIDATE_CAPTURE_FAIL: review JPEG exceeds custody cap")
            quit(6)
            return
        print("STANCE_CANDIDATE_NATIVE_CROP_JPEG_BASE64:" + mode + ":" + Marshalls.raw_to_base64(jpg))
        for character_id in NAMES:
            if stage.get_actor(character_id).global_position.distance_to(frozen[character_id]) > 0.0001:
                push_error("STANCE_CANDIDATE_CAPTURE_FAIL: A/B mutated physics coordinates")
                quit(7)
                return
    if FileAccess.get_sha256(OUTPUT + "stance-candidate-with-guides-native-960x640.png") == FileAccess.get_sha256(OUTPUT + "stance-candidate-without-guides-native-960x640.png"):
        push_error("STANCE_CANDIDATE_CAPTURE_FAIL: opt-in overlay not visible in renderer")
        quit(8)
        return
    print("STANCE_CANDIDATE_NATIVE_CAPTURE_PASS: two actual Godot OpenGL frames at identical world coordinates; provisional tethers only")
    quit(0)
