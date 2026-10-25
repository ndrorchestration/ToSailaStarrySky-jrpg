extends Node3D
## Isolated 960x640 Godot Compatibility scene. No secret routes or progression.
const TerrainStudy = preload("res://terrain.gd")
const ShipStudy = preload("res://ship.gd")
const FrameProbe = preload("res://frame_probe.gd")
const VisualStudy = preload("res://visuals.gd")
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
    _update_scene(step)
    _status_timer += step
    if _status_timer > 0.35:
        _status_timer = 0.0
        overlay.text = "TO SAIL THE STARRY SKY  /  VISUAL LAB\nCOAST  →  FOREST  →  HIGHLANDS\n" + ("CINEMATIC" if _cinematic else "FLIGHT CHASE") + "  |  %s TILES / %s NEAR LOD\n" % [terrain.visible_tiles, terrain.detailed_tiles] + "C camera · P pause · M still effects · R restart · V detail · H HUD\nNON-CANON ART STUDY  •  NOT A GAMEPLAY / FPS CLAIM"

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_C:
            _cinematic = not _cinematic
        KEY_P:
            _paused = not _paused
        KEY_M:
            _reduced_motion = not _reduced_motion
        KEY_R:
            _clock = 0.0
        KEY_V:
            _low_quality = not _low_quality
            if visuals != null:
                visuals.set_low_quality(_low_quality)
        KEY_H:
            overlay.visible = not overlay.visible

func _update_scene(delta: float) -> void:
    var phase: float = fmod(_clock, 37.0) / 37.0
    var x: float = lerpf(-52.0, 77.0, phase)
    var z: float = -12.0 + sin(_clock * 0.15) * 4.0
    var clearance: float = 6.7
    ship.position = Vector3(x, maxf(TerrainStudy.SEA_LEVEL, TerrainStudy.sample_height(x, z)) + clearance, z)
    ship.set_motion(_clock, _reduced_motion)
    var goal: Vector3
    var focus: Vector3 = ship.position + Vector3(12.0, 0.7, -5.0)
    if _cinematic:
        var arc: float = 0.5 + 0.5 * sin(_clock * 0.17)
        goal = ship.position + Vector3(-15.5 - arc * 4.5, 10.0 + arc * 3.0, 20.0 - arc * 3.0)
        focus = ship.position + Vector3(7.0, 0.8, -3.0)
    else:
        goal = ship.position + Vector3(-12.0, 7.4, 19.0)
        focus = ship.position + Vector3(12.0, 0.4, 0.0)
    # One-time snap prevents an initial camera whip.
    var weight: float = 1.0 if _clock < 0.11 else 1.0 - exp(-maxf(delta, 0.0) * 2.5)
    camera.position = camera.position.lerp(goal, weight)
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
