extends SceneTree
## End-to-end native scene gates for the isolated playable employment-to-engineering slice.
## Exercises real Godot scene/actors/dialogue/party state, not water or release behavior.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var packed: PackedScene = load("res://scenes/first_wake_job_preview.tscn")
    if packed == null:
        _fail("new playable scene failed to import")
        return
    var world = packed.instantiate()
    root.add_child(world)
    await process_frame

    if world.ender == null or world.ionia == null:
        _fail("Ender or Ionia actor missing")
        return
    if not world.ender.walk_review_enabled or not world.ionia.is_ionia_stage_art_enabled():
        _fail("existing opt-in character previews were not reused")
        return
    if world.room != "dock" or world.flyer_read or world.opening.active_party_ids != ["ender"]:
        _fail("initial job-search state drifted")
        return
    if world.opening.step_key() != "job_search":
        _fail("initial story stage drifted")
        return

    # Captain cannot hire Ender until he discovers the actual notice.
    world.ender.position = world.IONIA_DOCK_POSITION + Vector2(-25, 0)
    if world.interact() or world.dialogue_open or "ionia" in world.opening.active_party_ids:
        _fail("Ionia joined before flyer discovery")
        return
    world.ender.position = world.GANGWAY_POSITION
    if world.interact() or world.room != "dock":
        _fail("unemployed Ender was allowed to board for engineering")
        return

    world.ender.position = world.FLYER_POSITION
    if not world.interact() or not world.dialogue_open:
        _fail("flyer interaction failed")
        return
    if world.ender.player_controlled or world.flyer_read:
        _fail("dialogue allowed movement or awarded flyer before completion")
        return
    if not _finish_dialogue(world):
        _fail("flyer dialogue did not advance")
        return
    if not world.flyer_read or not world.ender.player_controlled:
        _fail("flyer did not mark complete or resume movement")
        return

    world.ender.position = world.IONIA_DOCK_POSITION + Vector2(-30, 0)
    if not world.interact() or not world.dialogue_open:
        _fail("Ionia interview failed")
        return
    if world.opening.active_party_ids != ["ender"]:
        _fail("Ionia joined before job dialogue was completed")
        return
    if not _finish_dialogue(world):
        _fail("interview dialogue failed")
        return
    if world.opening.active_party_ids != ["ender", "ionia"]:
        _fail("first recruitment must be Ionia")
        return
    if world.opening.step_key() != "engineering":
        _fail("provisional employment did not enter engineering stage")
        return

    # Enter engineering through physical gangway interaction, not a story card.
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        _fail("ship boarding failed")
        return
    if world.dock_background.visible or world.dock_foreground.visible:
        _fail("dock environment leaked into engineering room")
        return
    if not world.ender.walking_bounds.has_point(world.ender.position):
        _fail("engine room movement bounds invalid")
        return
    if world.opening.step_key() != "engineering":
        _fail("engineering phase was bypassed")
        return

    world.ender.position = world.ROOM_POSITIONS["checklist"]
    if world.interact() or world.opening.step_key() != "engineering":
        _fail("preflight checklist accepted without three inspections")
        return

    for item in ["fuel", "containment", "reference"]:
        world.ender.position = world.ROOM_POSITIONS[item]
        if not world.interact() or not world.dialogue_open:
            _fail("engineering station was not interactable: " + item)
            return
        if item in world.inspected_items:
            _fail("station recorded evidence before dialogue closure: " + item)
            return
        if not _finish_dialogue(world):
            _fail("engineering station dialogue failed: " + item)
            return
        if item not in world.inspected_items:
            _fail("station did not persist observation: " + item)
            return
    if world.inspected_items.size() != 3:
        _fail("three inspections were not recorded exactly")
        return

    world.ender.position = world.ROOM_POSITIONS["checklist"]
    if not world.interact() or not world.dialogue_open:
        _fail("completed checklist interaction failed")
        return
    if world.opening.step_key() != "engineering":
        _fail("preflight awarded before safety dialogue finished")
        return
    if not _finish_dialogue(world):
        _fail("preflight safety dialogue did not complete")
        return
    if world.opening.step_key() != "preflight":
        _fail("scene did not reach preflight state")
        return
    if world.ender.player_controlled:
        _fail("Ender can walk beyond the preview handoff")
        return
    if world.opening.active_party_ids != ["ender", "ionia"]:
        _fail("Lyra was recruited too early")
        return
    var snap: Dictionary = world.opening.snapshot()
    if snap["implemented_in_live_chapter_one"] or snap["actual_water_physics_verified"]:
        _fail("preview claimed full integration or sea physics")
        return
    if world.interact():
        _fail("repeated safety-check interaction was accepted after finish")
        return

    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_JOB_SCENE_PASS: playable flyer, gated interview, Ionia-first, boarded engineering, three inspections and preflight")
    quit(0)

func _finish_dialogue(world: Node) -> bool:
    var budget := 20
    while world.dialogue_open and budget > 0:
        if not world.interact():
            return false
        budget -= 1
    return not world.dialogue_open and budget > 0

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_JOB_SCENE_FAIL: " + reason)
    quit(1)
