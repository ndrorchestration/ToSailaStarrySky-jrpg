extends SceneTree
## Capture real Godot 960x640 scene in four genuine Ionia route orientations.
## Runner evidence is review-only, not available as a public/approved game asset.

const OUT := "res://review-evidence/"
const FRAME_NAMES := ["ionia-south-route-native-960x640.png", "ionia-west-route-native-960x640.png", "ionia-north-route-native-960x640.png", "ionia-east-route-native-960x640.png"]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("IONIA_CAPTURE_FAIL: cannot create review evidence path")
        quit(1)
        return
    world.set_dock_depth_review_enabled(true)
    world.ender.set_walk_review_enabled(true)
    var ionia = world.ionia
    ionia.set_ionia_route_review_enabled(true)
    var names := ["south", "west", "north", "east"]
    var samples := {}
    var positions := {}
    var last_segment := -1
    for i in range(412):
        await physics_frame
        var segment: int = ionia.ionia_route_segment
        # Save each view well into its own leg, with its native contact phase.
        if segment < 4 and segment != last_segment:
            last_segment = segment
        if segment < 4 and not samples.has(segment):
            var target_frames: Array[int] = [24, 28, 25, 28]
            var elapsed_frames: int = int(ionia.travel_distance / 14.8)
            if elapsed_frames % 6 >= 2 and i > (segment * 80 + 15):
                await RenderingServer.frame_post_draw
                var png := root.get_texture().get_image()
                if png.is_empty() or png.get_width() != 960 or png.get_height() != 640:
                    push_error("IONIA_CAPTURE_FAIL: missing actual native render surface")
                    quit(2)
                    return
                if ionia.ionia_facing != names[segment]:
                    push_error("IONIA_CAPTURE_FAIL: direction did not match route geometry")
                    quit(3)
                    return
                if png.save_png(OUT + FRAME_NAMES[segment]) != OK:
                    push_error("IONIA_CAPTURE_FAIL: could not store route capture")
                    quit(4)
                    return
                samples[segment] = png
                positions[segment] = ionia.global_position
    if samples.size() != 4:
        push_error("IONIA_CAPTURE_FAIL: missing at least one independently animated native orientation")
        quit(5)
        return
    for j in range(4):
        if not samples.has(j) or positions[j].distance_to(positions[(j + 1) % 4]) < 20.0:
            push_error("IONIA_CAPTURE_FAIL: view did not represent genuine distinct movement")
            quit(6)
            return
    print("IONIA_CAPTURE_PASS: four original Godot renderer views at 960x640, bounded NPC displacement")
    print("IONIA_CAPTURE_VISUAL_ACCEPTANCE=PENDING; artifact delivery blocked by Actions quota")
    quit(0)
