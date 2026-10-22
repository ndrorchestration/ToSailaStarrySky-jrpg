extends SceneTree
## Real native screenshots for the Chapter I migration review scene.
## Engineering/visual-review evidence only; no artistic or release acceptance.

const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_review.tscn")
const OUTPUT = "res://review-evidence/chapter1-migration/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("CHAPTER1_CAPTURE_FAIL: invalid real native viewport")
        return null
    if image.save_png(OUTPUT + name) != OK:
        push_error("CHAPTER1_CAPTURE_FAIL: PNG write failed: " + name)
        return null
    print("AETHERWAKE_CHAPTER1_PNG:" + name + ":960x640:" + FileAccess.get_sha256(OUTPUT + name))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame

    if world.get_script() == null or world.ender == null:
        push_error("CHAPTER1_CAPTURE_FAIL: real migration scene did not load")
        quit(1)
        return
    world.ender.set_physics_process(false)
    for actor in world.contacts.values():
        actor.set_physics_process(false)

    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("CHAPTER1_CAPTURE_FAIL: cannot create review directory")
        quit(2)
        return

    await process_frame
    var signal_image: Image = await _snapshot("chapter1-signal-native-960x640.png")
    if signal_image == null:
        quit(3)
        return

    # Capture a real authored dialogue state before crediting the signal.
    world.ender.position = world.SIGNAL_POINTS["harmonic_buoy"]
    if not world.interact_nearest():
        push_error("CHAPTER1_CAPTURE_FAIL: Wakeheart dialogue did not open")
        quit(31)
        return
    await process_frame
    var dialogue_image: Image = await _snapshot("chapter1-dialogue-native-960x640.png")
    if dialogue_image == null:
        quit(32)
        return
    for _line in range(5):
        world._advance_dialogue_review()
    if world.dialogue.open or "harmonic_buoy" not in world.chapter.completed_signals:
        push_error("CHAPTER1_CAPTURE_FAIL: dialogue did not close into signal progress")
        quit(33)
        return

    for signal_id in ["below_frequency", "sky_lane_warning"]:
        world.complete_signal_contact(signal_id)
    await process_frame
    var crossing: Image = await _snapshot("chapter1-crossing-native-960x640.png")
    if crossing == null:
        quit(4)
        return

    for hazard_id in ["sky_predator", "wind_shear", "corporate_intercept"]:
        world.complete_hazard_review(hazard_id)
    await process_frame
    var contact: Image = await _snapshot("chapter1-contact-native-960x640.png")
    if contact == null:
        quit(5)
        return

    world.meet_ionia_for_choice()
    await process_frame
    var choice: Image = await _snapshot("chapter1-choice-native-960x640.png")
    if choice == null:
        quit(6)
        return

    world.choose_path_review("path_c")
    await process_frame
    var wake: Image = await _snapshot("chapter1-wake-native-960x640.png")
    if wake == null:
        quit(7)
        return

    world.resolve_wake_review()
    await process_frame
    var done: Image = await _snapshot("chapter1-done-native-960x640.png")
    if done == null:
        quit(8)
        return

    var scene_region := Rect2i(80, 110, 800, 350)
    var frames := [signal_image, dialogue_image, crossing, contact, choice, wake, done]
    for i in range(frames.size() - 1):
        if frames[i].get_region(scene_region).get_data() == frames[i + 1].get_region(scene_region).get_data():
            push_error("CHAPTER1_CAPTURE_FAIL: adjacent stage frames are not visibly distinct at index " + str(i))
            quit(10 + i)
            return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS: Signal, Dialogue, Crossing, Contact, Choice, Wake and Done are visibly distinct 960x640 native frames")
    print("AETHERWAKE_GODOT_CHAPTER1_ARTISTIC_ACCEPTANCE=PENDING")
    quit(0)
