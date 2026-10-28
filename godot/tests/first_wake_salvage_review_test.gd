extends SceneTree
## Two-area source custody with true player-proximity and reversible scene.
## Provisional geometry/items only; no real fuel composition or inventory.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Scene = preload("res://scenes/first_wake_salvage_review.tscn")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")

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
    var world = Scene.instantiate()
    if world.configure_after_theory(Opening.new()) or world.configure_after_theory({}):
        _fail("forged or insufficient story authorized source inventory")
        return
    var story = _ready_story()
    if not world.configure_after_theory(story):
        _fail("verified crew story denied physical salvage")
        return
    if world.configure_after_theory(story):
        _fail("duplicate salvage configuration accepted")
        return
    root.add_child(world)
    await process_frame
    if world.ender == null or not world.ender.walk_review_enabled:
        _fail("Ender cannot physically navigate salvage areas")
        return
    if world.snapshot()["material_installation_ready"] or world.snapshot()["workshop_handoff"]:
        _fail("salvage initially claimed recovered materials/installed core")
        return
    if world.recover_item("recovered_part", world.DEPOT) or world.recover_item("recovered_supply", world.DEPOT):
        _fail("wrong-area world item receipt accepted")
        return
    if world.recover_item("recovered_supply", world.QUAY) or world.handoff_to_workshop():
        _fail("distant stock or empty handoff accepted")
        return
    world.ender.position = world.QUAY_SUPPLY
    if not world.interact():
        _fail("physical quay stock pickup failed")
        return
    var first: Dictionary = world.snapshot()
    if first["collected_ids"] != ["recovered_supply"] or first["material_installation_ready"] or first["required_regions_visited"]:
        _fail("one picked-up item fabricated full recovery")
        return
    if world.recover_item("recovered_supply", world.QUAY):
        _fail("duplicate physical stock accepted")
        return
    world.ender.position = world.QUAY_TO_DEPOT
    if not world.interact() or world.region != world.DEPOT:
        _fail("two-region scene traversal refused")
        return
    if world.recover_item("recovered_supply", world.QUAY):
        _fail("across-region forged stock pickup accepted")
        return
    world.ender.position = world.DEPOT_PART
    if not world.interact():
        _fail("physical depot replacement part pickup failed")
        return
    var second: Dictionary = world.snapshot()
    if not second["required_regions_visited"] or not second["material_installation_ready"]:
        _fail("two sources failed to establish install prerequisite")
        return
    if second["genuine_world_inventory"] or second["approved_material_identity"] or second["persistent_item_custody"]:
        _fail("source receipts claimed production-grade inventory/material canon")
        return
    if world.handoff_to_workshop():
        _fail("depot pickup teleported back to ship without a return path")
        return
    world.ender.position = world.DEPOT_TO_QUAY
    if not world.interact() or world.region != world.QUAY:
        _fail("walkable return to quay failed")
        return
    world.ender.position = world.RETURN_TO_WAKE
    if not world.interact() or world.workshop == null:
        _fail("return aboard ship did not transfer physical custody")
        return
    if not world.workshop.has_external_salvage_custody or world.workshop.core != world.core:
        _fail("workshop forged recovered item core rather than reuse same object")
        return
    if world.workshop.story != story or world.core.authorized_story != story:
        _fail("salvage lost same identity across full handoff")
        return
    if world.core.snapshot()["phase"] != "install" or world.core.snapshot()["installed"] != []:
        _fail("workshop skipped install or retest gate")
        return
    if world.interact() or world.workshop.core.snapshot()["can_launch"] or world.workshop.core.snapshot()["can_execute_art"]:
        _fail("duplicate handoff or ship/spell authority from salvage")
        return
    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_SALVAGE_SCENE_PASS: two walkable physical pickup regions, denied wrong-area/distance/duplicate receipts, same story+core into installation, no canon/inventory/flight authority")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_SALVAGE_SCENE_FAIL: " + reason)
    quit(1)
