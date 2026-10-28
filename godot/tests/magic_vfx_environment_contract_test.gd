extends SceneTree
## Admission guard for opt-in 2D lighting, layer ordering and fail-closed visual scope.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const Review = preload("res://scenes/magic_vfx_environment_review.tscn")

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var scene = Review.instantiate()
    root.add_child(scene)
    await process_frame
    if scene.active_index != 0 or not scene.reduced_motion or not scene.lighting_enabled or not scene.foreground_enabled:
        _fail("incorrect accessibility or isolated preview defaults")
        return
    if scene.effect.character_id != "ender" or scene.effect.is_processing():
        _fail("VFX preview must be static by default")
        return
    var rig = scene.get_node_or_null("AffinityLightRig")
    var light = rig.get_node_or_null("PhysicalCanvasLight")
    var front = scene.get_node_or_null("OccludingStoneColumn")
    var occluder = front.get_node_or_null("StoneLightOccluder")
    if light == null or not (light is PointLight2D) or light.texture == null:
        _fail("real PointLight2D radial texture unavailable")
        return
    if not light.shadow_enabled or not (occluder is LightOccluder2D) or occluder.occluder == null:
        _fail("real 2D occlusion/shadow resource unavailable")
        return
    if not front.visible or front.z_index <= scene.effect.z_index:
        _fail("foreground draw ordering violated")
        return
    if scene.seek_phase(-1) or scene.seek_phase(5) or scene.choose_affinity(5) or scene.choose_affinity(-1):
        _fail("review accepted unregistered timing or character")
        return
    for identity in Catalog.CHARACTER_ORDER:
        var index: int = Catalog.CHARACTER_ORDER.find(identity)
        if not scene.choose_affinity(index) or scene.effect.character_id != identity:
            _fail("authored affinity dispatch failed: " + identity)
            return
        if light.color != Color(str(Catalog.profile(identity)["color"])):
            _fail("physical light color routing drift: " + identity)
            return
        if not scene.seek_phase(3) or scene.effect.phase != "impact" or scene.effect.is_processing():
            _fail("impact preview cannot pause deterministically: " + identity)
            return
    scene.set_light_enabled(false)
    if light.visible or not scene.foreground.visible:
        _fail("lighting opt-out affected foreground or left light enabled")
        return
    scene.set_foreground_enabled(false)
    if occluder.is_visible_in_tree() or front.visible:
        _fail("occlusion toggle failed to hide geometry and occluder together")
        return
    scene.set_foreground_enabled(true)
    scene.set_light_enabled(true)
    if not front.visible or not light.visible:
        _fail("preview toggles are not reversible")
        return
    scene.set_reduced_motion(true)
    if not scene.effect.reduced_motion or scene.effect.is_processing():
        _fail("motion-safe static phase reset failed")
        return
    scene.queue_free()
    await process_frame
    print("STARRY_SKY_MAGIC_ENVIRONMENT_PASS: independent real 2D light, shadow occluder, reversible foreground and all five stateless affinities")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_MAGIC_ENVIRONMENT_FAIL: " + reason)
    quit(1)
