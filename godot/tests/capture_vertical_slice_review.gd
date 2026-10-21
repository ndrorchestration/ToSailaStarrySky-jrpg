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
    world.choose_path(false)
    world.start_encounter()
    for action in ["strike", "strike", "strike"]:
        world.encounter_action(action)
    if not world.finish_at_dock():
        push_error("SLICE_CAPTURE_FAIL: cannot reach real choice payoff")
        quit(5)
        return
    await process_frame
    var payoff: Image = await _snapshot("slice-beacon-payoff-native-960x640.png")
    if payoff == null:
        quit(6)
        return
    var text_region := Rect2i(15, 540, 930, 90)
    if first.get_region(text_region).get_data() == dialogue.get_region(text_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: dialogue pixels unchanged from discovery")
        quit(7)
        return
    if dialogue.get_region(text_region).get_data() == payoff.get_region(text_region).get_data():
        push_error("SLICE_CAPTURE_FAIL: payoff pixels unchanged from dialogue")
        quit(8)
        return
    print("AETHERWAKE_SLICE_NATIVE_RENDER_PASS: discovery, dialogue and payoff are visually distinct 960x640 frames")
    print("AETHERWAKE_SLICE_ARTISTIC_ACCEPTANCE=PENDING")
    quit(0)
