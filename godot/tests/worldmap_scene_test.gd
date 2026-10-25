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
    switch.keycode = KEY_4
    scene.call("_unhandled_input",switch)
    check(scene.call("get_mode") == "flight","3D low-sky mode switch")
    check(patch.visible and not chart.visible,"3D view replaces map overlay")
    check(camera.position.x > 900.0,"camera moves to isolated local tangent terrain")
    check(not State.encode(scene.call("snapshot")).is_empty(),"all modes save-safe")
    scene.queue_free()
    await process_frame
    if failed.is_empty():
        print("GODOT_WORLDMAP_SCENE_PASS: real 3D globe meshes, chart/local modes and state")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_SCENE_FAIL: " + ", ".join(failed))
        quit(1)
