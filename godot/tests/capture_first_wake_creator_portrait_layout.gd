extends SceneTree
## Genuine GL framebuffer layout proof using ONLY synthetic solid-color textures.
## The real creator-provided JPGs are local and are not in public GitHub/CI.
const Game = preload("res://scenes/first_wake_game.tscn")
const IDLE_RGB := Color(0.78, 0.22, 0.12)
const IONIA_RGB := Color(0.12, 0.72, 0.53)
const TARGET := Vector2i(814, 385)
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _texture(color: Color) -> Texture2D:
    var image := Image.create(432, 432, false, Image.FORMAT_RGBA8)
    image.fill(color)
    return ImageTexture.create_from_image(image)

func _failure(message: String) -> void:
    failures.append(message)
    push_error("TSTSS_PORTRAIT_NATIVE_RENDER_FAIL: " + message)

func _capture(tag: String, wanted: Color) -> void:
    for i in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_viewport().get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        _failure("wrong native render dimensions " + tag)
        return
    var sampled: Color = frame.get_pixelv(TARGET)
    if absf(sampled.r - wanted.r) > 0.12 or absf(sampled.g - wanted.g) > 0.12 or absf(sampled.b - wanted.b) > 0.12:
        _failure("source portrait box not visible or color changed in " + tag + ": " + str(sampled))
    var file: String = "/tmp/tstss_portrait_" + tag + "_native_960x640.png"
    if frame.save_png(file) != OK:
        _failure("native PNG not saved " + tag)
        return
    print("TSTSS_PORTRAIT_NATIVE_FRAME:", tag, ":sha256=", FileAccess.get_sha256(file))
    if tag == "ionia":
        var small: Image = frame.duplicate()
        small.resize(480, 320, Image.INTERPOLATE_LANCZOS)
        var jpeg: PackedByteArray = small.save_jpg_to_buffer(0.63)
        if jpeg.is_empty() or jpeg.size() > 90000:
            _failure("bounded still render review JPEG not saved")
            return
        print("TSTSS_PORTRAIT_LAYOUT_JPG_BEGIN")
        print(Marshalls.raw_to_base64(jpeg))
        print("TSTSS_PORTRAIT_LAYOUT_JPG_END")

func _run() -> void:
    if String(ProjectSettings.get_setting("application/run/main_scene")) != "res://scenes/first_wake_game.tscn":
        _failure("normal game entry altered")
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    if game.job == null or game.postflight != null:
        _failure("not in actual starting dock scene")
    else:
        var job = game.job
        var preview = job.portrait_preview
        preview.set_test_texture("ENDER", _texture(IDLE_RGB))
        preview.set_test_texture("IONIA", _texture(IONIA_RGB))
        job.ender.position = job.FLYER_POSITION
        if not job.interact() or not preview.visible or preview.current_speaker != "ENDER":
            _failure("real flyer Ender dialogue failed")
        else:
            await _capture("ender", IDLE_RGB)
        var n: int = 0
        while job.dialogue_open and n < 18:
            if not job.interact():
                _failure("flyer dialogue could not advance")
                break
            n += 1
        if not job.flyer_read:
            _failure("flyer story did not progress normally")
        job.ender.position = job.IONIA_DOCK_POSITION
        if not job.interact() or preview.current_speaker != "IONIA":
            _failure("actual dock Ionia dialogue failed")
        else:
            await _capture("ionia", IONIA_RGB)
        preview.set_portraits_enabled(false)
        job._sync_presentation()
        if preview.visible:
            _failure("accessibility toggle failed to hide the portrait")
        if game.session.opening.active_party_ids != ["ender"]:
            _failure("images mutated story party")
    game.queue_free()
    await process_frame
    if failures.is_empty():
        print("TSTSS_PORTRAIT_NATIVE_RENDER_PASS:real_dock=true 960x640=true both_speakers=true square=true source_images=test_only")
    quit(0 if failures.is_empty() else 1)
