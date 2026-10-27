extends Node3D
## Isolated 960x640 Godot Compatibility scene. No secret routes or progression.
const TerrainStudy = preload("res://terrain.gd")
const ShipStudy = preload("res://ship.gd")
const FrameProbe = preload("res://frame_probe.gd")
const VisualStudy = preload("res://visuals.gd")
const FlightStudy = preload("res://flight_controller.gd")
const CinematicShots = preload("res://cinematic_shot_rig.gd")
const LandingStudy = preload("res://landing_study.gd")
const LandingCollision = preload("res://landing_collision.gd")
var visuals: Node3D
var _low_quality: bool = false

var terrain
var ship
var camera: Camera3D
var overlay: Label
var _clock: float = 0.0
var _status_timer: float = 0.0
var _paused: bool = false
var _reduced_motion: bool = false
var _cinematic: bool = true
var _manual_active: bool = false
var _manual_position: Vector3 = Vector3.ZERO
var _manual_heading: float = 0.0
var landing = LandingStudy.new()
var landing_ground: StaticBody3D
var _touchdown_requested: bool = false
var last_touchdown_contact: Dictionary = {"valid": false}
var _landing_message: String = ""

func _ready() -> void:
    if OS.get_cmdline_user_args().has("--baseline"):
        _install_environment()
    else:
        visuals = VisualStudy.new()
        visuals.name = "FlightPresentation"
        add_child(visuals)
    terrain = TerrainStudy.new()
    terrain.name = "ArtSliceTerrain"
    add_child(terrain)
    landing_ground = LandingCollision.new()
    landing_ground.name = "TemporaryPhysicsGround"
    add_child(landing_ground)
    if visuals != null:
        visuals.bind_terrain(terrain)
    ship = ShipStudy.new()
    ship.name = "DragonflySilhouetteStudy"
    add_child(ship)
    camera = Camera3D.new()
    camera.name = "FlightCamera"
    camera.current = true
    camera.fov = 62.0
    camera.near = 0.15
    camera.far = 425.0
    camera.position = Vector3(-56.0, 20.0, 52.0)
    add_child(camera)
    _make_overlay()
    if OS.get_cmdline_user_args().has("--benchmark"):
        var probe = FrameProbe.new()
        probe.name = "UnverifiedHostFrameProbe"
        add_child(probe)
    _update_scene(0.0)

func _process(delta: float) -> void:
    var step: float = minf(delta, 0.10)
    if not _paused:
        _clock += step
        if _manual_active:
            advance_manual(Vector3(
                float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
                float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S)),
                float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
            ), step)
    _update_scene(step)
    _status_timer += step
    if _status_timer > 0.35:
        _status_timer = 0.0
        var flight_info: String = "PILOT %s  |  clearance %.1f m  |  heading %.0f°  |  %s" % [landing.state, FlightStudy.clearance(ship.position), rad_to_deg(_manual_heading), _landing_message] if _manual_active else "AUTOMATIC FLYOVER  |  C camera framing"
        overlay.text = "TO SAIL THE STARRY SKY  /  FLIGHT LAB\nCOAST  →  FOREST  →  HIGHLANDS\n" + flight_info + "  |  %s TILES / %s NEAR LOD\n" % [terrain.visible_tiles, terrain.detailed_tiles] + "F pilot/flyover · W/S move · A/D steer · E/Q ascend/descend\nT ground approach/takeoff (test field) · P pause · M still effects\nR reset · V detail · H HUD\nNON-CANON STUDY  •  TERRAIN RAYCAST / NO RIGIDBODY FLIGHT"

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_F:
            set_manual_mode(not _manual_active)
        KEY_T:
            request_touchdown()
        KEY_C:
            _cinematic = not _cinematic
        KEY_P:
            _paused = not _paused
        KEY_M:
            _reduced_motion = not _reduced_motion
        KEY_R:
            set_manual_mode(false)
            _clock = 0.0
        KEY_V:
            _low_quality = not _low_quality
            if visuals != null:
                visuals.set_low_quality(_low_quality)
        KEY_H:
            overlay.visible = not overlay.visible

func set_manual_mode(enabled: bool) -> void:
    if enabled == _manual_active:
        return
    _manual_active = enabled
    landing.reset()
    _touchdown_requested = false
    last_touchdown_contact = {"valid": false}
    _landing_message = ""
    if enabled:
        _manual_position = ship.position
        _manual_heading = 0.0
    else:
        ship.set_course(0.0)

func request_touchdown() -> bool:
    if not _manual_active or _paused or _touchdown_requested:
        return false
    if landing.state != "FLYING" and landing.state != "LANDED":
        return false
    # PhysicsDirectSpaceState3D is queried in _physics_process, never in input
    # callbacks, to avoid a locked physics space on threaded configurations.
    _touchdown_requested = true
    _landing_message = "CHECKING NATIVE TERRAIN COLLISION"
    return true

