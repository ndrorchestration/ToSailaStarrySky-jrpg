extends Node2D
## Native playable LOCAL berth sensor pilot following the verified open-water
## chapter checkpoint. This is not an authored harbor, coastal route, tow
## method, or permission to recruit Lyra automatically.
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const HULL_START := Vector2(215, 395)
const SENSOR_AT := Vector2(780, 395)
const SENSOR_SIZE := Vector2(78, 90)
const HULL_SIZE := Vector2(144, 34)
const APPROACH_SPEED := 74.0
const STABLE_SPEED := 6.0
const STABLE_SECONDS := 0.42

var session
var hull: RigidBody2D
var berth_area: Area2D
var phase: String = "unconfigured"
var contact_observed: bool = false
var float_stable: bool = false
var stable_seconds: float = 0.0
var lines_secured: bool = false
var return_requested: bool = false
var objective: Label
var hint: Label

func configure(s) -> bool:
    if is_inside_tree() or s == null:
        return false
    if not s.can_checkpoint() or not s.physical_landing_observed:
        return false
    if s.opening.active_party_ids != ["ender", "ionia"] or s.opening.step_key() != "postflight_diagnosis":
        return false
    session = s
    phase = "awaiting_approach"
    return true

func _ready() -> void:
    Inputs.ensure_defaults()
    if session == null:
        push_error("TSTSS_LOCAL_BERTH_REQUIRES_REAL_POSTFLIGHT")
        return
    berth_area = Area2D.new()
    berth_area.name = "LocalBerthPhysicalContactSensor"
    berth_area.position = SENSOR_AT
    berth_area.collision_layer = 0
    berth_area.collision_mask = 1
    berth_area.monitoring = true
    var berth_collision := CollisionShape2D.new()
    var berth_shape := RectangleShape2D.new()
    berth_shape.size = SENSOR_SIZE
    berth_collision.shape = berth_shape
    berth_area.add_child(berth_collision)
    add_child(berth_area)
    hull = RigidBody2D.new()
    hull.name = "ActualWakeLocalBerthRigidBody2D"
    hull.position = HULL_START
    hull.lock_rotation = true
    hull.gravity_scale = 0.0
    hull.linear_damp = 0.0
    hull.collision_layer = 1
    hull.collision_mask = 0
    hull.can_sleep = false
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = HULL_SIZE
    shape.shape = rectangle
    hull.add_child(shape)
    var visual := Polygon2D.new()
    visual.name = "AuthorialHullReviewSilhouette"
    visual.color = Color("#e9bd76")
    visual.polygon = PackedVector2Array([
        Vector2(-71, -8), Vector2(55, -8), Vector2(73, 0),
        Vector2(52, 16), Vector2(-52, 16), Vector2(-73, 0)])
    hull.add_child(visual)
    add_child(hull)
    var ui := CanvasLayer.new()
    ui.name = "BerthInstructionHUD"
    add_child(ui)
    objective = Label.new()
    objective.position = Vector2(26, 20)
    objective.add_theme_font_size_override("font_size", 22)
    objective.add_theme_color_override("font_color", Color("#f5e5cb"))
    ui.add_child(objective)
    hint = Label.new()
    hint.position = Vector2(26, 562)
    hint.add_theme_font_size_override("font_size", 18)
    hint.add_theme_color_override("font_color", Color("#f5e5cb"))
    ui.add_child(hint)
    _update_hud()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#233e55"))
    draw_rect(Rect2(0, 392, 960, 174), Color("#3e7f91"))
    for x in range(12):
        var offset := float(x) * 92.0
        draw_line(Vector2(offset, 426), Vector2(offset + 58.0, 426), Color(0.65, 0.83, 0.81, 0.35), 2)
    draw_rect(Rect2(790, 285, 110, 215), Color("#a88a67"))
    draw_rect(Rect2(790, 285, 110, 18), Color("#cfb58c"))
    draw_rect(Rect2(SENSOR_AT.x - 39.0, 360, 78, 72), Color(0.66, 0.87, 0.84, 0.1))
    draw_line(Vector2(790, 275), Vector2(790, 497), Color("#e0c89b"), 4)
    draw_rect(Rect2(0, 0, 960, 102), Color(0.04, 0.09, 0.15, 0.94))
    draw_rect(Rect2(0, 546, 960, 94), Color(0.04, 0.09, 0.15, 0.96))

func _physics_process(delta: float) -> void:
    if hull == null or berth_area == null or phase not in ["approaching", "settling"]:
        return
    if phase == "approaching":
        # Movement is actual RigidBody2D horizontal motion, not a cutscene
        # teleport or a made-up global navigation/travel method.
        hull.linear_velocity = Vector2(APPROACH_SPEED, 0)
        if berth_area.overlaps_body(hull):
            contact_observed = true
            phase = "settling"
            hull.linear_velocity = Vector2.ZERO
            hull.linear_damp = 15.0
    elif phase == "settling":
        if not berth_area.overlaps_body(hull):
            stable_seconds = 0.0
            return
        if hull.linear_velocity.length() <= STABLE_SPEED:
            stable_seconds += maxf(delta, 0.0)
        else:
            stable_seconds = 0.0
        if stable_seconds >= STABLE_SECONDS:
            float_stable = true
            phase = "berth_ready"
    _update_hud()

func start_local_approach() -> bool:
    if phase != "awaiting_approach" or session == null or not session.can_checkpoint():
        return false
    if hull == null or berth_area == null or berth_area.overlaps_body(hull):
        return false
    phase = "approaching"
    _update_hud()
    return true

func secure_lines() -> bool:
    if phase != "berth_ready" or not contact_observed or not float_stable:
        return false
    if hull == null or berth_area == null or not berth_area.overlaps_body(hull):
        return false
    if hull.linear_velocity.length() > STABLE_SPEED:
        return false
    lines_secured = true
    phase = "secured_local_berth"
    _update_hud()
    return true

func request_return() -> bool:
    if session == null or not session.can_checkpoint():
        return false
    return_requested = true
    return true

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if event.is_action_pressed(Inputs.INTERACT):
        var used: bool = start_local_approach() if phase == "awaiting_approach" else secure_lines()
        if used:
            get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
        if request_return():
            get_viewport().set_input_as_handled()

func review_snapshot() -> Dictionary:
    return {
        "phase": phase,
        "local_2d_sensor_contact": contact_observed and berth_area != null and hull != null and berth_area.overlaps_body(hull),
        "float_stable": float_stable,
        "stable_seconds": stable_seconds,
        "hull_speed": hull.linear_velocity.length() if hull != null else -1.0,
        "lines_secured": lines_secured,
        "party": session.opening.active_party_ids.duplicate() if session != null else [],
        "story_step": session.opening.step_key() if session != null else "unconfigured",
        "real_global_shoreline_route": false,
        "reunion_authorized": false,
        "fuel_formula": "unknown",
        "production_ocean_verified": false,
    }

func _update_hud() -> void:
    if objective == null:
        return
    objective.text = "FIRST WAKE / LOCAL SAFE BERTH REVIEW — ENDER + IONIA"
    match phase:
        "awaiting_approach":
            hint.text = "E: begin measured local berth approach  |  R: return to shipboard"
        "approaching":
            hint.text = "Observe actual ship contact; not a world-scale route  |  R: return"
        "settling":
            hint.text = "Waiting for verified stable berth overlap  |  R: return"
        "berth_ready":
            hint.text = "E: secure berth lines after stable physical contact  |  R: return"
        "secured_local_berth":
            hint.text = "Local lines secure. Later reunion remains separate. R: return to save."
        _:
            hint.text = "No physical berth proof."
