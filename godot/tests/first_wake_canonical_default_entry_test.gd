extends SceneTree
# Canonical default-entry acceptance: no developer-only F8 transition.
const TARGET := "res://scenes/first_wake_job_preview.tscn"
const Scene = preload(TARGET)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var configured: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
    if configured != TARGET:
        push_error("CH1_DEFAULT_ENTRY_FAIL: main scene is not Ionia-first")
        quit(1)
        return
    var scene = Scene.instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    if scene.opening == null or scene.opening.active_party_ids != ["ender"]:
        push_error("CH1_DEFAULT_ENTRY_FAIL: opening must begin with Ender alone")
        quit(2)
        return
    if scene.opening.accept_ionia_job() == false or scene.opening.active_party_ids != ["ender", "ionia"]:
        push_error("CH1_DEFAULT_ENTRY_FAIL: Ionia must join first")
        quit(3)
        return
    print("TSTSS_CANONICAL_DEFAULT_ENTRY_PASS: normal Godot main scene, Ender alone, Ionia first; no F8")
    quit(0)
