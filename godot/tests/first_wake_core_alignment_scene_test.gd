extends SceneTree
## Physical movement/interaction and subtitles in a separate bench review.
## Scripted fixture represents prerequisite story: not actual ocean gameplay.
const Scene = preload("res://scenes/first_wake_core_alignment_review.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    if world.ender == null or not world.ender.walk_review_enabled:
        _fail("visual player and review walking are missing")
        return
    if world.story.step_key() != "working_theory" or world.story.active_party_ids != ["ender", "ionia", "lyra"]:
        _fail("precondition story fixture skipped postflight reunion")
        return
    if world.core.snapshot()["phase"] != "recover":
        _fail("story did not begin at material recovery")
        return
    if world.interact() or world.core.snapshot()["phase"] != "recover":
        _fail("pickup accepted when Ender not near an item")
        return
    for target in [world.PICKUP_A, world.PICKUP_B]:
        world.ender.position = target
        if not world.interact():
            _fail("walk-up world pickup was rejected")
            return
    if world.core.snapshot()["phase"] != "install":
        _fail("two physical pickups did not unlock checked installation")
        return
    world.ender.position = world.INSTALL
    for i in range(2):
        if not world.interact():
            _fail("checked installation not interactable")
            return
    if world.core.snapshot()["phase"] != "retest":
        _fail("assembly did not lead to physical retest")
        return
    world.ender.position = world.ENGINE
    if not world.interact() or world.core.snapshot()["phase"] != "listen":
        _fail("mandatory material-only failed retest missing")
        return
    if not world.last_message.contains("still refuses phase-lock"):
        _fail("failed restart not made legible in player text")
        return
    if world.status_label.text.contains("FLIGHT: READY"):
        _fail("physical supply incorrectly enabled flight")
        return
    for step in ["listen", "repeat"]:
        world.ender.position = world.IONIA
        if not world.interact():
            _fail("Ionia song interaction refused: " + step)
            return
    if not world.last_message.contains("Denith"):
        _fail("Denith melody context missing from repeat")
        return
    world.ender.position = world.CHART
    if not world.interact() or not world.analysis.open:
        _fail("Ender's chart investigation did not open a readable choice panel")
        return
    if world.ender.player_controlled or not world.analysis_backdrop.visible:
        _fail("chart modal did not focus player control and display visible choices")
        return
    if world.interact() or world.submit_analysis():
        _fail("interact alone auto-solved the song without a chosen hypothesis")
        return
    if not world.choose_analysis(0) or world.submit_analysis():
        _fail("incorrect short-held phrase improperly advanced core")
        return
    if not world.choose_analysis(2) or world.submit_analysis():
        _fail("incorrect interval improperly advanced core")
        return
    if world.core.snapshot()["phase"] != "analyze" or world.analysis.attempts != 2:
        _fail("rejected guesses mutated story stage or did not record failed attempts")
        return
    if not world.close_analysis() or world.core.snapshot()["phase"] != "analyze" or not world.ender.player_controlled:
        _fail("closing chart failed to preserve unresolved state and free exploration")
        return
    if not world.interact() or not world.analysis.open:
        _fail("revisiting chart was not possible")
        return
    if not world.analysis_lines.text.contains("Measured phase changes"):
        _fail("accessible visual comparison data missing")
        return
    var option_input := InputEventKey.new()
    option_input.keycode = KEY_2
    option_input.pressed = true
    world._unhandled_input(option_input)
    if world.analysis.selected != 1:
        _fail("real keyboard choice 2 did not select correct rhythmic proposal")
        return
    var confirm_input := InputEventKey.new()
    confirm_input.keycode = KEY_E
    confirm_input.pressed = true
    world._unhandled_input(confirm_input)
    if world.analysis.open or world.core.snapshot()["phase"] != "observe" or not world.ender.player_controlled:
        _fail("explicit choice and confirm did not advance Ender interpretation correctly")
        return
    world.ender.position = world.LYRA
    if not world.interact():
        _fail("Lyra's independent sensory response not playable")
        return
    world.ender.position = world.IONIA
    if not world.interact():
        _fail("Ionia's final safety approval not playable")
        return
    world.ender.position = world.ENGINE
    if not world.interact():
        _fail("instrument-verified bench candidate not playable")
        return
    if world.core.snapshot()["phase"] != "candidate" or not world.core.snapshot()["alignment_candidate"]:
        _fail("bounded demo did not produce alignment candidate")
        return
    if world.core.snapshot()["can_launch"] or world.core.snapshot()["can_execute_art"]:
        _fail("review scene authorized physical launch or combat Art")
        return
    if not world.objective.text.contains("CANDIDATE") or not world.status_label.text.contains("FLIGHT: LOCKED"):
        _fail("candidate/flight distinction not readable in scene HUD")
        return
    if world.interact():
        _fail("repeated scene completion triggered second alignment")
        return
    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_CORE_SCENE_PASS: physical walk-to-pickup and installation, visible failed retest, Ionia song, Ender/Lyra bench review; launch locked")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_CORE_SCENE_FAIL: " + reason)
    quit(1)
