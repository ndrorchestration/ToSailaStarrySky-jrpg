extends Node3D
## Standalone, NON-CANON Godot 4.7.2 visual study.
## All geometry, art, radius, surface noise and camera scale are illustrative.
## No HTML, JS, external assets or network runtime.

const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")
const Flight = preload("res://scripts/planetary/planetary_flight.gd")
const MAP_RADIUS := 12.0
const STUDY_RADIUS_KM := 6371.0 # Experimental fixture, not world canon.

var _camera: Camera3D
var _clouds: MeshInstance3D
var _marker: MeshInstance3D
var _hud: Label
var _flight: Dictionary = Flight.create_state()
var _yaw: float = -0.25
var _pitch: float = 0.28
var _distance: float = 37.0
var _dragging: bool = false

func _ready() -> void:
    _environment()
    _build_globe()
    _build_stars()
    _build_marker()
    _build_camera()
    _build_hud()
    _update_view()

func _environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#020c19")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#7db4c3")
    env.ambient_light_energy = 0.4
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.light_color = Color("#fff2cd")
    sun.light_energy = 1.6
    sun.rotation_degrees = Vector3(-24.0, -52.0, 0.0)
    add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.light_color = Color("#3aacc0")
    fill.light_energy = 0.25
    fill.rotation_degrees = Vector3(140.0, 36.0, 0.0)
    add_child(fill)

func _sphere(radius: float, segments: int = 96) -> SphereMesh:
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2.0
    shape.radial_segments = segments
    shape.rings = int(segments / 2)
    return shape

func _build_globe() -> void:
    var surface := MeshInstance3D.new()
    surface.name = "IllustrativePlanetSurface"
    surface.mesh = _sphere(MAP_RADIUS)
    var surface_mat := StandardMaterial3D.new()
    surface_mat.albedo_texture = _surface_texture()
    surface_mat.roughness = 0.67
    surface_mat.metallic = 0.11
    surface.material_override = surface_mat
    add_child(surface)

    _clouds = MeshInstance3D.new()
    _clouds.name = "ProceduralClouds"
    _clouds.mesh = _sphere(MAP_RADIUS * 1.015)
    var cloud_mat := StandardMaterial3D.new()
    cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    cloud_mat.albedo_texture = _cloud_texture()
    cloud_mat.albedo_color = Color(1.0, 0.98, 0.94, 0.65)
    _clouds.material_override = cloud_mat
    add_child(_clouds)

    var haze := MeshInstance3D.new()
    haze.name = "ThinAtmosphericRim"
    haze.mesh = _sphere(MAP_RADIUS * 1.047)
    var rim_mat := ShaderMaterial.new()
    var rim_shader := Shader.new()
    rim_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never;
