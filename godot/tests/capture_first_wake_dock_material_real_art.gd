extends SceneTree
## Real Windows/OpenGL capture with creator-private JPEGs and matte-v3 PNGs.
## No embedded source art, no synthetic image substitution and no gameplay writes.
const Game = preload("res://scenes/first_wake_game.tscn")
const EXPECTED_SHA := {
    "res://art-review/creator-portrait-preview/ionia_hifi_review_crop.jpg": "ff38540a3b845f20078989d7523cb2e3e6911a8ff886fe8647c1a46fa3e7c07c",
    "res://art-review/creator-portrait-preview/ender_hifi_review_crop.jpg": "2e7d296698755157da194275a68f01a96b8e69131e69c0128995fee66895e413",
    "res://art-review/creator-field-review/ionia_field_matte_v3.png": "37d7cc3c852bbf5497e94e38502fb8aa35512f5492cf9a12abdf0eff49b11c49",
    "res://art-review/creator-field-review/ender_field_matte_v3.png": "8127ec4b87086027887c145fbde72704c61ad1d20d44395b111b3145d98660ca",
}
var problems: Array[String] = []
var target_dir: String = ""

func _initialize() -> void:
    call_deferred("_run")

func _bad(message: String) -> void:
    problems.append(message)
    push_error("TSTSS_DOCK_MATERIAL_RENDER_FAIL:" + message)

func _shot(label: String) -> Image:
    await process_frame
    await RenderingServer.frame_post_draw
    await process_frame
    await RenderingServer.frame_post_draw
    var result: Image = root.get_viewport().get_texture().get_image()
    if result == null or result.get_size() != Vector2i(960, 640):
        _bad("expected real native 960x640 frame " + label)
        return null
    var destination: String = target_dir.path_join("creator_dock_material_" + label + "_native_960x640.png")
    if result.save_png(destination) != OK:
        _bad("could not save native PNG " + label)
    else:
        print("TSTSS_DOCK_MATERIAL_NATIVE_FRAME:", label, ":SHA256:", FileAccess.get_sha256(destination), ":FILE:", destination)
    return result

func _pixel_difference(first: Image, second: Image, area: Rect2i) -> Dictionary:
    var count: int = 0
    var changed: int = 0
    var sum_delta: float = 0.0
    for y in range(area.position.y, area.end.y, 3):
        for x in range(area.position.x, area.end.x, 3):
            var a: Color = first.get_pixel(x, y)
            var b: Color = second.get_pixel(x, y)
            var diff: float = absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
            count += 1
            sum_delta += diff / 3.0
            if diff > 0.02:
                changed += 1
    return {"changed": changed, "samples": count, "mean_delta": sum_delta / float(maxi(count, 1))}

func _run() -> void:
    for path in EXPECTED_SHA:
        if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != EXPECTED_SHA[path]:
            _bad("real creator source missing or wrong SHA-256: " + path)
    if not problems.is_empty():
        quit(1)
        return
    target_dir = ProjectSettings.globalize_path("user://first_wake_dock_material_evidence")
    if DirAccess.make_dir_recursive_absolute(target_dir) != OK:
        _bad("could not create private local evidence folder")
        quit(1)
        return
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    if game.job == null or game.postflight != null:
        _bad("actual flyer dock not loaded")
        quit(1)
        return
    var dock = game.job
    dock.ender.position = dock.FLYER_POSITION
    dock.interact()
    var progressed: int = 0
    while dock.dialogue_open and progressed < 18:
        dock.interact()
        progressed += 1
    if not dock.flyer_read:
        _bad("real opening flyer did not advance")
    dock.ender.position = dock.IONIA_DOCK_POSITION
    dock.interact()
    dock.ender.position = dock.FLYER_POSITION
    if not dock.ender.enable_creator_standee(true) or not dock.ionia.enable_creator_standee(true):
        _bad("creator full-body source figures did not load")
    if dock.ender.creator_standee_variant != "matte_v3" or dock.ionia.creator_standee_variant != "matte_v3":
        _bad("native frame is not using exact creator matte v3 art")
    if dock.portrait_preview == null or not dock.portrait_preview.visible:
        _bad("creator dialogue portrait not visible in real interview")
    if not problems.is_empty():
        game.queue_free()
        quit(1)
        return
    dock._sync_presentation()
    var refined: Image = await _shot("refined")
    var toggle := InputEventKey.new()
    toggle.keycode = KEY_M
    toggle.pressed = true
    dock._unhandled_input(toggle)
    if dock.dock_background.refined_materials_enabled:
        _bad("M failed to disable material overlay")
    dock._sync_presentation()
    var legacy: Image = await _shot("original")
    dock._unhandled_input(toggle)
    if not dock.dock_background.refined_materials_enabled:
        _bad("M failed to restore refined materials")
    if refined != null and legacy != null:
        var deck_stats := _pixel_difference(refined, legacy, Rect2i(172, 407, 630, 105))
        var face_stats := _pixel_difference(refined, legacy, Rect2i(740, 155, 172, 180))
        if int(deck_stats.changed) < 30:
            _bad("refined deck not materially changed in real GPU framebuffer")
        if int(face_stats.changed) > 0:
            _bad("artist portrait pixels changed due to dock-only material")
        print("TSTSS_DOCK_MATERIAL_NATIVE_DELTA:deck_changed=", deck_stats.changed,
            ":deck_samples=", deck_stats.samples,
            ":deck_mean_delta=", snappedf(float(deck_stats.mean_delta), 0.00001),
            ":portrait_changed=", face_stats.changed)
    if game.session.opening.active_party_ids != ["ender"]:
        _bad("visual comparison changed story party")
    if not dock.dialogue_open or not dock.flyer_read:
        _bad("visual comparison changed dialogue/flyer progression")
    game.queue_free()
    await process_frame
    if problems.is_empty():
        print("TSTSS_DOCK_MATERIAL_RENDER_PASS:real_creator_art=true native_960x640=true material_ab=true story_unchanged=true")
    quit(0 if problems.is_empty() else 1)
