extends SceneTree
## Export-surface contract for the private Windows native Chapter I preview.

func _initialize() -> void:
    var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
    if main_scene != "res://scenes/first_wake_chapter1_player_preview.tscn":
        _fail("native preview main scene is not the Chapter I player-preview scene")
        return

    var app_name := str(ProjectSettings.get_setting("application/config/name", ""))
    if "Aetherwake" not in app_name or "Native Preview" not in app_name:
        _fail("native preview application name is not explicit")
        return

    var packed: PackedScene = load(main_scene)
    if packed == null:
        _fail("native preview main scene failed to import")
        return
    var world = packed.instantiate()
    root.add_child(world)
    await process_frame

    if world.get_script() == null or not world.has_method("complete_signal_contact"):
        _fail("native preview does not expose the Chapter I migration scene contract")
        return
    if world.chapter.stage_key() != "signal":
        _fail("native preview does not boot at Signal")
        return
    if world.chapter.desired_active_party_ids() != ["ender", "lyra"]:
        _fail("native preview initial party target drifted")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_WINDOWS_EXPORT_CONTRACT_PASS: native Chapter I preview main scene imports at Signal")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_WINDOWS_EXPORT_CONTRACT_FAIL: " + reason)
    quit(1)
