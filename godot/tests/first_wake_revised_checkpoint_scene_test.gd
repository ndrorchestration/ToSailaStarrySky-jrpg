extends SceneTree
## Actual Ionia-first playable-scene checkpoint save/restore; legacy slot
## is never overwritten or automatically upgraded. Uses existing safe store.
const Review = preload("res://scenes/first_wake_job_preview.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const Store = preload("res://scripts/first_wake_chapter1_save_store.gd")
const OldCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = Review.instantiate()
    root.add_child(world)
    await process_frame
    var store = Store.new()
    var old_path: String = Store.DEFAULT_PATH
    var legacy_before: String = FileAccess.get_sha256(old_path) if FileAccess.file_exists(old_path) else ""
    store.delete_slot(Codec.SLOT_PATH)

    var start: Dictionary = world.export_revised_checkpoint()
    if start.is_empty() or start.get("step", "") != "job_search":
        _fail("playable Ender-only opening failed to export")
        return
    if not bool(world.save_revised_checkpoint().get("ok", false)):
        _fail("new independent revised slot could not save")
        return
    var first: Dictionary = store.load_snapshot(Codec.SLOT_PATH, Codec)
    if not first.get("ok", false) or first["snapshot"] != start:
        _fail("new validator rejected its own persisted content")
        return
    if store.load_snapshot(Codec.SLOT_PATH).get("ok", false):
        _fail("legacy v1 store accidentally interpreted v2 slot")
        return

    world.ender.position = world.FLYER_POSITION
    if not world.interact():
        _fail("flyer player interaction not available")
        return
    if world.save_revised_checkpoint().get("ok", false):
        _fail("mid-dialogue save accepted transient state")
        return
    if not _finish_dialogue(world) or not world.flyer_read:
        _fail("flyer completion failed")
        return
    if not world.save_revised_checkpoint().get("ok", false):
        _fail("post-flyer checkpoint save failed")
        return

    world.ender.position = world.IONIA_DOCK_POSITION
    if not world.interact() or not _finish_dialogue(world):
        _fail("Ionia engineering employment dialogue failed")
        return
    if world.opening.active_party_ids != ["ender", "ionia"]:
        _fail("Ionia-first recruitment missing")
        return
    if not world.save_revised_checkpoint().get("ok", false):
        _fail("Ionia hiring checkpoint failed")
        return
    var after_hire: Dictionary = world.export_revised_checkpoint()
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        _fail("gangway gameplay transition failed")
        return
    world.ender.position = world.ROOM_POSITIONS["reference"]
    if not world.interact() or not _finish_dialogue(world):
        _fail("one engineering station inspection failed")
        return
    if world.inspected_items != ["reference"]:
        _fail("engineering observation did not persist")
        return
    var engineering: Dictionary = world.export_revised_checkpoint()
    if engineering.is_empty() or not world.save_revised_checkpoint().get("ok", false):
        _fail("intermediate engineering checkpoint did not save")
        return

    # Failed restore cannot alter scene, party/Resonance state or position.
    var before_invalid: Dictionary = world.export_revised_checkpoint()
    var invalid: Dictionary = before_invalid.duplicate(true)
    invalid["step"] = "family_reunion"
    if world.restore_revised_checkpoint(invalid) or world.export_revised_checkpoint() != before_invalid:
        _fail("invalid forward-story restore changed playable scene")
        return
    invalid = before_invalid.duplicate(true)
    invalid["trainingGrants"] = ["tidebound_promise"]
    if world.restore_revised_checkpoint(invalid) or world.export_revised_checkpoint() != before_invalid:
        _fail("save restored forged Art authorization")
        return

    # Restore the pre-boarding hiring checkpoint and verify gameplay, scene
    # presentation and locked Resonance status are coherently reconstructed.
    if not world.restore_revised_checkpoint(after_hire):
        _fail("staged post-hire restore denied")
        return
    if world.room != "dock" or world.opening.active_party_ids != ["ender", "ionia"] or world.dialogue_open:
        _fail("post-hire scene/party/dialogue restoration diverged")
        return
    if not world.resonance_status_label.text.contains("LOCKED"):
        _fail("Lyra's absence was not communicated after restore")
        return
    if not world.restore_revised_checkpoint(engineering):
        _fail("staged engineering restore denied")
        return
    if world.room != "engineering" or world.inspected_items != ["reference"]:
        _fail("engineering room/evidence did not restore")
        return
    if not world.ender.walking_bounds.has_point(world.ender.position):
        _fail("restored position violates engineering movement bounds")
        return

    # The normal store backs up the previous valid checkpoint; corruption of
    # the primary must recover a coherent earlier revision, NOT create magic.
    var file = FileAccess.open(Codec.SLOT_PATH, FileAccess.WRITE)
    if file == null:
        _fail("could not create corrupted primary fixture")
        return
    file.store_string("{this-is-broken-json")
    file.close()
    var fallback: Dictionary = store.load_snapshot(Codec.SLOT_PATH, Codec)
    if not fallback.get("ok", false) or fallback.get("source", "") != "backup" or not fallback.get("recovered", false):
        _fail("valid backup not selected after corrupt primary")
        return
    if not world.load_revised_checkpoint().get("ok", false):
        _fail("playable scene could not recover staged backup")
        return
    if world.opening.active_party_ids != ["ender", "ionia"] or world.room != "dock":
        _fail("backup did not reconstruct preceding hiring state")
        return
    if not world.resonance_status_label.text.contains("LOCKED"):
        _fail("backup recovery accidentally granted Resonance")
        return

    # Exercise the player's actual keyboard commands, not only save/load API
    # calls: K writes the checkpoint and L reconstructs the scene.
    var key_save := InputEventKey.new()
    key_save.pressed = true
    key_save.keycode = KEY_K
    world._unhandled_input(key_save)
    if not world.last_message.contains("saved"):
        _fail("K save input did not report checkpoint success")
        return
    var key_load := InputEventKey.new()
    key_load.pressed = true
    key_load.keycode = KEY_L
    world.ender.position = world.FLYER_POSITION
    world._unhandled_input(key_load)
    if not world.last_message.contains("restored") or world.ender.position != world.IONIA_DOCK_POSITION:
        _fail("L load input did not restore the previously saved hired state")
        return

    # Full playable engineering route: all three station dialogues, then the
    # safety checklist. A post-preflight restore must NOT resume movement.
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        _fail("could not reboard after restored Ionia employment")
        return
    for item in ["fuel", "containment", "reference"]:
        world.ender.position = world.ROOM_POSITIONS[item]
        if not world.interact() or not _finish_dialogue(world):
            _fail("full engineering evidence step failed: " + item)
            return
    world.ender.position = world.ROOM_POSITIONS["checklist"]
    if not world.interact() or not _finish_dialogue(world):
        _fail("preflight checklist dialogue failed")
        return
    if world.opening.step_key() != "preflight" or world.ender.player_controlled:
        _fail("preflight did not block movement at handoff")
        return
    var preflight_position: Vector2 = world.ender.position
    if not world.save_revised_checkpoint().get("ok", false):
        _fail("complete preflight checkpoint did not save")
        return
    if not world.restore_revised_checkpoint(start):
        _fail("could not return to new-game opening in test")
        return
    if world.opening.active_party_ids != ["ender"] or world.room != "dock":
        _fail("new-game opening reconstruction drifted")
        return
    if not world.load_revised_checkpoint().get("ok", false):
        _fail("preflight save could not be loaded")
        return
    if world.opening.step_key() != "preflight" or world.room != "engineering" or world.ender.position != preflight_position:
        _fail("end-of-demo checklist/position not restored")
        return
    if world.ender.player_controlled or world.inspected_items.size() != 3:
        _fail("preflight restore reopened movement or lost inspections")
        return
    if not world.resonance_status_label.text.contains("LOCKED") or "lyra" in world.opening.active_party_ids:
        _fail("preflight save incorrectly admitted Lyra or a combo")
        return

    var legacy_after: String = FileAccess.get_sha256(old_path) if FileAccess.file_exists(old_path) else ""
    if legacy_before != legacy_after:
        _fail("new checkpoint altered the v1 primary slot")
        return
    if OldCodec.validate(world.export_revised_checkpoint()).get("ok", false):
        _fail("old save schema accepted new preview")
        return
    store.delete_slot(Codec.SLOT_PATH)
    world.queue_free()
    await process_frame
    print("TSTSS_REVISED_OPENING_CHECKPOINT_SCENE_PASS: real flyer/hiring/engineering save and backup recovery, no v1 or battle authority drift")
    quit(0)

func _finish_dialogue(world: Node) -> bool:
    var steps: int = 0
    while world.dialogue_open and steps < 20:
        if not world.interact():
            return false
        steps += 1
    return not world.dialogue_open

func _fail(reason: String) -> void:
    push_error("TSTSS_REVISED_OPENING_CHECKPOINT_SCENE_FAIL: " + reason)
    quit(1)
