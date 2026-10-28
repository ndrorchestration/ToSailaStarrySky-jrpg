extends Node2D
## First integrated *playable* First Wake path. No debug scene-switching:
## dock -> Ionia interview -> engineering -> actual physical water contact
## -> controlled shipboard reserve inspection -> separate local checkpoint.
## Deliberately preserves legacy chapter game and save formats untouched.
const Session = preload("res://scripts/first_wake_game_session.gd")
const JobScene = preload("res://scenes/first_wake_job_preview.tscn")
const PostflightScene = preload("res://scenes/first_wake_postflight_game.tscn")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")

var session = Session.new()
var job
var postflight
var game_stage: String = "uninitialized"
var landing_hold: float = 0.0
var checkpoint_path: String = Checkpoint.DEFAULT_PATH
var transition_count: int = 0

func _ready() -> void:
    InputPolicy.ensure_defaults()
    _start_job()

func _start_job() -> bool:
    if job != null or postflight != null:
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

func save_game() -> bool:
    var ok: bool = game_stage == "postflight"         and session.save_checkpoint(checkpoint_path)
    if postflight != null:
        postflight.notify_checkpoint(
            "Postflight checkpoint saved (F9: load)." if ok else
            "Save unavailable: inspect the reserve after real splashdown.")
    return ok

func load_game() -> bool:
    if not session.load_checkpoint(checkpoint_path):
        if postflight != null:
            postflight.notify_checkpoint("No valid first-flight checkpoint found.")
        return false
    if job != null:
        job.queue_free()
        job = null
    if postflight != null:
        postflight.queue_free()
        postflight = null
    game_stage = "first_flight"
    var ok: bool = _enter_postflight()
    if ok:
        postflight.inspected_station = true
        postflight.notify_checkpoint("Recovered postflight checkpoint. Fuel still unknown.")
    return ok

func game_snapshot() -> Dictionary:
    var snap: Dictionary = session.progress_snapshot()
    snap["game_stage"] = game_stage
    snap["native_godot_game_root"] = true
    snap["postflight_player_present"] = postflight != null and postflight.ender != null
    snap["physical_review_active"] = job != null and job.flight_review != null
    snap["transition_count"] = transition_count
    snap["legacy_chapter_scene_used"] = false
    return snap
