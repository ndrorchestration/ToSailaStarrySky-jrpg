extends Node2D
## First integrated *playable* First Wake path. No debug scene-switching:
## dock -> Ionia interview -> engineering -> actual physical water contact
## -> controlled shipboard reserve inspection -> separate local checkpoint.
## Deliberately preserves legacy chapter game and save formats untouched.
const Session = preload("res://scripts/first_wake_game_session.gd")
const JobScene = preload("res://scenes/first_wake_job_preview.tscn")
const PostflightScene = preload("res://scenes/first_wake_postflight_game.tscn")
const FamilyScene = preload("res://scenes/first_wake_postflight_family_review.tscn")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")
const ChapterProgress = preload("res://scripts/first_wake_chapter1_progress_v2.gd")
const MelodyFixture = preload("res://scripts/first_wake_melody_math_fixture.gd")

var session = Session.new()
var job
var postflight
var family_review
# Explicitly staged, non-geographic safe-berth review. No tow, route,
# harbor coordinates, or travel simulation is implied by two presses.
var safe_berth_review_confirmations: int = 0
var game_stage: String = "uninitialized"
var landing_hold: float = 0.0
var checkpoint_path: String = Checkpoint.DEFAULT_PATH
var chapter_progress_path: String = ChapterProgress.DEFAULT_PATH
var transition_count: int = 0

func _ready() -> void:
    InputPolicy.ensure_defaults()
    _start_job()

func _start_job() -> bool:
    if job != null or postflight != null or family_review != null:
        return false
    job = JobScene.instantiate()
    job.name = "PlayableFirstWakeFromJobFlyer"
    add_child(job)
    if not session.bind_job_scene(job.opening):
        job.queue_free()
        job = null
        return false
    game_stage = "first_flight"
    return true

func _process(delta: float) -> void:
    if game_stage != "first_flight" or job == null:
        return
    var flight = job.flight_review
    if flight == null or flight.phase != "waterborne":
        return
    if not session.physical_landing_observed:
        if not session.record_physical_landing(flight.review_snapshot()):
            return
    landing_hold += maxf(0.0, delta)
    # Keep the real waterborne image available briefly; then restore player
    # agency inside the ship. Visual timing cannot assert physical contact.
    if landing_hold >= 0.8:
        _enter_postflight()

func _enter_postflight() -> bool:
    if game_stage != "first_flight" or not session.physical_landing_observed:
        return false
    if postflight != null:
        return false
    var candidate = PostflightScene.instantiate()
    if not candidate.configure(session):
        candidate.free()
        return false
    if job != null:
        job.queue_free()
        job = null
    safe_berth_review_confirmations = 0
    postflight = candidate
    postflight.name = "PlayablePostflightShipboardInspection"
    add_child(postflight)
    game_stage = "postflight"
    transition_count += 1
    return true

func _input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if event.is_action_pressed(InputPolicy.SAVE_PROGRESS):
        save_game()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(InputPolicy.LOAD_PROGRESS):
        load_game()
        get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
        if request_safe_berth_review():
            get_viewport().set_input_as_handled()

## Two explicit player acknowledgments are required after the *actual*
## physics-based water-contact and interactive reserve dialogue. This
## transition stages a controlled family *review* without claiming a route.
func request_safe_berth_review() -> bool:
    if game_stage != "postflight" or postflight == null or family_review != null:
        return false
    if postflight.reserve_dialogue_open or not postflight.inspected_station:
        return false
    if not session.can_checkpoint() or not session.physical_landing_observed:
        return false
    if safe_berth_review_confirmations == 0:
        safe_berth_review_confirmations = 1
        postflight.notify_checkpoint(
            "RECOVERY REVIEW ONLY: no tow or harbor simulated. R again stages safe berth.")
        return true
    if safe_berth_review_confirmations != 1:
        return false
    return _enter_family_review()

func _enter_family_review() -> bool:
    if game_stage != "postflight" or postflight == null or family_review != null:
        return false
    if safe_berth_review_confirmations != 1 or not session.can_checkpoint():
        return false
    if session.opening.step_key() != "postflight_diagnosis":
        return false
    # First persist the VERIFIED v1 landing/reserve anchor if not already
    # saved; the separate v2 family record may never invent water physics.
    if not ChapterProgress._valid_parent(checkpoint_path):
        if not session.save_checkpoint(checkpoint_path):
            return false
    # Preserve the exact original Opening object shared by the hired player
    # and the physical flight review. No scripted/forged party rebuilding.
    var candidate = FamilyScene.instantiate()
    if not candidate.configure_after_safe_review(
        session.opening,session.physical_landing_observed,
        session.physical_landing_observed,session.reserve_inspected,true):
        candidate.free()
        return false
    postflight.queue_free()
    postflight = null
    family_review = candidate
    family_review.name = "PlayablePostflightFamilyToHarmonicReview"
    family_review.last_message = (
        "STAGED SAFE BERTH / SITE UNASSIGNED. F5 saves Chapter I review "
        + "progress in separate v2; F9 restores it only with valid v1 evidence.")
    add_child(family_review)
    safe_berth_review_confirmations = 2
    game_stage = "family_review"
    transition_count += 1
    return true

func save_game() -> bool:
    if game_stage == "family_review" and family_review != null:
        var extended: Dictionary = ChapterProgress.from_scene(family_review,checkpoint_path)
        var accepted: bool = (not extended.is_empty() and
            ChapterProgress.save(extended,checkpoint_path,chapter_progress_path))
        if family_review.repair_review != null:
            var shop = family_review.repair_review
            shop.last_message = ("Chapter One review progress saved (F9: restore)." if accepted
                else "Save unavailable during conversation/chart or without valid landing proof.")
            shop._refresh()
        else:
            family_review.last_message = ("Chapter One review progress saved (F9: restore)." if accepted
                else "Finish dialogue and verify reserve checkpoint before saving.")
            family_review._refresh()
        return accepted
    var ok: bool = game_stage == "postflight" and session.save_checkpoint(checkpoint_path)
    if postflight != null:
        postflight.notify_checkpoint(
            "Postflight checkpoint saved (F9: load)." if ok else
            "Save unavailable: inspect the reserve after real splashdown.")
    return ok

