extends SceneTree
## Native framebuffer from actual Chapter I scene, not independently painted study set.
const Review = preload("res://scenes/magic_vfx_chapter1_camera_review.tscn")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const OUTPUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame.is_empty() or frame.get_width() != 960 or frame.get_height() != 640:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: native framebuffer dimensions invalid")
        return null
    if frame.save_png(OUTPUT + name) != OK:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: cannot save PNG " + name)
        return null
    print("STARRY_SKY_CHAPTER1_MAGIC_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(OUTPUT + name))
    return frame

func _different(a: Image, b: Image, roi: Rect2i) -> bool:
    return a.get_region(roi).get_data() != b.get_region(roi).get_data()

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: evidence directory unavailable")
        quit(1)
        return
    var review = Review.instantiate()
    root.add_child(review)
    await process_frame
    var before: Dictionary = review.world.chapter.snapshot()
    var save_before: Dictionary = review.world.export_save_snapshot()
    var actor_position: Vector2 = review.world.ender.global_position
    review.set_magic_visible(false)
    await process_frame
    var original: Image = await _snapshot("chapter1-magic-original-dock-native-960x640.png")
    if original == null:
        quit(2)
        return
    var previous: Image = null
    for i in range(Catalog.CHARACTER_ORDER.size()):
        review.set_magic_visible(true)
        if not review.choose_affinity(i):
            push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: affinity unavailable")
            quit(3)
            return
        await process_frame
        var id: String = Catalog.CHARACTER_ORDER[i]
        var frame: Image = await _snapshot("chapter1-magic-" + id + "-dock-native-960x640.png")
        if frame == null:
            quit(4)
            return
        var center := Rect2i(265, 302, 188, 208)
        if not _different(original, frame, center):
            push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: no native VFX drawn over real dock " + id)
            quit(5)
            return
        if previous != null and not _different(previous, frame, center):
            push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: affinity visuals identical " + id)
            quit(6)
            return
        previous = frame
    review.choose_affinity(0)
    review.set_front_composite(false)
    await process_frame
    var behind: Image = await _snapshot("chapter1-magic-ender-behind-native-960x640.png")
    if behind == null:
        quit(7)
        return
    review.set_front_composite(true)
    await process_frame
    var front: Image = await _snapshot("chapter1-magic-ender-front-native-960x640.png")
    if front == null:
        quit(8)
        return
    if not _different(behind, front, Rect2i(326, 350, 72, 134)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: effect front/behind layering made no actor-pixel difference")
        quit(9)
        return
    review.set_front_composite(false)
    review.set_lighting_enabled(false)
    await process_frame
    var unlit: Image = await _snapshot("chapter1-magic-ender-unlit-native-960x640.png")
    if unlit == null:
        quit(10)
        return
    if not _different(behind, unlit, Rect2i(300, 360, 170, 154)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: actual native dock does not respond to 2D light")
        quit(11)
        return
    review.set_lighting_enabled(true)
    review.set_camera_closeup(true)
    await process_frame
    var closeup: Image = await _snapshot("chapter1-magic-ender-camera-close-native-960x640.png")
    if closeup == null:
        quit(12)
        return
    if not _different(behind, closeup, Rect2i(245, 295, 255, 235)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: Camera2D closeup did not affect rendered pixels")
        quit(13)
        return
    # Same world/camera/actor coordinates across all isolated contrast measurements.
    review.set_camera_closeup(false)
    review.choose_affinity(0)
    review.set_lighting_enabled(true)
    review.set_lighting_preset("daylight")
    review.set_weather_preset("clear")
    await process_frame
    var bright: Image = await _snapshot("chapter1-magic-daylight-clear-native-960x640.png")
    if bright == null:
        quit(16)
        return
    if not review.set_lighting_preset("dusk"):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: dusk was refused")
        quit(17)
        return
    await process_frame
    var dusk: Image = await _snapshot("chapter1-magic-dusk-clear-native-960x640.png")
    if dusk == null:
        quit(18)
        return
    if not _different(bright, dusk, Rect2i(280, 410, 270, 100)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: dusk did not affect native dock lighting")
        quit(19)
        return
    review.set_lighting_preset("night")
    await process_frame
    var night: Image = await _snapshot("chapter1-magic-night-clear-native-960x640.png")
    if night == null:
        quit(20)
        return
    if not _different(dusk, night, Rect2i(280, 410, 270, 100)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: night did not affect native dock lighting")
        quit(21)
        return
    review.set_weather_preset("mist")
    await process_frame
    var mist: Image = await _snapshot("chapter1-magic-night-mist-native-960x640.png")
    if mist == null:
        quit(22)
        return
    if not _different(night, mist, Rect2i(300, 232, 340, 180)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: mist not visibly distinguishable")
        quit(23)
        return
    review.set_weather_preset("rain")
    await process_frame
    var rain: Image = await _snapshot("chapter1-magic-night-rain-native-960x640.png")
    if rain == null:
        quit(24)
        return
    if not _different(night, rain, Rect2i(300, 232, 340, 180)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: rain not visibly distinguishable")
        quit(25)
        return
    if review.world.chapter.snapshot() != before or review.world.export_save_snapshot() != save_before:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: visual captures changed Chapter I durable state")
        quit(14)
        return
    if review.world.ender.global_position != actor_position:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: camera/compositing moved Ender")
        quit(15)
        return
    review.queue_free()
    await process_frame
    print("STARRY_SKY_CHAPTER1_MAGIC_NATIVE_CAPTURE_PASS: real dock+Ender, five affinities, layering and camera, daylight/dusk/night + mist/rain A/B")
    print("STARRY_SKY_CHAPTER1_MAGIC_ART_ACCEPTANCE=PENDING")
    quit(0)
