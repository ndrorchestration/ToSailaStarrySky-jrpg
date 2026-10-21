extends SceneTree
## Review-only source-bound sole-landmark motion trace.
## The lower boot mark is NOT an artist-annotated stance/plant event.
## This probes actual Godot CharacterBody2D motion, not simulated coordinates.

const SOURCE_CELL := Vector2(512.0, 768.0)
const SOURCE_FRAME_OFFSET_X := 230.4
const SOURCE_BOOT_EXPECTED_Y_REAR := 731.0
const SOURCE_BOOT_EXPECTED_Y_FRONT := 727.0
const ROUTE_LIMIT_TICKS := 430
const EXPECTED_ROUTE_PIXELS := 382.0
const TRACKED_FACINGS := ["east", "west"]

func _initialize() -> void:
    call_deferred("_trace")

func _boot_sole_vertex(source: String, facing: String, limb: String, phase: int) -> Vector2:
    var group_tag := '<g id="' + facing + '-v4-' + limb + '-leg-' + str(phase) + '">'
    var start: int = source.find(group_tag)
    if start < 0:
        return Vector2(-1.0, -1.0)
    var end: int = source.find("</g>", start)
    if end < 0:
        return Vector2(-1.0, -1.0)
    var group := source.substr(start, end - start)
    var boot_fill: int = group.find('fill="url(#boot)"')
    if boot_fill < 0:
        return Vector2(-1.0, -1.0)
    var path_start: int = group.rfind('<path d="', boot_fill)
    if path_start < 0:
        return Vector2(-1.0, -1.0)
    var d_start: int = path_start + len('<path d="')
    var d_end: int = group.find('"', d_start)
    if d_end <= d_start:
        return Vector2(-1.0, -1.0)
    # Source boot polygon starts M{x} {y} L{x} {y} L{x} {y}.
    # The 3rd vertex is the material boot toe/sole corner in every v4 phase.
    var tokens: PackedStringArray = group.substr(d_start, d_end - d_start).split(" ", false)
    if tokens.size() < 6 or not tokens[0].begins_with("M") or not tokens[2].begins_with("L") or not tokens[4].begins_with("L"):
        return Vector2(-1.0, -1.0)
    if not tokens[4].substr(1).is_valid_float() or not tokens[5].is_valid_float():
        return Vector2(-1.0, -1.0)
    return Vector2(float(tokens[4].substr(1)) + SOURCE_FRAME_OFFSET_X, float(tokens[5]))

