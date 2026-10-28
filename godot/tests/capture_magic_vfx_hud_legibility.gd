extends SceneTree
## Renderer-observed UI legibility under real Chapter I VFX, lighting and weather presets.
## Pixels are a conservative image-space proxy, NOT formal WCAG or human art review.
const Review = preload("res://scenes/magic_vfx_chapter1_camera_review.tscn")
const OUT = "res://review-evidence/"
const CONDITIONS = [
    {"id":"day-clear", "time":"daylight", "weather":"clear", "closeup":false},
    {"id":"dusk-mist", "time":"dusk", "weather":"mist", "closeup":false},
    {"id":"night-rain", "time":"night", "weather":"rain", "closeup":false},
    {"id":"night-rain-closeup", "time":"night", "weather":"rain", "closeup":true},
]
const UI_REGIONS = {
    "headline": Rect2i(24, 16, 470, 31),
    "objective": Rect2i(24, 54, 565, 39),
    "hint": Rect2i(28, 567, 890, 57),
}

func _initialize() -> void:
    call_deferred("_run")

func _snapshot(filename: String) -> Image:
    await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        push_error("MAGIC_HUD_QA_FAIL: no actual 960x640 frame")
        return null
    if img.save_png(OUT + filename) != OK:
        push_error("MAGIC_HUD_QA_FAIL: failed to save " + filename)
        return null
    print("STARRY_SKY_MAGIC_HUD_FRAME:" + filename + ":960x640:" + FileAccess.get_sha256(OUT + filename))
    return img

func _brightness(c: Color) -> float:
    var linear: Color = c.srgb_to_linear()
    return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func _glyph_contrast(visible_image: Image, hidden_image: Image, bounds: Rect2i) -> Dictionary:
    # Derive glyph witness pixels by hiding only the native CanvasLayer labels.
    # This isolates actual UI strokes from the same environmental backdrop.
    var ratios := PackedFloat32Array()
    for y in range(bounds.position.y, bounds.end.y):
        for x in range(bounds.position.x, bounds.end.x):
            var ink: float = _brightness(visible_image.get_pixel(x, y))
            var background: float = _brightness(hidden_image.get_pixel(x, y))
            if ink - background >= 0.14:
                ratios.append((ink + 0.05) / (background + 0.05))
    ratios.sort()
    if ratios.is_empty():
        return {"glyph_pixels":0, "median_ratio":0.0, "p10_ratio":0.0}
    return {
        "glyph_pixels":ratios.size(),
        "median_ratio":ratios[ratios.size() / 2],
        "p10_ratio":ratios[int(float(ratios.size() - 1) * 0.1)]
    }

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("MAGIC_HUD_QA_FAIL: output directory inaccessible")
        quit(1)
        return
    var review = Review.instantiate()
    root.add_child(review)
    await process_frame
    if not review.reduced_motion or review.world.ender.player_controlled:
        push_error("MAGIC_HUD_QA_FAIL: unsafe review defaults")
        quit(2)
        return
    var before_state: Dictionary = review.world.chapter.snapshot()
    var before_save: Dictionary = review.world.export_save_snapshot()
    var before_position: Vector2 = review.world.ender.global_position
    var ui = review.world.get_node_or_null("ChapterOneMigrationUI")
    if ui == null or not (ui is CanvasLayer) or not ui.visible:
        push_error("MAGIC_HUD_QA_FAIL: did not find actual Chapter I UI CanvasLayer")
        quit(3)
        return
    if review._camera_ui_scrims.size() != 2:
        push_error("MAGIC_HUD_QA_FAIL: closeup contrast panels missing")
        quit(9)
        return
    for scrim in review._camera_ui_scrims:
        if scrim.visible or scrim.get_parent() != ui:
            push_error("MAGIC_HUD_QA_FAIL: closeup UI correction leaked into normal camera")
            quit(10)
            return
    review.choose_affinity(1) # Lyra's pink/light stress case, visual-only.
    review.seek_phase(3) # pause at cinematic impact.
    for condition in CONDITIONS:
        var id: String = condition["id"]
        if not review.set_lighting_preset(condition["time"]) or not review.set_weather_preset(condition["weather"]):
            push_error("MAGIC_HUD_QA_FAIL: rejected condition " + id)
            quit(4)
            return
        review.set_camera_closeup(condition["closeup"])
        for scrim in review._camera_ui_scrims:
            if scrim.visible != bool(condition["closeup"]):
                push_error("MAGIC_HUD_QA_FAIL: screen-space scrim not synchronized to camera")
                quit(11)
                return
        review.set_magic_visible(true)
        ui.visible = true
        await process_frame
        var on: Image = await _snapshot("chapter1-magic-hud-" + id + "-visible-native-960x640.png")
        if on == null:
            quit(5)
            return
        ui.visible = false
        await process_frame
        var off: Image = await _snapshot("chapter1-magic-hud-" + id + "-hidden-native-960x640.png")
        ui.visible = true
        if off == null:
            quit(6)
            return
        for key in UI_REGIONS:
            var result: Dictionary = _glyph_contrast(on, off, UI_REGIONS[key])
            print("STARRY_SKY_MAGIC_HUD_CONTRAST:" + id + ":" + key +
                ":pixels=" + str(result["glyph_pixels"]) +
                ":median=" + str(result["median_ratio"]) +
                ":p10=" + str(result["p10_ratio"]))
            # Engineering witness floor. This does not certify all accessibility text.
            if int(result["glyph_pixels"]) < 70 or float(result["median_ratio"]) < 4.5 or float(result["p10_ratio"]) < 3.5:
                push_error("MAGIC_HUD_QA_FAIL: native UI median/p10 glyph contrast witness below candidate gate " + id + "/" + key)
                quit(7)
                return
    if review.world.chapter.snapshot() != before_state or review.world.export_save_snapshot() != before_save or review.world.ender.global_position != before_position:
        push_error("MAGIC_HUD_QA_FAIL: optical review changed Chapter I state")
        quit(8)
        return
    review.queue_free()
    await process_frame
    print("STARRY_SKY_MAGIC_HUD_NATIVE_PASS: actual Chapter I text contrast witness under four environments including camera closeup; gameplay state unchanged")
    print("STARRY_SKY_MAGIC_HUD_ACCESSIBILITY_CERTIFICATION=NOT_ESTABLISHED")
    quit(0)
