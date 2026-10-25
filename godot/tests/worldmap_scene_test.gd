extends SceneTree
const WorldScene = preload("res://scenes/planetary_worldmap.tscn")
const State = preload("res://scripts/planetary/worldmap_state.gd")
var failed: Array[String] = []

func check(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: Node3D = WorldScene.instantiate()
    root.add_child(scene)
    await process_frame
    var terrain := scene.get_node_or_null("WorldTerrainAndSeas") as MeshInstance3D
    var weather := scene.get_node_or_null("LayeredWeatherClouds") as MeshInstance3D
    var limb := scene.get_node_or_null("AtmosphericLimb") as MeshInstance3D
    var camera := scene.get_node_or_null("WorldMapOrbitCamera") as Camera3D
    var marker := scene.get_node_or_null("GeodesicShipLocator") as MeshInstance3D
    var chart := scene.get_node_or_null("WorldMapUI/GlobalChartOrLocalHorizon") as Control
    check(terrain != null and terrain.mesh != null,"terrain mesh instantiated")
    check(weather != null and weather.mesh != null,"clouds instantiated")
    check(limb != null and limb.mesh != null,"atmosphere instantiated")
    check(camera != null and camera.current,"camera current")
    check(marker != null and marker.mesh != null,"geodesic ship indicator")
    check(chart != null and not chart.visible,"globe starts without chart")
    check(State.validate(scene.call("snapshot")).has("flight"),"scene state valid")
    var switch := InputEventKey.new()
    switch.keycode = KEY_2
    switch.pressed = true
    scene.call("_unhandled_input",switch)
    check(scene.call("get_mode") == "chart","chart mode switch")
    check(chart.visible,"chart visible")
    scene.call("_set_waypoint",-30.0,140.0)
    var snapshot: Dictionary = scene.call("snapshot")
    check(not snapshot["waypoint"].is_empty(),"waypoint set without teleport")
    switch.keycode = KEY_3
    scene.call("_unhandled_input",switch)
    check(scene.call("get_mode") == "local","local view switch")
    check(chart.visible,"local survey visible")
    
    var patch := scene.get_node_or_null("LowSkyTerrainDevelopmentPatch")
    check(patch != null and patch.call("has_mesh"),"actual native local 3D terrain mesh")
    var ocean := patch.get_node_or_null("OceanSurface") as MeshInstance3D
    check(ocean != null,"separate ocean mesh node")
    check(ocean != null and ocean.mesh != null,"native water surface generated")
    var stats: Dictionary = patch.call("surface_stats")
    check(int(stats["land_cells"]) > 0 and int(stats["water_cells"]) > 0,
            "starting fixture spans both land and ocean")
    check(bool(stats["has_water"]),"water material is active")
    check(ocean != null and ocean.mesh.surface_get_material(0) is ShaderMaterial,
            "native wave and shoreline shader assigned")
    switch.keycode = KEY_4
    scene.call("_unhandled_input",switch)
    check(scene.call("get_mode") == "flight","3D low-sky mode switch")
    check(patch.visible and not chart.visible,"3D view replaces map overlay")
    var atmosphere := scene.get_node_or_null("WorldMapEnvironment") as WorldEnvironment
    check(atmosphere != null and atmosphere.environment.background_mode == Environment.BG_SKY,
            "low-sky view enables atmospheric sky")
    check(camera.position.x > 900.0,"camera moves to isolated local tangent terrain")
    var before_camera := camera.position
    var before_origin: Dictionary = patch.call("origin")
    var moved: Dictionary = scene.call("snapshot")
    moved["flight"]["lonDeg"] = float(moved["flight"]["lonDeg"]) + 0.1
    scene.call("_apply_state",moved)
    scene.call("_refresh_chart")
    scene.call("_update_view")
    check(camera.position.distance_to(before_camera) > 0.10,
            "geodesic ship travel moves the actual local camera continuously")
    check(patch.call("origin") == before_origin,
            "small ship movement does not teleport or rebuild the patch")
    var old_extent: float = patch.call("extent_km")
    var climbed: Dictionary = scene.call("snapshot")
    climbed["flight"]["altitudeKm"] = 200.0
    scene.call("_apply_state",climbed)
    scene.call("_refresh_chart")
    scene.call("_update_view")
    var new_extent: float = patch.call("extent_km")
    check(new_extent > old_extent,
            "large altitude change expands local patch to follow the horizon")
    switch.keycode = KEY_5
    scene.call("_unhandled_input",switch)
    var sphere_stream := scene.get_node_or_null("NativeCubedSphereTerrain")
    check(scene.call("get_mode") == "tiles","fifth cube-sphere mode accepts input")
    check(sphere_stream != null and sphere_stream.visible,"cube tile scene visible")
    check(not chart.visible and not patch.visible,"tile view isolates other two display modes")
    var tile_stats: Dictionary = sphere_stream.call("stats")
    check(int(tile_stats["visible"]) > 0 and int(tile_stats["visible"]) <= 32,
            "real cube-sphere tiles bounded by planner")
    var cube_nodes := sphere_stream.get_children()
    check(not cube_nodes.is_empty(),"generated cube tile child instances exist")
    var tile_sample := cube_nodes[0] as Node3D
    var tile_land := tile_sample.get_node_or_null("SphericalLand") as MeshInstance3D
    check(tile_land != null and tile_land.mesh != null,"cube tile carries real surface mesh")
    check(tile_land.material_override is StandardMaterial3D and
            (tile_land.material_override as StandardMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED,
            "double-sided review terrain material prevents intermittent cube-face backface masking")
    check(camera.position.length() < 40.0,
            "fifth-mode camera uses actual globe positions, not fake local 1000-unit origin")
    check(not terrain.visible,"tile-only review does not mask spherical surface behind whole-globe preview")
    var check_state: Dictionary = scene.call("snapshot")
    check(check_state["mode"] == "tiles","isolated save retains new cube-sphere mode")
    check(not State.encode(check_state).is_empty(),"all modes save-safe")
    scene.queue_free()
    await process_frame
    if failed.is_empty():
        print("GODOT_WORLDMAP_SCENE_PASS: real 3D globe meshes, chart/local modes and state")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_SCENE_FAIL: " + ", ".join(failed))
        quit(1)
