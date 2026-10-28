extends SceneTree
## Native F6 playable-preview integration regression: notebook is real UI,
## remains locked before postflight and never acquires save/quest authority.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        errors.append(message)

func _run() -> void:
    var scene = Preview.instantiate()
    root.add_child(scene)
    await process_frame
    var notebook = scene.evidence_panel
    check(notebook != null, "notebook mounted in real F6 preview")
    check(not notebook.visible, "notebook hidden at first launch")
    check(notebook.opening == scene.opening, "real opening state bound")
    var key = InputEventKey.new()
    key.keycode = KEY_J
    key.pressed = true
    scene._unhandled_input(key)
    check(notebook.visible, "J opens notebook")
    check(not scene.ender.player_controlled, "notebook suspends player movement")
    check(notebook.compare_button.disabled, "comparison locked before reunion")
    var interact_key = InputEventKey.new()
    interact_key.keycode = KEY_E
    interact_key.pressed = true
    # An open journal is modal: world interaction must not advance the scene.
    var stage_before: Dictionary = scene.opening.snapshot()
    scene._unhandled_input(interact_key)
    check(scene.opening.snapshot() == stage_before, "E cannot advance story behind open notebook")

    for clue_id in notebook.buttons:
        check(notebook.buttons[clue_id].disabled, "unobserved clue cannot be selected: " + clue_id)
    var saved: Dictionary = scene.opening.snapshot()
    scene._unhandled_input(key)
    check(not notebook.visible, "J closes notebook")
    check(scene.ender.player_controlled, "closing notebook restores valid world control")
    check(scene.opening.snapshot() == saved, "notebook never advances story")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_CH1_NOTEBOOK_F6_PASS ui_mounted=true early_lock=true story_unchanged=true")
        quit(0)
        return
    for issue in errors:
        push_error("TSTSS_CH1_NOTEBOOK_F6_FAIL: " + issue)
    quit(1)