func _physics_process(delta: float) -> void:
    if not _manual_active or _paused:
        if _touchdown_requested:
            _landing_message = "CANCELLED"
        _touchdown_requested = false
        return
    var contact: Dictionary = {"valid": false}
    if landing.state == "DESCENDING" or landing.state == "LANDED" or _touchdown_requested:
        contact = _probe_landing_contact()
    # Validate existing support before a queued takeoff can change the state.
    # Losing the ground and pressing T on the same tick still requires recovery.
    if landing.state == "DESCENDING" or landing.state == "LANDED":
        last_touchdown_contact = contact
        if not landing.has_support(contact):
            last_touchdown_contact = {"valid": false,
                "reason": contact.get("reason", "SUPPORT_MOVED_OR_UNSAFE")}
            _touchdown_requested = false
            landing.recover(_manual_position)
            _landing_message = "CONTACT LOST / RETURNING TO HOVER"
            print("GODOT_TOUCHDOWN_RECOVERY reason=", last_touchdown_contact["reason"])
    if _touchdown_requested:
        _touchdown_requested = false
        last_touchdown_contact = contact
        var accepted: bool = landing.toggle_with_physics(_manual_position, contact)
        _landing_message = "" if accepted else "NATIVE COLLIDER / SAFE FIELD REQUIRED"
        if accepted:
            print("GODOT_TOUCHDOWN_PHYSICS_ADMISSION_PASS state=", landing.state)
        else:
            print("GODOT_TOUCHDOWN_PHYSICS_REJECT reason=", contact.get("reason", "FIELD_OR_SLOPE"))
    # A fresh query and the corresponding landing motion share the physics tick.
    # Rendering/input ticks cannot advance a cached touchdown between queries.
    if landing.state != "FLYING":
        _manual_position = landing.tick(_manual_position, delta)

func _probe_landing_contact() -> Dictionary:
    if not is_instance_valid(landing_ground) or not landing_ground.is_inside_tree():
        return {"valid": false, "reason": "NO_NATIVE_TERRAIN_BODY"}
    return landing_ground.probe(_manual_position, get_world_3d().direct_space_state)

func advance_manual(controls: Vector3, delta: float) -> void:
    if not _manual_active or _paused:
        return
    if landing.state != "FLYING":
        return
    var next: Dictionary = FlightStudy.advance(_manual_position, _manual_heading,
        controls, delta)
    _manual_position = next["position"]
    _manual_heading = next["heading"]

func _update_scene(delta: float) -> void:
    if _manual_active:
        ship.position = _manual_position
        ship.set_course(-PI / 2.0 - _manual_heading)
    else:
        var phase: float = fmod(_clock, 37.0) / 37.0
        var x: float = lerpf(-52.0, 77.0, phase)
        var z: float = -12.0 + sin(_clock * 0.15) * 4.0
        var clearance: float = 6.7
        ship.position = Vector3(x, maxf(TerrainStudy.SEA_LEVEL,
            TerrainStudy.sample_height(x, z)) + clearance, z)
    ship.set_motion(_clock, _reduced_motion)
    ship.set_landing_gear(_manual_active and landing.state != "FLYING")
    var goal: Vector3
    var focus: Vector3
    var target_fov: float = 62.0
    if _manual_active:
        var forward := Vector3(cos(_manual_heading), 0.0, sin(_manual_heading))
        var lateral := Vector3(-forward.z, 0.0, forward.x)
        goal = ship.position - forward * 16.0 + lateral * 5.0 + Vector3.UP * 8.0
        focus = ship.position + forward * 9.0 + Vector3.UP * 0.7
    elif _cinematic:
        # Camera-only staging; gameplay/flight and terrain remain unchanged.
        var shot: Dictionary = CinematicShots.sample(
            _clock, ship.position, _reduced_motion)
        goal = shot["position"]
        focus = shot["focus"]
        target_fov = float(shot["fov"])
    else:
        goal = ship.position + Vector3(-12.0, 7.4, 19.0)
        focus = ship.position + Vector3(12.0, 0.4, 0.0)
    # One-time snap prevents an initial camera whip.
    var weight: float = 1.0 if _clock < 0.11 else 1.0 - exp(-maxf(delta, 0.0) * 2.5)
    camera.position = camera.position.lerp(goal, weight)
    camera.fov = lerpf(camera.fov, target_fov, weight)
    camera.look_at(focus, Vector3.UP)
    terrain.update_detail(camera.position, delta)
    if visuals != null:
        visuals.set_clock(_clock, _reduced_motion)

func _install_environment() -> void:
    var daylight := DirectionalLight3D.new()
    daylight.name = "GoldenHourKey"
    daylight.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    daylight.light_color = Color(1.0, 0.85, 0.66)
    daylight.light_energy = 1.07
    daylight.shadow_enabled = true
    add_child(daylight)
    var ambient := WorldEnvironment.new()
    ambient.name = "TealSilverSky"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var material := ProceduralSkyMaterial.new()
    material.sky_top_color = Color(0.025, 0.105, 0.195)
    material.sky_horizon_color = Color(0.42, 0.60, 0.65)
    material.ground_horizon_color = Color(0.37, 0.47, 0.45)
    material.ground_bottom_color = Color(0.06, 0.14, 0.17)
    material.use_debanding = true
    sky.sky_material = material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.45, 0.63, 0.65)
    environment.fog_density = 0.004
    ambient.environment = environment
    add_child(ambient)

func _make_overlay() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "StudyHUD"
    add_child(canvas)
    overlay = Label.new()
    overlay.name = "Status"
    overlay.position = Vector2(24, 22)
    overlay.add_theme_font_size_override("font_size", 15)
    overlay.add_theme_color_override("font_color", Color(0.94, 0.96, 0.91))
    overlay.add_theme_color_override("font_shadow_color", Color(0.02, 0.08, 0.12, 0.85))
    overlay.add_theme_constant_override("shadow_offset_x", 1)
    overlay.add_theme_constant_override("shadow_offset_y", 2)
    overlay.text = "COAST-TO-HIGHLAND ART STUDY / LOADING"
    canvas.add_child(overlay)
