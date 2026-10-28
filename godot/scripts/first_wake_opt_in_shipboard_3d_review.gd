extends Node
## Isolated, playable G3-candidate handoff: first-wake 2D → review-only 3D → 2D.
## NOT used by project.godot main_scene, production save or canonical chapter.
const FirstWakeScene = preload("res://scenes/first_wake_job_preview.tscn")
const ShipScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const ZoneCamera = preload("res://scripts/first_wake_3d_zone_camera_review.gd")
const CrewMotion = preload("res://scripts/first_wake_3d_crew_motion_proxy.gd")
const MaritimeAtmosphere = preload("res://scripts/first_wake_maritime_atmosphere_review.gd")
const REVIEW_ID := "tstss.first-wake.3d-ship-walk.review.v1"
const REVIEW_PRODUCTION_READY: bool = false
const HELM_CONSOLE_INTERACT_RANGE_M: float = 1.55
const RECOGNIZED_STEPS := ["engineering", "preflight"]
var chapter: Node2D
var ship: Node3D
var three_d_review_active: bool = false
var zone_camera: Node3D
var motion_visual: Node3D
var maritime_atmosphere: Node3D
var review_observations: int = 0
var review_label: Label
var instruction_label: Label
var helm_feedback: PanelContainer
var helm_feedback_heading: Label
var helm_feedback_body: Label
var last_review_message: String = ""
var _eligibility_last: bool = false

func _ready() -> void:
    chapter = FirstWakeScene.instantiate()
    chapter.name = "ExistingFirstWake2D"
    add_child(chapter)

    ship = ShipScene.instantiate()
    ship.name = "OptionalAureateWake3D"
    add_child(ship)
    # Both are actually instantiated Godot scenes, not screenshots. Only one
    # can consume movement/input at a time. No new save state exists.
    ship.visible = false
    ship.process_mode = Node.PROCESS_MODE_DISABLED
    ship.crew_walker.manual_controls_enabled = false
    ship.get_node("MetricShipStudyCamera").current = false
    zone_camera = ZoneCamera.new()
    zone_camera.actor = ship.crew_walker
    ship.add_child(zone_camera)
    maritime_atmosphere = MaritimeAtmosphere.new()
    ship.add_child(maritime_atmosphere)
    # The original inherited BG_COLOR WorldEnvironment stays as a nonactive
    # asset reference; a single sky environment is enabled in this wrapper.
    ship.get_node("MetricShipEnvironment").environment = null
    motion_visual = CrewMotion.new()
    ship.crew_walker.add_child(motion_visual)
    # The original anonymous whole-body capsule remains the physical collider.
    # Only its old mesh is visually replaced in this optional review scene.
    ship.crew_walker.get_node("AnonymousCrewBodyVisual").visible = false
    ship.crew_walker.get_node("FacingMarker").visible = false
    _set_chapter_present(true)

    var overlay := CanvasLayer.new()
    overlay.name = "BridgeReviewHelpOverlay"
    add_child(overlay)
    review_label = Label.new()
    review_label.name = "PreviewStatusLabel"
    review_label.position = Vector2(25, 148)
    review_label.add_theme_font_size_override("font_size", 16)
    review_label.add_theme_color_override(
        "font_color", Color(1.0, 0.92, 0.74))
    review_label.add_theme_color_override(
        "font_shadow_color", Color(0.04, 0.07, 0.11))
    review_label.add_theme_constant_override("shadow_offset_x", 2)
    review_label.add_theme_constant_override("shadow_offset_y", 2)
    overlay.add_child(review_label)
    instruction_label = Label.new()
    instruction_label.name = "ReviewInstructionLabel"
    instruction_label.position = Vector2(22, 593)
    instruction_label.add_theme_font_size_override("font_size", 14)
    instruction_label.add_theme_color_override(
        "font_color", Color(0.95, 0.89, 0.73))
    overlay.add_child(instruction_label)
    _build_readonly_helm_feedback(overlay)
    _refresh_ui()

func review_eligible() -> bool:
    if chapter == null or chapter.dialogue_open:
        return false
    return chapter.room == "engineering" and (
        chapter.opening.step_key() in RECOGNIZED_STEPS) and (
        chapter.opening.active_party_ids == ["ender", "ionia"])

func _build_readonly_helm_feedback(overlay: CanvasLayer) -> void:
    helm_feedback = PanelContainer.new()
    helm_feedback.name = "AccessibleReviewStatusPanel"
    helm_feedback.position = Vector2(608, 68)
    helm_feedback.custom_minimum_size = Vector2(324, 94)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.055, 0.10, 0.15, 0.94)
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.border_color = Color(0.68, 0.55, 0.35)
    panel_style.content_margin_left = 12
    panel_style.content_margin_top = 10
    panel_style.content_margin_right = 12
    panel_style.content_margin_bottom = 9
    helm_feedback.add_theme_stylebox_override("panel", panel_style)
    overlay.add_child(helm_feedback)
    var stack := VBoxContainer.new()
    helm_feedback.add_child(stack)
    helm_feedback_heading = Label.new()
    helm_feedback_heading.name = "Title"
    helm_feedback_heading.text = "SHIPBOARD REVIEW / READ-ONLY"
    helm_feedback_heading.add_theme_font_size_override("font_size", 13)
    helm_feedback_heading.add_theme_color_override(
        "font_color", Color(0.91, 0.73, 0.48))
    stack.add_child(helm_feedback_heading)
    helm_feedback_body = Label.new()
    helm_feedback_body.name = "Notice"
    helm_feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    helm_feedback_body.custom_minimum_size = Vector2(292, 45)
    helm_feedback_body.add_theme_font_size_override("font_size", 14)
    helm_feedback_body.add_theme_color_override(
        "font_color", Color(0.95, 0.94, 0.86))
    stack.add_child(helm_feedback_body)

