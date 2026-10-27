extends SceneTree
## Genuine Godot 4.7.2 framebuffer evidence. Images are review-only, not art acceptance.
const Review = preload("res://scenes/magic_vfx_showcase.tscn")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const OUTPUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("MAGIC_VFX_CAPTURE_FAIL: invalid GPU viewport")
        return null
    if image.save_png(OUTPUT + name) != OK:
        push_error("MAGIC_VFX_CAPTURE_FAIL: could not write " + name)
        return null
    print("STARRY_SKY_MAGIC_VFX_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(OUTPUT + name))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("MAGIC_VFX_CAPTURE_FAIL: directory inaccessible")
        quit(1)
        return
    var world = Review.instantiate()
    root.add_child(world)
    await process_frame
    if not world.reduced_motion:
        push_error("MAGIC_VFX_CAPTURE_FAIL: motion safety was not the default")
        quit(2)
        return
    var previous: Image = null
    var static_spirit: Image = null
    var previous_ground: Image = null
    var floor_roi := Rect2i(335, 429, 290, 64)
    for i in range(Catalog.CHARACTER_ORDER.size()):
        if not world.choose(i):
            push_error("MAGIC_VFX_CAPTURE_FAIL: could not choose affinity")
            quit(3)
            return
        await process_frame
        var identity: String = Catalog.CHARACTER_ORDER[i]
        var frame: Image = await _snapshot("magic-vfx-" + identity + "-static-native-960x640.png")
        if frame == null:
            quit(4)
            return
        if previous != null and frame.get_region(Rect2i(345, 172, 280, 280)).get_data() == previous.get_region(Rect2i(345, 172, 280, 280)).get_data():
            push_error("MAGIC_VFX_CAPTURE_FAIL: effect centers identical across affinities " + identity)
            quit(5)
            return
        if previous_ground != null and frame.get_region(floor_roi).get_data() == previous_ground.get_region(floor_roi).get_data():
            push_error("MAGIC_VFX_CAPTURE_FAIL: floor contact unchanged between identities " + identity)
            quit(9)
            return
        previous_ground = frame
        if i == 0:
            static_spirit = frame
        previous = frame
        if not world.effect.seek_visual_phase(0.67):
            push_error("MAGIC_VFX_CAPTURE_FAIL: deterministic impact frame rejected")
            quit(10)
            return
        await process_frame
        var impact: Image = await _snapshot("magic-vfx-" + identity + "-impact-native-960x640.png")
        if impact == null:
            quit(11)
            return
        if frame.get_region(Rect2i(345, 172, 280, 280)).get_data() == impact.get_region(Rect2i(345, 172, 280, 280)).get_data():
            push_error("MAGIC_VFX_CAPTURE_FAIL: static and impact stage identical " + identity)
            quit(12)
            return
    world.choose(0)
    world.toggle_reduced_motion()
    if world.reduced_motion:
        push_error("MAGIC_VFX_CAPTURE_FAIL: motion opt-in unavailable")
        quit(6)
        return
    world.effect._process(0.93)
    await process_frame
    var moving: Image = await _snapshot("magic-vfx-ender-motion-native-960x640.png")
    if moving == null:
        quit(7)
        return
    if static_spirit.get_region(Rect2i(345, 172, 280, 280)).get_data() == moving.get_region(Rect2i(345, 172, 280, 280)).get_data():
        push_error("MAGIC_VFX_CAPTURE_FAIL: dynamic and static presentations visually identical")
        quit(8)
        return
    world.queue_free()
    await process_frame
    print("STARRY_SKY_MAGIC_VFX_NATIVE_CAPTURE_PASS: five static and five impact 960x640 effects with distinct floor contacts, plus real animated frame")
    print("STARRY_SKY_MAGIC_VFX_ART_ACCEPTANCE=PENDING")
    quit(0)