func _reset_to_postflight() -> bool:
    if not session.load_checkpoint(checkpoint_path):
        return false
    if job != null:
        job.queue_free()
        job = null
    if postflight != null:
        postflight.queue_free()
        postflight = null
    if family_review != null:
        family_review.queue_free()
        family_review = null
    safe_berth_review_confirmations = 0
    game_stage = "first_flight"
    var ready: bool = _enter_postflight()
    if ready:
        postflight.inspected_station = true
        postflight.notify_checkpoint("Recovered postflight checkpoint. Fuel still unknown.")
    return ready

func _replay_core_saved_state(saved: Dictionary) -> bool:
    if family_review == null or family_review.repair_review == null:
        return false
    var core = family_review.repair_review.core
    for item in saved["recovered"]:
        if not core.take_world_item(item,"world_pickup"):
            return false
    for item in saved["installed"]:
        if not core.install_part(item,true):
            return false
    const PHASE_SEQUENCE = ["retest","listen","repeat","analyze","observe","authorize","verify","candidate"]
    var target: String = saved["phase"]
    if target in PHASE_SEQUENCE:
        if PHASE_SEQUENCE.find(target) >= 1 and not core.retest_with_supplies(true,true,true):
            return false
        if PHASE_SEQUENCE.find(target) >= 2 and not core.ionia_hums_unprompted(true):
            return false
        if PHASE_SEQUENCE.find(target) >= 3 and not core.ionia_repeats_denith_song(true,true):
            return false
        if PHASE_SEQUENCE.find(target) >= 4 and not core.ender_matches_review_phrase(
                MelodyFixture.sample_phrase(),MelodyFixture.sample_sensor_vector()):
            return false
        if PHASE_SEQUENCE.find(target) >= 5 and not core.lyra_confirms_response(true):
            return false
        if PHASE_SEQUENCE.find(target) >= 6 and not core.ionia_approves_bench_test(true,true):
            return false
        if PHASE_SEQUENCE.find(target) >= 7 and not core.verify_stable_core(true,true):
            return false
    var now: Dictionary = core.snapshot()
    return (now["phase"] == saved["phase"] and
        now["recovered"] == saved["recovered"] and now["installed"] == saved["installed"] and
        now["failed_retest"] == saved["failed_retest"] and
        now["melody_recognized"] == saved["melody_recognized"] and
        not now["can_launch"] and not now["can_execute_art"])

func _restore_chapter_progress(saved: Dictionary) -> bool:
    if not ChapterProgress.validate(saved) or game_stage != "postflight":
        return false
    if not request_safe_berth_review() or not request_safe_berth_review():
        return false
    if family_review == null or family_review.opening != session.opening:
        return false
    var family = family_review
    family.child_block_ship_viewed = saved["talen_blocks"]
    var stage: String = saved["stage"]
    if stage != "family_arrival":
        if not session.opening.introduce_lyra_and_talen(true):
            return false
        family.scene_phase = "investigation"
        for clue in saved["clues"]:
            if not session.opening.record_clue(clue):
                return false
    if stage in ["working_theory","repair_review"]:
        if not session.opening.form_working_fuel_theory():
            return false
        family.scene_phase = "working_theory"
    if stage == "repair_review":
        family.ender.position = family.THEORY_TABLE
        if not family.open_connected_workshop():
            return false
        if not _replay_core_saved_state(saved["core"]):
            return false
        family.repair_review.last_message = (
            "Recovered historical Chapter One review progress; core flight remains locked.")
        family.repair_review._refresh()
    else:
        family.last_message = ("Recovered Chapter One review; harbor route is still unverified.")
        family._refresh()
    return (family.scene_phase == stage and
        session.opening.active_party_ids == saved["party"] and
        session.opening.clues == saved["clues"])

func load_game() -> bool:
    # Only the existing v1 checkpoint may certify historical water contact.
    # If the separate v2 stage file is malformed/mismatched, return safely
    # to v1 without editing either disk file or admitting fictional progress.
    var saved: Dictionary = ChapterProgress.load(checkpoint_path,chapter_progress_path)
    if not _reset_to_postflight():
        if postflight != null:
            postflight.notify_checkpoint("No valid first-flight checkpoint found.")
        return false
    if saved.is_empty():
        return true
    if _restore_chapter_progress(saved):
        return true
    # Defensive transaction rollback: no partial family state survives a
    # failed replay even if a structurally valid malicious file was supplied.
    return _reset_to_postflight()

func game_snapshot() -> Dictionary:
    var snap: Dictionary = session.progress_snapshot()
    snap["game_stage"] = game_stage
    snap["native_godot_game_root"] = true
    snap["postflight_player_present"] = postflight != null and postflight.ender != null
    snap["family_review_active"] = family_review != null
    snap["safe_berth_staging_confirmations"] = safe_berth_review_confirmations
    snap["real_return_route_verified"] = false
    snap["family_progress_persisted"] = (game_stage == "family_review" and
        not ChapterProgress.load(checkpoint_path,chapter_progress_path).is_empty())
    snap["connected_repair_review_active"] = (
        family_review != null and family_review.repair_review != null)
    snap["physical_review_active"] = job != null and job.flight_review != null
    snap["transition_count"] = transition_count
    snap["legacy_chapter_scene_used"] = false
    return snap
