extends SceneTree
## Real native displacement + frame-cadence trace, not a human acceptance oracle.
## Capture uses actual OpenGL/Xvfb pixels only when env flag explicitly enabled.

const OUT := "res://review-evidence/"
const PHASE_PIXELS := 14.8
const MAX_PER_TICK_DISPLACEMENT := 3.0
const REQUIRED_FACINGS := ["south", "west", "north", "east"]
const SELECTED_PHASES := [1, 4]

func _initialize() -> void:
    call_deferred("_trace")

func _snapshot(facing: String, phase: int) -> bool:
    await RenderingServer.frame_post_draw
    var captured: Image = root.get_texture().get_image()
    if captured.is_empty() or captured.get_width() != 960 or captured.get_height() != 640:
        push_error("MOVING_GAIT_FAIL: real native capture resolution incorrect")
        return false
    var path := OUT + "ionia-moving-" + facing + "-phase-" + str(phase) + "-native-960x640.png"
    if captured.save_png(path) != OK:
        push_error("MOVING_GAIT_FAIL: unable to save original native screenshot: " + path)
        return false
    print("MOVING_GAIT_REAL_PNG:" + facing + ":phase=" + str(phase) + ":sha256=" + FileAccess.get_sha256(path))
    return true

func _trace() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ionia = world.ionia
    var ender = world.ender
    if ionia == null or ender == null:
        push_error("MOVING_GAIT_FAIL: native First Wake actors missing")
        quit(1)
        return
    ender.set_physics_process(false)
    world.set_dock_depth_review_enabled(true)
    var capture_enabled := OS.get_environment("AW_REAL_MOVING_CAPTURE") == "1"
    if capture_enabled:
        if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
            push_error("MOVING_GAIT_FAIL: capture directory inaccessible")
            quit(2)
            return
    ionia.set_ionia_route_review_enabled(true)
    var previous_position: Vector2 = ionia.global_position
    var previous_distance: float = ionia.travel_distance
    var previous_facing := ""
    var previous_phase := -1
    var observed: Dictionary = {}
    var counts: Dictionary = {}
    var captured: Dictionary = {}
    var max_held_frame_translation := 0.0
    var current_held_frame_translation := 0.0
    var total_translation := 0.0
    var active_ticks := 0
    var last_segment := 0
    for tick in range(430):
        await physics_frame
        var position: Vector2 = ionia.global_position
        var moved: float = position.distance_to(previous_position)
        if moved > MAX_PER_TICK_DISPLACEMENT:
            push_error("MOVING_GAIT_FAIL: discontinuous route step at tick " + str(tick))
            quit(3)
            return
        if not ionia.walking_bounds.has_point(position):
            push_error("MOVING_GAIT_FAIL: moved outside native deck")
            quit(4)
            return
        if moved > 0.001:
            active_ticks += 1
            total_translation += moved
            var facing: String = ionia.ionia_facing
            if not REQUIRED_FACINGS.has(facing):
                push_error("MOVING_GAIT_FAIL: unknown direction while moving")
                quit(5)
                return
            var sprites := {
                "south": ionia.ionia_front_walk_sprite,
                "west": ionia.ionia_west_walk_sprite,
                "north": ionia.ionia_north_walk_sprite,
                "east": ionia.ionia_east_walk_sprite
            }
            var active: Sprite2D = sprites[facing]
            var frame: int = active.frame
            var expected: int = int(ionia.travel_distance / PHASE_PIXELS) % 6
            if frame != expected or not active.visible:
                push_error("MOVING_GAIT_FAIL: displayed frame differs from distance-based phase")
                quit(6)
                return
            for alternate in sprites:
                if sprites[alternate].visible != (alternate == facing):
                    push_error("MOVING_GAIT_FAIL: multiple directions visible during translation")
                    quit(7)
                    return
            if ionia.travel_distance < previous_distance - 0.001:
                push_error("MOVING_GAIT_FAIL: travel distance decreased while moving")
                quit(8)
                return
            if not observed.has(facing):
                observed[facing] = {}
                counts[facing] = 0
            observed[facing][frame] = true
            counts[facing] += 1
            if facing == previous_facing and frame == previous_phase:
                # Every pixel of a held sprite frame moves with the actor root.
                # This is a proxy for potential foot-slide, NOT proof of a planted foot.
                current_held_frame_translation += moved
                max_held_frame_translation = maxf(max_held_frame_translation, current_held_frame_translation)
            else:
                current_held_frame_translation = 0.0
            if capture_enabled and SELECTED_PHASES.has(frame):
                var key := facing + "-" + str(frame)
                if not captured.has(key):
                    if not await _snapshot(facing, frame):
                        quit(9)
                        return
                    captured[key] = true
            previous_facing = facing
            previous_phase = frame
            last_segment = ionia.ionia_route_segment
        previous_position = position
        previous_distance = ionia.travel_distance
    if ionia.ionia_route_segment != 4 or ionia.global_position.distance_to(Vector2(570, 419)) > 0.5:
        push_error("MOVING_GAIT_FAIL: route incomplete or end position changed")
        quit(10)
        return
    if active_ticks < 250 or active_ticks > 410 or total_translation < 370.0 or total_translation > 400.0:
        push_error("MOVING_GAIT_FAIL: unexpected moving duration or traveled route length")
        quit(11)
        return
    for facing in REQUIRED_FACINGS:
        if not observed.has(facing) or observed[facing].size() != 6:
            push_error("MOVING_GAIT_FAIL: incomplete six-phase movement for " + facing)
            quit(12)
            return
        print("MOVING_GAIT_PHASES:" + facing + ":ticks=" + str(counts[facing]) + ":unique=6")
        if capture_enabled:
            for phase in SELECTED_PHASES:
                if not captured.has(facing + "-" + str(phase)):
                    push_error("MOVING_GAIT_FAIL: missing original moving capture: " + facing)
                    quit(13)
                    return
    print("MOVING_GAIT_MEASURED:ACTIVE_TICKS=" + str(active_ticks) +
        ":TRAVEL_WORLD_PIXELS=" + str(snappedf(total_translation, 0.01)) +
        ":MAX_TRANSLATION_DURING_HELD_ATLAS_FRAME=" + str(snappedf(max_held_frame_translation, 0.01)) +
        ":LAST_SEGMENT=" + str(last_segment))
    print("MOVING_GAIT_SOURCE_PIXEL_FOOT_PLANT=NOT_IDENTIFIED")
    print("MOVING_GAIT_SHADOW_ART_ACCEPTANCE=NOT_ESTABLISHED")
    print("MOVING_GAIT_PASS: real four-direction translation/frame-cadence trace, review-only")
    ionia.set_ionia_route_review_enabled(false)
    if ionia.is_ionia_route_review_enabled() or ionia.is_review_art_enabled():
        push_error("MOVING_GAIT_FAIL: review not fully reversible")
        quit(14)
        return
    quit(0)
