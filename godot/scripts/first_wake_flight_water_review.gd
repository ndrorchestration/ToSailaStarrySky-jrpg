extends Node2D
## Bounded Chapter I first-flight/ocean-splashdown review, not production flight.
## RigidBody2D + Area2D report actual 2D physics contact; buoyancy is an
## intentionally simplified LOCAL test. No planet/ocean route or save admission.
## Requires the creator-directed Ionia-first preflight contract from the job scene.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")

const SURFACE_Y := 410.0
const FLOAT_BUOYANCY := 120.0
const SETTLE_SECONDS := 0.45
const ASCENT_SECONDS := 1.25
## Development dialogue candidate paraphrasing the FW-07 story document;
## observation only, not approved final VO or a unique-fuel formula.
const POSTFLIGHT_INSPECTION_LINES := [
    "ENDER: The usable reserve is gone. The phase drift and containment strain appeared under load.",
    "IONIA: Denith required a particular supply. I know how it was handled, not what it contained.",
    "ENDER: Then we have observations, not a recipe. We cannot substitute ordinary fuel on a guess.",
]

var opening
var phase: String = "not_configured"
var elapsed: float = 0.0
var settled_seconds: float = 0.0
var contact_observed: bool = false
var stable_float_verified: bool = false
var ship_body: RigidBody2D
var sea_area: Area2D
var status_label: Label
var hint_label: Label
var telemetry_label: Label
var inspection_label: Label
var postflight_dialogue_open: bool = false
var postflight_dialogue_cursor: int = 0
var postflight_reserve_observed: bool = false

func configure_preflight(preflight) -> bool:
    if is_inside_tree() or preflight == null:
        return false
    if not preflight.has_method("step_key") or preflight.step_key() != "preflight":
        return false
    if preflight.active_party_ids != ["ender", "ionia"]:
        return false
    opening = preflight
    phase = "awaiting_launch"
    return true

func _ready() -> void:
    InputPolicy.ensure_defaults()
    sea_area = Area2D.new()
    sea_area.name = "LocalReviewOceanSensor"
    sea_area.monitoring = true
    sea_area.collision_layer = 0
    sea_area.collision_mask = 1
    sea_area.position = Vector2(480, SURFACE_Y + 115)
    var sea_shape := CollisionShape2D.new()
    var sea_rectangle := RectangleShape2D.new()
    sea_rectangle.size = Vector2(960, 230)
    sea_shape.shape = sea_rectangle
    sea_area.add_child(sea_shape)
    add_child(sea_area)
    sea_area.body_entered.connect(_on_water_body_entered)

    ship_body = RigidBody2D.new()
    ship_body.name = "AureateWakeLocalBuoyancyProof"
    ship_body.position = Vector2(480, 255)
    ship_body.lock_rotation = true
    ship_body.gravity_scale = 0.0
    ship_body.linear_damp = 0.0
    ship_body.collision_layer = 1
    ship_body.collision_mask = 0
    var hull_shape := CollisionShape2D.new()
    var hull_rectangle := RectangleShape2D.new()
    hull_rectangle.size = Vector2(144, 34)
    hull_shape.shape = hull_rectangle
    ship_body.add_child(hull_shape)
    var hull_visual := Polygon2D.new()
    hull_visual.color = Color("#e0b875")
    hull_visual.polygon = PackedVector2Array([
        Vector2(-72, -8), Vector2(57, -8), Vector2(75, 0),
        Vector2(52, 16), Vector2(-54, 16), Vector2(-75, 0),
    ])
    ship_body.add_child(hull_visual)
    var wings := Polygon2D.new()
    wings.color = Color(0.56, 0.84, 0.88, 0.64)
    wings.polygon = PackedVector2Array([
        Vector2(-18, -6), Vector2(-92, -38), Vector2(-102, -18),
        Vector2(-24, 5), Vector2(-70, 25), Vector2(-57, 31),
        Vector2(8, 12), Vector2(84, -22), Vector2(102, -15),
        Vector2(30, 12),
    ])
    ship_body.add_child(wings)
    add_child(ship_body)

    var ui := CanvasLayer.new()
    ui.name = "FlightReviewOverlay"
    add_child(ui)
    status_label = _make_label(ui, Vector2(24, 20), 19)
    telemetry_label = _make_label(ui, Vector2(24, 59), 15)
    hint_label = _make_label(ui, Vector2(26, 563), 17)
    inspection_label = _make_label(ui, Vector2(35, 474), 16)
    inspection_label.custom_minimum_size = Vector2(875, 82)
    inspection_label.visible = false
    _refresh_presentation()

