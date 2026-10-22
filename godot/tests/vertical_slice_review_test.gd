extends SceneTree
## Native scene test for the opt-in First Wake gameplay hypothesis.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var scene: PackedScene = load("res://scenes/vertical_slice_review.tscn")
    if scene == null:
        _fail("scene import failed")
        return
    var world = scene.instantiate()
    root.add_child(world)
    await process_frame
    if world.ender == null or world.ionia == null or world.stage != "search":
        _fail("scene actors or initial state missing")
        return
    if world.ionia.is_review_art_enabled():
        _fail("unapproved Ionia artwork enabled by default")
        return
    if world.finish_at_dock() or world.start_encounter() or world.open_choice():
        _fail("stage transition accepted out of order")
        return
    if not world.discover_signal() or world.discover_signal():
        _fail("clue gate broken")
        return
    if not world.open_choice() or world.ender.player_controlled:
        _fail("dialogue failed to pause player input")
        return
    if not world.choose_path(true) or not world.ender.player_controlled:
        _fail("crew choice did not resume movement")
        return
    if world.choose_path(false) or not world.start_encounter():
        _fail("choice mutated or challenge failed to open")
        return
    if world.ender.player_controlled or not world.encounter.telegraph_winding_up:
        _fail("challenge input pause or telegraph missing")
        return
    for action in ["guard", "strike", "guard", "strike"]:
        if not world.encounter_action(action):
            _fail("valid challenge turn rejected")
            return
    if world.stage != "return" or not world.ender.player_controlled:
        _fail("challenge completion failed to restore movement")
        return
    if not world.finish_at_dock() or world.choice_state.dock_payoff_key() != "crew_reconnected":
        _fail("crew payoff missing")
        return
    if world.trace_events.size() != 0:
        _fail("review trace unexpectedly enabled")
        return
    world.queue_free()
    await process_frame

    var other = scene.instantiate()
    root.add_child(other)
    await process_frame
    other.discover_signal()
    other.open_choice()
    if not other.choose_path(false) or other.choice_state.choice != 2:
        _fail("beacon alternative missing")
        return
    if not other.start_encounter():
        _fail("beacon challenge blocked")
        return
    for action in ["guard", "strike", "guard", "strike"]:
        other.encounter_action(action)
    if not other.finish_at_dock() or other.choice_state.dock_payoff_key() != "beacon_restored":
        _fail("beacon payoff missing")
        return
    other.queue_free()
    await process_frame
    print("AETHERWAKE_VERTICAL_SLICE_PASS: real scene, exclusive paths, readable challenge, pause/resume and two payoffs")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_VERTICAL_SLICE_FAIL: " + reason)
    quit(1)