func _trace() -> void:
    var boots: Dictionary = {}
    for facing in TRACKED_FACINGS:
        var path: String = "res://art-review/ionia-" + facing + "-sidebody-v4-candidate.svg"
        var source: String = FileAccess.get_file_as_string(path)
        if source.is_empty() or source.count('id="' + facing + '-v4-pose-') != 6:
            push_error("SOLE_TRACE_FAIL: missing or altered six-frame V4 source: " + facing)
            quit(1)
            return
        boots[facing] = {}
        for phase in range(6):
            var rear: Vector2 = _boot_sole_vertex(source, facing, "rear", phase)
            var front: Vector2 = _boot_sole_vertex(source, facing, "front", phase)
            if rear.x < 145.0 or rear.x > 367.0 or front.x < 145.0 or front.x > 367.0:
                push_error("SOLE_TRACE_FAIL: SVG boot marker escapes source frame")
                quit(2)
                return
            if absf(rear.y - SOURCE_BOOT_EXPECTED_Y_REAR) > 0.01 or absf(front.y - SOURCE_BOOT_EXPECTED_Y_FRONT) > 0.01:
                push_error("SOLE_TRACE_FAIL: boot lowest-source marker semantics changed")
                quit(3)
                return
            boots[facing][phase] = {"rear": rear, "front": front}
        print("SOLE_SOURCE_BINDING:" + facing + ":SIX_REAR_AND_FRONT_BOOT_PATHS=PASS:LOWEST_DRAWN_REAR=true")

    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ionia = world.ionia
    if ionia == null:
        push_error("SOLE_TRACE_FAIL: no real Godot actor")
        quit(4)
        return
    world.ender.set_physics_process(false)
    ionia.set_ionia_route_review_enabled(true)

    var max_segment_translation: Dictionary = {"east": 0.0, "west": 0.0}
    var cumulative_sole_translation: Dictionary = {"east": 0.0, "west": 0.0}
    var phase_coverage: Dictionary = {"east": {}, "west": {}}
    var measurement_ticks: Dictionary = {"east": 0, "west": 0}
    var sample_count: Dictionary = {"east": 0, "west": 0}
    var current_facing := ""
    var current_frame := -1
    var start_world: Vector2 = Vector2.ZERO
    var previous_world: Vector2 = Vector2.ZERO
    var previous_position: Vector2 = ionia.global_position
    var current_segment_samples := 0
    var route_distance := 0.0

    for tick in range(ROUTE_LIMIT_TICKS):
        await physics_frame
        var position: Vector2 = ionia.global_position
        var moved: float = position.distance_to(previous_position)
        previous_position = position
        if moved > 3.0:
            push_error("SOLE_TRACE_FAIL: native route position jumped")
            quit(5)
            return
        route_distance += moved
        if moved <= 0.001:
            continue
        var facing: String = ionia.ionia_facing
        if not TRACKED_FACINGS.has(facing):
            current_facing = ""
            current_frame = -1
            current_segment_samples = 0
            continue
        var sprite: Sprite2D = ionia.ionia_east_walk_sprite if facing == "east" else ionia.ionia_west_walk_sprite
        var frame: int = sprite.frame
        if not sprite.visible or frame < 0 or frame >= 6:
            push_error("SOLE_TRACE_FAIL: wrong native moving sprite/phase")
            quit(6)
            return
        if frame != int(ionia.travel_distance / 14.8) % 6:
            push_error("SOLE_TRACE_FAIL: source-landmark trace disconnected from runtime gait")
            quit(7)
            return
        phase_coverage[facing][frame] = true
        sample_count[facing] += 1
        # Sprite2D hframes=6, center=true, scale=0.13. The lower rear boot
        # sole vertex is a SOURCE-BOUND geometry landmark, not an assigned
        # planted-foot gait marker.
        var rear: Vector2 = boots[facing][frame]["rear"]
        var front: Vector2 = boots[facing][frame]["front"]
        var selected: Vector2 = rear if rear.y >= front.y else front
        var sprite_local: Vector2 = selected - SOURCE_CELL * 0.5
        var sole_world: Vector2 = sprite.to_global(sprite_local)
        var relative_world_y: float = sole_world.y - ionia.global_position.y
        if relative_world_y < -5.0 or relative_world_y > 5.0:
            push_error("SOLE_TRACE_FAIL: sole mark separated from actor/dock anchor")
            quit(8)
            return
        if facing == current_facing and frame == current_frame:
            var movement: float = sole_world.distance_to(previous_world)
            cumulative_sole_translation[facing] += movement
            measurement_ticks[facing] += 1
            current_segment_samples += 1
            if current_segment_samples >= 2:
                max_segment_translation[facing] = maxf(max_segment_translation[facing], sole_world.distance_to(start_world))
        else:
            current_facing = facing
            current_frame = frame
            start_world = sole_world
            current_segment_samples = 1
        previous_world = sole_world

    if ionia.ionia_route_segment != 4 or absf(route_distance - EXPECTED_ROUTE_PIXELS) > 1.0:
        push_error("SOLE_TRACE_FAIL: not the expected completed real native route")
        quit(9)
        return
    for facing in TRACKED_FACINGS:
        if phase_coverage[facing].size() != 6 or sample_count[facing] < 70 or measurement_ticks[facing] < 50:
            push_error("SOLE_TRACE_FAIL: incomplete side-view actual-world observations: " + facing)
            quit(10)
            return
        var held_max: float = max_segment_translation[facing]
        if held_max < 0.0 or held_max > 15.5:
            push_error("SOLE_TRACE_FAIL: implausible source-bound lower boot marker motion")
            quit(11)
            return
        print("SOLE_TRACE_OBSERVATION:" + facing +
            ":HELD_FRAME_MAX_WORLD_DISPLACEMENT=" + str(snappedf(held_max, 0.01)) +
            ":SAME_FRAME_SOLE_TRAVEL_WORLD_PIXELS=" + str(snappedf(cumulative_sole_translation[facing], 0.01)) +
            ":OBSERVED_SAME_FRAME_TICKS=" + str(measurement_ticks[facing]) +
            ":PHASES=6")
        if held_max >= 3.0:
            print("SOLE_TRACE_LOWER_BOOT_MOTION_RISK:" + facing + "=OBSERVED")
        else:
            print("SOLE_TRACE_LOWER_BOOT_MOTION_RISK:" + facing + "=LOW_IN_THIS_TRACE")
    ionia.set_ionia_route_review_enabled(false)
    if ionia.is_ionia_route_review_enabled() or ionia.is_review_art_enabled():
        push_error("SOLE_TRACE_FAIL: opt-in not reversible")
        quit(12)
        return
    print("SOLE_TRACE_PASS: source-linked v4 boot geometries and actual CharacterBody2D route observations")
    print("SOLE_TRACE_STANCE_PHASE_LABELS=NOT_AUTHORED")
    print("SOLE_TRACE_PHYSICALLY_PLANTED_FOOT_SLIDE=NOT_ESTABLISHED")
    print("SOLE_TRACE_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
