extends SceneTree
## GPU-only controlled A/B scenes; do not call mock illustrations native captures.
const Review = preload("res://scenes/magic_vfx_environment_review.tscn")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const OUTPUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(label: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("MAGIC_ENV_CAPTURE_FAIL: incorrect native viewport")
        return null
    if image.save_png(OUTPUT + label) != OK:
        push_error("MAGIC_ENV_CAPTURE_FAIL: image write failed")
        return null
    print("STARRY_SKY_MAGIC_ENV_FRAME:" + label + ":960x640:" + FileAccess.get_sha256(OUTPUT + label))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("MAGIC_ENV_CAPTURE_FAIL: evidence directory inaccessible")
        quit(1)
        return
    var scene = Review.instantiate()
    root.add_child(scene)
    await process_frame
    var previous: Image = null
    for i in range(Catalog.CHARACTER_ORDER.size()):
        if not scene.choose_affinity(i):
            push_error("MAGIC_ENV_CAPTURE_FAIL: unavailable affinity")
            quit(2)
            return
        await process_frame
        var name: String = Catalog.CHARACTER_ORDER[i]
        var img: Image = await _snapshot("magic-env-" + name + "-lit-native-960x640.png")
        if img == null:
            quit(3)
            return
        if previous != null and img.get_region(Rect2i(290, 150, 210, 250)).get_data() == previous.get_region(Rect2i(290, 150, 210, 250)).get_data():
            push_error("MAGIC_ENV_CAPTURE_FAIL: lit affinity frames indistinguishable " + name)
            quit(4)
            return
        previous = img
    scene.choose_affinity(0)
    await process_frame
    var base: Image = await _snapshot("magic-env-ender-foreground-native-960x640.png")
    if base == null:
        quit(5)
        return
    scene.set_foreground_enabled(false)
    await process_frame
    var open_view: Image = await _snapshot("magic-env-ender-open-native-960x640.png")
    if open_view == null:
        quit(6)
        return
    if base.get_region(Rect2i(560, 245, 75, 140)).get_data() == open_view.get_region(Rect2i(560, 245, 75, 140)).get_data():
        push_error("MAGIC_ENV_CAPTURE_FAIL: foreground not blocking actual VFX pixels")
        quit(7)
        return
    scene.set_foreground_enabled(true)
    scene.set_light_enabled(false)
    await process_frame
    var unlit: Image = await _snapshot("magic-env-ender-unlit-native-960x640.png")
    if unlit == null:
        quit(8)
        return
    if base.get_region(Rect2i(461, 404, 62, 27)).get_data() == unlit.get_region(Rect2i(461, 404, 62, 27)).get_data():
        push_error("MAGIC_ENV_CAPTURE_FAIL: toggling PointLight2D did not change direct-lit stone witness")
        quit(9)
        return
    if not scene.seek_phase(3):
        push_error("MAGIC_ENV_CAPTURE_FAIL: impact keyframe denied")
        quit(10)
        return
    await process_frame
    var impact: Image = await _snapshot("magic-env-ender-impact-native-960x640.png")
    if impact == null:
        quit(11)
        return
    if unlit.get_region(Rect2i(285, 174, 215, 235)).get_data() == impact.get_region(Rect2i(285, 174, 215, 235)).get_data():
        push_error("MAGIC_ENV_CAPTURE_FAIL: impact made no world-space VFX change")
        quit(12)
        return
    scene.queue_free()
    await process_frame
    print("STARRY_SKY_MAGIC_ENV_CAPTURE_PASS: five native affinity-lit scenes plus foreground, unlit and impact A/B at 960x640")
    print("STARRY_SKY_MAGIC_ENV_ART_ACCEPTANCE=PENDING; this is 2D compositing, NOT depth-tested 3D integration")
    quit(0)
