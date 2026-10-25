extends Node3D
## Native planet-scale exploration map, provisional geometry/visuals.
## Separate from First Wake progression, saves and private late-game routes.
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Flight = preload("res://scripts/planetary/planetary_flight.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const State = preload("res://scripts/planetary/worldmap_state.gd")
const Chart = preload("res://scripts/planetary/worldmap_chart.gd")
const LocalTerrain = preload("res://scripts/planetary/worldmap_local_terrain.gd")

const PLANET_KM := 6371.0 # Illustration, NOT canonical planet radius.
const GLOBE_UNITS := 12.0
const SURVEY_MARKERS := [
    {"id":"survey_a","name":"Survey A","latDeg":30.0,"lonDeg":140.0},
    {"id":"survey_b","name":"Survey B","latDeg":-9.0,"lonDeg":-27.0},
    {"id":"survey_c","name":"Survey C","latDeg":55.0,"lonDeg":82.0},
    {"id":"survey_d","name":"Survey D","latDeg":-59.0,"lonDeg":164.0}
]

var _flight: Dictionary = {}
var _mode := "globe"
var _discovered: Array[String] = []
var _waypoint: Dictionary = {}
var _autopilot := false
var _yaw := 0.22
var _pitch := 0.27
var _distance := 36.0
var _dragging := false
var _camera: Camera3D
var _clouds: MeshInstance3D
var _marker: MeshInstance3D
var _chart: Control
var _headline: Label
var _footer: Label
var _atlas: Texture2D
var _survey: Texture2D
var _survey_center: Dictionary = {}
var _survey_altitude := -1.0
var _panel_timer := 0.0
var _low_sky: Node3D
var _terrain_timer := 0.0

func _ready() -> void:
    _apply_state(State.defaults())
    _build_environment()
    _atlas = ImageTexture.create_from_image(Cart.render_equirect(640,320))
    _build_globe()
    _build_stars()
    _build_ship_locator()
    _build_camera()
    _build_local_patch()
    _build_overlay()
    _refresh_chart()
    _update_view()

func _apply_state(next: Dictionary) -> void:
    var safe := State.validate(next)
    if safe.is_empty():
        return
    _flight = safe["flight"]
    _mode = str(safe["mode"])
    _discovered.clear()
    for id in safe["discovered"]:
        _discovered.append(str(id))
    _waypoint = safe["waypoint"]
    _autopilot = false
    _survey_center = {}
    _survey_altitude = -1.0

func snapshot() -> Dictionary:
    return {"flight": _flight.duplicate(true), "mode": _mode,
            "discovered": _discovered.duplicate(), "waypoint": _waypoint.duplicate(true)}

func get_flight_state() -> Dictionary:
    return _flight.duplicate(true)

func get_mode() -> String:
    return _mode

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    world.name = "WorldMapEnvironment"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#03101f")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#80aec4")
    env.ambient_light_energy = 0.38
    world.environment = env
    add_child(world)
    var sunlight := DirectionalLight3D.new()
    sunlight.name = "IllustrativeSun"
    sunlight.light_color = Color("#ffebc7")
    sunlight.light_energy = 1.85
    sunlight.rotation_degrees = Vector3(-31.0,-42.0,0.0)
    add_child(sunlight)
    var skylight := DirectionalLight3D.new()
    skylight.light_color = Color("#5baebf")
    skylight.light_energy = 0.17
    skylight.rotation_degrees = Vector3(140.0,38.0,0.0)
    add_child(skylight)

func _sphere_mesh(radius: float, columns: int = 160, rows: int = 80) -> ArrayMesh:
    # Explicit lat/lon->UV correspondence with Geo.to_cartesian; unlike a
    # generic SphereMesh seam, map markers and colors use exactly one frame.
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uv := PackedVector2Array()
    var indices := PackedInt32Array()
    for y in range(rows+1):
        var lat := PI*0.5 - PI*float(y)/float(rows)
        for x in range(columns+1):
            var lon := -PI+TAU*float(x)/float(columns)
            var direction := Vector3(cos(lat)*cos(lon),sin(lat),cos(lat)*sin(lon))
            vertices.append(direction*radius)
            normals.append(direction)
            uv.append(Vector2(float(x)/float(columns),float(y)/float(rows)))
    for y in range(rows):
        for x in range(columns):
            var a := y*(columns+1)+x
            var b := a+1
            var c := a+columns+1
            var d := c+1
            indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uv
    arrays[Mesh.ARRAY_INDEX] = indices
    var output := ArrayMesh.new()
    output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return output

func _cloud_texture() -> Texture2D:
    const W := 512
    const H := 256
    var img := Image.create(W,H,false,Image.FORMAT_RGBA8)
    for y in range(H):
        var lat := PI*0.5 - PI*float(y)/float(H-1)
        for x in range(W):
            var lon := -PI+TAU*float(x)/float(W-1)
            var sx := cos(lat)*cos(lon)
            var sy := sin(lat)
            var sz := cos(lat)*sin(lon)
            var n := sin(10.0*sx+4.0*sy)*cos(8.0*sz-3.1*sy)
            n += 0.44*sin(18.0*sz+7.0*sx+6.0*sy)
            var alpha := clampf((n-0.30)*0.31,0.0,0.39)
            img.set_pixel(x,y,Color(0.97,0.97,1.0,alpha))
    return ImageTexture.create_from_image(img)

func _build_globe() -> void:
    var surface := MeshInstance3D.new()
    surface.name = "WorldTerrainAndSeas"
    surface.mesh = _sphere_mesh(GLOBE_UNITS)
    var terrain_mat := StandardMaterial3D.new()
    terrain_mat.albedo_texture = _atlas
    terrain_mat.roughness = 0.59
    terrain_mat.metallic = 0.06
    surface.material_override = terrain_mat
    add_child(surface)
    _clouds = MeshInstance3D.new()
    _clouds.name = "LayeredWeatherClouds"
    _clouds.mesh = _sphere_mesh(GLOBE_UNITS*1.016,128,64)
    var cloud_mat := StandardMaterial3D.new()
    cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    cloud_mat.albedo_texture = _cloud_texture()
    _clouds.material_override = cloud_mat
    add_child(_clouds)
    var atmosphere := MeshInstance3D.new()
    atmosphere.name = "AtmosphericLimb"
    atmosphere.mesh = _sphere_mesh(GLOBE_UNITS*1.046,96,48)
    var mat := ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never;
void fragment() {
    float falloff = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.1);
    ALBEDO = vec3(0.07, 0.54, 0.72);
    ALPHA = 0.6 * falloff;
}
"""
    mat.shader = shader
    atmosphere.material_override = mat
    add_child(atmosphere)

func _build_stars() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 30781
    var pin := SphereMesh.new()
    pin.radius = 0.052
    pin.height = 0.104
    pin.radial_segments = 6
    pin.rings = 3
    var white := StandardMaterial3D.new()
    white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    white.albedo_color = Color("#bfdbe3")
    pin.material = white
    var field := MultiMesh.new()
    field.transform_format = MultiMesh.TRANSFORM_3D
    field.mesh = pin
    field.instance_count = 280
    for i in range(field.instance_count):
        var dir := Vector3(rng.randf_range(-1.0,1.0),
                rng.randf_range(-1.0,1.0),rng.randf_range(-1.0,1.0)).normalized()
        field.set_instance_transform(i,Transform3D(Basis(),dir*rng.randf_range(96.0,175.0)))
    var node := MultiMeshInstance3D.new()
    node.name = "DistantStars"
    node.multimesh = field
    add_child(node)

func _build_ship_locator() -> void:
    _marker = MeshInstance3D.new()
    _marker.name = "GeodesicShipLocator"
    var orb := SphereMesh.new()
    orb.radius = 0.115
    orb.height = 0.23
    orb.radial_segments = 12
    orb.rings = 6
    _marker.mesh = orb
    var warm := StandardMaterial3D.new()
    warm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    warm.albedo_color = Color("#ffe1a2")
    _marker.material_override = warm
    add_child(_marker)

func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.name = "WorldMapOrbitCamera"
    _camera.current = true
    _camera.fov = 49.0
    _camera.near = 0.03
    _camera.far = 350.0
    add_child(_camera)

func _build_local_patch() -> void:
    _low_sky = LocalTerrain.new()
    add_child(_low_sky)
    _low_sky.call("rebuild",_flight,190.0,64)
    _low_sky.visible = false

func _add_label(parent: Node, name: String, position: Vector2, font_size: int,
        color: Color) -> Label:
    var node := Label.new()
    node.name = name
    node.position = position
    node.add_theme_font_size_override("font_size",font_size)
    node.add_theme_color_override("font_color",color)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(node)
    return node

func _build_overlay() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "WorldMapUI"
    add_child(canvas)
    var header := ColorRect.new()
    header.color = Color(0.015,0.055,0.10,0.89)
    header.size = Vector2(960,105)
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(header)
    _headline = _add_label(canvas,"NavigationReadout",Vector2(25,15),18,Color("#f4e7c9"))
    var foot_bg := ColorRect.new()
    foot_bg.position = Vector2(0,565)
    foot_bg.size = Vector2(960,75)
    foot_bg.color = Color(0.017,0.06,0.09,0.91)
    foot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(foot_bg)
    _footer = _add_label(canvas,"NavigationControls",Vector2(25,578),15,Color("#cee8e3"))
    _chart = Chart.new()
    _chart.name = "GlobalChartOrLocalHorizon"
    _chart.position = Vector2(65,136)
    _chart.size = Vector2(830,402)
    _chart.mouse_filter = Control.MOUSE_FILTER_STOP
    _chart.connect("waypoint_requested",Callable(self,"_set_waypoint"))
    canvas.add_child(_chart)

func _set_waypoint(lat: float,lon: float) -> void:
    _waypoint = Geo.position(lat,lon)
    _autopilot = false
    _refresh_chart()

func _known_markers() -> Array[Dictionary]:
    var records: Array[Dictionary] = []
    for item in SURVEY_MARKERS:
        var entry: Dictionary = item.duplicate()
        entry["discovered"] = _discovered.has(str(item["id"]))
        records.append(entry)
    return records

func _discover_nearby() -> void:
    for marker in SURVEY_MARKERS:
        var id := str(marker["id"])
        if _discovered.has(id):
            continue
        if Geo.great_circle_distance_km(_flight,marker,PLANET_KM) <= 180.0:
            _discovered.append(id)

func _refresh_chart() -> void:
    if _chart == null:
        return
    _chart.visible = _mode == "chart" or _mode == "local"
    if _low_sky != null:
        _low_sky.visible = _mode == "flight"
        if _mode == "flight":
            var origin: Dictionary = _low_sky.call("origin")
            if origin.is_empty() or Geo.great_circle_distance_km(origin,_flight,PLANET_KM) > 55.0:
                var horizon := Geo.horizon_distance_km(float(_flight["altitudeKm"]),PLANET_KM)
                _low_sky.call("rebuild",_flight,clampf(horizon*1.18,90.0,800.0),64)
    if _mode == "local":
        var moved := _survey_center.is_empty()
        if not moved:
            moved = Geo.great_circle_distance_km(_survey_center,_flight,PLANET_KM) > 15.0
            moved = moved or absf(float(_flight["altitudeKm"])-_survey_altitude) > 0.25
        if moved:
            var horizon := Geo.horizon_distance_km(float(_flight["altitudeKm"]),PLANET_KM)
            _survey = ImageTexture.create_from_image(Cart.render_local(_flight,
                    horizon,PLANET_KM,160))
            _survey_center = _flight.duplicate(true)
            _survey_altitude = float(_flight["altitudeKm"])
    _chart.call("configure",_mode,_atlas,_survey,_flight,_waypoint,
            _known_markers(),Geo.horizon_distance_km(float(_flight["altitudeKm"]),PLANET_KM))

func _update_view() -> void:
    if _camera == null:
        return
    
    if _mode == "flight" and _low_sky != null:
        var center: Vector3 = _low_sky.call("camera_position",_flight)
        var direction := deg_to_rad(float(_flight["headingDeg"]))
        var forward := Vector3(sin(direction),0.0,-cos(direction))
        _camera.position = center-forward*0.14+Vector3(0.0,0.018,0.0)
        _camera.look_at(center+forward*0.5-Vector3(0.0,0.024,0.0),Vector3.UP)
        _camera.near = 0.002
        _camera.far = 400.0
    else:
        _camera.position = Vector3(sin(_yaw)*cos(_pitch),sin(_pitch),
                cos(_yaw)*cos(_pitch))*_distance
        _camera.look_at(Vector3.ZERO,Vector3.UP)
        _camera.near = 0.03
        _camera.far = 350.0
    _marker.position = Geo.to_cartesian(_flight,PLANET_KM).normalized()*(GLOBE_UNITS+0.25)
    var nearby := Cart.sample(float(_flight["latDeg"]),float(_flight["lonDeg"]))
    var bearing_text := "No waypoint"
    if not _waypoint.is_empty():
        var distance := Geo.great_circle_distance_km(_flight,_waypoint,PLANET_KM)
        bearing_text = "Waypoint %.0f km" % distance
    _headline.text = "TO SAIL THE STARRY SKY    /    NATIVE GODOT WORLD MAP    /    NON-CANON GEOGRAPHY\n"
    _headline.text += "LAT %.2f   LON %.2f   ALT %.2f km   HDG %.0f°   SPEED %.0f km/h   BIOME %s\n" % [
            float(_flight["latDeg"]),float(_flight["lonDeg"]),float(_flight["altitudeKm"]),
            float(_flight["headingDeg"]),float(_flight["speedKmh"]),str(nearby["biome"])]
    _headline.text += "%s   /   Survey markers discovered: %d / %d   /   Geometric horizon: %.1f km" % [
            bearing_text,_discovered.size(),SURVEY_MARKERS.size(),
            Geo.horizon_distance_km(float(_flight["altitudeKm"]),PLANET_KM)]
    _footer.text = "1 GLOBE   2 GLOBAL CHART   3 HORIZON SURVEY   4 LOW-SKY 3D   W/S THROTTLE     Q/E TURN     R/F ALTITUDE\n"
    _footer.text += "A/D ORBIT   DRAG/WHEEL CAMERA   SHIFT FAST TRAVEL   P WAYPOINT PILOT   K SAVE   O LOAD"
    if _autopilot:
        _footer.text += "   /   WAYPOINT PILOT ACTIVE"

func _process(delta: float) -> void:
    var dt := minf(delta,0.05)
    _yaw += (float(int(Input.is_key_pressed(KEY_D)))-
            float(int(Input.is_key_pressed(KEY_A))))*dt*0.55
    var time_scale := 220.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
    var controls := {"turn":float(int(Input.is_key_pressed(KEY_E))-int(Input.is_key_pressed(KEY_Q))),
            "throttle":float(int(Input.is_key_pressed(KEY_W))-int(Input.is_key_pressed(KEY_S))),
            "climb":float(int(Input.is_key_pressed(KEY_R))-int(Input.is_key_pressed(KEY_F))),
            "timeScale":time_scale}
    if _autopilot and not _waypoint.is_empty():
        var remaining := Geo.great_circle_distance_km(_flight,_waypoint,PLANET_KM)
        var reach := maxf(3.0,float(_flight["speedKmh"])*dt*time_scale/3600.0)
        if remaining <= reach:
            _autopilot = false
            _flight["speedKmh"] = 0.0
        else:
            var target_bearing := Geo.initial_bearing_deg(_flight,_waypoint)
            var turn_error := fposmod(target_bearing-float(_flight["headingDeg"])+540.0,360.0)-180.0
            controls["turn"] = clampf(turn_error/(Flight.TURN_DEG_PER_SECOND*maxf(dt,0.001)),-1.0,1.0)
            controls["throttle"] = 1.0 if absf(turn_error) < 30.0 else -1.0
    elif Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_W):
        _autopilot = false
    _flight = Flight.advance(_flight,controls,dt,PLANET_KM)
    _clouds.rotate_y(dt*0.0022)
    _discover_nearby()
    _panel_timer += dt
    if _panel_timer >= 0.35:
        _panel_timer = 0.0
        _refresh_chart()
    _update_view()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key := event as InputEventKey
        if not key.pressed or key.echo:
            return
        match key.keycode:
            KEY_1: _mode = "globe"
            KEY_2: _mode = "chart"
            KEY_3: _mode = "local"
            KEY_4: _mode = "flight"
            KEY_P:
                _autopilot = not _autopilot if not _waypoint.is_empty() else false
            KEY_K:
                if not State.save_preview(snapshot()):
                    push_warning("WORLD_MAP_SAVE_REJECTED")
            KEY_O:
                var loaded := State.load_preview()
                if not loaded.is_empty():
                    _apply_state(loaded)
                else:
                    push_warning("WORLD_MAP_LOAD_REJECTED")
            KEY_ESCAPE:
                _autopilot = false
        _refresh_chart()
        _update_view()
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            _dragging = mouse.pressed
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
            _distance = maxf(17.0,_distance-2.0)
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _distance = minf(70.0,_distance+2.0)
    elif event is InputEventMouseMotion and _dragging:
        var motion := event as InputEventMouseMotion
        _yaw -= motion.relative.x*0.007
        _pitch = clampf(_pitch+motion.relative.y*0.007,-1.35,1.35)
