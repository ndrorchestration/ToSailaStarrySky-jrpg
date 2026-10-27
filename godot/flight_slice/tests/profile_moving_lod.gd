extends SceneTree
## HEADLESS CPU diagnostic of actual detail updates along a repeatable local path.
## Not an FPS, GPU, target-hardware, or full-flight performance measurement.
const TerrainStudy = preload("res://terrain.gd")

func _initialize() -> void:
    call_deferred("_run")

func _snapshot_mesh_ids(terrain: Node3D) -> Array[int]:
    var ids: Array[int] = []
    for tile in terrain._tiles:
        var mesh: ArrayMesh = tile["stitched_mesh"]
        ids.append(0 if mesh == null else mesh.get_instance_id())
    return ids

func _run() -> void:
    var started: int = Time.get_ticks_usec()
    var terrain = TerrainStudy.new()
    root.add_child(terrain)
    var startup_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
    if terrain.chunk_count() != 64:
        push_error("MOVING_LOD_PROFILE_INVALID_TILE_COUNT")
        quit(1)
        return
    var records: Array[Dictionary] = []
    var durations: Array[float] = []
    var total_rebuilds: int = 0
    # 42 regularly spaced positions eastbound, then reverse; one call models
    # 0.2 simulated seconds and crosses multiple LOD/hysteresis boundaries.
    for leg in range(2):
        for step in range(42):
            var n: int = step if leg == 0 else 41 - step
            var x: float = -52.0 + float(n) * 3.1
            var z: float = -12.0 + 4.0 * sin(float(n) * 0.12)
            var old_ids: Array[int] = _snapshot_mesh_ids(terrain)
            var before: int = Time.get_ticks_usec()
            terrain.update_detail(Vector3(x, 24.0, z), 0.2)
            var elapsed_ms: float = float(Time.get_ticks_usec() - before) / 1000.0
            var new_ids: Array[int] = _snapshot_mesh_ids(terrain)
            var rebuilt: int = 0
            for i in range(old_ids.size()):
                if new_ids[i] != 0 and new_ids[i] != old_ids[i]:
                    rebuilt += 1
            total_rebuilds += rebuilt
            durations.append(elapsed_ms)
            records.append({"leg":leg,"step":step,"x":x,"z":z,
                "elapsed_ms":elapsed_ms,"stitched_mesh_id_changes":rebuilt,
                "visible_tiles":terrain.visible_tiles,"high_detail_tiles":terrain.detailed_tiles})
    if records.size() != 84 or total_rebuilds == 0:
        push_error("MOVING_LOD_PROFILE_NO_TRANSITIONS")
        terrain.queue_free()
        quit(1)
        return
    var ordered: Array[float] = durations.duplicate()
    ordered.sort()
    var folder: String = ProjectSettings.globalize_path("res://evidence")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("MOVING_LOD_PROFILE_DIRECTORY_FAILED")
        quit(1)
        return
    var path: String = folder.path_join("moving-lod-profile.json")
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("MOVING_LOD_PROFILE_WRITE_FAILED")
        quit(1)
        return
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,
        "os":OS.get_name(),"rendering":"headless",
        "method":"wall time inside update_detail; excludes draw, GPU and frame scheduling",
        "startup_ms":startup_ms,"steps":records.size(),
        "median_ms":ordered[42],"p95_ms":ordered[79],"max_ms":ordered[83],
        "total_stitched_mesh_id_changes":total_rebuilds,"records":records}, "  "))
    file.close()
    print("MOVING_LOD_PROFILE_PASS steps=", records.size(),
        " startup_ms=", startup_ms, " median_ms=", ordered[42],
        " p95_ms=", ordered[79], " max_ms=", ordered[83],
        " stitched_mesh_id_changes=", total_rebuilds)
    terrain.queue_free()
    await process_frame
    quit(0)
