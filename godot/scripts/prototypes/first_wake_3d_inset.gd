extends Control
## Genuine in-engine 3D visual layer in the playable 2D Chapter I review scene.
## The original noncanonical Aureate Wake ship mesh is source-ported verbatim
## from the independent native flight study (PR #486, 36a13d6).
## Presentation-only: never owns physics, action handling, story, or saves.
const Ship = preload("res://scripts/prototypes/aureate_wake_source_ship_3d.gd")
const WarningLens = preload("res://scripts/first_wake_engine_warning_vfx.gd")
const SHOTS = {
    "bow-quarter": Vector3(6.5, 3.0, -7.0),
    "stern-quarter": Vector3(-7.0, 2.8, 7.0),
    "wing-planform": Vector3(2.5, 10.5, 2.0),
}
const SIZE := Vector2i(355, 200)
const WIDE_SIZE := Vector2i(960, 442)
const SEA_Y := -0.89
const BODY_SCALE_Y := 0.035

var viewport: SubViewport
var viewport_container: SubViewportContainer
var ship_model
var shot_camera: Camera3D
var key_light: DirectionalLight3D
var environment_node: WorldEnvironment
var last_camera_shot: String = ""
var last_phase: String = ""
var last_grade: String = ""
var use_reduced_motion: bool = false
var use_low_detail: bool = false
var scene_clock: float = 0.0
var presentation_updates: int = 0
var label: Label
var wide_stage_enabled: bool = false
var physical_body_y: float = 255.0
var visual_altitude_above_waterline: float = 0.0
var physically_stable: bool = false
var warning_visual
var warning_enabled: bool = true
var warning_interrupted: bool = false
var warning_admitted: bool = false
var warning_admission_count: int = 0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(355, 227)
    var border := ColorRect.new()
    border.color = Color("#152c3b")
    border.size = size
    border.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(border)

    viewport_container = SubViewportContainer.new()
    viewport_container.name = "NativeFlightFrame"
    viewport_container.position = Vector2.ZERO
    viewport_container.size = Vector2(SIZE)
    viewport_container.stretch = true
    viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(viewport_container)

    viewport = SubViewport.new()
    viewport.name = "RenderedShip3D"
    viewport.size = SIZE
    viewport.own_world_3d = true
    viewport.transparent_bg = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_container.add_child(viewport)

    var stage := Node3D.new()
    stage.name = "IndependentVisualStageOnly"
    viewport.add_child(stage)
    environment_node = WorldEnvironment.new()
    environment_node.name = "NoncanonicalLocalLight"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#7c92a7")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#a4b4bf")
    env.ambient_light_energy = 0.70
    environment_node.environment = env
    stage.add_child(environment_node)

    key_light = DirectionalLight3D.new()
    key_light.name = "SmallSceneKey"
    key_light.rotation_degrees = Vector3(-46, -27, 0)
    key_light.light_color = Color("#f7d7a2")
    key_light.light_energy = 1.4
    key_light.shadow_enabled = false
    stage.add_child(key_light)

    var sea := MeshInstance3D.new()
    sea.name = "VisualWaterOnly_NoPhysics"
    var sea_mesh := PlaneMesh.new()
    sea_mesh.size = Vector2(400, 400)
    sea.mesh = sea_mesh
    var ocean := StandardMaterial3D.new()
    ocean.albedo_color = Color("#245d72")
    ocean.metallic = 0.06
    ocean.roughness = 0.48
    sea.material_override = ocean
    sea.position.y = -0.89
    stage.add_child(sea)

    ship_model = Ship.new()
    ship_model.name = "AureateWakeOriginalVisualMesh"
    stage.add_child(ship_model)

    shot_camera = Camera3D.new()
    shot_camera.name = "VisualShotCamera"
    shot_camera.fov = 47.0
    shot_camera.current = true
    stage.add_child(shot_camera)
    shot_camera.position = SHOTS["bow-quarter"]
    shot_camera.look_at(Vector3(0, 0.2, 0), Vector3.UP)

    label = Label.new()
    label.name = "VisualStudyCaption"
    label.position = Vector2(7, 202)
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color("#fff0cd"))
    label.text = "3D SHIP STUDY  /  PHYSICS REMAINS 2D"
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)

    # Original PW-01 CanvasItem warning renders ABOVE the genuine 3D ship view.
    # Never on the hidden 2D collision body and never in the 3D physics world.
    warning_visual = WarningLens.new()
    add_child(warning_visual)
    warning_visual.configure(true, 0)
    _place_warning_visual()

