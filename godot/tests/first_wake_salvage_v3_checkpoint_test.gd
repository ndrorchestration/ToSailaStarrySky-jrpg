extends SceneTree
## Isolated durable salvage-v3 roundtrip, corruption/refusal and source identity.
## Does not authorize launch, new Art, ocean re-verification or v1/v2 migration.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const SalvageScene = preload("res://scenes/first_wake_salvage_review.tscn")
const Codec = preload("res://scripts/first_wake_salvage_checkpoint_v3.gd")
const V2 = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const V1 = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const Store = preload("res://scripts/first_wake_chapter1_save_store.gd")
const TEST_PATH := "user://aetherwake-tests/first-wake-salvage-v3-regression.json"

func _initialize() -> void:
    call_deferred("_verify")

func _ready_story():
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
    return story

func _verify() -> void:
    var store = Store.new()
    store.delete_slot(TEST_PATH)
    var v1_before: String = _sha(Store.DEFAULT_PATH)
    var v2_before: String = _sha(V2.SLOT_PATH)
    var world = SalvageScene.instantiate()
    if not world.configure_after_theory(_ready_story()):
        _fail("valid source story refused")
        return
    root.add_child(world)
    await process_frame
    if not InputMap.has_action("tstss_first_wake_resume_salvage_v3"):
        _fail("J resume action default not registered")
        return
    var empty: Dictionary = world.export_review_checkpoint()
    if not Codec.validate(empty).get("ok", false) or empty["custody"].size() != 0:
        _fail("empty but valid salvage progress not checkpointable")
        return
    if Codec.validate(V1.encode(preload("res://scripts/first_wake_chapter1_state.gd").new(), {"hull_integrity": 100, "morale": 50, "engine_integration": 0})).get("ok", false):
        _fail("v1 chapter save misread as salvage v3")
        return
    if V1.validate(empty).get("ok", false) or V2.validate(empty).get("ok", false):
        _fail("salvage v3 accepted into original v1 or preflight v2 codec")
        return

    world.ender.position = world.QUAY_SUPPLY
    if not world.interact():
        _fail("real physical first item pickup failed")
        return
    var initial: Dictionary = world.export_review_checkpoint()
    if not Codec.validate(initial).get("ok", false) or initial["custody"].size() != 1:
        _fail("physical stock receipt did not serialize as v3")
        return
    var result: Dictionary = world.save_review_checkpoint(TEST_PATH)
    if not result.get("ok", false) or result.get("schema", "") != Codec.SCHEMA:
        _fail("verified first generation was not saved durably")
        return
    if world.save_review_checkpoint(TEST_PATH).get("ok", false) != true:
        _fail("second generation save failed")
        return

    world.ender.position = world.QUAY_TO_DEPOT
    if not world.interact():
        _fail("could not walk from quay to depot")
        return
    world.ender.position = world.DEPOT_PART
    if not world.interact():
        _fail("second material not collected")
        return
    if world.export_review_checkpoint()["custody"].size() != 2:
        _fail("both items not in current active review")
        return
    if not world.load_review_checkpoint(TEST_PATH).get("ok", false):
        _fail("same-scene load failed")
        return
    if world.region != world.QUAY or world.ender.position != world.QUAY_SUPPLY or world.core.recovered != ["recovered_supply"]:
        _fail("same-scene load did not roll back to prior source and position")
        return
    if world.core.authorized_story != world.story:
        _fail("same-scene load severed shared narrative identity")
        return

    var bad: Dictionary = initial.duplicate(true)
    var cases: Array = [
        {"field": "schema", "value": V2.SCHEMA},
        {"field": "step", "value": "test_flight"},
        {"field": "region", "value": "imaginary_castle"},
        {"field": "clues", "value": ["phase_readings"]},
        {"field": "clues", "value": ["phase_readings", "phase_readings"]},
        {"field": "clues", "value": ["phase_readings", "resonance_spell"]},
        {"field": "custody", "value": [
            {"item_id": "recovered_supply", "area_id": Codec.DEPOT, "custodian": "ender", "source": "walkable_scene_interaction"},
        ]},
        {"field": "custody", "value": [
            initial["custody"][0],
            initial["custody"][0],
        ]},
        {"field": "player_position", "value": {"x": 9999.0, "y": 460.0}},
        {"field": "player_position", "value": {"x": NAN, "y": 460.0}},
    ]
    for entry in cases:
        bad = initial.duplicate(true)
        bad[entry["field"]] = entry["value"]
        if Codec.validate(bad).get("ok", false) or Codec.restore(bad).get("ok", false):
            _fail("invalid v3 snapshot accepted: " + str(entry["field"]))
            return
        if world.restore_review_checkpoint(bad):
            _fail("bad v3 snapshot mutated active salvage")
            return
    for forbidden in ["active_party_ids", "can_launch", "trainingGrants", "fuel_formula", "actual_water_physics_verified"]:
        bad = initial.duplicate(true)
        bad[forbidden] = true
        if Codec.validate(bad).get("ok", false):
            _fail("forbidden authority persisted in salvage save: " + forbidden)
            return
    var unequal: Dictionary = initial.duplicate(true)
    unequal["clues"] = ["depleted_reserve", "phase_readings"]
    if world.restore_review_checkpoint(unequal):
        _fail("valid other-crew clue memory overwrote active family's story")
        return

    # A reopened process may replay only the bounded postflight story. It
    # never claims to reproduce the earlier real physics/towing encounter.
    var disk: Dictionary = store.load_snapshot(TEST_PATH, Codec)
    if not disk.get("ok", false):
        _fail("durable primary missing")
        return
    var rebuilt: Dictionary = Codec.restore(disk["snapshot"])
    if not rebuilt.get("ok", false) or rebuilt.get("prior_physical_water_reverified", true):
        _fail("restored model claims previous physical sea proof")
        return
    var resumed = SalvageScene.instantiate()
    if not resumed.configure_from_restored_checkpoint(rebuilt):
        _fail("fresh scene could not accept validated save from disk")
        return
    # A real resume REPLACES the earlier scene. Keeping both CharacterBody2D
    # actors active at the same saved position lets move_and_slide separate
    # them nondeterministically during the first physics frame, incorrectly
    # reporting a valid position as a broken checkpoint.
    world.queue_free()
    await process_frame
    root.add_child(resumed)
    await process_frame
    if resumed.region != resumed.QUAY or resumed.ender.position != resumed.QUAY_SUPPLY:
        _fail("fresh runtime area/position not restored")
        return
    if resumed.core.recovered != ["recovered_supply"] or resumed.core.authorized_story != resumed.story:
        _fail("fresh runtime custody/story not restored")
        return

    # With a valid prior generation in .bak, a corrupt primary must be
    # rejected and the explicit backup recovery path must remain functional.
    var damaged := FileAccess.open(TEST_PATH, FileAccess.WRITE)
    damaged.store_string("{invalid json corruption")
    damaged.close()
    var recovery: Dictionary = store.load_snapshot(TEST_PATH, Codec)
    if not recovery.get("ok", false) or recovery.get("source", "") != "backup" or not recovery.get("recovered", false):
        _fail("corrupt primary did not fall back to verified independent v3 backup")
        return
    if recovery["snapshot"] != initial:
        _fail("backup did not preserve previous valid source receipt")
        return
    if _sha(Store.DEFAULT_PATH) != v1_before or _sha(V2.SLOT_PATH) != v2_before:
        _fail("salvage v3 persistence modified legacy v1 or revised v2 bytes")
        return

    resumed.queue_free()
    await process_frame
    store.delete_slot(TEST_PATH)
    print("TSTSS_SALVAGE_V3_CHECKPOINT_PASS: isolated K/L review store, bounded two-area custody/position resume, wrong-schema/tamper rejections, fallback backup, no v1/v2 or combat claims")
    quit(0)

func _sha(path: String) -> String:
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func _fail(why: String) -> void:
    push_error("TSTSS_SALVAGE_V3_CHECKPOINT_FAIL: " + why)
    quit(1)
