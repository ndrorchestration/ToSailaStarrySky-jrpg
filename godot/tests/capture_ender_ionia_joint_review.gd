extends SceneTree
## Native review-only combined evidence; no art admission/publication.
const OUTPUT := "res://review-evidence/joint-ender-ionia/"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    await process_frame
    if world.ender == null or world.ionia == null:
        push_error("JOINT_REVIEW_FAIL: missing actor")
        quit(2)
        return
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("JOINT_REVIEW_FAIL: output path")
        quit(3)
        return
    var captures := {}
    var variants := [
        {"name": "00-both-placeholders", "ender": false, "ionia": false},
        {"name": "01-ender-only", "ender": true, "ionia": false},
        {"name": "02-ionia-only", "ender": false, "ionia": true},
        {"name": "03-ender-and-ionia", "ender": true, "ionia": true},
    ]
    for state in variants:
        world.ender.set_walk_review_enabled(state["ender"])
        world.ionia.set_review_art_enabled(state["ionia"])
        await process_frame
        await RenderingServer.frame_post_draw
        var shot: Image = root.get_texture().get_image()
        if shot.is_empty() or shot.get_width() != 960 or shot.get_height() != 640:
            push_error("JOINT_REVIEW_FAIL: invalid native 960x640 frame")
            quit(4)
            return
        if shot.save_png(OUTPUT + state["name"] + ".png") != OK:
            push_error("JOINT_REVIEW_FAIL: PNG write")
            quit(5)
            return
        captures[state["name"]] = shot
    var baseline: Image = captures["00-both-placeholders"]
    var ender_only: Image = captures["01-ender-only"]
    var ionia_only: Image = captures["02-ionia-only"]
    var together: Image = captures["03-ender-and-ionia"]
    var ender_roi := Rect2i(300, 350, 100, 130)
    var ionia_roi := Rect2i(510, 340, 140, 135)
    if baseline.get_region(ender_roi).get_data() == ender_only.get_region(ender_roi).get_data():
        push_error("JOINT_REVIEW_FAIL: Ender not visible")
        quit(6)
        return
    if baseline.get_region(ionia_roi).get_data() == ionia_only.get_region(ionia_roi).get_data():
        push_error("JOINT_REVIEW_FAIL: Ionia not visible")
        quit(7)
        return
    if together.get_region(ender_roi).get_data() != ender_only.get_region(ender_roi).get_data():
        push_error("JOINT_REVIEW_FAIL: Ender unexpectedly changed")
        quit(8)
        return
    if together.get_region(ionia_roi).get_data() != ionia_only.get_region(ionia_roi).get_data():
        push_error("JOINT_REVIEW_FAIL: Ionia unexpectedly changed")
        quit(9)
        return
    world.ender.set_walk_review_enabled(false)
    world.ionia.set_review_art_enabled(false)
    print("JOINT_NATIVE_CAPTURE_PASS: four genuine 960x640 native rendered states")
    print("FRONT_BACK_POSES=NOT_AUTHORED; STAFF_CONTINUITY=NOT_ACCEPTED")
    print("VISUAL_ACCEPTANCE=PENDING; EVIDENCE_DISTRIBUTION=NOT_ESTABLISHED")
    quit(0)
