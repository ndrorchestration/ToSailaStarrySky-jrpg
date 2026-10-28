extends SceneTree
## The exact project main scene launches the revised creator-directed story.
## A live Area2D/RigidBody2D sea landing is required before shipboard control.
## Saves are new-format only; old Lyra-first Chapter I snapshots fail closed.
const Game = preload("res://scenes/first_wake_game.tscn")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")
const Extended = preload("res://scripts/first_wake_chapter1_progress_v2.gd")
const PATH = "user://first_wake_game_entry_integration_test.json"
const PATH_V2 = PATH + ".chapter_v2"

var checks: int = 0
var errors: Array[String] = []
var capture_enabled: bool = false
var captured: Array[String] = []
var cinematic_pairs_captured: int = 0

func capture_native_frame(frame_id: String) -> void:
    if not capture_enabled:
        return
    # Capture actual configured F5 game viewport, never an invented scene.
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.get_size() != Vector2i(960, 640):
        verify(false, "native frame size not 960x640: "+frame_id)
        return
    var target := "res://review-evidence/ch1-f5-"+frame_id+"-native-960x640.png"
    if image.save_png(target) != OK:
        verify(false, "native image cannot save: "+frame_id)
        return
    captured.append(frame_id)


func capture_cinematic_pair(scene: Node2D, game: Node, label: String) -> void:
    if not (capture_enabled and OS.get_cmdline_user_args().has("--cinematic-pairs")):
        return
    var state_before: Dictionary = game.game_snapshot()
    scene.set_cinematic_environment_enabled(false)
    await process_frame
    await RenderingServer.frame_post_draw
    var original: Image = root.get_texture().get_image()
    scene.set_cinematic_environment_enabled(true)
    await process_frame
    await RenderingServer.frame_post_draw
    var cinematic: Image = root.get_texture().get_image()
    var changed := 0
    for y in range(180,535,3):
        for x in range(28,932,3):
            var a: Color = original.get_pixel(x,y)
            var b: Color = cinematic.get_pixel(x,y)
            if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))) > 3.0/255.0:
                changed += 1
    verify(changed >= 1900,
        "native in-game environmental background must visibly change: "+label)
    verify(game.game_snapshot() == state_before,
        "cinematic background cannot mutate chapter state: "+label)
    for entry in [
        {"version":"original","image":original},
        {"version":"cinematic","image":cinematic}
    ]:
        var target: String = "res://review-evidence/ch1-visual-%s-%s-960x640.png" % [
                label,str(entry["version"])]
        verify(entry["image"].save_png(target) == OK,
            "full native A/B image must save: "+target)
    cinematic_pairs_captured += 1
    print("TSTSS_CH1_CINEMATIC_AB label=",label," changed_sample_pixels=",changed,
        " state_unchanged=true real_game_viewport=true")

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
    capture_enabled = OS.get_cmdline_user_args().has("--capture")
    if capture_enabled:
        root.size = Vector2i(960, 640)
        var folder: String = ProjectSettings.globalize_path("res://review-evidence")
        verify(DirAccess.make_dir_recursive_absolute(folder) == OK,
            "native capture directory available")
    for path in [PATH, PATH + ".tmp", PATH + ".bak", PATH_V2, PATH_V2 + ".tmp", PATH_V2 + ".bak"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    verify(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "normal Godot project Play enters integrated game")
    var root_game = Game.instantiate()
    root.add_child(root_game)
    await process_frame
    root_game.checkpoint_path = PATH
    root_game.chapter_progress_path = PATH_V2
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
    await capture_native_frame("01-phase-warning")
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
    verify(deck.checkpoint_message.is_empty(),
        "successful inspection clears the earlier declined-save warning")
    await capture_native_frame("02-reserve-inspected")
    await capture_cinematic_pair(deck,root_game,"reserve")
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
    resumed.chapter_progress_path = PATH_V2
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
    verify(resumed.save_game() and Extended._valid_parent(PATH),
        "restoring first-flight generation reestablishes valid v1 anchor for separate stage progress")
    # New normal-F5 in-memory continuation: never forge an ocean-to-harbor
    # route. A player must explicitly acknowledge provisional safe staging.
    verify(not resumed._enter_family_review(),
        "family screen cannot be entered without player staging")
    var same_story = resumed.session.opening
    var checkpoint_before_family: String = FileAccess.get_file_as_string(PATH)
    verify(resumed.request_safe_berth_review()
        and resumed.safe_berth_review_confirmations == 1,
        "first R only requests explicitly nongeographic safe recovery")
    verify(resumed.family_review == null
        and resumed.session.opening.active_party_ids == ["ender", "ionia"],
        "one safe recovery acknowledgment cannot teleport or recruit Lyra")
    verify(resumed.request_safe_berth_review()
        and resumed.game_stage == "family_review",
        "second R starts clearly staged safe berth family scene")
    await process_frame
    var family = resumed.family_review
    verify(family != null and family.opening == same_story
        and family.review_snapshot()["real_return_route_verified"] == false,
        "F5 continuation preserves identical first-flight story without inventing route")
    verify(family.scene_phase == "family_arrival"
        and family.ender.player_controlled,
        "the actual postflight family scene is walkable and initially Lyra-free")
    verify(family.objective_label.get_line_count() == 1,
        "family arrival objective must not overlap party HUD")
    await capture_native_frame("03-staged-family-arrival")
    await capture_cinematic_pair(family,resumed,"family")
    verify(resumed.save_game()
        and Extended.load(PATH,PATH_V2).get("stage") == "family_arrival",
        "F5 now writes a separate admissible family v2 checkpoint")
    verify(FileAccess.get_file_as_string(PATH) == checkpoint_before_family,
        "family stage save leaves physical v1 checkpoint byte-identical")
    family.ender.position = family.TALEN_POSITION
    verify(family.interact() and _finish_dialogue(family)
        and family.child_block_ship_viewed,
        "optional Talen block ship stays an everyday noncombat scene")
    verify(not family.opening.active_party_ids.has("talen")
        and not family.opening.active_party_ids.has("lyra"),
        "child dialogue does not recruit child or Lyra")
    family.ender.position = family.LYRA_POSITION
    verify(family.interact()
        and not family.opening.active_party_ids.has("lyra"),
        "Lyra joins only after full family conversation")
    verify(not resumed.save_game(),
        "cannot save an interrupted conversation or skip Lyra's full introduction")
    verify(_finish_dialogue(family)
        and family.opening.active_party_ids == ["ender", "ionia", "lyra"],
        "first-flight session identity admits Lyra SECOND after mandatory reunion")
    await process_frame
    verify(family.objective_label.get_line_count() == 1
        and family.objective_label.text.contains("GATHER TWO CLUES"),
        "investigation objective remains one visible line and clearly names two clues")
    await capture_native_frame("04-lyra-second-join")
    verify(family.interact() and _finish_dialogue(family)
        and "lyra_observation" in family.opening.clues,
        "Lyra's physical listening clue is genuinely interacted with")
    family.ender.position = family.THEORY_TABLE
    verify(not family.interact(),
        "a single clue cannot invent a fuel theory")
    family.ender.position = family.PHASE_CHART
    verify(family.interact() and _finish_dialogue(family),
        "Ender independently inspects the loaded phase readings")
    family.ender.position = family.THEORY_TABLE
    verify(family.interact() and _finish_dialogue(family)
        and same_story.step_key() == "working_theory",
        "same F5 story admits working theory only after dialogue and two clues")
    verify(resumed.save_game()
        and Extended.load(PATH,PATH_V2).get("stage") == "working_theory",
        "crew hypothesis can be saved after complete dialogue without inventing fuel certainty")
    verify(family.interact() and family.repair_review != null
        and family.repair_review.story == same_story,
        "in-game family leads to real physical pickup/melody scene with same story")
    await capture_native_frame("05-connected-workshop-entry")
    verify(not family.repair_review.core.snapshot()["can_launch"]
        and resumed.save_game(),
        "new separate stage save supports repair entry without granting launch")
    var workshop = family.repair_review
    for target in [workshop.PICKUP_A, workshop.PICKUP_B]:
        workshop.ender.position = target
        verify(workshop.interact(),"actual F5 shop physically retrieves material")
    verify(workshop.core.snapshot()["phase"] == "install",
        "same F5 story owns two recovered items")
    verify(resumed.save_game() and Extended.load(PATH,PATH_V2)["core"]["phase"] == "install",
        "real recovered materials persist as independent review checkpoint")
    workshop.ender.position = workshop.INSTALL
    verify(workshop.interact() and workshop.interact(),
        "both source-owned supplies physically installed")
    workshop.ender.position = workshop.ENGINE
    verify(workshop.interact() and workshop.core.snapshot()["phase"] == "listen",
        "mandatory material-only restart fails before melody discovery")
    await capture_native_frame("06-failed-material-retest")
    await capture_cinematic_pair(workshop,resumed,"workshop")
    verify(resumed.save_game() and Extended.load(PATH,PATH_V2)["core"]["phase"] == "listen",
        "saved failure cannot be retroactively treated as a stable core")
    workshop.ender.position = workshop.IONIA
    verify(workshop.interact() and workshop.interact(),
        "Ionia recalls Denith's shanty only AFTER the failed material retest")
    await capture_native_frame("07-ionia-remembered-shanty")
    workshop.ender.position = workshop.CHART
    verify(workshop.interact() and workshop.analysis.open,
        "actual full F5 route opens accessible harmonic choice panel")
    verify(not resumed.save_game(),
        "modal harmonic analysis cannot be saved before a resolved choice")
    await capture_native_frame("08-interactive-harmonic-chart")
    verify(not workshop.submit_analysis(),"no automatic correct harmonic answer")
    verify(workshop.choose_analysis(1) and workshop.submit_analysis(),
        "Ender selects correct isolated review interval pattern")
    workshop.ender.position = workshop.LYRA
    verify(workshop.interact(),"Lyra independently corroborates the stable note")
    workshop.ender.position = workshop.IONIA
    verify(workshop.interact(),"Ionia independently authorizes contained bench test")
    workshop.ender.position = workshop.ENGINE
    verify(workshop.interact()
        and workshop.core.snapshot()["alignment_candidate"]
        and not workshop.core.snapshot()["can_launch"],
        "bench candidate is achieved after real F5 scene inputs, flight locked")
    await capture_native_frame("09-bench-candidate")
    verify(resumed.save_game()
        and Extended.load(PATH,PATH_V2)["core"]["phase"] == "candidate",
        "completed bench candidate persists only in separately versioned v2")
    verify(FileAccess.get_file_as_string(PATH) == checkpoint_before_family,
        "even full bench stage never silently edits v1 physical evidence")
    var candidate_for_cold_process: Dictionary = Extended.load(PATH,PATH_V2)
    # Separate scene-instance cold-start proxy: no in-memory Session, Actor,
    # party or Core object is reused from the previous live scene.
    var cold = Game.instantiate()
    root.add_child(cold)
    await process_frame
    cold.checkpoint_path = PATH
    cold.chapter_progress_path = PATH_V2
    verify(cold.load_game()
        and cold.game_stage == "family_review"
        and cold.family_review.repair_review != null
        and cold.family_review.repair_review.core.snapshot()["phase"] == "candidate"
        and cold.family_review.opening == cold.session.opening,
        "new native Godot scene instance replays completed chapter from verified disk files")
    verify(not cold.family_review.repair_review.core.snapshot()["can_launch"],
        "fresh game instance restores no physical launch permission")
    cold.queue_free()
    await process_frame
    # Same semantic v1 JSON with even one additional whitespace byte cannot
    # certify a different v2-generation parent digest.
    var different_parent := PATH + ".different-generation"
    var different_file := FileAccess.open(different_parent,FileAccess.WRITE)
    different_file.store_string(checkpoint_before_family + "\n")
    different_file.close()
    verify(Checkpoint.validate(Checkpoint.load(different_parent))
        and Extended.load(different_parent,PATH_V2).is_empty(),
        "valid-but-different v1 file bytes cannot silently inherit another v2 generation")
    DirAccess.remove_absolute(different_parent)
    if capture_enabled:
        verify(captured.size() == 9, "all nine native chapter frames captured")
        if OS.get_cmdline_user_args().has("--cinematic-pairs"):
            verify(cinematic_pairs_captured == 3,
                "all three true native scene A/B cinematic comparisons captured")
    verify(resumed.load_game()
        and resumed.game_stage == "family_review"
        and resumed.family_review != null
        and resumed.family_review.repair_review != null
        and resumed.family_review.repair_review.core.snapshot()["phase"] == "candidate"
        and resumed.session.opening.active_party_ids == ["ender","ionia","lyra"],
        "F9 now reconstructs complete family and safe bench candidate from separate validated v2")
    verify(not resumed.family_review.repair_review.core.snapshot()["can_launch"],
        "reloaded candidate NEVER authorizes actual flight or combat Art")
    verify(FileAccess.get_file_as_string(PATH) == checkpoint_before_family,
        "v2 replay does not rewrite original v1 physical checkpoint bytes")
    var tampered: Dictionary = Extended.load(PATH,PATH_V2)
    tampered["party"] = ["ender","ionia","lyra","talen"]
    verify(not Extended.validate(tampered),
        "malicious child party grant rejected")
    tampered = Extended.load(PATH,PATH_V2)
    tampered["unapproved_discovery"] = "moon_bridge"
    verify(not Extended.validate(tampered),
        "unrecognized save keys cannot smuggle early geographic or story unlocks")
    tampered = Extended.load(PATH,PATH_V2)
    tampered["core"]["phase"] = "candidate"
    tampered["core"]["failed_retest"] = false
    verify(not Extended.validate(tampered),
        "forged bench bypass without material failure rejected")
    var corrupt := FileAccess.open(PATH_V2,FileAccess.WRITE)
    corrupt.store_string('{"schema":"aetherwake.first-wake.chapter1.v1"}')
    corrupt.close()
    verify(Extended.load(PATH,PATH_V2).get("core",{}).get("phase") == "listen",
        "corrupt v2 primary falls back to previously verified failed-retest backup")
    verify(resumed.load_game() and
        resumed.family_review.repair_review.core.snapshot()["phase"] == "listen",
        "F9 replays valid stage backup without jumping ahead to candidate")
    var broken_backup := FileAccess.open(PATH_V2 + ".bak",FileAccess.WRITE)
    broken_backup.store_string('{"schema":"invalid"}')
    broken_backup.close()
    verify(resumed.load_game()
        and resumed.game_stage == "postflight"
        and resumed.family_review == null
        and resumed.session.opening.active_party_ids == ["ender","ionia"],
        "invalid v2 and backup recover honest v1 landing/reserve checkpoint")
    verify(FileAccess.get_file_as_string(PATH) == checkpoint_before_family,
        "v2 failure never edits original first-flight v1 evidence")

    resumed.queue_free()
    await process_frame
    var keep_for_cold_process: bool = OS.get_cmdline_user_args().has("--retain-stage-save")
    if keep_for_cold_process:
        verify(Extended.save(candidate_for_cold_process,PATH,PATH_V2)
            and Extended.load(PATH,PATH_V2).get("core",{}).get("phase") == "candidate",
            "restore actual authored candidate for separate Godot OS-process replay")
        print("TSTSS_CH1_COLD_PROCESS_FIXTURE_READY: v1_verified=true v2_candidate=true")
    else:
        for path in [PATH, PATH + ".tmp", PATH + ".bak",
            PATH_V2, PATH_V2 + ".tmp", PATH_V2 + ".bak"]:
            if FileAccess.file_exists(path):
                DirAccess.remove_absolute(path)
    if errors.is_empty():
        print("TSTSS_FIRST_WAKE_GAME_ENTRY_PASS checks=", checks,
            " real_water_contact=true postflight_player=true",
            " save_resume=true legacy_schema_isolated=true family_to_repair=true\n",
            " staged_geography=false extended_save=true",
            " harmonic_bench_candidate=true captures=",captured.size())
        quit(0)
    else:
        for error in errors:
            push_error("TSTSS_FIRST_WAKE_GAME_ENTRY_FAIL: " + error)
        quit(1)
