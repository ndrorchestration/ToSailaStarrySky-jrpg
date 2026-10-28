extends SceneTree
## Local-only, real-creator-JPEG native OpenGL screenshot proof.
## Unlike the CI fixture this script REQUIRES source images with exact custody hashes.
## Use: godot --rendering-driver opengl3 --resolution 960x640 --path godot
##      --script res://tests/capture_first_wake_creator_portrait_real_art.gd
const Game = preload("res://scenes/first_wake_game.tscn")
const SOURCES := {
    "ENDER": "res://art-review/creator-portrait-preview/ender_hifi_review_crop.jpg",
    "IONIA": "res://art-review/creator-portrait-preview/ionia_hifi_review_crop.jpg",
}
const HASHES := {
    "ENDER": "2e7d296698755157da194275a68f01a96b8e69131e69c0128995fee66895e413",
    "IONIA": "ff38540a3b845f20078989d7523cb2e3e6911a8ff886fe8647c1a46fa3e7c07c",
}
var failures: Array[String] = []
var output_dir: String = ""

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    failures.append(message)
    push_error("TSTSS_CREATOR_REAL_ART_CAPTURE_FAIL: " + message)

func _verify_source_assets() -> void:
    for id in SOURCES:
        var path: String = String(SOURCES[id])
        if not FileAccess.file_exists(path):
            _fail("creator artwork missing: " + path)
            continue
        if FileAccess.get_sha256(path) != HASHES[id]:
            _fail("creator artwork has unrecognized checksum: " + path)
            continue
        var texture: Texture2D = load(path) as Texture2D
        if texture == null or texture.get_size() != Vector2(432, 432):
            _fail("creator source image is not imported as 432x432: " + id)

func _photo(tag: String, actor) -> Image:
    if not actor.visible or actor.current_speaker != tag.to_upper():
        _fail("correct creator portrait speaker not displayed: " + tag)
        return null
    for i in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_viewport().get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        _fail("native framebuffer invalid for " + tag)
        return null
    var file: String = output_dir.path_join("first_wake_" + tag + "_creator_native_960x640.png")
    if frame.save_png(file) != OK:
        _fail("failed to write real Godot screenshot: " + file)
        return null
    print("TSTSS_CREATOR_REAL_ART_FRAME:", tag, ":SHA256:", FileAccess.get_sha256(file), ":FILE:", file)
    return frame

func _portrait_delta(a: Image, b: Image) -> float:
    if a == null or b == null:
        return 0.0
    var acc: float = 0.0
    # The actual source-art frame is x=714..930, y=131..347.
    for y in range(149, 326, 8):
        for x in range(732, 914, 8):
            var l: Color = a.get_pixel(x, y)
            var r: Color = b.get_pixel(x, y)
            acc += absf(l.r - r.r) + absf(l.g - r.g) + absf(l.b - r.b)
    return acc

func _run() -> void:
    _verify_source_assets()
    if not failures.is_empty():
        quit(1)
        return
    if String(ProjectSettings.get_setting("application/run/main_scene", "")) != "res://scenes/first_wake_game.tscn":
        _fail("wrong Godot project; playable First Wake not the F5 main scene")
        quit(1)
        return
    output_dir = ProjectSettings.globalize_path("user://first_wake_native_portrait_evidence")
    if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
        _fail("cannot create local screenshot directory")
        quit(1)
        return
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    var job = game.job
    if job == null or game.postflight != null:
        _fail("real job-search stage did not appear")
        game.queue_free()
        quit(1)
        return
    job.ender.position = job.FLYER_POSITION
    if not job.interact():
        _fail("actual Ender flyer failed")
    var ender_shot: Image = await _photo("ender", job.portrait_preview)
    var advances: int = 0
    while job.dialogue_open and advances < 18:
        if not job.interact():
            _fail("flyer dialog progression failed")
            break
        advances += 1
    if not job.flyer_read:
        _fail("actual flyer not confirmed")
    job.ender.position = job.IONIA_DOCK_POSITION
    if not job.interact():
        _fail("actual Ionia interview failed")
    var ionia_shot: Image = await _photo("ionia", job.portrait_preview)
    var delta: float = _portrait_delta(ender_shot, ionia_shot)
    if delta < 25.0:
        _fail("source-art rendered frames insufficiently different; inspect actual images")
    if game.session.opening.active_party_ids != ["ender"]:
        _fail("capture unexpectedly advanced recruitment")
    if job.portrait_preview.position.y + job.portrait_preview.size.y >= job.DOCK_BOUNDS.position.y:
        _fail("portrait overlaps walkable dock")
    print("TSTSS_CREATOR_REAL_ART_DELTA:", snappedf(delta, 0.1))
    game.queue_free()
    await process_frame
    if failures.is_empty():
        print("TSTSS_CREATOR_REAL_ART_CAPTURE_PASS:actual_jpg=true native_gl=960x640 story_unchanged=true")
        print("TSTSS_CREATOR_REAL_ART_CAPTURE_FOLDER:", output_dir)
    quit(0 if failures.is_empty() else 1)
