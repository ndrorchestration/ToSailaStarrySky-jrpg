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

func _deck_brightness(frame: Image) -> float:
    # Neutral dock witnesses outside the spell core, camera/control fixed.
    # Proves expected relative tone ordering, not perceptual contrast compliance.
    var sum: float = 0.0
    for point in [Vector2i(185, 476), Vector2i(215, 495), Vector2i(755, 474), Vector2i(810, 495)]:
        sum += frame.get_pixelv(point).get_luminance()
    return sum / 4.0

func _silhouette_retention(reference: Image, without_actor: Image, with_behind_magic: Image, roi: Rect2i) -> Dictionary:
    # Mask inferred from real native Ender pixels; no guessed flat sprite rectangle.
    # Compare only opaque-ish actor pixels to a no-light behind-layer VFX frame.
    var n: int = 0
    var retained: int = 0
    for y in range(roi.position.y, roi.end.y):
        for x in range(roi.position.x, roi.end.x):
            var a: Color = reference.get_pixel(x, y)
            var absent: Color = without_actor.get_pixel(x, y)
            var actor_difference: float = absf(a.r - absent.r) + absf(a.g - absent.g) + absf(a.b - absent.b)
            if actor_difference < 0.24:
                continue
            n += 1
            var after: Color = with_behind_magic.get_pixel(x, y)
            var delta: float = absf(a.r - after.r) + absf(a.g - after.g) + absf(a.b - after.b)
            if delta <= 0.075:
                retained += 1
    return {"actor_pixels": n, "retained_pixels": retained, "retention": float(retained) / float(maxi(n, 1))}

func _pink_spirit_pixels(with_visual: Image, without_visual: Image, roi: Rect2i) -> int:
    # Distinctive magenta/pink chroma in *newly drawn* magic pixels, not Ender's sprite.
    # This is a candidate-art signal detector; it is not a perceptual acceptance score.
    var pixels: int = 0
    for y in range(roi.position.y, roi.end.y):
        for x in range(roi.position.x, roi.end.x):
            var a: Color = with_visual.get_pixel(x, y)
            var base: Color = without_visual.get_pixel(x, y)
            var delta: float = absf(a.r - base.r) + absf(a.g - base.g) + absf(a.b - base.b)
            if delta >= 0.11 and a.r > a.g + 0.05 and a.b > a.g + 0.05 and a.r > 0.22:
                pixels += 1
    return pixels

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
    # Derive the Ender shape mask from the exact Chapter I scene with only its
    # visual node hidden; restore immediately without touching gameplay state.
    review.world.ender.visible = false
    await process_frame
    var no_actor: Image = await _snapshot("chapter1-magic-dock-without-ender-native-960x640.png")
    review.world.ender.visible = true
    if no_actor == null:
        quit(28)
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
        if id == "lyra":
            var daytime_pink: int = _pink_spirit_pixels(frame, original, Rect2i(275, 315, 175, 190))
            print("STARRY_SKY_MAGIC_LYRA_PINK_DAY_PIXELS=" + str(daytime_pink))
            if daytime_pink < 10:
                push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: Lyra pink spirit motif missing under daylight")
                quit(29)
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
    var mask: Dictionary = _silhouette_retention(original, no_actor, unlit, Rect2i(316, 356, 89, 133))
    print("STARRY_SKY_MAGIC_ENDER_SILHOUETTE: pixels=" + str(mask["actor_pixels"]) + ":preserved=" + str(mask["retained_pixels"]) + ":ratio=" + str(mask["retention"]))
    if int(mask["actor_pixels"]) < 150 or float(mask["retention"]) < 0.94:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: behind-composited spell degraded original Ender silhouette")
        quit(30)
        return
    for hud_roi in [Rect2i(10, 8, 940, 91), Rect2i(10, 550, 940, 82)]:
        if _different(original, unlit, hud_roi):
            push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: VFX reached Chapter I HUD protection zone")
            quit(31)
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
    var day_luma: float = _deck_brightness(bright)
    var dusk_luma: float = _deck_brightness(dusk)
    var night_luma: float = _deck_brightness(night)
    print("STARRY_SKY_CHAPTER1_MAGIC_TONE_LUMINANCE: daylight=" + str(day_luma) + ":dusk=" + str(dusk_luma) + ":night=" + str(night_luma))
    if not (day_luma > dusk_luma + 0.015 and dusk_luma > night_luma + 0.015):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: brightness not monotonically ordered day > dusk > night")
        quit(26)
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
    if not _different(mist, rain, Rect2i(300, 232, 340, 180)):
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: mist and rain paint identical pixels")
        quit(27)
        return
    # Reuse the SAME actual night-mist scene for Lyra's spirit-color validation,
    # comparing against a matched background with VFX and light both disabled.
    review.set_weather_preset("mist")
    review.choose_affinity(1)
    await process_frame
    var lyra_mist: Image = await _snapshot("chapter1-magic-lyra-night-mist-native-960x640.png")
    if lyra_mist == null:
        quit(32)
        return
    review.set_magic_visible(false)
    await process_frame
    var mist_control: Image = await _snapshot("chapter1-magic-night-mist-no-vfx-native-960x640.png")
    if mist_control == null:
        quit(33)
        return
    var night_pink: int = _pink_spirit_pixels(lyra_mist, mist_control, Rect2i(275, 315, 175, 190))
    print("STARRY_SKY_MAGIC_LYRA_PINK_NIGHT_MIST_PIXELS=" + str(night_pink))
    if night_pink < 4:
        push_error("CHAPTER1_MAGIC_CAPTURE_FAIL: Lyra spirit-pink disappears under night mist")
        quit(34)
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
    print("STARRY_SKY_CHAPTER1_MAGIC_NATIVE_CAPTURE_PASS: real dock+Ender, silhouette and HUD protection, Lyra pink motif in day/night mist, lighting/weather A/B")
    print("STARRY_SKY_CHAPTER1_MAGIC_ART_ACCEPTANCE=PENDING")
    quit(0)
