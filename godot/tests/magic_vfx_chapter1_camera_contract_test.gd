extends SceneTree
## Real Chapter I scene graph integration, read-only with explicit camera and actor layering.
const Review = preload("res://scenes/magic_vfx_chapter1_camera_review.tscn")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var scene = Review.instantiate()
    root.add_child(scene)
    await process_frame
    var world = scene.world
    var actor_layer = world.get_node_or_null("ChapterOneMigrationActors")
    var foreground = world.get_node_or_null("ChapterOneDockForegroundReviewOnly")
    var background = world.get_node_or_null("ChapterOneDockBackgroundReviewOnly")
    if actor_layer == null or background == null or foreground == null:
        _fail("not using real Chapter I terrain/actor/foreground resources")
        return
    if not actor_layer.y_sort_enabled or scene.effect.get_parent() != actor_layer:
        _fail("magic visual bypasses native Y-sorted actors")
        return
    if not world.ender.walk_review_enabled or not world.ender.walk_review_sprite.visible:
        _fail("native Ender field-art candidate is not actually visible")
        return
    var ionia = world.contacts.get("elder_farmer", null)
    if ionia == null or ionia.visible or ionia.is_ionia_stage_art_enabled():
        _fail("the visual preview exposed Ionia before Contact")
        return
    if scene.active_index != 0 or not scene.reduced_motion or scene.effect.is_processing():
        _fail("unsafe default animation or character")
        return
    if world.ender.player_controlled or world.ender.is_physics_processing():
        _fail("review wrapper allows native actor movement")
        return
    if scene.effect.position != world.ender.position + scene.EFFECT_OFFSET:
        _fail("spell review is not anchored to native actor world coordinates")
        return
    var camera = scene.camera
    if not (camera is Camera2D) or camera.position != scene.DEFAULT_CAMERA or camera.zoom != Vector2.ONE:
        _fail("native 960x640 fixed framing default drift")
        return
    if not scene.effect.has_node("AtmosphericLens") or not scene.effect.has_node("CinematicMicroParticles"):
        _fail("magic VFX node did not reuse actual shader/particle assets")
        return
    if not scene.light_rig.has_node("PhysicalCanvasLight"):
        _fail("native 2D light not connected to actual dock scene")
        return
    var state_before: Dictionary = world.chapter.snapshot()
    var save_before: Dictionary = world.export_save_snapshot()
    var player_start: Vector2 = world.ender.global_position
    if scene.choose_affinity(-1) or scene.choose_affinity(5) or scene.seek_phase(-1) or scene.seek_phase(5):
        _fail("out-of-range study selection accepted")
        return
    for id in Catalog.CHARACTER_ORDER:
        var i: int = Catalog.CHARACTER_ORDER.find(id)
        if not scene.choose_affinity(i) or scene.effect.character_id != id:
            _fail("affinity-only review failed: " + id)
            return
        if not scene.seek_phase(3) or scene.effect.phase != "impact" or scene.effect.is_processing():
            _fail("visual-only impact keyframe could not be held: " + id)
            return
    scene.set_front_composite(true)
    if scene.effect.z_index != 1 or foreground.z_index != 8:
        _fail("front VFX compositing broke fixed foreground layer")
        return
    scene.set_front_composite(false)
    if scene.effect.z_index != -1:
        _fail("front/behind visual switch did not reverse")
        return
    scene.set_camera_closeup(true)
    if camera.zoom != Vector2(1.16, 1.16) or camera.position == scene.DEFAULT_CAMERA:
        _fail("isolated closeup framing unavailable")
        return
    scene.set_camera_closeup(false)
    if camera.position != scene.DEFAULT_CAMERA or camera.zoom != Vector2.ONE:
        _fail("camera framing did not return without scene mutations")
        return
    scene.set_magic_visible(false)
    if scene.effect.visible or scene.light_rig.light.visible:
        _fail("visual disable left lighting or geometry active")
        return
    scene.set_magic_visible(true)
    scene.set_lighting_enabled(false)
    if scene.light_rig.light.visible or not scene.effect.visible:
        _fail("light-only disable hid decorative magic")
        return
    scene.set_lighting_enabled(true)
    scene.set_reduced_motion(true)
    if not scene.effect.reduced_motion or scene.effect.is_processing():
        _fail("motion-safe default not maintained")
        return
    if world.chapter.snapshot() != state_before or world.export_save_snapshot() != save_before:
        _fail("visual preview changed Chapter I progression/save surface")
        return
    if world.ender.global_position != player_start or ionia.visible:
        _fail("visual preview changed characters or reveal gates")
        return
    scene.queue_free()
    await process_frame
    print("STARRY_SKY_CHAPTER1_MAGIC_COMPOSITE_PASS: native dock+Ender, reversible camera/light/occlusion, five affinities, unchanged chapter/save")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_CHAPTER1_MAGIC_COMPOSITE_FAIL: " + reason)
    quit(1)
