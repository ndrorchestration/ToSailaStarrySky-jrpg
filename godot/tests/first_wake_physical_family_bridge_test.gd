extends SceneTree
## Test REAL revised Chapter I and actual 2D berth Area2D/RigidBody2D overlap.
## The safe berth is a local mechanics review, never a fictitious world route.
const Game = preload("res://scenes/first_wake_game.tscn")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")
const TEST_PATH := "user://first_wake_berth_integration_test.json"
var assertions: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, claim: String) -> void:
    assertions += 1
    if not ok:
        failures.append(claim)

func finish_dialogue(job) -> bool:
    for index in range(18):
        if not job.dialogue_open:
            return true
        if not job.interact():
            return false
    return not job.dialogue_open

func _run() -> void:
    for path in [TEST_PATH, TEST_PATH + ".tmp", TEST_PATH + ".bak"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    game.checkpoint_path = TEST_PATH
    check(not game._enter_local_berth(), "cannot enter berth without actual flight")
    check(not game.session.safe_local_berth_recorded, "fresh game cannot claim mooring")
    var job = game.job
    job.ender.position = job.FLYER_POSITION
    check(job.interact() and finish_dialogue(job), "Ender examines actual flyer")
    job.ender.position = job.IONIA_DOCK_POSITION
    check(job.interact() and finish_dialogue(job), "Ionia recruited before first flight")
    job.ender.position = job.GANGWAY_POSITION
    check(job.interact(), "real gangway interaction")
    for item in ["reference", "containment", "fuel"]:
        job.ender.position = job.ROOM_POSITIONS[item]
        check(job.interact() and finish_dialogue(job), "actual engineering: " + item)
    job.ender.position = job.ROOM_POSITIONS["checklist"]
    check(job.interact() and finish_dialogue(job), "preflight inspection and safety check")
    check(job.launch_flight_review(), "actual flight launched")
    var flight = job.flight_review
    check(flight.begin_short_test_flight(), "physically modeled local lift")
    for tick in range(220):
        await process_frame
        if flight.phase == "warning":
            break
    check(flight.phase == "warning" and flight.stabilize_for_water_descent(),
        "legitimate warning and controlled descent")
    for tick in range(560):
        await process_frame
        if flight.phase == "waterborne":
            break
    check(flight.phase == "waterborne" and flight.contact_observed
        and flight.stable_float_verified,
        "original 2D water sensor and stable float occurred")
    for tick in range(125):
        await process_frame
        if game.game_stage == "postflight":
            break
    check(game.game_stage == "postflight" and game.postflight != null,
        "player returned to physically justified shipboard deck")
    var deck = game.postflight
    check(not deck.request_local_berth_review(),
        "cannot request berth before player examines depleted reserve")
    deck.ender.position = deck.ionia.position
    check(not deck.request_local_berth_review(),
        "Ionia cannot initiate berth without reserve evidence")
    deck.ender.position = deck.RESERVE_STATION
    check(deck.interact_reserve(), "real player enters reserve dialogue")
    for line in range(deck.messages.size()):
        check(deck.interact_reserve(), "real reserve dialogue " + str(line))
    check(game.session.can_checkpoint(), "first-flight physical landing + inspection recorded")
    deck.ender.position = deck.ionia.position + Vector2(150, 0)
    check(not deck.request_local_berth_review(), "proximity to captain is required")
    deck.ender.position = deck.ionia.position
    check(deck.request_local_berth_review(), "player explicitly asks Ionia to evaluate berth")
    await process_frame
    await process_frame
    check(game.game_stage == "local_berth" and game.berth_review != null
        and game.postflight == null, "real live game scene changes to local berth")
    var pilot = game.berth_review
    check(pilot.hull is RigidBody2D and pilot.berth_area is Area2D,
        "actual local hull physics and independent berth Area2D sensor exist")
    var stage_report: Dictionary = pilot.cinematic_stage.visual_snapshot()
    check(stage_report.get("native_source_sky_shader", false)
        and stage_report.get("native_source_sea_shader", false),
        "source-reused native sky and sea shader materials render in playable berth")
    check(stage_report.get("source_native_pier_art", false)
        and stage_report.get("art_only_no_physics", false)
        and not stage_report.get("has_collision_authority", true),
        "timber/brass pier is strictly art, physical overlap still separate")
    check(not stage_report.get("has_story_authority", true)
        and not stage_report.get("has_canonical_world_location", true)
        and not stage_report.get("production_art_approved", true),
        "art remains explicitly noncanonical and nonauthoritative")
    check(pilot.ship_art.get_parent() == pilot.hull
        and pilot.ship_art.get_script() == preload("res://scripts/first_wake_berth_ship_art.gd"),
        "four-wing Wake geometry follows source native RigidBody2D, not proxy animation")
    var sea_shader: ShaderMaterial = pilot.cinematic_stage.sea.material as ShaderMaterial
    var physics_before: Dictionary = pilot.review_snapshot()
    pilot.set_reduced_motion(true)
    check(pilot.cinematic_stage.reduced_motion
        and sea_shader.get_shader_parameter("motion_scale") == 0.0,
        "M reduced motion stops genuine native shader animation")
    pilot.set_reduced_motion(false)
    check(not pilot.cinematic_stage.reduced_motion
        and sea_shader.get_shader_parameter("motion_scale") == 1.0,
        "re-enable waves without altering the original physics")
    check(pilot.review_snapshot().get("local_2d_sensor_contact") ==
        physics_before.get("local_2d_sensor_contact")
        and not pilot.contact_observed,
        "visual settings do not forge or transform berth physics")
    check(pilot.phase == "awaiting_approach" and not pilot.berth_area.overlaps_body(pilot.hull),
        "no staged initial berth contact")
    check(not pilot.secure_lines() and not pilot.contact_observed,
        "cannot secure lines before physical sensor contact")
    check(not game.session.record_verified_local_berth(pilot),
        "session rejects premature berth from real but unready physics scene")
    check(pilot.start_local_approach(), "player commands local approach")
    check(not pilot.start_local_approach(), "cannot duplicate physical approach")
    var contact_happened := false
    for tick in range(800):
        await process_frame
        if pilot.contact_observed:
            contact_happened = true
            break
    check(contact_happened and pilot.berth_area.overlaps_body(pilot.hull),
        "physical hull entered independent local berth Area2D")
    check(not pilot.lines_secured, "contact alone does not imply secured berth")
    for tick in range(180):
        await process_frame
        if pilot.phase == "berth_ready":
            break
    check(pilot.phase == "berth_ready" and pilot.float_stable
        and pilot.stable_seconds >= pilot.STABLE_SECONDS,
        "berth dwell / low speed is truly achieved")
    check(not game.session.safe_local_berth_recorded,
        "session does not claim secure lines before explicit player action")
    check(pilot.secure_lines(), "player explicitly secures lines after overlap/dwell")
    await process_frame
    await process_frame
    check(game.session.safe_local_berth_recorded,
        "game session admits real secured source scene only")
    var proof: Dictionary = pilot.review_snapshot()
    check(proof.get("lines_secured") and proof.get("local_2d_sensor_contact")
        and proof.get("float_stable"), "physical receipt must include all safety gates")
    check(proof.get("real_global_shoreline_route") == false
        and proof.get("reunion_authorized") == false
        and proof.get("production_ocean_verified") == false,
        "local berth cannot imply canonical harbor, family arrival or 3D ocean")
    check(game.session.opening.active_party_ids == ["ender", "ionia"]
        and game.session.opening.step_key() == "postflight_diagnosis",
        "no early Lyra, fuel, moon or invented quest progression")
    check(not game.save_game(), "v1 checkpoint does not save unsupported berth stage")
    check(pilot.request_return(), "R returns player to proper shipboard game")
    await process_frame
    await process_frame
    check(game.game_stage == "postflight" and game.postflight != null
        and game.postflight.ender.player_controlled, "playable Ender regains shipboard control")
    check(game.session.safe_local_berth_recorded,
        "live session retains genuine local berth receipt during this game")
    # Save only the valid v1 postflight snapshot BEFORE the session-only
    # family scene. F9 must discard berth/reunion, never fabricate custody.
    check(game.save_game() and Checkpoint.validate(Checkpoint.load(TEST_PATH)),
        "legitimate postflight v1 saved before optional family review")
    var deck_again = game.postflight
    check(not game._enter_family_review(),
        "game cannot advance family stage without a real player request")
    deck_again.ender.position = deck_again.RESERVE_STATION
    check(not deck_again.request_safe_family_review(),
        "physical berth alone does not bypass captain interaction range")
    deck_again.ender.position = deck_again.ionia.position
    check(deck_again.request_safe_family_review(),
        "after true berth, Ender can ask Ionia about safe family arrival")
    await process_frame
    await process_frame
    check(game.game_stage == "family_review" and game.family_review != null,
        "family scene is connected to real physical berth instead of scripted mooring flags")
    var family = game.family_review
    check(family.opening == game.session.opening and family.safe_mooring_review,
        "original live story authority shared through genuine berth family handoff")
    check(family.scene_phase == "family_arrival"
        and family.opening.active_party_ids == ["ender", "ionia"],
        "Lyra is not enrolled just because a physics gate has passed")
    check(family.review_snapshot().get("child_noncombat", false),
        "Talen remains a non-combat character")
    check(not game.save_game(), "v1 never invents an unsupported family checkpoint")
    family.ender.position = family.LYRA_POSITION
    check(family.interact() and family.dialogue_open,
        "Ender actually initiates Lyra's authored family introduction")
    var dialogue_count: int = family.dialogue_lines.size()
    for i in range(dialogue_count):
        check(family.advance_dialogue(),
            "explicit player progression through Lyra dialogue " + str(i))
    check(family.scene_phase == "investigation"
        and family.opening.active_party_ids == ["ender", "ionia", "lyra"],
        "Lyra joins after player conversation and genuine berth evidence")
    check(not family.opening.clues.has("fuel_formula")
        and family.opening.clues.is_empty(),
        "no unearned fuel explanation, clue or finished engine")
    check(game.load_game(),
        "previous physical v1 checkpoint can be loaded without forging family stage")
    check(game.game_stage == "postflight" and game.family_review == null
        and not game.session.safe_local_berth_recorded
        and game.session.opening.active_party_ids == ["ender", "ionia"],
        "old save recovers exact safe history, not unsaved berth or Lyra event")
    check(not game._enter_family_review(),
        "cold restored v1 cannot skip newly required berth physics")
    game.queue_free()
    await process_frame
    for path in [TEST_PATH, TEST_PATH + ".tmp", TEST_PATH + ".bak"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    if failures.is_empty():
        print("TSTSS_FIRST_WAKE_PHYSICAL_FAMILY_BRIDGE_PASS checks=", assertions,
            " original_ocean_contact=true real_berth_sensor=true",
            " adult_family_dialogue=true lyra_after_mooring_only=true",
            " old_save_does_not_restore_unsaved_contact=true")
        quit(0)
    else:
        for err in failures:
            push_error("TSTSS_FIRST_WAKE_PHYSICAL_FAMILY_BRIDGE_FAIL: " + err)
        quit(1)
