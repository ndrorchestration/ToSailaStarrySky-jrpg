extends SceneTree
## Native review contract: accessibility toggles, privacy opt-in and safe retry.

func _initialize() -> void:
    call_deferred("_verify")

func _key(code: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event

func _verify() -> void:
    var world = load("res://scenes/vertical_slice_review.tscn").instantiate()
    root.add_child(world)
    await process_frame
    # Audio generation has its own asset-independent contract; avoid dummy-driver playback leaks here.
    world.audio_enabled = false
    if not world.reduced_motion or world.trace_opt_in or world.text_size < 18:
        _fail("inaccessible or telemetry-on defaults")
        return
    if world.context_prompt_text() != "Find the labeled SIGNAL":
        _fail("context prompt does not name the current objective")
        return
    if world.dialogue_history.size() != 1 or world.history_panel.visible:
        _fail("dialogue history did not initialize hidden with opening context")
        return
    world.toggle_history()
    if not world.history_panel.visible or not world.history_open or world.ender.player_controlled:
        _fail("dialogue history did not open as a movement-pausing review surface")
        return
    world.toggle_history()
    if world.history_panel.visible or world.history_open or not world.ender.player_controlled:
        _fail("dialogue history did not close and restore exploration")
        return
    world.ender.global_position = world.SIGNAL_POINT
    if world.context_prompt_text() != "E: Inspect the signal":
        _fail("nearby context prompt does not name the interaction")
        return
    world._unhandled_input(_key(KEY_M))
    if world.reduced_motion:
        _fail("motion toggle cannot enable animation")
        return
    world._unhandled_input(_key(KEY_M))
    if not world.reduced_motion:
        _fail("motion toggle cannot restore reduction")
        return
    var initial_size: int = world.text_size
    world._unhandled_input(_key(KEY_EQUAL))
    if world.text_size <= initial_size:
        _fail("text size increase unavailable")
        return
    world._unhandled_input(_key(KEY_MINUS))
    if world.text_size != initial_size:
        _fail("text size not reversible")
        return
    world._unhandled_input(_key(KEY_P))
    if not world.trace_opt_in:
        _fail("local trace opt-in unavailable")
        return
    world.discover_signal()
    if world.dialogue_history.size() < 2 or not world.dialogue_history[-1].contains("broken signal"):
        _fail("new story context was not retained in dialogue history")
        return
    if world.trace_events.size() != 1 or world.trace_events[0]["event"] != "clue_discovered":
        _fail("anonymous opt-in trace not recorded")
        return
    world._unhandled_input(_key(KEY_P))
    if world.trace_opt_in or not world.trace_events.is_empty():
        _fail("trace opt-out failed to clear local events")
        return
    world.open_choice()
    if world.ender.player_controlled:
        _fail("dialogue failed to pause actor")
        return
    world._unhandled_input(_key(KEY_ESCAPE))
    if world.stage != "meet" or not world.ender.player_controlled:
        _fail("dialogue cancel failed to resume actor")
        return
    world.open_choice()
    world.choose_path(true)
    world.start_encounter()
    for i in range(32):
        if world.stage != "encounter":
            break
        world.encounter_action("guard")
    if world.stage != "approach" or not world.ender.player_controlled:
        _fail("challenge failure trapped movement or lacked retry")
        return
    if not world.start_encounter() or world.encounter.player_hp != 18:
        _fail("challenge retry did not reset state")
        return
    var blind = load("res://scripts/vertical_slice_encounter.gd").new()
    for i in range(4):
        if blind.is_failed():
            break
        blind.take_turn("strike")
    if not blind.is_failed() or blind.completed:
        _fail("ignoring pulse warnings did not carry a real risk")
        return
    world.signal_audio_player.stop()
    world.signal_audio_player.stream = null
    await process_frame
    world.queue_free()
    await process_frame
    print("AETHERWAKE_ACCESSIBILITY_PASS: text, motion, trace opt-out, dialogue cancel, safe challenge retry")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_ACCESSIBILITY_FAIL: " + reason)
    quit(1)