func set_wide_stage_enabled(enabled: bool) -> bool:
    if viewport == null or viewport_container == null or ship_model == null:
        return false
    wide_stage_enabled = enabled
    var extent: Vector2i = WIDE_SIZE if enabled else SIZE
    viewport.size = extent
    viewport_container.size = Vector2(extent)
    size = Vector2(extent) + Vector2(0, 25)
    var border: ColorRect = get_child(0) as ColorRect
    border.size = size
    label.position = Vector2(10, float(extent.y) + 2.0)
    if enabled:
        label.text = "3D SHIP REVIEW | CONTACT CONTROLLED BY 2D SENSOR"
    else:
        label.text = "3D SHIP STUDY  /  PHYSICS REMAINS 2D"
    if not enabled:
        ship_model.position = Vector3.ZERO
        visual_altitude_above_waterline = 0.0
    _reframe()
    _place_warning_visual()
    return true

func sync_physical_waterline(body_y: float, water_y: float,
        body_stable: bool) -> bool:
    # The 2D Rigidbody is authoritative; the 3D ship only READS its height.
    # Sea and hull cannot grant physics contact or approve a state transition.
    if not is_finite(body_y) or not is_finite(water_y):
        return false
    physical_body_y = body_y
    physically_stable = body_stable
    if not wide_stage_enabled or ship_model == null:
        return false
    visual_altitude_above_waterline = (water_y - 14.0 - body_y) * BODY_SCALE_Y
    ship_model.position.y = visual_altitude_above_waterline
    _reframe()
    return true

func _reframe() -> void:
    if shot_camera == null or ship_model == null:
        return
    var shot: String = last_camera_shot if SHOTS.has(last_camera_shot) else "bow-quarter"
    shot_camera.position = ship_model.position + SHOTS[shot]
    shot_camera.look_at(ship_model.position + Vector3(0.0, 0.2, 0.0), Vector3.UP)

func set_visual_intent(plan: Dictionary) -> bool:
    if not bool(plan.get("admitted_for_review", false)):
        return false
    if bool(plan.get("executes_visuals", true)) or bool(plan.get("blocks_progression", true)):
        # The *descriptor* remains read-only. This viewport executes only
        # its own visual stage; no authority is gained by attaching a camera.
        return false
    if int(plan.get("visual_source_pr", -1)) != 486:
        return false
    var shot: String = str(plan.get("camera_shot_id", ""))
    var grade: String = str(plan.get("visual_grade_id", ""))
    if not SHOTS.has(shot) or grade not in ["golden-clear", "storm-night-study"]:
        return false
    if ship_model == null or shot_camera == null or environment_node == null:
        return false
    use_reduced_motion = bool(plan.get("reduced_motion", false))
    use_low_detail = bool(plan.get("low_detail", false))
    last_camera_shot = shot
    last_phase = str(plan.get("scene_phase", ""))
    last_grade = grade
    _reframe()
    ship_model.set_motion(scene_clock, use_reduced_motion)
    # Review palette only: not a climate event, and cannot change physics.
    if grade == "storm-night-study":
        environment_node.environment.background_color = Color("#405065")
        environment_node.environment.ambient_light_color = Color("#637587")
        key_light.light_color = Color("#9caec0")
        key_light.light_energy = 0.83
    else:
        environment_node.environment.background_color = Color("#7c92a7")
        environment_node.environment.ambient_light_color = Color("#a4b4bf")
        key_light.light_color = Color("#f7d7a2")
        key_light.light_energy = 1.4
    _sync_warning_from_intent(plan)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    presentation_updates += 1
    return true

