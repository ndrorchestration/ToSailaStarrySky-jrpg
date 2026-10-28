extends Node2D
## Bounded Chapter I first-flight/ocean-splashdown review, not production flight.
## RigidBody2D + Area2D report actual 2D physics contact; buoyancy is an
## intentionally simplified LOCAL test. No planet/ocean route or save admission.
## Requires the creator-directed Ionia-first preflight contract from the job scene.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const FamilyScene = preload("res://scenes/first_wake_postflight_family_review.tscn")
const AureateWakeVisual = preload("res://scripts/first_wake_aureate_wake_visual_review.gd")
const TidalSurfaceShader = preload("res://shaders/first_wake_tidal_surface_review.gdshader")

const SURFACE_Y := 410.0
const FLOAT_BUOYANCY := 120.0
const SETTLE_SECONDS := 0.45
const ASCENT_SECONDS := 1.25
# Local towing/berthing prototype geometry, NOT established geography,
# rescue method, shipping lanes or powered levitation propulsion.
const BERTH_CENTER := Vector2(891.0, SURFACE_Y - 14.0)
const BERTH_SENSOR_SIZE := Vector2(42.0, 78.0)
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
var ship_visual_rig: Node2D
var tidal_surface_visual: ColorRect
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

    # Screen-space animated water material behind the physical vessel.
    # The actual water-contact sensor and buoyancy math above remain separate.
    tidal_surface_visual = ColorRect.new()
    tidal_surface_visual.name = "LayeredTidalSurfaceVisualReview"
    tidal_surface_visual.position = Vector2(0, SURFACE_Y)
    tidal_surface_visual.size = Vector2(960, 640.0 - SURFACE_Y)
    tidal_surface_visual.color = Color.WHITE
    tidal_surface_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var water_material := ShaderMaterial.new()
    water_material.shader = TidalSurfaceShader
    tidal_surface_visual.material = water_material
    add_child(tidal_surface_visual)

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
    # A hand-layered, purely decorative Aureate Wake profile is attached
    # to the *same* original RigidBody2D and its unmodified 144x34 collider.
    # No scene logic or flight/water authority is moved into the art node.
    ship_visual_rig = AureateWakeVisual.new()
    ship_visual_rig.name = "AureateWakeGeodesicBridgeVisualReview"
    ship_body.add_child(ship_visual_rig)
    add_child(ship_body)

    flight_overlay = CanvasLayer.new()
    var ui := flight_overlay
    ui.name = "FlightReviewOverlay"
    add_child(ui)
    # UI panels must render over the dedicated sea CanvasItem, including
    # at the bottom of the 960x640 viewport. These are readability surfaces.
    for panel_rect in [
        Rect2(0, 0, 960, 103),
        Rect2(0, 545, 960, 95),
    ]:
        var panel := ColorRect.new()
        panel.name = "TelemetryContrastPanel"
        panel.position = panel_rect.position
        panel.size = panel_rect.size
        panel.color = Color(0.035, 0.065, 0.13, 0.92)
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ui.add_child(panel)
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
    # One compositional sky plane, long-distance cloud bands and low sun.
    # Review-layer artistry only: no clock/weather/save/celestial authority.
    for index in range(61):
        var t := float(index) / 60.0
        var tone := Color("#142d46").lerp(Color("#d2a778"), t * t)
        draw_rect(Rect2(0, float(index) * 7.0, 960, 8), tone)
    # Broad, low-contrast overlapping halo layers avoid conspicuous
    # concentric disks while preserving a warm celestial focal point.
    for halo in range(20, 0, -1):
        var radius := 35.0 + float(halo) * 5.0
        var alpha := 0.003 + float(20 - halo) * 0.0007
        draw_circle(Vector2(754, 184), radius, Color(0.98, 0.84, 0.66, alpha))
    draw_circle(Vector2(754, 184), 30.0, Color("#ffe3b1"))
    draw_circle(Vector2(754, 184), 24.0, Color("#fff0c9"))
    # Broken wisps and thin, depth-ordered strata instead of rounded circles.
    # This is artwork-layer fog, not a simulated weather or cloud system.
    for index in range(7):
        var x := float(index) * 171.0 - 130.0
        var y := 206.0 + float(index % 3) * 21.0
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 34, y + 11), Vector2(x - 8, y + 2),
            Vector2(x + 11, y - 5), Vector2(x + 32, y + 3),
            Vector2(x + 59, y + 6), Vector2(x + 86, y + 13),
            Vector2(x + 112, y + 18), Vector2(x + 83, y + 22),
            Vector2(x + 22, y + 20), Vector2(x - 31, y + 16),
        ]), Color(0.77, 0.85, 0.83, 0.055))
        draw_line(Vector2(x - 3, y + 7), Vector2(x + 74, y + 11), Color(0.91, 0.89, 0.80, 0.075), 1.3)
    for index in range(4):
        var y := 285.0 + float(index) * 12.0
        draw_line(Vector2(0, y), Vector2(960, y - 5), Color(0.94, 0.85, 0.70, 0.035), 2.0)
    # Three depth-separated coastal silhouettes are authored screen-space art.
    # They never affect the water sensor, berth region or collision geometry.
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 372), Vector2(75, 363), Vector2(140, 368),
        Vector2(223, 355), Vector2(307, 367), Vector2(388, 357),
        Vector2(492, 365), Vector2(581, 352), Vector2(680, 361),
        Vector2(755, 349), Vector2(857, 357), Vector2(960, 344),
        Vector2(960, SURFACE_Y), Vector2(0, SURFACE_Y),
    ]), Color("#82928c"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 391), Vector2(61, 376), Vector2(119, 383),
        Vector2(195, 369), Vector2(280, 382), Vector2(350, 371),
        Vector2(445, 386), Vector2(536, 369), Vector2(620, 382),
        Vector2(714, 368), Vector2(801, 377), Vector2(895, 362),
        Vector2(960, 370), Vector2(960, SURFACE_Y), Vector2(0, SURFACE_Y),
    ]), Color("#526f72"))
    # Distant quay roofs and intermittent headland lanterns remain silhouettes:
    # scenic architecture only; there are no enterable buildings here.
    for index in range(9):
        var cx := 37.0 + float(index) * 118.0
        var roof_y := 379.0 - float(index % 3) * 5.0
        draw_colored_polygon(PackedVector2Array([
            Vector2(cx - 23, roof_y + 11), Vector2(cx - 19, roof_y),
            Vector2(cx, roof_y - 8), Vector2(cx + 20, roof_y),
            Vector2(cx + 24, roof_y + 11),
        ]), Color("#304d58"))
        draw_rect(Rect2(cx - 17, roof_y + 10, 34, 16), Color("#35535a"))
        draw_line(Vector2(cx - 20, roof_y + 1), Vector2(cx, roof_y - 8), Color("#a28f78", 0.6), 1.0)
        draw_rect(Rect2(cx + 7, roof_y + 13, 3, 4), Color("#e7c68e", 0.6))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 403), Vector2(83, 394), Vector2(156, 400),
        Vector2(237, 391), Vector2(335, 402), Vector2(432, 390),
        Vector2(533, 402), Vector2(623, 389), Vector2(733, 399),
        Vector2(832, 390), Vector2(960, 397),
        Vector2(960, SURFACE_Y), Vector2(0, SURFACE_Y),
    ]), Color("#304f60"))
    for index in range(24):
        var glint_x := float(index) * 43.0 + 8.0
        var glint_y := 400.0 + float(index % 4) * 2.0
        draw_line(Vector2(glint_x, glint_y), Vector2(glint_x + 12.0, glint_y), Color(0.83, 0.84, 0.70, 0.12), 1.0)
    draw_line(Vector2(0, SURFACE_Y), Vector2(960, SURFACE_Y), Color("#b9d4c5"), 2.0)
    if phase in ["recovery_approach", "berth_contact", "berth_securing", "berth_ready"]:
        draw_rect(Rect2(864, SURFACE_Y - 4, 96, 134), Color("#806d57"))
        for y in [423.0, 452.0, 481.0, 510.0]:
            draw_line(Vector2(866, y), Vector2(960, y), Color("#bea281"), 2.0)
        draw_line(Vector2(854, SURFACE_Y - 57), Vector2(854, SURFACE_Y + 15), Color("#e0c58c"), 3.0)
        draw_circle(Vector2(854, SURFACE_Y - 58), 8, Color("#b5e6d2") if berth_contact_observed else Color("#e8bc7f"))
        if phase in ["berth_securing", "berth_ready"]:
            # The line is visible only after the player explicitly secures it.
            var bow := ship_body.position + Vector2(70.0, -6.0)
            draw_line(bow, Vector2(864.0, SURFACE_Y - 28.0), Color("#dfd0a8"), 2.5)
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
    if ship_visual_rig != null:
        ship_visual_rig.set_visual_phase(phase)
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
