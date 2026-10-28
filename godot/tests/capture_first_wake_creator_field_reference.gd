extends SceneTree
## Source-byte-gated local Windows capture. Static art is not walking animation.
const Game = preload("res://scenes/first_wake_game.tscn")
const SOURCES := {
    "Ionia": "res://art-review/creator-field-review/ionia_field_static_review.png",
    "Ender": "res://art-review/creator-field-review/ender_field_static_review.png"
}
# SHA-256 digests of private locally processed source art. Not public repository files.
const LOCAL_DIGESTS := {
    "Ionia": "a37f1cde79fbee7b70d2f25ad9b1625fac1c8340f9c162b54f9333491d203f84",
    "Ender": "7d95d72e6d8953b0db594511cb2705947925363025e737d2710bc247ee43ec4b"
}
var faults: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _fail(reason: String) -> void:
    faults.append(reason)
    push_error("TSTSS_CREATOR_FIELD_NATIVE_FAIL: " + reason)

func _photo(tag: String) -> void:
    for n in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_viewport().get_texture().get_image()
    if img == null or img.get_size() != Vector2i(960, 640):
        _fail("unexpected native framebuffer " + tag)
        return
    var directory: String = ProjectSettings.globalize_path("user://first_wake_field_source_review")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        _fail("could not create output folder")
        return
    var output: String = directory.path_join("field_art_" + tag + "_native_960x640.png")
    if img.save_png(output) != OK:
        _fail("could not save genuine engine screenshot " + tag)
    else:
        print("TSTSS_CREATOR_FIELD_NATIVE_FRAME:", tag, ":SHA256:", FileAccess.get_sha256(output), ":FILE:", output)

func _capture() -> void:
    for name in SOURCES:
        if not FileAccess.file_exists(SOURCES[name]) or FileAccess.get_sha256(SOURCES[name]) != LOCAL_DIGESTS[name]:
            _fail("creator-supplied local processed artwork missing or wrong SHA: " + name)
    if not faults.is_empty():
        quit(1)
        return
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    var dock = game.job
    if dock == null or game.postflight != null:
        _fail("opening dock not active")
    else:
        dock.ender.position = dock.FLYER_POSITION
        dock.interact()
        while dock.dialogue_open:
            dock.interact()
        dock.ender.position = dock.IONIA_DOCK_POSITION
        dock.interact()
        # After authentic Ionia dialogue starts, separate the actor standees visually;
        # this is camera-only positioning for capture, not a story event.
        dock.ender.position = dock.FLYER_POSITION
        if not dock.ender.enable_creator_standee(true) or not dock.ionia.enable_creator_standee(true):
            _fail("both independently sourced full-body static references not visible")
        else:
            await _photo("static_source")
        if not dock.ender.creator_standee_enabled or not dock.ionia.creator_standee_enabled:
            _fail("full-body static source not enabled")
        dock.ender.enable_creator_standee(false)
        dock.ionia.enable_creator_standee(false)
        await _photo("existing_walkers")
        if dock.ender.creator_standee_enabled or dock.ionia.creator_standee_enabled:
            _fail("reversible originals not restored")
        if game.session.opening.active_party_ids != ["ender"]:
            _fail("source visual toggle mutated story recruitment")
    game.queue_free()
    await process_frame
    if faults.is_empty():
        print("TSTSS_CREATOR_FIELD_NATIVE_PASS:source=actual_creator_sheet static_only=true art_swap=true 960x640=true story_unchanged=true")
    quit(0 if faults.is_empty() else 1)
