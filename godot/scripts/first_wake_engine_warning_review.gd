extends Node2D
## Standalone PW-01 first-flight review. The legitimate Chapter I FSM and
## actual Area2D/RigidBody2D decide warning, descent and waterborne.
## This wrapper never writes to them and is not a production ship model.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Flight = preload("res://scenes/first_wake_flight_water_review.tscn")
const Handoff = preload("res://scripts/first_wake_cinematic_handoff.gd")
const Warning = preload("res://scripts/first_wake_engine_warning_vfx.gd")

var opening
var flight: Node2D
var warning_visual: Node2D
var visual_enabled: bool = true
var visual_interrupted: bool = false
var reduced_motion: bool = true
var detail_level: int = 0
var last_admitted_warning: bool = false
var admission_count: int = 0

func _ready() -> void:
    opening = Opening.new()
    if not opening.accept_ionia_job() or not opening.complete_engineering_checks():
        push_error("PW01_SETUP_FAIL: exact Ionia-first preflight was refused")
        return
    flight = Flight.instantiate()
    if not flight.configure_preflight(opening):
        push_error("PW01_SETUP_FAIL: real First Wake flight refused preflight")
        return
    flight.name = "AuthoritativeFirstWake2DFlight"
    add_child(flight)
    warning_visual = Warning.new()
    warning_visual.position = Vector2(0, -7)
    flight.ship_body.add_child(warning_visual)
    warning_visual.configure(reduced_motion, detail_level)
    set_process(true)

func _process(_delta: float) -> void:
    synchronize_visual()

func synchronize_visual() -> bool:
    if flight == null or warning_visual == null:
        return false
    # Only a live Godot scene's snapshot reaches the existing cinema handoff.
    # A forged detached dictionary cannot turn this visual on.
    var descriptor: Dictionary = Handoff.build(flight.review_snapshot(), reduced_motion, detail_level == 0, false)
    var admitted: bool = (
        bool(descriptor.get("admitted_for_review", false))
        and descriptor.get("scene_phase", "") == "warning"
        and descriptor.get("camera_shot_id", "") == "stern-quarter"
        and descriptor.get("visual_grade_id", "") == "golden-clear"
        and not bool(descriptor.get("grants_combat_magic", true))
        and not bool(descriptor.get("modifies_story_state", true))
        and not bool(descriptor.get("changes_saves", true))
    )
    if not admitted:
        last_admitted_warning = false
        visual_interrupted = false
        warning_visual.stop_warning()
        return false
    if not last_admitted_warning:
        admission_count += 1
    last_admitted_warning = true
    if not visual_enabled or visual_interrupted:
        warning_visual.stop_warning()
        return true
    if not warning_visual.active:
        warning_visual.begin_warning()
    return true

func set_visual_enabled(enabled: bool) -> void:
    visual_enabled = enabled
    synchronize_visual()

func interrupt_visual() -> bool:
    if not last_admitted_warning or not warning_visual.active:
        return false
    visual_interrupted = true
    warning_visual.stop_warning()
    return true

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    warning_visual.configure(reduced_motion, detail_level)
    synchronize_visual()

func set_detail_level(level: int) -> bool:
    if level < 0 or level > 2:
        return false
    detail_level = level
    warning_visual.configure(reduced_motion, detail_level)
    return true

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_V:
        set_visual_enabled(not visual_enabled)
    elif event.keycode == KEY_I:
        interrupt_visual()
    elif event.keycode == KEY_M:
        set_reduced_motion(not reduced_motion)
    elif event.keycode == KEY_Q:
        set_detail_level((detail_level + 1) % 3)
    elif event.keycode == KEY_ESCAPE:
        get_tree().quit()
