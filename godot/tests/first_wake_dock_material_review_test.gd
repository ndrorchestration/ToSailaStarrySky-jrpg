extends SceneTree
## Real First Wake material toggle is presentation-only. No art-source or story authority.
const Game = preload("res://scenes/first_wake_game.tscn")
const Dock = preload("res://scripts/dock_depth_review.gd")
var checks: int = 0
var errors: Array[String] = []

func assert_qa(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        errors.append(message)
        push_error("TSTSS_DOCK_MATERIAL_FAIL:" + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert_qa(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "playable main scene changed")
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    assert_qa(game.job != null and game.postflight == null, "real job-flyer dock did not load")
    if game.job != null:
        var job = game.job
        var background: Node = job.dock_background
        var foreground: Node = job.dock_foreground
        assert_qa(background is Dock and not background.foreground, "real dock background not found")
        assert_qa(foreground is Dock and foreground.foreground, "real dock foreground not found")
        assert_qa(background.MATERIAL_REVISION == "dock-grain-v1", "revision unbound")
        assert_qa(background.refined_materials_enabled, "new materials must begin enabled")
        assert_qa(background.painted_sky_enabled, "cinematic sky preserved")
        assert_qa(foreground.refined_materials_enabled, "foreground structure unchanged")
        var original_position: Vector2 = job.ender.position
        var original_party: Array[String] = game.session.opening.active_party_ids.duplicate()
        var m_key := InputEventKey.new()
        m_key.keycode = KEY_M
        m_key.pressed = true
        job._unhandled_input(m_key)
        assert_qa(not background.refined_materials_enabled, "M did not disable new materials")
        assert_qa("Original simple pier" in job.last_message, "fallback must be discoverable")
        assert_qa(job.ender.position == original_position, "materials changed actor position")
        assert_qa(game.session.opening.active_party_ids == original_party, "M mutated party")
        assert_qa(not job.flyer_read, "M advanced the flyer story")
        job._unhandled_input(m_key)
        assert_qa(background.refined_materials_enabled, "second M did not restore materials")
        assert_qa(not foreground.foreground == false, "foreground layer switched unexpectedly")
        assert_qa(job.ender.position == original_position, "restoration displaced actor")
        assert_qa(not game.session.can_checkpoint(), "visual switch granted checkpoint")
        # Source/collision systems are not part of the dock material implementation.
        for actor in [job.ender, job.ionia]:
            assert_qa(actor is CharacterBody2D and actor.get_child_count() > 0,
                "original physics actors not retained")
        var plain := Dock.new()
        plain.refined_materials_enabled = false
        plain.painted_sky_enabled = false
        root.add_child(plain)
        await process_frame
        assert_qa(plain.painted_sky == null, "legacy sky path no longer reversible")
        assert_qa(plain.get_child_count() == 0, "legacy dock gained unwanted nodes")
        plain.queue_free()
    game.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_DOCK_MATERIAL_PASS checks=", checks,
            " gameplay_entry=true materials_toggle=true legacy_fallback=true actors_unchanged=true")
    quit(0 if errors.is_empty() else 1)