func _set_chapter_present(enabled: bool) -> void:
    chapter.visible = enabled
    # CanvasLayer visibility is independent of its Node2D parent's visible.
    # Without this, 2D First Wake dialogue/objective would cover the 3D view.
    chapter.get_node("ReadableGameplayOverlay").visible = enabled
    chapter.process_mode = (
        Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED)

func request_3d_ship_review(enabled: bool) -> bool:
    if enabled:
        # No 'armed' state: a premature B cannot auto-open once hired later.
        if three_d_review_active:
            return true
        if not review_eligible():
            return false
        three_d_review_active = true
        _set_chapter_present(false)
        ship.visible = true
        ship.process_mode = Node.PROCESS_MODE_INHERIT
        ship.crew_walker.manual_controls_enabled = true
        ship.set_crew_follow_camera(false)
        zone_camera.set_active(true)
        last_review_message = "Ordinary bridge walkthrough only. No flight controls."
        _refresh_ui()
        return true
    if not three_d_review_active:
        return false
    three_d_review_active = false
    ship.crew_walker.manual_controls_enabled = false
    zone_camera.set_active(false)
    ship.set_crew_follow_camera(false)
    ship.visible = false
    ship.process_mode = Node.PROCESS_MODE_DISABLED
    _set_chapter_present(true)
    last_review_message = "Returned to the existing Chapter I engineering preview."
    _refresh_ui()
    return true

func inspect_review_helm() -> bool:
    if not three_d_review_active:
        return false
    var actor: CharacterBody3D = ship.crew_walker
    if not actor.is_on_floor():
        return false
    var console: MeshInstance3D = ship.get_node("HelmNavigationConsole")
    var horizontal: float = Vector2(
        actor.global_position.x - console.global_position.x,
        actor.global_position.z - console.global_position.z).length()
    if horizontal > HELM_CONSOLE_INTERACT_RANGE_M:
        return false
    review_observations += 1
    last_review_message = (
        "HELM STUDY: Navigation station visible. Calibration and flight are unverified.")
    _refresh_ui()
    return true

func cycle_glass_review() -> bool:
    if not three_d_review_active:
        return false
    var modes := ["metric_proxy", "source_clear", "source_low_glare"]
    var current: int = modes.find(ship.glass_review_profile)
    var next: String = modes[(current + 1) % modes.size()]
    if not ship.set_glass_art_review(next):
        return false
    last_review_message = "Visual-only geodesic glass review: " + next
    _refresh_ui()
    return true

func cycle_camera_review() -> bool:
    if not three_d_review_active:
        return false
    zone_camera.cycle_shot()
    last_review_message = "Camera framing: " + (
        "elevated" if zone_camera.shot == 1 else "follow")
    _refresh_ui()
    return true

func transient_review_contract() -> Dictionary:
    return {
        "schema": REVIEW_ID,
        "active": three_d_review_active,
        "eligible": review_eligible(),
        "review_only": true,
        "saved_in_chapter1": false,
        "party_grant": false,
        "flight_controls_enabled": false,
        "story_progression_enabled": false,
        "ship_space_production_ready": REVIEW_PRODUCTION_READY
    }

func _process(delta: float) -> void:
    if three_d_review_active:
        zone_camera.update_view(delta)
    else:
        var eligible: bool = review_eligible()
        if eligible != _eligibility_last:
            _eligibility_last = eligible
            _refresh_ui()

func _refresh_ui() -> void:
    if review_label == null or instruction_label == null:
        return
    helm_feedback.visible = three_d_review_active and (
        last_review_message != "")
    if helm_feedback.visible:
        helm_feedback_body.text = last_review_message
    if three_d_review_active:
        review_label.position = Vector2(24, 24)
        review_label.text = "AUREATE WAKE / ORDINARY SHIP WALKTHROUGH — STUDY ONLY"
        instruction_label.text = (
            "WASD / ARROWS: walk    E: hatch    F: helm    G: glass    C: camera    M: still sea    N: sky    B: return")
        instruction_label.visible = true
    else:
        review_label.position = Vector2(24, 148)
        review_label.text = (
            "B: inspect an optional 3D shipboard prototype"
            if review_eligible() else "")
        instruction_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_B:
        if request_3d_ship_review(not three_d_review_active):
            get_viewport().set_input_as_handled()
    elif three_d_review_active and event.keycode == KEY_F:
        if inspect_review_helm():
            get_viewport().set_input_as_handled()
    elif three_d_review_active and event.keycode == KEY_G:
        if cycle_glass_review():
            get_viewport().set_input_as_handled()
    elif three_d_review_active and event.keycode == KEY_N:
        maritime_atmosphere.set_twilight_review(not maritime_atmosphere.twilight_review)
        last_review_message = "Sky study: " + ("twilight" if maritime_atmosphere.twilight_review else "daylight")
        _refresh_ui()
        get_viewport().set_input_as_handled()
    elif three_d_review_active and event.keycode == KEY_M:
        maritime_atmosphere.set_reduced_motion(not maritime_atmosphere.reduced_motion)
        last_review_message = "Ocean animation: " + ("reduced" if maritime_atmosphere.reduced_motion else "normal")
        _refresh_ui()
        get_viewport().set_input_as_handled()
    elif three_d_review_active and event.keycode == KEY_C:
        if cycle_camera_review():
            get_viewport().set_input_as_handled()
