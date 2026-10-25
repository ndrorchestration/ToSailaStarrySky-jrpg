extends SceneTree
## Native Godot scene construction smoke. No GPU/screenshot or performance claim.
const Scene = preload("res://scenes/planetary_globe_study.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var study: Node3D = Scene.instantiate()
    if study == null:
        push_error("GODOT_PLANETARY_SCENE_FAIL: cannot instantiate")
        quit(1)
        return
    root.add_child(study)
    await process_frame
    var camera := study.get_node_or_null("GlobeOrbitCamera") as Camera3D
    var surface := study.get_node_or_null("IllustrativePlanetSurface") as MeshInstance3D
    var clouds := study.get_node_or_null("ProceduralClouds") as MeshInstance3D
    var marker := study.get_node_or_null("ExperimentalFlightPositionMarker") as MeshInstance3D
    if camera == null or surface == null or clouds == null or marker == null:
        push_error("GODOT_PLANETARY_SCENE_FAIL: required native nodes missing")
        quit(2)
        return
    if surface.mesh == null or clouds.mesh == null or marker.mesh == null:
        push_error("GODOT_PLANETARY_SCENE_FAIL: actual meshes missing")
        quit(3)
        return
    print("GODOT_PLANETARY_SCENE_PASS: meshes, clouds, camera, native flight marker")
    quit(0)
