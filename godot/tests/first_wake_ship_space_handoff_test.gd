extends SceneTree
## Real Godot Chapter I scene: ship-space visual intake only; no story authority.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const Handoff = preload("res://scripts/first_wake_ship_spaces_handoff.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _verify() -> void:
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    var intake = world.ship_spaces_handoff as Handoff
    check(intake != null and intake.name == "ShipSpacesHandoffReviewOnly",
        "actual playable Ionia-first scene instantiates independent ship review")
    check(not intake.visible and not world._ship_spaces_requested,
        "review-only schematic is not visible or armed by default")
    check(not world.set_ship_spaces_review_enabled(true),
        "Ender cannot summon review sheet before employment and boarding")
    var contract: Dictionary = intake.source_contract()
    check(contract["source_head"] == Handoff.SHIP_ART_SOURCE_HEAD
        and str(contract["source_head"]).length() == 40,
        "study source exactly pinned, not dynamically assumed merged")
    check(int(contract["source_pr"]) == 482 and
        str(contract["source_engine"]).contains("Godot 4.7.2"),
        "metadata identifies actual off-branch native flight-lab prototype")
    check(contract["ship_part_ids"] == [
        "open_foredeck", "geodesic_helm", "crew_entry", "engineering"],
        "only four public-safe observable ship-space roles projected")
    check(float(contract["dome_diameter_study_m"]) >
        float(contract["cabin_width_study_m"]),
        "source scale conflict remains visible to admission check")
    check(float(contract["roof_shortfall_study_m"]) > 0.20,
        "standing-clearance failure is preserved in main chapter project")
    check(contract["admission"] == Handoff.ADMISSION_STATUS
        and not contract["can_traverse"] and not contract["water_seal_verified"],
        "scene refuses false boarding, sealing or protected-hull claims")
    var initial: Dictionary = world.opening.snapshot()
    var initial_checkpoint: Dictionary = world.export_revised_checkpoint()
    var initial_ender: Vector2 = world.ender.position
    var initial_nodes: int = world.get_child_count()
    check(initial_checkpoint.get("step", "") == "job_search",
        "real playable preview starts at employment quest")
    check(world.opening.active_party_ids == ["ender"] and
        world.resonance_status_label.text.contains("LOCKED"),
        "no early Ionia, Lyra or Resonance powers appear")
    check(world.opening.snapshot() == initial and
        world.export_revised_checkpoint() == initial_checkpoint and
        world.ender.position == initial_ender,
        "rejected early toggle makes no story/save/actor change")

    world.ender.position = world.FLYER_POSITION
    check(world.interact() and finish_dialogue(world) and world.flyer_read,
        "real dock flyer can be completed without schematic")
    world.ender.position = world.IONIA_DOCK_POSITION
    check(world.interact() and finish_dialogue(world),
        "Ionia hiring dialogue completes before crew boarding")
    check(world.opening.active_party_ids == ["ender", "ionia"] and
        world.opening.step_key() == "engineering",
        "employment transitions to correct Ionia-first stage")
    check(not world.set_ship_spaces_review_enabled(true),
        "still cannot preview ship interiors from dock before boarding")
    world.ender.position = world.GANGWAY_POSITION
    check(world.interact() and world.room == "engineering",
        "real in-scene gangway transition enters the ship engineering room")
    check(not intake.visible and not world._ship_spaces_requested,
        "boarded scene remains unchanged unless opted in")
    var snapshot: Dictionary = world.opening.snapshot()
    var checkpoint: Dictionary = world.export_revised_checkpoint()
    var before_pos: Vector2 = world.ender.position
    var before_bounds: Rect2 = world.ender.walking_bounds
    var before_text: String = world.objective.text
    var before_message: String = world.last_message
    check(world.set_ship_spaces_review_enabled(true) and intake.visible,
        "explicit test-only opt in displays engineering space diagram")
    check(world.opening.snapshot() == snapshot and
        world.export_revised_checkpoint() == checkpoint,
        "visible ship-space study never edits progression or v2 save schema")
    check(world.ender.position == before_pos and
        world.ender.walking_bounds == before_bounds and
        world.objective.text == before_text and
        world.last_message == before_message,
        "review plate never moves actor or changes chapter objective")
    check(world.get_child_count() == initial_nodes and
        world.resonance_status_label.text.contains("LOCKED"),
        "toggle creates no gameplay nodes and keeps ability locks")
    check(not intake.request_review(true, "dock", "engineering",
        ["ender", "ionia"]) and not intake.visible,
        "projection rejects fabricated room even with correct crew")
    check(not intake.request_review(true, "engineering", "engineering",
        ["ender", "lyra"]) and not intake.visible,
        "no unsupported party chronology can show study")
    check(not intake.request_review(true, "engineering", "waterborne",
        ["ender", "ionia"]) and not intake.visible,
        "projection refuses stages beyond real playable preview")
    check(world.set_ship_spaces_review_enabled(true) and intake.visible,
        "normal eligible scene can recover review state after invalid request")
    check(not world.set_ship_spaces_review_enabled(false) and not intake.visible,
        "opt out clears all visual review state")

    # Transient visual study must never travel through the existing checkpoint.
    check(world.set_ship_spaces_review_enabled(true), "review was re-enabled")
    check(world.restore_revised_checkpoint(checkpoint),
        "unchanged existing v2 checkpoint can still restore in same scene")
    check(not intake.visible and not world._ship_spaces_requested,
        "load does not persist or re-enable opt-in ship visual overlay")
    check(world.opening.snapshot() == snapshot and
        world.export_revised_checkpoint() == checkpoint,
        "restored story and serialized bytes remain identical")
    check(world.resonance_status_label.text.contains("LOCKED"),
        "save restore cannot grant Resonance from an art projection")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_SHIP_SPACE_HANDOFF_PASS checks=", checks,
            " scene=REAL_NATIVE preview=OPT_IN admission=BLOCKED")
        quit(0)
    else:
        for message in failures:
            push_error("FIRST_WAKE_SHIP_SPACE_HANDOFF_FAIL: " + message)
        quit(1)
