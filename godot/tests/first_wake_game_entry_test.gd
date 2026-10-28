extends SceneTree
## The exact project main scene launches the revised creator-directed story.
## A live Area2D/RigidBody2D sea landing is required before shipboard control.
## Saves are new-format only; old Lyra-first Chapter I snapshots fail closed.
const Game = preload("res://scenes/first_wake_game.tscn")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")
const PATH = "user://first_wake_game_entry_integration_test.json"

var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, msg: String) -> void:
    checks += 1
    if not ok:
        errors.append(msg)

func _finish_dialogue(job) -> bool:
    for i in range(18):
        if not job.dialogue_open:
            return true
        if not job.interact():
            return false
    return not job.dialogue_open

func _run() -> void:
    for path in [PATH, PATH + ".tmp", PATH + ".bak"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    verify(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "normal Godot project Play enters integrated game")
    var root_game = Game.instantiate()
    root.add_child(root_game)
    await process_frame
    root_game.checkpoint_path = PATH
    verify(root_game.job != null and root_game.postflight == null,
        "real player-controlled job-search scene is loaded")
    verify(root_game.game_stage == "first_flight"
        and root_game.session.opening.step_key() == "job_search",
        "revised job-first story is the only game authority")
    verify(root_game.job.ender.player_controlled
        and root_game.job.opening.active_party_ids == ["ender"],
        "player has actual Ender control before recruiting Ionia")
    verify(not root_game.save_game(), "game refuses preflight and unverified landing saves")
    verify(not root_game.load_game(), "no invented checkpoint before a real save")
    verify(not root_game.session.record_physical_landing({
        "phase": "waterborne", "story_step": "waterborne",
        "party": ["ender", "ionia"],
        "actual_2d_area_contact_observed": true,
        "stable_buoyant_hull_observed": true,
        "production_ocean_verified": false, "fuel_formula": "unknown",
    }), "forged landing cannot skip opening stage")
    var job = root_game.job
    job.ender.position = job.FLYER_POSITION
    verify(job.interact() and _finish_dialogue(job), "real flyer and dialogue completed")
    verify(job.flyer_read, "read flyer precedes hiring")
    job.ender.position = job.IONIA_DOCK_POSITION
    verify(job.interact() and _finish_dialogue(job), "actual interview with Ionia")
    verify(job.opening.active_party_ids == ["ender", "ionia"]
        and job.opening.step_key() == "engineering",
        "Ionia joins first; Lyra remains absent")
    job.ender.position = job.GANGWAY_POSITION
    verify(job.interact() and job.room == "engineering",
        "player uses actual gangway to enter engine room")
    for item in ["reference", "containment", "fuel"]:
        job.ender.position = job.ROOM_POSITIONS[item]
        verify(job.interact() and _finish_dialogue(job),
            "source-authored engineering inspection " + item)
    job.ender.position = job.ROOM_POSITIONS["checklist"]
    verify(job.interact() and _finish_dialogue(job),
        "actual safety dialogue authorizes the brief preflight")
    verify(job.opening.step_key() == "preflight", "preflight not bypassed")
    verify(job.launch_flight_review(), "normal scene enters real native flight and 3D ship")
    var flight = job.flight_review
    verify(flight.ship_body is RigidBody2D and flight.sea_area is Area2D,
        "physics, not the 3D art layer, owns water contact")
    verify(flight.cinematic_inset != null and flight.cinematic_inset.wide_stage_enabled,
        "integrated flight actually displays original-source wide 3D ship")
    verify(flight.begin_short_test_flight(), "controlled first flight starts from real preflight")
    var warned := false
    for tick in range(180):
        await process_frame
        if flight.phase == "warning":
            warned = true
            break
    verify(warned, "real flight reaches phase-drift warning")
    verify(flight.stabilize_for_water_descent(), "Ionia executes controlled sea descent")
    var settled := false
    for tick in range(540):
        await process_frame
        if flight.phase == "waterborne":
            settled = true
            break
    verify(settled and flight.contact_observed and flight.stable_float_verified,
        "real water Area2D contact and sustained buoyancy required")
    # The physics transition occurs after the game root's _process in this
    # frame; allow the game authority to consume the real contact next frame.
    await process_frame
    await process_frame
    verify(root_game.session.physical_landing_observed,
        "game root admitted only the actual post-contact physics review")
    for tick in range(110):
        await process_frame
        if root_game.game_stage == "postflight":
            break
    verify(root_game.game_stage == "postflight" and root_game.job == null,
        "player returns automatically to shipboard control after waterborne")
    verify(root_game.postflight != null and root_game.postflight.ender.player_controlled,
        "player regains Ender movement in the ship after splashdown")
    verify(root_game.session.opening.step_key() == "waterborne"
        and root_game.session.opening.active_party_ids == ["ender", "ionia"],
        "no premature Lyra, fuel discovery or new chapter stage")
    verify(not root_game.save_game(), "save fails until player inspects depleted reserve")
    var deck = root_game.postflight
    deck.ender.position = deck.RESERVE_STATION
    verify(deck.interact_reserve() and deck.reserve_dialogue_open,
        "depleted reserve has an actual player-triggered interaction")
    for line in range(deck.messages.size()):
        verify(deck.interact_reserve(), "postflight observation dialogue action " + str(line))
    verify(deck.inspected_station and root_game.session.can_checkpoint(),
        "reserve becomes recorded only after player finishes dialogue")
    verify(root_game.session.opening.step_key() == "postflight_diagnosis",
        "revised story advances to correct postflight stage")
    verify(root_game.save_game() and FileAccess.file_exists(PATH),
        "F5 checkpoint persists new-format first-flight data")
    var data: Dictionary = Checkpoint.load(PATH)
    verify(Checkpoint.validate(data), "saved checkpoint semantically valid")
    verify(data["schema"] != "aetherwake.first-wake.chapter1.v1",
        "legacy incompatible save schema was not silently reused")
    var forged: Dictionary = data.duplicate(true)
    forged["party"] = ["ender", "lyra"]
    verify(not Checkpoint.validate(forged), "older Lyra-first party is forbidden")
    forged = data.duplicate(true)
    forged["fuel_explanation_status"] = "confirmed"
    verify(not Checkpoint.validate(forged), "early fuel explanation rejected")
    forged = data.duplicate(true)
    forged["evidence"]["actual_2d_water_contact_at_checkpoint"] = false
    verify(not Checkpoint.validate(forged), "unverified water-contact claim rejected")

    root_game.queue_free()
    await process_frame
    var resumed = Game.instantiate()
    root.add_child(resumed)
    await process_frame
    resumed.checkpoint_path = PATH
    verify(resumed.load_game(), "F9 loads postflight state in a fresh Godot game")
    verify(resumed.job == null and resumed.postflight != null
        and resumed.postflight.ender.player_controlled,
        "load resumes with playable Ender after splashdown")
    verify(resumed.session.restored_from_local_checkpoint
        and resumed.session.can_checkpoint(),
        "loaded past landing is marked historical, not a new sensor event")
    verify(resumed.session.opening.active_party_ids == ["ender", "ionia"]
        and resumed.session.opening.step_key() == "postflight_diagnosis",
        "restored chronology and party stay correct")
    verify(resumed.game_snapshot()["legacy_chapter_scene_used"] == false,
        "new root never loads incompatible legacy quest state")

    # Backup recovery must use a previously valid generation.
    verify(resumed.save_game() and FileAccess.file_exists(PATH + ".bak"),
        "second save retains a verified backup generation")
    var broken := FileAccess.open(PATH, FileAccess.WRITE)
    broken.store_string('{"schema":"aetherwake.first-wake.chapter1.v1"}')
    broken.close()
    verify(Checkpoint.load(PATH).get("schema", "") == Checkpoint.SCHEMA,
        "corrupt/legacy primary falls back to valid prior save without migration")
    resumed.queue_free()
    await process_frame
    for path in [PATH, PATH + ".tmp", PATH + ".bak"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    if errors.is_empty():
        print("TSTSS_FIRST_WAKE_GAME_ENTRY_PASS checks=", checks,
            " real_water_contact=true postflight_player=true",
            " save_resume=true legacy_schema_isolated=true")
        quit(0)
    else:
        for error in errors:
            push_error("TSTSS_FIRST_WAKE_GAME_ENTRY_FAIL: " + error)
        quit(1)
