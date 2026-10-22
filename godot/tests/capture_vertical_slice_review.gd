extends SceneTree
## Actual GPU/Xvfb screenshots of the standalone opt-in playability study.
## Visual QA evidence only, not approved artwork or public release material.

const REVIEW_SCENE = preload("res://scenes/vertical_slice_review.tscn")
const OUTPUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("SLICE_CAPTURE_FAIL: invalid real native viewport")
        return null
    if image.save_png(OUTPUT + name) != OK:
        push_error("SLICE_CAPTURE_FAIL: PNG write failed: " + name)
        return null
    print("AETHERWAKE_SLICE_PNG:" + name + ":960x640:" + FileAccess.get_sha256(OUTPUT + name))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    if world.ender == null or world.ionia == null:
        push_error("SLICE_CAPTURE_FAIL: real actors missing")
        quit(1)
        return
    world.ender.set_physics_process(false)
    world.ionia.set_physics_process(false)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("SLICE_CAPTURE_FAIL: cannot create review directory")
        quit(2)
        return
    await process_frame
    var first: Image = await _snapshot("slice-discovery-native-960x640.png")
    if first == null:
        quit(3)
        return
    world.discover_signal()
    world.open_choice()
    await process_frame
    var dialogue: Image = await _snapshot("slice-dialogue-choice-native-960x640.png")
    if dialogue == null:
        quit(4)
        return
    world.toggle_history()
    await process_frame
    var history: Image = await _snapshot("slice-dialogue-history-native-960x640.png")
    if history == null:
        quit(13)
        return
    world.toggle_history()
    await process_frame
    var history_region := Rect2i(80, 125, 800, 350)
    if dialogue.get_region(history_region).get_data() == history.get_region(history_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: dialogue history panel is not visibly distinct")
        quit(14)
        return
    world.choose_path(false)
    world.start_encounter()
    await process_frame
    var warning: Image = await _snapshot("slice-encounter-warning-native-960x640.png")
    if warning == null:
        quit(5)
        return
    world.encounter_action("guard")
    await process_frame
    var echo_ready: Image = await _snapshot("slice-echo-ready-native-960x640.png")
    if echo_ready == null:
        quit(6)
        return
    for action in ["strike", "guard", "strike"]:
        world.encounter_action(action)
    if not world.finish_at_dock():
        push_error("SLICE_CAPTURE_FAIL: cannot reach real choice payoff")
        quit(7)
        return
    await process_frame
    var payoff: Image = await _snapshot("slice-beacon-payoff-native-960x640.png")
    if payoff == null:
        quit(8)
        return
    var text_region := Rect2i(15, 540, 930, 90)
    if first.get_region(text_region).get_data() == dialogue.get_region(text_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: dialogue pixels unchanged from discovery")
        quit(9)
        return
    if dialogue.get_region(text_region).get_data() == payoff.get_region(text_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: payoff pixels unchanged from dialogue")
        quit(10)
        return
    var challenge_region := Rect2i(700, 345, 125, 125)
    if warning.get_region(challenge_region).get_data() == echo_ready.get_region(challenge_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: warning and echo-ready challenge pixels are identical")
        quit(11)
        return
    var payoff_region := Rect2i(155, 330, 790, 165)
    if first.get_region(payoff_region).get_data() == payoff.get_region(payoff_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: world-space payoff did not alter signal/horizon region")
        quit(12)
        return
    # Let the short procedural answer motif finish on the real audio path, then release it cleanly.
    await create_timer(0.7).timeout
    world.signal_audio_player.stop()
    world.signal_audio_player.stream = null
    await process_frame
    world.queue_free()
    await process_frame
    print("AETHERWAKE_SLICE_NATIVE_RENDER_PASS: discovery, dialogue, dialogue-history, guard warning, echo-ready and payoff are visually distinct 960x640 frames")
    print("AETHERWAKE_SLICE_ARTISTIC_ACCEPTANCE=PENDING")
    quit(0)
