extends SceneTree
## Real playable-dock scene: test an opt-in visual-only distant ridge patch.
## No claims of forest geometry, planetary biomes or creator art admission.
const RidgeSurface = preload("res://scripts/dock_ridge_surface.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("RIDGE_VEGETATION_FAIL: " + message)
    quit(1)

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var patch: Node2D = world.get_node_or_null("RidgeVegetationReviewOnly")
    var back: Node2D = world.get_node_or_null("DockDepthBackgroundReviewOnly")
    var actors: Node2D = world.get_node_or_null("YSortedActors")
    if patch == null or back == null or actors == null or patch.visible:
        _fail("review patch absent or visible by default")
        return
    if not (patch.get_index() > back.get_index() and patch.get_index() < actors.get_index()):
        _fail("vegetation render order is not behind playable actors")
        return
    var collision_before: int = world.find_children("*","CollisionShape2D",true,false).size()
    var ender_pos: Vector2 = world.ender.position
    var ionia_pos: Vector2 = world.ionia.position
    var ender_bounds: Rect2 = world.ender.walking_bounds
    var ionia_bounds: Rect2 = world.ionia.walking_bounds
    var dialogue_open: bool = world.dialogue_open
    if patch.get_child_count() != 0:
        _fail("vegetation contains gameplay descendants")
        return
    var source_polygon: Array[Vector2] = RidgeSurface.ridge_polygon()
    if source_polygon.size() != 16 or source_polygon[0] != Vector2(0,319) or (
            source_polygon[13] != Vector2(960,263)) or (
            source_polygon[15] != Vector2(0,408)):
        _fail("underlying dock ridge drawing geometry drifted")
        return
    if patch.source_surface_id != RidgeSurface.SURFACE_ID or (
            patch.surface_anchors.size() != patch.ANCHOR_X.size()):
        _fail("vegetation did not bind to the actual authored ridge geometry")
        return
    var profile_was_sampled: bool = false
    for i in range(patch.surface_anchors.size()):
        var root_point: Vector2 = patch.surface_anchors[i]
        var query: Dictionary = RidgeSurface.sample_root(patch.ANCHOR_X[i])
        if not query["ok"] or root_point.distance_to(query["point"]) > 0.001:
            _fail("vegetation root differs from shared ridge sampler")
            return
        if root_point.y >= ender_bounds.position.y:
            _fail("vegetation would overlap the supported walking deck")
            return
        if i == 0:
            # This was a manually entered root in #513. Underlying profile
            # now owns the true, fractional foot position instead.
            profile_was_sampled = not is_equal_approx(root_point.y, 290.0)
    if not profile_was_sampled:
        _fail("study still depends on stale hand-entered root heights")
        return
    for bad_id in ["planet_world", "chapter1_walkable_deck"]:
        if RidgeSurface.sample_root(316.0, bad_id)["ok"]:
            _fail("surface adapter incorrectly authorizes another surface ID")
            return
    for rejected_x in [-1.0, 961.0, INF, NAN]:
        if RidgeSurface.sample_root(rejected_x)["ok"]:
            _fail("out-of-range or nonfinite probe was accepted")
            return
    world.set_ridge_vegetation_review_enabled(true)
    await process_frame
    if not world.dock_depth_review_enabled or not world.is_ridge_vegetation_review_enabled():
        _fail("explicit review cannot enable actual dock-depth presentation")
        return
    world.set_ridge_vegetation_low_quality(true)
    if not patch.low_quality:
        _fail("low detail setting did not propagate")
        return
    world.set_ridge_vegetation_low_quality(false)
    if patch.low_quality:
        _fail("high detail setting did not restore")
        return
    if world.find_children("*","CollisionShape2D",true,false).size() != collision_before:
        _fail("opt-in review introduced collider geometry")
        return
    if world.ender.position != ender_pos or world.ionia.position != ionia_pos or (
            world.ender.walking_bounds != ender_bounds or world.ionia.walking_bounds != ionia_bounds):
        _fail("visual-only scene changed actors or their walk surface")
        return
    if world.dialogue_open != dialogue_open:
        _fail("visual-only scene changed interaction state")
        return
    # The same real player pilot remains controllable with the scenery active.
    world.ender.set_walk_review_enabled(true)
    Input.action_press("ui_right")
    for i in range(12):
        await physics_frame
    Input.action_release("ui_right")
    if world.ender.position.x <= ender_pos.x:
        _fail("vegetation blocked real player movement")
        return
    world.set_ridge_vegetation_review_enabled(false)
    if patch.visible or not world.dock_depth_review_enabled:
        _fail("off state must retain the underlying dock-depth reference")
        return
    world.set_ridge_vegetation_review_enabled(true)
    world.set_dock_depth_review_enabled(false)
    if patch.visible or world.ridge_vegetation_review_enabled:
        _fail("disabling parent depth must hide and clear vegetation")
        return
    if world.find_children("*","CollisionShape2D",true,false).size() != collision_before:
        _fail("review toggle changed collision count after restore")
        return
    print("RIDGE_VEGETATION_PASS: shared authored ridge sampler, deterministic real surface roots, no new collision, real movement and reversible low detail")
    world.queue_free()
    await process_frame
    quit(0)