func _make_label(parent: Node, at: Vector2, size: int) -> Label:
    var node := Label.new()
    node.position = at
    node.custom_minimum_size = Vector2(905, 45)
    node.add_theme_font_size_override("font_size", size)
    node.add_theme_color_override("font_color", Color("#fff0d0"))
    node.add_theme_color_override("font_shadow_color", Color("#152536"))
    node.add_theme_constant_override("shadow_offset_x", 1)
    node.add_theme_constant_override("shadow_offset_y", 2)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(node)
    return node

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#17364e"))
    draw_rect(Rect2(0, 124, 960, 286), Color("#366579"))
    draw_circle(Vector2(752, 174), 44.0, Color(0.99, 0.84, 0.54, 0.74))
    for index in range(8):
        var x := float(index * 142 - 40)
        draw_arc(Vector2(x, 308), 82.0, PI, TAU, 18, Color(0.66, 0.85, 0.84, 0.15), 2.0)
    draw_rect(Rect2(0, SURFACE_Y, 960, 230), Color("#20596a"))
    draw_line(Vector2(0, SURFACE_Y), Vector2(960, SURFACE_Y), Color("#aadad2"), 4.0)
    for index in range(8):
        var x := float(index * 143)
        draw_line(Vector2(x, 452), Vector2(x + 71, 452), Color(0.74, 0.88, 0.87, 0.35), 2.0)
    draw_rect(Rect2(0, 0, 960, 103), Color(0.04, 0.08, 0.16, 0.91))
    draw_rect(Rect2(0, 545, 960, 95), Color(0.04, 0.08, 0.16, 0.94))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(InputPolicy.INTERACT) and not event.is_echo():
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if phase == "awaiting_launch":
        return begin_short_test_flight()
    if phase == "warning":
        return stabilize_for_water_descent()
    if postflight_dialogue_open:
        return advance_postflight_inspection()
    if phase == "waterborne":
        return start_postflight_inspection()
    return false

func start_postflight_inspection() -> bool:
    if phase != "waterborne" or opening == null or postflight_dialogue_open or postflight_reserve_observed:
        return false
    if not contact_observed or not stable_float_verified or opening.step_key() != "waterborne":
        return false
    if opening.active_party_ids != ["ender", "ionia"]:
        return false
    postflight_dialogue_open = true
    postflight_dialogue_cursor = 0
    _refresh_presentation()
    return true

func advance_postflight_inspection() -> bool:
    if not postflight_dialogue_open:
        return false
    if postflight_dialogue_cursor + 1 < POSTFLIGHT_INSPECTION_LINES.size():
        postflight_dialogue_cursor += 1
        _refresh_presentation()
        return true
    # Confirmation only AFTER every diagnostic line has been observed;
    # this is still an authored measurement, not a fuel chemistry proof.
    if not opening.inspect_postflight_reserve(true):
        return false
    postflight_dialogue_open = false
    postflight_reserve_observed = true
    phase = "postflight_diagnosis"
    _refresh_presentation()
    return true

func begin_short_test_flight() -> bool:
    if phase != "awaiting_launch" or opening == null:
        return false
    if not opening.begin_test_flight():
        return false
    phase = "ascent"
    elapsed = 0.0
    ship_body.gravity_scale = 0.0
    ship_body.linear_velocity = Vector2(0, -38)
    _refresh_presentation()
    return true

