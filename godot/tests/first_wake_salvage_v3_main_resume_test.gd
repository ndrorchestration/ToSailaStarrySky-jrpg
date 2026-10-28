extends SceneTree
## Actual configured original startup -> F8 opt-in revised dock -> J-format v3
## recovery from a private separate slot -> F8 exact original return.
const Startup = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Salvage = preload("res://scenes/first_wake_salvage_review.tscn")
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Route = preload("res://scripts/first_wake_prototype_route.gd")
const Codec = preload("res://scripts/first_wake_salvage_checkpoint_v3.gd")
const V2 = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const Store = preload("res://scripts/first_wake_chapter1_save_store.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const TEST_PATH := "user://aetherwake-tests/first-wake-v3-main-resume-review.json"

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var store = Store.new()
    store.delete_slot(TEST_PATH)
    var v1_before: String = _sha(Store.DEFAULT_PATH)
    var v2_before: String = _sha(V2.SLOT_PATH)

    # Generate review v3 from actual salvaged pickup actions, not direct JSON.
    var story = Opening.new()
    story.accept_ionia_job()
    story.complete_engineering_checks()
    story.begin_test_flight()
    story.record_engine_failure(true, true, true)
    story.complete_ocean_splashdown(true, true)
    story.inspect_postflight_reserve(true)
    story.introduce_lyra_and_talen(true)
    story.record_clue("phase_readings")
    story.record_clue("lyra_observation")
    story.form_working_fuel_theory()
    var originating = Salvage.instantiate()
    if not originating.configure_after_theory(story):
        _fail("creator-ordered source story cannot enter salvage")
        return
    root.add_child(originating)
    await process_frame
    originating.ender.position = originating.QUAY_SUPPLY
    if not originating.interact() or not originating.save_review_checkpoint(TEST_PATH).get("ok", false):
        _fail("physical first pickup did not write separate v3 slot")
        return
    originating.queue_free()
    await process_frame

    if ProjectSettings.get_setting("application/run/main_scene", "") != Route.LEGACY_ENTRY:
        _fail("startup main scene silently altered by v3 resume feature")
        return
    if change_scene_to_packed(Startup) != OK:
        _fail("could not open actual startup scene")
        return
    var original = await _scene(Route.LEGACY_ENTRY)
    if original == null:
        _fail("old Chapter I not instantiated")
        return
    original.ender.position = Vector2(509, 474)
    original.review_hull_integrity = 81
    original.review_morale = 74
    var prior_state: Dictionary = original.export_save_snapshot()
    var f8 := InputEventKey.new()
    f8.keycode = KEY_F8
    f8.pressed = true
    original._unhandled_input(f8)
    var preview = await _scene(Route.REVISED_REVIEW)
    if preview == null or preview.opening.step_key() != "job_search":
        _fail("F8 did not enter fresh revised Ender-only dock")
        return
    if not InputMap.has_action(Inputs.RESUME_SALVAGE_REVIEW):
        _fail("J explicit resume binding missing")
        return
    if preview.resume_salvage_review_v3("user://nonexistent-v3-file.json").get("ok", false):
        _fail("nonexistent v3 save granted a rescue or scene state")
        return
    if preview.room != "dock" or preview.salvage_review != null:
        _fail("failed v3 resume modified intact dock")
        return
    var loaded: Dictionary = preview.resume_salvage_review_v3(TEST_PATH)
    if not loaded.get("ok", false) or loaded.get("prior_physical_water_reverified", true):
        _fail("dedicated v3 restoration falsely certified prior flight")
        return
    if preview.room != "salvage_review" or preview.salvage_review == null:
        _fail("resume did not reveal playable salvage scene")
        return
    if preview.ui_layer.visible or preview.ender.visible or preview.ionia.visible:
        _fail("underlying job art/actors leaked into restored salvage")
        return
    if not preview.export_revised_checkpoint().is_empty() or preview.load_revised_checkpoint().get("ok", false):
        _fail("v3 salvage scene incorrectly exposes v2 preflight checkpoint")
        return
    var salvage = preview.salvage_review
    if salvage.region != salvage.QUAY or salvage.core.recovered != ["recovered_supply"]:
        _fail("recovered source region/material wrong after full scene resume")
        return
    if salvage.story != preview.opening or salvage.core.authorized_story != preview.opening:
        _fail("restored party did not share same instance as active salvage")
        return
    if salvage.core.snapshot()["can_launch"] or salvage.core.snapshot()["can_execute_art"]:
        _fail("v3 restore incorrectly granted flight or battle magic")
        return

    salvage.ender.position = salvage.QUAY_TO_DEPOT
    if not salvage.interact() or salvage.region != salvage.DEPOT:
        _fail("restored game could not travel to missing item area")
        return
    salvage.ender.position = salvage.DEPOT_PART
    if not salvage.interact():
        _fail("restored game could not take last material")
        return
    salvage.ender.position = salvage.DEPOT_TO_QUAY
    if not salvage.interact():
        _fail("restored game could not return to the Wake")
        return
    salvage.ender.position = salvage.RETURN_TO_WAKE
    if not salvage.interact() or salvage.workshop == null:
        _fail("restored game could not access the repair workshop")
        return
    if not salvage.export_review_checkpoint().is_empty() or salvage.save_review_checkpoint(TEST_PATH).get("ok", false):
        _fail("v3 salvage-only schema accepted mid-workshop persistence")
        return
    if salvage.workshop.story != preview.opening or salvage.workshop.core != salvage.core:
        _fail("workshop created a forged story/core after loading v3")
        return
    preview._unhandled_input(f8)
    var returned = await _scene(Route.LEGACY_ENTRY)
    if returned == null or returned.export_save_snapshot() != prior_state:
        _fail("F8 from resumed salvage did not restore exact original v1 scene")
        return
    if _sha(Store.DEFAULT_PATH) != v1_before or _sha(V2.SLOT_PATH) != v2_before:
        _fail("v3 resume rewrote original v1 or revised preflight v2 disk slots")
        return
    if has_meta(Route.REVIEW_RETURN_SNAPSHOT) or has_meta(Route.RESTORE_PENDING):
        _fail("volatile F8 route metadata leaked")
        return
    store.delete_slot(TEST_PATH)
    print("TSTSS_SALVAGE_V3_MAIN_RESUME_PASS: original main F8 -> validated independent v3 salvage resume -> 2nd item/ship install -> F8 original v1 state, no physics replay or authority")
    quit(0)

func _scene(path: String) -> Node:
    for i in range(12):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == path:
            return current_scene
    return null

func _sha(path: String) -> String:
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func _fail(reason: String) -> void:
    push_error("TSTSS_SALVAGE_V3_MAIN_RESUME_FAIL: " + reason)
    quit(1)
