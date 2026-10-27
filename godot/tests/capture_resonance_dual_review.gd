extends SceneTree
## Real Godot GL-Compatibility frames from the opt-in Resonance scene.
## This is visual evidence of provisional procedural shapes, NOT accepted art.
const ReviewScene = preload("res://scenes/resonance_dual_review.tscn")
const OUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: unexpected viewport")
        return null
    var output := OUT + name
    if image.save_png(output) != OK:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: write failed: " + name)
        return null
    print("RESONANCE_NATIVE_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(output))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: output directory denied")
        quit(2)
        return
    var world = ReviewScene.instantiate()
    root.add_child(world)
    await process_frame
    if not world.reduced_motion or world.battle.snapshot()["phase"] != "player":
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: initial review fixture invalid")
        quit(3)
        return
    var opening: Image = await _snapshot("resonance-opening-native-960x640.png")
    if opening == null:
        quit(4)
        return
    # The operator-facing training grant is explicit, never inferred.
    world._grant()
    if world.battle.snapshot()["trainingGrants"].size() != 1:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: explicit training grant not issued")
        quit(10)
        return
    world._cast()
    await process_frame
    var armed: Image = await _snapshot("resonance-ward-native-960x640.png")
    if armed == null:
        quit(5)
        return
    if world.battle.snapshot()["phase"] != "enemy" or int(world.battle.snapshot()["wardCapacity"]) != 4:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: ward state inconsistent with visible frame")
        quit(6)
        return
    world._strike()
    await process_frame
    var resolved: Image = await _snapshot("resonance-resolved-native-960x640.png")
    if resolved == null:
        quit(7)
        return
    if int(world.battle.snapshot()["lastOutcome"]["absorbed"]) != 4:
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: result state inconsistent with visible frame")
        quit(8)
        return
    var a: PackedByteArray = opening.get_region(Rect2i(365, 188, 230, 242)).get_data()
    var b: PackedByteArray = armed.get_region(Rect2i(365, 188, 230, 242)).get_data()
    if a == b or armed.get_data() == resolved.get_data():
        push_error("RESONANCE_NATIVE_CAPTURE_FAIL: renderer frames not visually distinct")
        quit(9)
        return
    print("GODOT_RESONANCE_NATIVE_CAPTURE_PASS: opening, ward and resolved native screenshots")
    world.queue_free()
    await process_frame
    quit(0)
