extends SceneTree
## Real worldmap scene, existing mode-5 flight camera and bounded cube stream.
## P2B opt-in material admission does not invent landing or save authority.
const Scene = preload("res://scenes/planetary_worldmap.tscn")
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    call_deferred("_run")

func _count_candidates(stream: Node3D) -> int:
    var changed := 0
    for tile_node in stream.get_children():
        var land := tile_node.get_node_or_null("SphericalLand") as MeshInstance3D
        if land != null and land.material_override is ShaderMaterial:
            changed += 1
    return changed

func _run() -> void:
    var world := Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.set_process(false)
    var stream := world.get_node("NativeCubedSphereTerrain") as Node3D
    check(not world.call("set_surface_review","snow"),
        "material preview cannot activate in globe mode")
    check(str(stream.call("stats")["review_kind"]) == "",
        "runtime defaults to original land material")
    check(not stream.call("set_surface_review","fabricated"),
        "unapproved material family rejected")
    for kind in ["wet_ground","snow"]:
        var pair: Array[Dictionary] = Study.find_pair(kind)
        check(pair.size() == 2,"real native biome neighboring fixtures exist: "+kind)
        if pair.size() != 2:
            continue
        var center: Vector2 = Tiles.tile_center(pair[0])
        var data: Dictionary = world.call("snapshot")
        data["flight"]["latDeg"] = center.x
        data["flight"]["lonDeg"] = center.y
        data["flight"]["headingDeg"] = 90.0
        data["flight"]["altitudeKm"] = 2.0
        data["mode"] = "tiles"
        world.call("_apply_state",data)
        world.call("_refresh_chart")
        world.call("_update_view")
        var original: Dictionary = world.call("snapshot")
        var first: Dictionary = stream.call("stats")
        check(int(first["visible"]) > 0 and int(first["visible"]) <= 32,
            "actual flight camera has bounded rendered tiles")
        check(int(first["cache_size"]) <= 64,"stream cache remains bounded")
        check(_count_candidates(stream) == 0,
            "all tile land materials retain original default")
        check(world.call("set_surface_review",kind),
            "opt-in review accepted only for explicit named look")
        var after: Dictionary = stream.call("stats")
        check(str(after["review_kind"]) == kind,"selected look preserved in ephemeral renderer")
        check(str(after["review_key"]) != "","one eligible streamed tile actually receives a shader")
        check(_count_candidates(stream) == 1,
            "at most one real mesh receives enhanced material")
        check(world.call("snapshot") == original,
            "material toggle does not change flight, discovery, mode or save record")
        var key: String = str(after["review_key"])
        check(key != "" and stream.call("active_keys").has(key),
            "material belongs to an active horizon streamed tile")
        var before: int = int(after["generated"])
        stream.call("refresh",data["flight"])
        var stable: Dictionary = stream.call("stats")
        check(str(stable["review_key"]) == key and int(stable["generated"]) == before,
            "revisit reuses cached mesh and same selected material")
        check(stream.call("set_surface_review",kind,true),
            "low-quality bypass accepted without changing visual source")
        check(str(stream.call("stats")["review_key"]) == "" and
            _count_candidates(stream) == 0,
            "low quality restores every original mesh material")
        check(world.call("set_surface_review",""),
            "reversible original material selected")
        check(_count_candidates(stream) == 0,
            "all active tile materials restored on disable")
        var key_event := InputEventKey.new()
        key_event.keycode = KEY_J
        key_event.pressed = true
        world.call("_unhandled_input",key_event)
        check(str(stream.call("stats")["review_kind"]) == "snow",
            "mode-5 J key enters optical snow review without gameplay mutation")
        check(world.call("snapshot") == original,
            "key-driven look change is excluded from preview save schema")
        check(world.call("set_surface_review",""),
            "J preview can be fully restored")
        world.call("_apply_state",original)
        check(str(stream.call("stats")["review_kind"]) == "",
            "loading validated scene state drops temporary preview look")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_WORLDMAP_MODE5_MATERIAL_PASS checks=",checks,
            " source=real_spherical_stream modes=read_only physical_landing=UNAUTHORIZED")
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_WORLDMAP_MODE5_MATERIAL_FAIL: "+failure)
        quit(1)
