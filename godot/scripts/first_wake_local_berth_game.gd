extends Node2D
## Native playable LOCAL berth sensor pilot following the verified open-water
## chapter checkpoint. This is not an authored harbor, coastal route, tow
## method, or permission to recruit Lyra automatically.
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const CinematicStage = preload("res://scripts/first_wake_berth_cinematic_stage.gd")
const ShipArt = preload("res://scripts/first_wake_berth_ship_art.gd")
const SourceShip3D = preload("res://scripts/prototypes/first_wake_3d_inset.gd")
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
var telemetry: Label
var cinematic_stage
var ship_art
var native_3d_review: Control
var three_d_review_enabled: bool = false
var hud_layer: CanvasLayer

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
    # Original source shader materials and art sit BEHIND all physical nodes,
    # with no collision shapes, input capture, scene or story authority.
    cinematic_stage = CinematicStage.new()
    cinematic_stage.name = "SourceNativePlayableBerthAtmosphere"
    add_child(cinematic_stage)
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
    ship_art = ShipArt.new()
    ship_art.name = "FourWingWakeStudyAttachedToPhysicalHull"
    hull.add_child(ship_art)
    add_child(hull)
    var ui := CanvasLayer.new()
    ui.name = "BerthInstructionHUD"
    hud_layer = ui
    add_child(ui)
    objective = Label.new()
    objective.position = Vector2(26, 20)
    objective.add_theme_font_size_override("font_size", 22)
    objective.add_theme_color_override("font_color", Color("#f5e5cb"))
    ui.add_child(objective)
    telemetry = Label.new()
    telemetry.position = Vector2(27, 75)
    telemetry.add_theme_font_size_override("font_size", 15)
    telemetry.add_theme_color_override("font_color", Color("#c4dfd6"))
    ui.add_child(telemetry)
    hint = Label.new()
    hint.position = Vector2(27, 559)
    hint.custom_minimum_size.x = 910.0
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_font_size_override("font_size", 18)
    hint.add_theme_color_override("font_color", Color("#f5e5cb"))
    ui.add_child(hint)
    _update_hud()
    queue_redraw()

func _draw() -> void:
    # The source-native cinematic stage owns all decorative draw calls.
    # The collision shapes and authoritative hull remain unchanged.
    pass

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

func set_native_3d_review_enabled(enabled: bool) -> bool:
    # Original PR #486 source mesh and existing Chapter I viewport are reused;
    # the optional shot is never a substitute for 2D hull or berth physics.
    if not is_inside_tree() or hull == null or hud_layer == null:
        return false
    if enabled and native_3d_review == null:
        native_3d_review = SourceShip3D.new()
        native_3d_review.name = "ReadOnlySourceAureateWakeBerth3D"
        native_3d_review.position = Vector2(578, 125)
        hud_layer.add_child(native_3d_review)
        var plan := {
            "admitted_for_review": true,
            "executes_visuals": false,
            "blocks_progression": false,
            "visual_source_pr": 486,
            "camera_shot_id": "bow-quarter",
            "visual_grade_id": "golden-clear",
            "scene_phase": "local-berth-study",
            "reduced_motion": cinematic_stage.reduced_motion if cinematic_stage != null else false,
            "low_detail": false,
            "grants_combat_magic": false,
            "modifies_story_state": false,
            "changes_saves": false,
            "production_ocean_verified": false,
        }
        if not native_3d_review.set_visual_intent(plan):
            native_3d_review.queue_free()
            native_3d_review = null
            return false
        native_3d_review.set_warning_enabled(false)
    three_d_review_enabled = enabled
    if native_3d_review != null:
        native_3d_review.visible = enabled
        native_3d_review.set_review_quality(
            cinematic_stage.reduced_motion if cinematic_stage != null else false, false)
    _update_hud()
    return true

func _process(delta: float) -> void:
    if three_d_review_enabled and native_3d_review != null:
        native_3d_review.advance_visual_clock(delta)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_V:
        if set_native_3d_review_enabled(not three_d_review_enabled):
            get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_M:
        if cinematic_stage != null:
            cinematic_stage.set_reduced_motion(not cinematic_stage.reduced_motion)
            _update_hud()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed(Inputs.INTERACT):
        var used: bool = start_local_approach() if phase == "awaiting_approach" else secure_lines()
        if used:
            get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
        if request_return():
            get_viewport().set_input_as_handled()

func set_reduced_motion(enabled: bool) -> void:
    if cinematic_stage != null:
        cinematic_stage.set_reduced_motion(enabled)
    if native_3d_review != null:
        native_3d_review.set_review_quality(enabled, false)
    _update_hud()

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
        "cinematic_art_has_no_contact_authority": true,
        "source_3d_review_enabled": three_d_review_enabled,
        "source_3d_mesh_present": native_3d_review != null and native_3d_review.ship_model != null,
        "source_3d_has_no_contact_authority": true,
        "reduced_motion_visual_only": cinematic_stage.reduced_motion if cinematic_stage != null else false,
    }

func _update_hud() -> void:
    if objective == null:
        return
    var dwell: float = clampf(stable_seconds / STABLE_SECONDS, 0.0, 1.0)
    if cinematic_stage != null:
        cinematic_stage.set_berth_display(phase,
            hull.position.x if hull != null else HULL_START.x, dwell)
    if ship_art != null:
        ship_art.set_lines_secured(lines_secured)
    objective.text = "FIRST WAKE  /  AUREATE WAKE — LOCAL BERTH"
    var contact_label := "SENSOR: OVERLAP" if contact_observed else "SENSOR: CLEAR"
    var dwell_label := str(int(roundf(dwell * 100.0))) + "%"
    telemetry.text = "ENDER + IONIA   |   " + contact_label + "   |   STABLE DWELL: " + dwell_label
    var motion := "STILL SEA" if cinematic_stage != null and cinematic_stage.reduced_motion else "SEA MOTION"
    var view := "3D ON" if three_d_review_enabled else "3D OFF"
    match phase:
        "awaiting_approach":
            hint.text = "E: approach berth  |  V: " + view + "  |  M: " + motion + "  |  R: shipboard"
        "approaching":
            hint.text = "Local hull is moving; await actual sensor overlap  |  M: " + motion
        "settling":
            hint.text = "Physical contact registered; waiting for safe low-speed settling  |  M: " + motion
        "berth_ready":
            hint.text = "Stable contact achieved — E: secure lines  |  M: " + motion
        "secured_local_berth":
            hint.text = "Lines secured locally. Family arrival is NOT triggered.  |  R: return"
        _:
            hint.text = "Physical berth proof unavailable."