void fragment() {
    float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.2);
    ALBEDO = vec3(0.10, 0.68, 0.86);
    ALPHA = 0.65 * fresnel;
}
"""
    rim_mat.shader = rim_shader
    haze.material_override = rim_mat
    add_child(haze)

func _surface_texture() -> Texture2D:
    const WIDTH := 512
    const HEIGHT := 256
    var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
    for y in range(HEIGHT):
        var lat: float = (0.5 - float(y) / float(HEIGHT - 1)) * PI
        for x in range(WIDTH):
            var lon: float = (float(x) / float(WIDTH - 1) - 0.5) * TAU
            # Periodic longitude harmonics: no hard dateline relief seam.
            var elevation: float = 0.34*sin(3.0*lon + 0.4) + 0.19*cos(5.0*lon - 2.0*lat)
            elevation += 0.16*sin(7.0*lon + 3.0*lat) + 0.16*cos(2.0*lon + 5.0*lat)
            var pixel: Color
            if absf(lat) > 1.35:
                pixel = Color("#dcece9")
            elif elevation > 0.13:
                if absf(lat) > 0.95 or elevation > 0.55:
                    pixel = Color("#b3b8a5")
                elif elevation > 0.34:
                    pixel = Color("#7c9172")
                elif absf(lat) < 0.38:
                    pixel = Color("#2b8068")
                else:
                    pixel = Color("#417a69")
            elif elevation > 0.07:
                pixel = Color("#d8c7a0")
            elif elevation > -0.08:
                pixel = Color("#127c89")
            else:
                pixel = Color("#073b65")
            img.set_pixel(x, y, pixel)
    return ImageTexture.create_from_image(img)

func _cloud_texture() -> Texture2D:
    const WIDTH := 512
    const HEIGHT := 256
    var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
    for y in range(HEIGHT):
        var lat: float = (0.5 - float(y) / float(HEIGHT - 1)) * PI
        for x in range(WIDTH):
            var lon: float = (float(x) / float(WIDTH - 1) - 0.5) * TAU
            var vapor: float = sin(11.0*lon + 2.0*sin(lat*4.0)) * cos(lat*7.0 - 3.0*lon)
            vapor += 0.36*cos(17.0*lon + 9.0*lat)
            var alpha := clampf((vapor - 0.35) * 0.45, 0.0, 0.38)
            img.set_pixel(x, y, Color(0.96, 0.98, 1.0, alpha))
    return ImageTexture.create_from_image(img)

func _build_stars() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 18407
    var mesh := _sphere(0.05, 8)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color("#bbdfeb")
    mesh.material = mat
    var stars := MultiMesh.new()
    stars.transform_format = MultiMesh.TRANSFORM_3D
    stars.mesh = mesh
    stars.instance_count = 320
    for i in range(stars.instance_count):
        var v := Vector3(rng.randf_range(-1.0, 1.0),
                rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
        stars.set_instance_transform(i, Transform3D(Basis(), v * rng.randf_range(100.0, 180.0)))
    var field := MultiMeshInstance3D.new()
    field.name = "FixedSeedStarfield"
    field.multimesh = stars
    add_child(field)

func _build_marker() -> void:
    _marker = MeshInstance3D.new()
    _marker.name = "ExperimentalFlightPositionMarker"
    _marker.mesh = _sphere(0.14, 12)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color("#ffd997")
    _marker.material_override = mat
    add_child(_marker)

func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.name = "GlobeOrbitCamera"
    _camera.current = true
    _camera.fov = 48.0
    _camera.near = 0.05
    _camera.far = 300.0
    add_child(_camera)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "NonCanonStudyOverlay"
    add_child(layer)
    _hud = Label.new()
    _hud.position = Vector2(20.0, 16.0)
    _hud.add_theme_color_override("font_color", Color("#e6f2ee"))
    _hud.add_theme_font_size_override("font_size", 16)
    layer.add_child(_hud)

func _update_view() -> void:
    _camera.position = Vector3(sin(_yaw)*cos(_pitch), sin(_pitch),
            cos(_yaw)*cos(_pitch)) * _distance
    _camera.look_at(Vector3.ZERO, Vector3.UP)
    _marker.position = Geometry.to_cartesian(_flight, STUDY_RADIUS_KM).normalized() * (MAP_RADIUS + 0.23)
    _hud.text = "TO SAIL THE STARRY SKY   |   GODOT 4.7.2   |   NON-CANON GLOBE STUDY\n"
    _hud.text += "Drag: orbit   Wheel: zoom   W/S: throttle   Q/E: turn   R/F: climb/descend   Shift: fast study time\n"
    _hud.text += "Lat %.2f   Lon %.2f   Alt %.2f km   Heading %.1f   Speed %.0f km/h\n" % [
            float(_flight["latDeg"]), float(_flight["lonDeg"]), float(_flight["altitudeKm"]),
            float(_flight["headingDeg"]), float(_flight["speedKmh"])]
    _hud.text += "Sea-level geometric horizon %.1f km | Artist review, ship mesh and canon geography pending" % [
            Geometry.horizon_distance_km(float(_flight["altitudeKm"]), STUDY_RADIUS_KM)]

func _process(delta: float) -> void:
    if Input.is_key_pressed(KEY_A):
        _yaw -= delta * 0.55
    if Input.is_key_pressed(KEY_D):
        _yaw += delta * 0.55
    var controls := {
        "turn": float(int(Input.is_key_pressed(KEY_E)) - int(Input.is_key_pressed(KEY_Q))),
        "throttle": float(int(Input.is_key_pressed(KEY_W)) - int(Input.is_key_pressed(KEY_S))),
        "climb": float(int(Input.is_key_pressed(KEY_R)) - int(Input.is_key_pressed(KEY_F))),
        "timeScale": 220.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
    }
    _flight = Flight.advance(_flight, controls, minf(delta, 0.05), STUDY_RADIUS_KM)
    _clouds.rotate_y(delta * 0.003)
    _update_view()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT:
            _dragging = button.pressed
        elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
            _distance = maxf(20.0, _distance - 2.5)
        elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _distance = minf(68.0, _distance + 2.5)
    elif event is InputEventMouseMotion and _dragging:
        var motion := event as InputEventMouseMotion
        _yaw -= motion.relative.x * 0.007
        _pitch = clampf(_pitch + motion.relative.y * 0.007, -1.35, 1.35)
