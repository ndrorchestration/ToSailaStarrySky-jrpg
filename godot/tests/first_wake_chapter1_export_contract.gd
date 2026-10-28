extends SceneTree
## Safe private Windows *preview surface* contract, not export certification.
## Allow ONLY the historical signal/crossing preview or new revised
## Ender-job/Ionia-first playable candidate as the Godot normal main scene.
## Legacy preview must still import and preserve its separate old semantics.

const LEGACY := "res://scenes/first_wake_chapter1_player_preview.tscn"
const GAME := "res://scenes/first_wake_game.tscn"

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
    var app_name: String = str(ProjectSettings.get_setting("application/config/name", ""))
    if main_scene not in [LEGACY, GAME]:
        _fail("unexpected main scene; no arbitrary export entry allowed")
        return
    if main_scene == LEGACY:
        if "Aetherwake" not in app_name or "Native Preview" not in app_name:
            _fail("legacy preview app name is not explicitly a preview")
            return
    elif "To Sail the Starry Sky" not in app_name or "Playable Candidate" not in app_name:
        _fail("revised candidate does not explicitly identify nonrelease app")
        return

    var packed: PackedScene = load(main_scene)
    if packed == null:
        _fail("allowlisted main game scene did not import")
        return
    var world = packed.instantiate()
    root.add_child(world)
    await process_frame
    if main_scene == GAME:
        if not world.has_method("game_snapshot") or not world.has_method("save_game"):
            _fail("new game root does not expose gameplay and checkpoint boundaries")
            return
        var report: Dictionary = world.game_snapshot()
        if report.get("story_step", "") != "job_search" or report.get("story_party", []) != ["ender"]:
            _fail("new game started at wrong character or story phase")
            return
        if report.get("legacy_chapter_scene_used", true) or report.get("checkpoint_available", true):
            _fail("new game incorrectly imports legacy save or starts with completed checkpoint")
            return
        if world.job == null or world.postflight != null or not world.job.ender.player_controlled:
            _fail("new entry does not start with controllable Ender at the dock")
            return
    else:
        if not world.has_method("complete_signal_contact"):
            _fail("historical preview lost its own signal/crossing contract")
            return
        if world.chapter.stage_key() != "signal":
            _fail("legacy preview no longer boots at Signal")
            return
        if world.chapter.desired_active_party_ids() != ["ender", "lyra"]:
            _fail("legacy baseline story/party drifted")
            return
    world.queue_free()
    await process_frame

    # The new root is NOT permitted to delete or silently reinterpret old
    # preview resources. The old package scene remains importable separately.
    var historic: PackedScene = load(LEGACY)
    if historic == null:
        _fail("historical preview entry was removed")
        return
    var old = historic.instantiate()
    root.add_child(old)
    await process_frame
    if not old.has_method("complete_signal_contact"):
        _fail("historical Chapter I save-preview scene contract missing")
        return
    if old.chapter.stage_key() != "signal" or old.chapter.desired_active_party_ids() != ["ender", "lyra"]:
        _fail("legacy migration state unexpectedly changed")
        return
    old.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_WINDOWS_EXPORT_CONTRACT_PASS: allowlisted_native_main=",
        main_scene, " legacy_scene_preserved=true candidate_not_release=true")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_WINDOWS_EXPORT_CONTRACT_FAIL: " + reason)
    quit(1)
