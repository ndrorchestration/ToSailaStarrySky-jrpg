extends SceneTree
## Genuine native Godot 960×640 renderer comparison at FIXED actor anchors.
## Field art unapproved; same frame and dock geometry across all four facings.
## This checks presence, independent views, scale/provenance, not artistic acceptance.

const OUT := "res://review-evidence/"
const DIRECTION_ORDER := ["east", "west", "south", "north"]
const ENDER_ROI := Rect2i(280, 325, 160, 185)
const IONIA_ROI := Rect2i(500, 315, 155, 195)
const ENDER_AT := Vector2(350, 462)
const IONIA_AT := Vector2(570, 458)

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var png: Image = root.get_texture().get_image()
    if png.is_empty() or png.get_width() != 960 or png.get_height() != 640:
        push_error("JOINT_FOURWAY_FAIL: renderer is not actual 960x640")
        return null
    if png.save_png(OUT + name) != OK:
        push_error("JOINT_FOURWAY_FAIL: cannot write original native PNG")
        return null
    return png

func _changed_bytes(a: Image, b: Image, rect: Rect2i) -> int:
    var source: PackedByteArray = a.get_region(rect).get_data()
    var target: PackedByteArray = b.get_region(rect).get_data()
    if source.size() != target.size():
        return -1
    var changed := 0
    for i in range(source.size()):
        if source[i] != target[i]:
            changed += 1
    return changed

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ender = world.ender
    var ionia = world.ionia
    if ender == null or ionia == null:
        push_error("JOINT_FOURWAY_FAIL: missing native actor")
        quit(1)
        return
    # Freeze real actor physics; the only manipulated dimension is facing.
    ender.set_physics_process(false)
    ionia.set_physics_process(false)
    ender.global_position = ENDER_AT
    ionia.global_position = IONIA_AT
    world.set_dock_depth_review_enabled(true)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("JOINT_FOURWAY_FAIL: review output unavailable")
        quit(2)
        return
    await process_frame
    var baseline: Image = await _snapshot("joint-fixed-baseline-native-960x640.png")
    if baseline == null:
        quit(3)
        return

    ender.set_walk_review_enabled(true)
    ionia.set_ionia_route_review_enabled(true)
    ionia.set_physics_process(false)
    ender.global_position = ENDER_AT
    ionia.global_position = IONIA_AT
    var ender_sources := {
        "east": ender.walk_review_sprite,
        "west": ender.walk_west_sprite,
        "south": ender.walk_front_sprite,
        "north": ender.walk_back_sprite
    }
    var ionia_sources := {
        "east": ionia.ionia_east_walk_sprite,
        "west": ionia.ionia_west_walk_sprite,
        "south": ionia.ionia_front_walk_sprite,
        "north": ionia.ionia_north_walk_sprite
    }
    var ender_proofs := []
    var ionia_proofs := []
    for facing in DIRECTION_ORDER:
        ender.walk_facing = facing
        ender._sync_ender_direction()
        ionia.ionia_facing = facing
        ionia._sync_ionia_direction()
        for candidate in ender_sources.values():
            candidate.frame = 0
            if candidate.visible != (candidate == ender_sources[facing]):
                push_error("JOINT_FOURWAY_FAIL: Ender has an unexpected direction visible")
                quit(4)
                return
        for candidate in ionia_sources.values():
            candidate.frame = 0
            if candidate.visible != (candidate == ionia_sources[facing]):
                push_error("JOINT_FOURWAY_FAIL: Ionia has an unexpected direction visible")
                quit(5)
                return
        if ender.global_position != ENDER_AT or ionia.global_position != IONIA_AT:
            push_error("JOINT_FOURWAY_FAIL: anchor changed between facings")
            quit(6)
            return
        await process_frame
        var shot: Image = await _snapshot("joint-fixed-" + facing + "-native-960x640.png")
        if shot == null:
            quit(7)
            return
        var ender_changed := _changed_bytes(baseline, shot, ENDER_ROI)
        var ionia_changed := _changed_bytes(baseline, shot, IONIA_ROI)
        # This is a non-blank proof against the same-place placeholder control,
        # NOT an aesthetic density score or source approval.
        if ender_changed < 500 or ionia_changed < 500:
            push_error("JOINT_FOURWAY_FAIL: character not materially visible in " + facing)
            quit(8)
            return
        var ender_pixels: PackedByteArray = shot.get_region(ENDER_ROI).get_data()
        var ionia_pixels: PackedByteArray = shot.get_region(IONIA_ROI).get_data()
        for prior in ender_proofs:
            if prior == ender_pixels:
                push_error("JOINT_FOURWAY_FAIL: duplicate Ender facing pixels")
                quit(9)
                return
        for prior in ionia_proofs:
            if prior == ionia_pixels:
                push_error("JOINT_FOURWAY_FAIL: duplicate Ionia facing pixels")
                quit(10)
                return
        ender_proofs.append(ender_pixels)
        ionia_proofs.append(ionia_pixels)
        print("JOINT_FOURWAY_FACING:" + facing +
            ":ENDER_CHANGED_BYTES=" + str(ender_changed) +
            ":IONIA_CHANGED_BYTES=" + str(ionia_changed))
    if ender_proofs.size() != 4 or ionia_proofs.size() != 4:
        push_error("JOINT_FOURWAY_FAIL: incomplete direction set")
        quit(11)
        return
    # Tear down all opt-in artwork, leaving original pilot defaults untouched.
    ender.set_walk_review_enabled(false)
    ionia.set_ionia_route_review_enabled(false)
    print("JOINT_FOURWAY_NATIVE_PASS: 5 real 960x640 captures at identical Ender/Ionia positions")
    print("JOINT_FOURWAY_STYLE_PARITY=NOT_ESTABLISHED")
    print("JOINT_FOURWAY_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
