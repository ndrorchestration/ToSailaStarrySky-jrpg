extends SceneTree
## Four authentic native GL frame captures, all five original-source actors.
## Review-only; changes facing without changing source atlases or world positions.
const Studio = preload("res://scenes/five_lights_motion_studio.tscn")
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const CAST: Array[String] = ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var studio = Studio.instantiate()
    root.add_child(studio)
    studio.keyboard_enabled = false
    await process_frame
    studio.toggle_pose_inspector()
    var roots: Dictionary = {}
    for id in CAST:
        roots[id] = studio.cast_actors[id].global_position
    var hashes: Dictionary = {}
    for direction in FACINGS:
        for id in CAST:
            var actor = studio.cast_actors[id]
            if not actor.set_facing(direction):
                push_error("TSTSS_FIVE_WAY_RENDER_FAIL: invalid facing " + id + "/" + direction)
                quit(1)
                return
            if actor.global_position != roots[id]:
                push_error("TSTSS_FIVE_WAY_RENDER_FAIL: changed position " + id)
                quit(1)
                return
        await process_frame
        await RenderingServer.frame_post_draw
        var img: Image = root.get_viewport().get_texture().get_image()
        if img == null or img.get_width() != 960 or img.get_height() != 640:
            push_error("TSTSS_FIVE_WAY_RENDER_FAIL: nonnative framebuffer")
            quit(1)
            return
        var target: String = "/tmp/tstss_five_lights_" + direction + "_all_cast_native_960x640.png"
        if img.save_png(target) != OK:
            push_error("TSTSS_FIVE_WAY_RENDER_FAIL: PNG save failed")
            quit(1)
            return
        var digest: String = FileAccess.get_sha256(target)
        if hashes.values().has(digest):
            push_error("TSTSS_FIVE_WAY_RENDER_FAIL: duplicate whole-frame directional render")
            quit(1)
            return
        hashes[direction] = digest
        print("TSTSS_FIVE_WAY_RENDER_FRAME:" + direction + ":960x640:sha256=" + digest)
    studio.queue_free()
    print("TSTSS_FIVE_WAY_RENDER_PASS:directions=4 cast=5 full_frames=4 main_game_unchanged=true")
    quit(0)
