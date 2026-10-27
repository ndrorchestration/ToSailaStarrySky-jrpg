extends SceneTree
## Reversible real-physics movement contract for Lyra, Aepex, Reson ONLY.
## No animation/footplant quality assertion, combat ability or field-pack approval.
const ReviewActor = preload("res://scripts/character_field_walk_review_actor.gd")
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const MAX_TICK_MOVE := 2.3

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("THREE_PHYSICS_WALK_FAIL: " + message)
    quit(code)

func _verify() -> void:
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    var positions := {}
    var seen := {}
    var previous_phases := {}
    var previous_facings := {}
    var held_distance := {}
    var max_held_distance := {}
    for character_id in NAMES:
        var actor = stage.get_actor(character_id)
        if actor == null or actor.is_queued_for_deletion():
            _fail("actor absent " + character_id, 1)
            return
        if actor.get("review_enabled") or actor.get("completed"):
            _fail("movement begins without opt-in", 2)
            return
        var sources: Dictionary = actor.get("source_sprites")
        if sources.size() != 4:
            _fail("wrong native source count: " + character_id, 3)
            return
        for facing in FACINGS:
            var sprite: Sprite2D = sources.get(facing)
            var original_source := "res://art-review/%s-%s-sixphase-v1-unapproved.svg" % [character_id.to_lower(), facing]
            if sprite == null or sprite.texture == null or sprite.texture.resource_path != original_source or sprite.hframes != 6 or sprite.flip_h:
                _fail("provenance/mirroring mismatch " + character_id + " " + facing, 4)
                return
            if sprite.visible != (facing == "south") or sprite.frame != 0:
                _fail("nondefault frame or direction: " + character_id, 5)
                return
        positions[character_id] = actor.global_position
        seen[character_id] = {"south": {}, "west": {}, "north": {}, "east": {}}
        previous_phases[character_id] = 0
        previous_facings[character_id] = "south"
        held_distance[character_id] = 0.0
        max_held_distance[character_id] = 0.0
    stage.start_all()
    var moving_world_ticks := 0
    for tick in range(340):
        await physics_frame
        var any_active := false
        for character_id in NAMES:
            var actor = stage.get_actor(character_id)
            var position: Vector2 = actor.global_position
            var moved: float = position.distance_to(positions[character_id])
            if moved > MAX_TICK_MOVE:
                _fail("non-physical teleport at tick %d: %s" % [tick, character_id], 6)
                return
            positions[character_id] = position
            if not actor.get("completed"):
                any_active = true
            if moved > 0.0001 and actor.get("completed"):
                # At final physical arrival, actor stops and deliberately resets to
                # idle atlas frame zero. This is not a walking-frame mismatch.
                if actor.get("current_phase") != 0 or actor.get("review_enabled"):
                    _fail("completed route did not return to idle source", 18)
                    return
            elif moved > 0.0001:
                moving_world_ticks += 1
                var facing: String = actor.get("facing")
                var phase: int = actor.get("current_phase")
                var travel: float = actor.get("travel_distance")
                if not FACINGS.has(facing) or phase != (int(travel / 12.5) % 6):
                    _fail("distance-driven phase diverged: " + character_id, 7)
                    return
                var sources: Dictionary = actor.get("source_sprites")
                for candidate in FACINGS:
                    var sprite: Sprite2D = sources[candidate]
                    if sprite.visible != (candidate == facing) or sprite.frame != phase or sprite.flip_h:
                        _fail("wrong original facing/frame/mirror: " + character_id, 8)
                        return
                seen[character_id][facing][phase] = true
                if facing == previous_facings[character_id] and phase == previous_phases[character_id]:
                    held_distance[character_id] += moved
                    max_held_distance[character_id] = maxf(max_held_distance[character_id], held_distance[character_id])
                else:
                    held_distance[character_id] = 0.0
                previous_phases[character_id] = phase
                previous_facings[character_id] = facing
        if not any_active:
            break
    if moving_world_ticks < 700:
        _fail("insufficient real physics ticks", 9)
        return
    for character_id in NAMES:
        var actor = stage.get_actor(character_id)
        if not actor.get("completed") or actor.get("segment") != 4 or actor.get("review_enabled"):
            _fail("four-leg world route incomplete: " + character_id, 10)
            return
        if actor.global_position.distance_to(actor.get("origin")) > 0.1:
            _fail("closed physics route does not return to anchor", 11)
            return
        if absf(actor.get("travel_distance") - 400.0) > 3.0:
            _fail("physics distance not within 400-unit path: " + character_id, 12)
            return
        if actor.get("collision_ticks") != 0:
            _fail("unobstructed actors collided unexpectedly", 13)
            return
        for facing in FACINGS:
            if seen[character_id][facing].size() < 6:
                _fail("less than six genuine phases while moving: %s %s" % [character_id, facing], 14)
                return
        if max_held_distance[character_id] > 17.0:
            _fail("excessive world movement while sprite contact frame held", 15)
            return
        print("THREE_PHYSICS_WALK_TRACE:%s:world_distance=%.2f:moving_ticks=%d:max_held_frame_translation=%.2f" % [
            character_id, actor.get("travel_distance"), actor.get("moving_ticks"), max_held_distance[character_id]])
    # Independent collision sentinel: the same CharacterBody2D MUST be physically
    # stopped by an actual StaticBody2D obstacle rather than pass through.
    var obstacle := StaticBody2D.new()
    obstacle.name = "StaticReviewObstacle"
    obstacle.collision_layer = 1
    obstacle.position = Vector2(115, 188)
    var stop_shape := CollisionShape2D.new()
    var wall := RectangleShape2D.new()
    wall.size = Vector2(40, 12)
    stop_shape.shape = wall
    obstacle.add_child(stop_shape)
    root.add_child(obstacle)
    var probe = ReviewActor.new()
    probe.name = "BlockedLyraReview"
    probe.set("character_id", "Lyra")
    probe.position = Vector2(115, 140)
    root.add_child(probe)
    await physics_frame
    probe.call("start_route_review")
    for tick in range(85):
        await physics_frame
    if probe.get("collision_ticks") < 1 or probe.global_position.y > 180.0 or probe.get("segment") != 0:
        _fail("physics collision barrier was bypassed", 16)
        return
    probe.call("stop_route_review")
    var stopped: Vector2 = probe.global_position
    for tick in range(5):
        await physics_frame
    if probe.global_position.distance_to(stopped) > 0.001 or probe.get("current_phase") != 0:
        _fail("blocked actor still translated after disabled", 17)
        return
    print("THREE_PHYSICS_WALK_OBSTACLE:COLLISION_TICKS=" + str(probe.get("collision_ticks")) + ":BLOCKED_Y=" + str(snappedf(stopped.y, 0.01)))
    print("THREE_PHYSICS_WALK_SOURCE_PIXEL_FOOT_PLANTS=NOT_CERTIFIED")
    print("THREE_PHYSICS_WALK_PASS: three actual closed physical routes, four facings x six phases, obstacle stop, reversible state")
    quit(0)
