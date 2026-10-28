extends SceneTree
## A DISTINCT Godot process runs this script after a previous native game process
## physically played F5 all the way to the bounded repair/bench candidate.
## This test receives no in-memory Session, Game, or Core instances.
const Game = preload("res://scenes/first_wake_game.tscn")
const V1 = preload("res://scripts/first_wake_game_checkpoint.gd")
const V2 = preload("res://scripts/first_wake_chapter1_progress_v2.gd")
const PATH := "user://first_wake_game_entry_integration_test.json"
const PATH_V2 := PATH + ".chapter_v2"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures.append(why)

func _verify() -> void:
    check(V2._valid_parent(PATH),"parent file verifies original v1 real-water schema")
    var old_v1_hash: String = FileAccess.get_sha256(PATH)
    var old_v2_hash: String = FileAccess.get_sha256(PATH_V2)
    var stage: Dictionary = V2.load(PATH,PATH_V2)
    check(stage.get("stage","") == "repair_review"
        and stage.get("core",{}).get("phase","") == "candidate",
        "separate-process source saved actual bench progression")
    check(V2.validate(stage),"saved progression has exact v2 schema and causal state")
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    game.checkpoint_path = PATH
    game.chapter_progress_path = PATH_V2
    var success: bool = game.load_game()
    check(success,"F9 can replay historical scene state from new Godot process")
    if success:
        check(game.session.restored_from_local_checkpoint
            and game.session.physical_landing_observed
            and game.session.reserve_inspected,
            "real physical source evidence restored as historical v1, not new sensor hit")
        check(game.game_stage == "family_review"
            and game.family_review != null and game.postflight == null,
            "normal Godot gameplay opens real family/repair scene instead of job fixture")
        if game.family_review != null:
            var family = game.family_review
            check(family.opening == game.session.opening,
                "same reconstructed story authority across native root and family")
            check(family.opening.active_party_ids == ["ender","ionia","lyra"]
                and not family.opening.active_party_ids.has("talen"),
                "true crew order retained; child remains noncombat")
            check(family.scene_phase == "repair_review"
                and family.repair_review != null,
                "actual connected workshop reappears after OS process exit")
            if family.repair_review != null:
                var core: Dictionary = family.repair_review.core.snapshot()
                check(core["phase"] == "candidate"
                    and core["failed_retest"] and core["melody_recognized"]
                    and core["recovered"].size() == 2 and core["installed"].size() == 2,
                    "real material/failed test/melody history reconstructed causally")
                check(core["alignment_candidate"] and not core["can_launch"]
                    and not core["can_execute_art"],
                    "saved bench proof cannot authorize physical flight or combat")
    check(FileAccess.get_sha256(PATH) == old_v1_hash,
        "second OS process never mutates validated v1 physical checkpoint bytes")
    check(FileAccess.get_sha256(PATH_V2) == old_v2_hash,
        "loading Chapter One continuation never mutates v2 bytes")
    game.queue_free()
    await process_frame
    for file in [PATH,PATH+".tmp",PATH+".bak",PATH_V2,PATH_V2+".tmp",PATH_V2+".bak"]:
        if FileAccess.file_exists(file):
            DirAccess.remove_absolute(file)
    if failures.is_empty():
        print("TSTSS_CH1_COLD_PROCESS_RESTORE_PASS checks=",checks,
            " independent_godot_invocation=true source_v1_verified=true",
            " family_workshop_restored=true relaunch_denied=true")
        quit(0)
    else:
        for reason in failures:
            push_error("TSTSS_CH1_COLD_PROCESS_RESTORE_FAIL: "+reason)
        quit(1)