func _place_warning_visual() -> void:
    if warning_visual == null:
        return
    if wide_stage_enabled:
        warning_visual.position = Vector2(480.0, 221.0)
        warning_visual.scale = Vector2.ONE
    else:
        warning_visual.position = Vector2(177.5, 100.0)
        warning_visual.scale = Vector2(0.48, 0.48)

func _sync_warning_from_intent(plan: Dictionary) -> void:
    if warning_visual == null:
        return
    # Original actual Ionia-first story snapshot was validated by #492.
    # We permit only an authorised warning-stern, never a cinematic forged
    # waterborne or assumed specialist fuel / combat magic reveal.
    var admitted: bool = (
        plan.get("scene_phase", "") == "warning"
        and plan.get("camera_shot_id", "") == "stern-quarter"
        and plan.get("visual_grade_id", "") == "golden-clear"
        and not bool(plan.get("grants_combat_magic", true))
        and not bool(plan.get("modifies_story_state", true))
        and not bool(plan.get("changes_saves", true))
        and not bool(plan.get("production_ocean_verified", true))
    )
    if not admitted:
        warning_admitted = false
        warning_interrupted = false
        warning_visual.stop_warning()
        return
    if not warning_admitted:
        warning_admission_count += 1
    warning_admitted = true
    # Motion-safe default for engine phase distortion independently of the
    # existing ship's wing motion. No change to player motion policy.
    warning_visual.configure(true, 0 if use_low_detail else 1)
    if not warning_enabled or warning_interrupted:
        warning_visual.stop_warning()
    elif not warning_visual.active:
        warning_visual.begin_warning()

func set_warning_enabled(enabled: bool) -> void:
    warning_enabled = enabled
    if warning_visual == null:
        return
    if not enabled:
        warning_visual.stop_warning()
    elif warning_admitted and not warning_interrupted and not warning_visual.active:
        warning_visual.begin_warning()

func interrupt_warning_visual() -> bool:
    if not warning_admitted or warning_visual == null or not warning_visual.active:
        return false
    warning_interrupted = true
    warning_visual.stop_warning()
    return true

func advance_visual_clock(delta: float) -> void:
    if ship_model == null or use_reduced_motion:
        return
    scene_clock += maxf(0.0, delta)
    ship_model.set_motion(scene_clock, false)

func set_review_quality(reduced_motion: bool, low_detail: bool) -> void:
    use_reduced_motion = reduced_motion
    use_low_detail = low_detail
    if ship_model != null:
        ship_model.set_motion(scene_clock, use_reduced_motion)

func review_snapshot() -> Dictionary:
    return {
        "is_actual_native_3d_subviewport": viewport != null and ship_model != null,
        "source_visual_pr": 486,
        "camera_shot": last_camera_shot,
        "phase": last_phase,
        "visual_grade": last_grade,
        "reduced_motion": use_reduced_motion,
        "low_detail": use_low_detail,
        "ship_mesh_present": ship_model != null and ship_model.has_node("LongHull"),
        "visual_water_has_physics": false,
        "read_only": true,
        "ready_for_creator_art_approval": false,
        "original_study_weather_shaders_imported": false,
        "planet_or_production_ocean_rendered": false,
        "update_count": presentation_updates,
        "wide_stage_enabled": wide_stage_enabled,
        "inset_dimensions": viewport.size if viewport != null else Vector2i.ZERO,
        "physical_body_y": physical_body_y,
        "visual_altitude_above_waterline": visual_altitude_above_waterline,
        "physical_stable_for_review": physically_stable,
        "visual_ship_has_no_colliders": true,
        "engine_warning_overlay_is_canvas_only": warning_visual != null,
        "engine_warning_active": warning_visual.active if warning_visual != null else false,
        "engine_warning_visible": warning_visual.visible if warning_visual != null else false,
        "engine_warning_admitted": warning_admitted,
        "engine_warning_interrupted": warning_interrupted,
        "engine_warning_admission_count": warning_admission_count,
    }
