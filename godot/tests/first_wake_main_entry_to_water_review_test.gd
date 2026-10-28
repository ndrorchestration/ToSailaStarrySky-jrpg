extends SceneTree
## Vertical integration from the configured Chapter I entry to the revised
## flyer/engineering branch and actual LOCAL RigidBody2D seawater contact.
## No planet/ocean-scale physics, Lyra reunion, v1 migration or new authority.
const Startup = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Route = preload("res://scripts/first_wake_prototype_route.gd")
const SaveStore = preload("res://scripts/first_wake_chapter1_save_store.gd")
const RevisedCodec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if ProjectSettings.get_setting("application/run/main_scene", "") != Route.LEGACY_ENTRY:
        _fail("configured startup scene was altered")
        return
    var v1_hash: String = _file_hash(SaveStore.DEFAULT_PATH)
    var v2_hash: String = _file_hash(RevisedCodec.SLOT_PATH)
    if change_scene_to_packed(Startup) != OK:
        _fail("original startup scene could not open")
        return
    var original = await _current_with_path(Route.LEGACY_ENTRY)
    if original == null:
        _fail("configured original scene did not instantiate")
        return
    original.ender.position = Vector2(507, 474)
    original.review_hull_integrity = 87
    original.review_morale = 66
    var old_state: Dictionary = original.export_save_snapshot()
    var f8 = InputEventKey.new()
    f8.keycode = KEY_F8
    f8.pressed = true
    original._unhandled_input(f8)
    var preview = await _current_with_path(Route.REVISED_REVIEW)
    if preview == null or preview.opening.active_party_ids != ["ender"]:
        _fail("F8 did not open Ender-only revised playable preview")
        return
    if not InputMap.has_action(Inputs.FLIGHT_REVIEW_LAUNCH):
        _fail("F launch action not configured")
        return
    if preview.launch_flight_review():
        _fail("flight activated before employment")
        return

    preview.ender.position = preview.FLYER_POSITION
    if not preview.interact() or not _finish_dialogue(preview):
        _fail("job flyer dialogue could not complete")
        return
    preview.ender.position = preview.IONIA_DOCK_POSITION
    if not preview.interact() or not _finish_dialogue(preview):
        _fail("Ionia first hire could not complete")
        return
    if preview.opening.active_party_ids != ["ender", "ionia"]:
        _fail("wrong story party during preflight")
        return
    preview.ender.position = preview.GANGWAY_POSITION
    if not preview.interact() or preview.room != "engineering":
        _fail("physical gangway boarding not available")
        return
    if preview.launch_flight_review():
        _fail("flight permitted before safety checks")
        return

    for station in ["reference", "containment", "fuel"]:
        preview.ender.position = preview.ROOM_POSITIONS[station]
        if not preview.interact() or not _finish_dialogue(preview):
            _fail("engineering station failed: " + station)
            return
    preview.ender.position = preview.ROOM_POSITIONS["checklist"]
    if not preview.interact() or not _finish_dialogue(preview):
        _fail("preflight checklist failed")
        return
    if preview.opening.step_key() != "preflight" or not preview.resonance_status_label.text.contains("LOCKED"):
        _fail("preflight stage or pre-Lyra lock was bypassed")
        return
    var preflight_v2: Dictionary = preview.export_revised_checkpoint()
    if not RevisedCodec.validate(preflight_v2).get("ok", false):
        _fail("preflight v2 snapshot no longer valid after the new flight link")
        return
    if preview.interact():
        _fail("E entered flight even though launch is bound to F")
        return
    var f_key = InputEventKey.new()
    f_key.keycode = KEY_F
    f_key.pressed = true
    preview._unhandled_input(f_key)
    if preview.room != "flight_review" or preview.flight_review == null:
        _fail("F did not enter native local flight simulation")
        return
    if preview.ui_layer.visible or preview.ender.visible or preview.ender.player_controlled:
        _fail("old dock/engineering UI or player movement leaked into flight")
        return
    if not preview.export_revised_checkpoint().is_empty():
        _fail("flight state leaked into the preflight-only v2 schema")
        return
    if preview.restore_revised_checkpoint(preflight_v2):
        _fail("mid-flight restore improperly discarded physical ship")
        return
    var read_result: Dictionary = preview.load_revised_checkpoint()
    if read_result.get("ok", true) or read_result.get("reason", "") != "flight_review_is_transient_and_unpersisted":
        _fail("mid-flight disk load not denied")
        return
    var flight = preview.flight_review
    if flight.opening != preview.opening or flight.phase != "awaiting_launch":
        _fail("Ionia-first story contract identity lost during handoff")
        return
    if flight.stabilize_for_water_descent() or flight.contact_observed:
        _fail("water contact/stabilization claimed before takeoff")
        return
    if not flight.interact():
        _fail("physical first takeoff rejected")
        return

    var warning := false
    for i in range(240):
        await process_frame
        if flight.phase == "warning":
            warning = true
            break
    if not warning:
        _fail("bounded in-flight phase-drift warning missing")
        return
    if not flight.interact():
        _fail("Ionia did not authorize controlled descent")
        return

    var waterborne := false
    for i in range(600):
        await process_frame
        if flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne:
        _fail("native 2D physical contact/flotation gate did not finish")
        return
    var review: Dictionary = flight.review_snapshot()
    if not review.get("actual_2d_area_contact_observed", false) or not review.get("stable_buoyant_hull_observed", false):
        _fail("water-contact or buoyancy measurement omitted")
        return
    if review.get("production_ocean_verified", true) or preview.opening.step_key() != "waterborne":
        _fail("local fixture falsely claimed production or lost state")
        return
    if preview.opening.active_party_ids != ["ender", "ionia"] or "talen" in preview.opening.active_party_ids:
        _fail("Lyra/Talen prematurely joined before safe reunion")
        return
    if review.get("reserve_inspection_observed", true) or flight.opening.step_key() != "waterborne":
        _fail("depleted-reserve diagnosis was granted before explicit player inspection")
        return
    if flight.inspect_empty_reserve_after_splashdown():
        _fail("could inspect reserve without boarding the onboard review")
        return
    if not flight.interact() or flight.phase != "afloat_inspection":
        _fail("stable float did not open the gated onboard reserve deck")
        return
    if not flight.review_snapshot().get("afloat_station_entered", false):
        _fail("afloat station did not enter the actual flight scene")
        return
    if flight.open_afloat_reserve_review() or flight.interact():
        _fail("duplicate entry or distant inspection was incorrectly permitted")
        return
    var deck = flight.afloat_review
    if deck == null or deck.opening != flight.opening:
        _fail("afloat review lost the shared story contract")
        return
    if deck.review_snapshot().get("real_inventory_scan_verified", true):
        _fail("afloat station incorrectly claimed inventory verification")
        return
    var before_walk: float = deck.ender.position.x
    if not deck.ender.player_controlled or not deck.ender.is_physics_processing():
        _fail("afloat Ender actor was not configured for live movement")
        return
    Input.action_press("ui_right")
    for i in range(50):
        await physics_frame
    Input.action_release("ui_right")
    print("TSTSS_AFLOAT_MOVE_DIAGNOSTIC: start=", before_walk, " end=", deck.ender.position.x, " global=", deck.ender.global_position.x, " velocity=", deck.ender.velocity, " active=", deck.ender.player_controlled)
    if deck.ender.position.x <= before_walk:
        _fail("Ender could not physically move in the reserve station scene")
        return
    if flight.interact() or deck.inspection_observed:
        _fail("remote inspection was possible before arriving at the station")
        return
    deck.ender.position = deck.RESERVE_POSITION
    if not flight.interact() or flight.phase != "postflight_diagnosis":
        _fail("nearby reserve-station inspection failed to advance the story")
        return
    if not flight.review_snapshot().get("physical_reserve_interaction_verified", false):
        _fail("actual onboard reserve interaction receipt missing")
        return
    if deck.review_snapshot().get("salvage_verified", true):
        _fail("onboard inspection improperly granted physical salvage")
        return
    if flight.opening.step_key() != "postflight_diagnosis" or not flight.review_snapshot().get("reserve_inspection_observed", false):
        _fail("safe reserve examination did not progress to diagnosed postflight")
        return
    if flight.review_snapshot().get("real_inventory_scan_verified", true) or flight.interact():
        _fail("authored fuel review claimed inventory implementation or duplicate inspection")
        return
    if flight.opening.active_party_ids != ["ender", "ionia"]:
        _fail("postflight diagnosis recruited Lyra before safe family meeting")
        return
    if _file_hash(SaveStore.DEFAULT_PATH) != v1_hash or _file_hash(RevisedCodec.SLOT_PATH) != v2_hash:
        _fail("transient flight rewrote either save slot")
        return

    # The opt-in review route can still be exited, restoring the entire
    # original configured Chapter I state in memory without v1/v2 crossover.
    preview._unhandled_input(f8)
    var returned = await _current_with_path(Route.LEGACY_ENTRY)
    if returned == null or returned.export_save_snapshot() != old_state:
        _fail("return after splashdown did not restore exact original chapter")
        return
    if has_meta(Route.REVIEW_RETURN_SNAPSHOT) or has_meta(Route.RESTORE_PENDING):
        _fail("route metadata remained after returning to legacy startup")
        return
    if _file_hash(SaveStore.DEFAULT_PATH) != v1_hash or _file_hash(RevisedCodec.SLOT_PATH) != v2_hash:
        _fail("F8 exit from splashdown rewrote v1/v2 checkpoint data")
        return
    print("TSTSS_FIRST_WAKE_MAIN_TO_WATER_PASS: configured startup F8, flyer/Ionia job, three engineering checks, F flight, actual local water contact and floating, physical onboard reserve-station proximity inspection, F8 exact v1 return; no save or Art migration")
    quit(0)

func _finish_dialogue(world: Node) -> bool:
    var remaining := 20
    while world.dialogue_open and remaining > 0:
        if not world.interact():
            return false
        remaining -= 1
    return remaining > 0 and not world.dialogue_open

func _current_with_path(path: String) -> Node:
    for i in range(10):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == path:
            return current_scene
    return null

func _file_hash(path: String) -> String:
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_MAIN_TO_WATER_FAIL: " + reason)
    quit(1)