func stabilize_for_water_descent() -> bool:
    if phase != "warning" or opening == null:
        return false
    # These are authored trial telemetry observations, NOT validated engine
    # equations and not evidence about the specialized fuel's composition.
    if not opening.record_engine_failure(true, true, true):
        return false
    phase = "descent"
    ship_body.gravity_scale = 0.65
    ship_body.linear_damp = 0.9
    ship_body.linear_velocity = Vector2(0, 38)
    _refresh_presentation()
    return true

func _physics_process(delta: float) -> void:
    if ship_body == null:
        return
    if phase == "ascent":
        elapsed += delta
        if elapsed >= ASCENT_SECONDS:
            ship_body.linear_velocity = Vector2.ZERO
            phase = "warning"
            _refresh_presentation()
    elif phase == "descent":
        if contact_observed:
            var submergence := maxf(0.0, (ship_body.position.y + 20.0) - SURFACE_Y)
            ship_body.apply_central_force(Vector2(0.0, -minf(submergence, 60.0) * FLOAT_BUOYANCY))
            ship_body.linear_damp = 5.0
            if absf(ship_body.linear_velocity.y) <= 18.0 and absf(ship_body.position.y - (SURFACE_Y - 14.0)) <= 19.0:
                settled_seconds += delta
            else:
                settled_seconds = 0.0
            if settled_seconds >= SETTLE_SECONDS:
                stable_float_verified = true
                if opening.complete_ocean_splashdown(contact_observed, stable_float_verified):
                    phase = "waterborne"
                    ship_body.freeze = true
                    _refresh_presentation()

func _on_water_body_entered(body: Node2D) -> void:
    if body != ship_body or phase != "descent":
        return
    contact_observed = true
    _refresh_presentation()

func review_snapshot() -> Dictionary:
    return {
        "phase": phase,
        "party": opening.active_party_ids.duplicate() if opening != null else [],
        "story_step": opening.step_key() if opening != null else "unconfigured",
        "inspection_dialogue_open": postflight_dialogue_open,
        "postflight_reserve_observed": postflight_reserve_observed,
        "actual_2d_area_contact_observed": contact_observed,
        "stable_buoyant_hull_observed": stable_float_verified,
        "settle_seconds": settled_seconds,
        "hull_y": ship_body.position.y if ship_body != null else -1.0,
        "fuel_formula": "unknown",
        "production_ocean_verified": false,
    }

func _refresh_presentation() -> void:
    if status_label == null:
        return
    status_label.text = "FIRST WAKE / AUREATE WAKE — LOCAL 2D FLIGHT & WATER REVIEW"
    var line := "STAGE: " + phase.to_upper()
    if opening != null:
        line += "  |  STORY PARTY: " + " + ".join(opening.active_party_ids).to_upper()
    telemetry_label.text = line
    inspection_label.visible = postflight_dialogue_open
    if postflight_dialogue_open:
        inspection_label.text = str(POSTFLIGHT_INSPECTION_LINES[postflight_dialogue_cursor])
    else:
        inspection_label.text = ""
    match phase:
        "awaiting_launch":
            hint_label.text = "E: launch one short test flight. Ionia at helm; Ender at engineering."
        "ascent":
            hint_label.text = "First lift after a year grounded. Watch the ship rise."
        "warning":
            hint_label.text = "Phase drift / containment strain / depleted reserve observed. E: controlled sea descent."
        "descent":
            hint_label.text = "Ionia selects open water. Physics water contact and flotation are being measured."
        "waterborne":
            if postflight_dialogue_open:
                hint_label.text = "E: examine the next diagnosis note (%d / %d). Hypothesis not yet established." % [postflight_dialogue_cursor + 1, POSTFLIGHT_INSPECTION_LINES.size()]
            else:
                hint_label.text = "WATERBORNE: crew safe afloat. E: inspect depleted fuel reserve and compare readings."
        "postflight_diagnosis":
            hint_label.text = "POSTFLIGHT: empty reserve observed. Fuel composition/source UNKNOWN. Safe reunion route OPEN."
        _:
            hint_label.text = "Preflight scene required."
    queue_redraw()
