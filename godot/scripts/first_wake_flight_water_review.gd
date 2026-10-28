extends Node2D
## Bounded Chapter I first-flight/ocean-splashdown review, not production flight.
## RigidBody2D + Area2D report actual 2D physics contact; buoyancy is an
## intentionally simplified LOCAL test. No planet/ocean route or save admission.
## Requires the creator-directed Ionia-first preflight contract from the job scene.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const FamilyScene = preload("res://scenes/first_wake_postflight_family_review.tscn")

const SURFACE_Y := 410.0
const FLOAT_BUOYANCY := 120.0
const SETTLE_SECONDS := 0.45
const ASCENT_SECONDS := 1.25
# Local towing/berthing prototype geometry, NOT established geography,
# rescue method, shipping lanes or powered levitation propulsion.
const BERTH_CENTER := Vector2(817.0, SURFACE_Y - 14.0)
const BERTH_SENSOR_SIZE := Vector2(112.0, 78.0)
const RECOVERY_PULL_SPEED := 58.0
const BERTH_STABLE_SPEED := 6.0
const BERTH_STABLE_SECONDS := 0.35

var opening
var phase: String = "not_configured"
var elapsed: float = 0.0
var settled_seconds: float = 0.0
var contact_observed: bool = false
var stable_float_verified: bool = false
var reserve_inspection_observed: bool = false
var recovery_request_recorded: bool = false
var berth_contact_observed: bool = false
var berth_stable_verified: bool = false
var berth_stable_seconds: float = 0.0
var berth_area: Area2D
var safe_berth_confirmed_review: bool = false
var family_review: Node2D
var flight_overlay: CanvasLayer
var ship_body: RigidBody2D
var sea_area: Area2D
var status_label: Label
var hint_label: Label
var telemetry_label: Label

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

    berth_area = Area2D.new()
    berth_area.name = "LocalReviewBerthContactSensor"
    berth_area.monitoring = true
    berth_area.collision_layer = 0
    berth_area.collision_mask = 1
    berth_area.position = BERTH_CENTER
    var berth_shape := CollisionShape2D.new()
    var berth_rectangle := RectangleShape2D.new()
    berth_rectangle.size = BERTH_SENSOR_SIZE
    berth_shape.shape = berth_rectangle
    berth_area.add_child(berth_shape)
    add_child(berth_area)
    berth_area.body_entered.connect(_on_berth_body_entered)

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

    flight_overlay = CanvasLayer.new()
    var ui := flight_overlay
    ui.name = "FlightReviewOverlay"
    add_child(ui)
    status_label = _make_label(ui, Vector2(24, 20), 19)
    telemetry_label = _make_label(ui, Vector2(24, 59), 15)
    hint_label = _make_label(ui, Vector2(26, 563), 17)
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
    if phase in ["recovery_approach", "berth_contact", "berth_securing", "berth_ready"]:
        draw_rect(Rect2(864, SURFACE_Y - 4, 96, 134), Color("#806d57"))
        for y in [423.0, 452.0, 481.0, 510.0]:
            draw_line(Vector2(866, y), Vector2(960, y), Color("#bea281"), 2.0)
        draw_line(Vector2(798, SURFACE_Y - 57), Vector2(798, SURFACE_Y + 15), Color("#e0c58c"), 3.0)
        draw_circle(Vector2(798, SURFACE_Y - 58), 8, Color("#b5e6d2"))
        draw_string(ThemeDB.fallback_font, Vector2(656, 319), "PROVISIONAL BERTH / 2D REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 296, 14, Color("#f4e4c4"))

func _unhandled_input(event: InputEvent) -> void:
    if family_review != null:
        return
    if event.is_action_pressed(InputPolicy.INTERACT) and not event.is_echo():
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if phase == "awaiting_launch":
        return begin_short_test_flight()
    if phase == "warning":
        return stabilize_for_water_descent()
    if phase == "waterborne":
        return inspect_empty_reserve_after_splashdown()
    if phase == "postflight_diagnosis":
        return request_safe_recovery_review()
    if phase == "berth_contact":
        return secure_berth_lines_review()
    if phase == "berth_ready":
        return acknowledge_safe_berth_and_open_family_review()
    return false

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

func inspect_empty_reserve_after_splashdown() -> bool:
    # Only after measured local water contact and a sustained stable float.
    # The depleted reserve is an authored *inspection* for this review, not a
    # simulated fuel fluid or approved inventory system.
    if phase != "waterborne" or not contact_observed or not stable_float_verified:
        return false
    if opening == null or opening.step_key() != "waterborne":
        return false
    if opening.active_party_ids != ["ender", "ionia"]:
        return false
    if not opening.inspect_postflight_reserve(true):
        return false
    reserve_inspection_observed = true
    phase = "postflight_diagnosis"
    _refresh_presentation()
    return true

func request_safe_recovery_review() -> bool:
    # Stage the crew's practical decision first. No ferry, tow distance,
    # geography, rescue craft or time-of-travel has been simulated here.
    if phase != "postflight_diagnosis" or not reserve_inspection_observed:
        return false
    if not contact_observed or not stable_float_verified:
        return false
    if opening.step_key() != "postflight_diagnosis" or opening.active_party_ids != ["ender", "ionia"]:
        return false
    recovery_request_recorded = true
    # The ship has already been physically proven to float. This toy force
    # models external recovery assistance only; engines remain offline.
    ship_body.freeze = false
    ship_body.gravity_scale = 0.0
    ship_body.linear_damp = 0.0
    ship_body.linear_velocity = Vector2(RECOVERY_PULL_SPEED, 0.0)
    phase = "recovery_approach"
    _refresh_presentation()
    return true

func secure_berth_lines_review() -> bool:
    # No silent staging: E is accepted only after a real physics overlap
    # with the independent berth sensor. Safe mooring takes several frames.
    if phase != "berth_contact" or not berth_contact_observed:
        return false
    if berth_area == null or ship_body == null or not berth_area.overlaps_body(ship_body):
        return false
    if opening.step_key() != "postflight_diagnosis":
        return false
    if opening.active_party_ids != ["ender", "ionia"]:
        return false
    berth_stable_seconds = 0.0
    ship_body.linear_damp = 12.0
    phase = "berth_securing"
    _refresh_presentation()
    return true

func acknowledge_safe_berth_and_open_family_review() -> bool:
    # A real LOCAL spatial arrival and stable speed must precede family
    # staging; still not proof of a world-scale voyage or approved harbor.
    if phase != "berth_ready" or not recovery_request_recorded:
        return false
    if not berth_contact_observed or not berth_stable_verified:
        return false
    if berth_area == null or ship_body == null or not berth_area.overlaps_body(ship_body):
        return false
    if ship_body.linear_velocity.length() > BERTH_STABLE_SPEED:
        return false
    if berth_stable_seconds < BERTH_STABLE_SECONDS:
        return false
    if not contact_observed or not stable_float_verified or not reserve_inspection_observed:
        return false
    if family_review != null:
        return false
    if opening.step_key() != "postflight_diagnosis" or opening.active_party_ids != ["ender", "ionia"]:
        return false
    var preview := FamilyScene.instantiate()
    if not bool(preview.call("configure_after_safe_review", opening, contact_observed, stable_float_verified, reserve_inspection_observed, true)):
        preview.free()
        return false
    safe_berth_confirmed_review = true
    family_review = preview
    phase = "family_review"
    ship_body.freeze = true
    ship_body.visible = false
    sea_area.monitoring = false
    flight_overlay.visible = false
    add_child(family_review)
    queue_redraw()
    return true

func _physics_process(delta: float) -> void:
    if ship_body == null:
        return
    if phase == "recovery_approach":
        # A bounded *review* pull along the waterline; do not revive the
        # failed levitation engine or grant the ship new propulsion.
        ship_body.linear_velocity = Vector2(RECOVERY_PULL_SPEED, 0.0)
        if ship_body.position.x > 950.0:
            ship_body.linear_velocity = Vector2.ZERO
            ship_body.freeze = true
            phase = "recovery_out_of_bounds"
            _refresh_presentation()
    elif phase == "berth_securing":
        if berth_area.overlaps_body(ship_body) and ship_body.linear_velocity.length() <= BERTH_STABLE_SPEED:
            berth_stable_seconds += delta
        else:
            berth_stable_seconds = 0.0
        if berth_stable_seconds >= BERTH_STABLE_SECONDS:
            berth_stable_verified = true
            ship_body.linear_velocity = Vector2.ZERO
            ship_body.freeze = true
            phase = "berth_ready"
            _refresh_presentation()
    elif phase == "ascent":
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

func _on_berth_body_entered(body: Node2D) -> void:
    if body != ship_body or phase != "recovery_approach":
        return
    berth_contact_observed = true
    # Assist speed tapers near the berth, independent of player reaction time.
    ship_body.linear_damp = 12.0
    phase = "berth_contact"
    _refresh_presentation()

func review_snapshot() -> Dictionary:
    return {
        "phase": phase,
        "party": opening.active_party_ids.duplicate() if opening != null else [],
        "story_step": opening.step_key() if opening != null else "unconfigured",
        "actual_2d_area_contact_observed": contact_observed,
        "stable_buoyant_hull_observed": stable_float_verified,
        "reserve_inspection_observed": reserve_inspection_observed,
        "recovery_request_recorded": recovery_request_recorded,
        "berth_sensor_contact_observed": berth_contact_observed,
        "berth_stable_verified": berth_stable_verified,
        "berth_stable_seconds": berth_stable_seconds,
        "local_2d_berth_approach_verified": berth_contact_observed and berth_stable_verified,
        "approved_shoreline_or_tow_method": false,
        "safe_berth_confirmed_review": safe_berth_confirmed_review,
        "family_review_active": family_review != null,
        "real_recovery_route_verified": false,
        "real_inventory_scan_verified": false,
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
            hint_label.text = "WATERBORNE: hull safely afloat, engines offline. E: inspect the depleted fuel reserve."
        "postflight_diagnosis":
            hint_label.text = "RESERVE EMPTY: E to request safe recovery. Actual route and location still unassigned."
        "recovery_approach":
            hint_label.text = "ASSISTED SURFACE RECOVERY REVIEW: hull moves through local 2D water. Engines stay offline."
        "berth_contact":
            hint_label.text = "LOCAL BERTH SENSOR CONTACT: E to secure lines; do not rush family boarding."
        "berth_securing":
            hint_label.text = "Securing berth: hold the hull stable until the speed/overlap test passes."
        "berth_ready":
            hint_label.text = "LOCAL BERTH STABLE (NOT WORLD GEOGRAPHY): E to open safe family meeting."
        "recovery_out_of_bounds":
            hint_label.text = "Recovery overshot this 2D review corridor. No family access. Restart the review."
        "family_review":
            hint_label.text = "Safe-berth family review opened. Arrival location remains unassigned."
        _:
            hint_label.text = "Preflight scene required."
    queue_redraw()
