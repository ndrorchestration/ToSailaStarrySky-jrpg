extends SceneTree
## Native headless geometry/material contract for the DETACHED dune art study.
const DuneStudy = preload("res://dune_study.gd")
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
    if not value:
        failures.append(reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var dune := DuneStudy.new()
    root.add_child(dune)
    await process_frame
    check(dune.dune_mesh != null, "detached mesh exists")
    check(dune.dune_material != null, "same native terrain shader is reused")
    if dune.dune_mesh == null or dune.dune_material == null:
        push_error("DUNE_STUDY_FAIL missing study mesh/material")
        quit(1)
        return
    check(dune.dune_material.shader.resource_path == "res://shaders/terrain.gdshader",
        "shared source shader, not a copied sand shader")
    check(dune.dune_material.get_shader_parameter("dune_study_override") == true,
        "dunes are explicitly opt-in and do not repaint the base terrain")
    check(is_zero_approx(float(
        dune.dune_material.get_shader_parameter("shoreline_wetness"))),
        "dry dune study has no waterline tint")
    check(dune.get_child_count() == 1,
        "single geometry instance, no per-grain mesh nodes")
    var mesh: ArrayMesh = dune.dune_mesh.mesh
    check(mesh.get_surface_count() == 1, "single shared dune material surface")
    var arrays: Array = mesh.surface_get_arrays(0)
    var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    check(verts.size() == (dune.SEGMENTS+1)*(dune.SEGMENTS+1),
        "bounded deterministic dune vertex budget")
    check(normals.size() == verts.size(), "every dune vertex has analytic height normal")
    check(ids.size() == 6*dune.SEGMENTS*dune.SEGMENTS,
        "bounded two-triangle-per-cell dune budget")
    # Real Godot Compatibility GL screenshot caught the backfacing original
    # mesh: first triangle must use the approved camera-visible winding.
    check(ids.size() >= 6 and ids[0] == 0 and ids[1] == 1
        and ids[2] == dune.SEGMENTS+1
        and ids[3] == 1 and ids[4] == dune.SEGMENTS+2
        and ids[5] == dune.SEGMENTS+1,
        "actual dune triangles face the Godot review camera")
    for i in range(0, verts.size(), 71):
        var vertex: Vector3 = verts[i]
        check(is_equal_approx(vertex.y, dune.sample_height(vertex.x, vertex.z)),
            "dune vertices always use exact art sampler heights")
        check(normals[i].y > 0.72, "dune normals face sky and slopes remain smooth")
    check(absf(dune.sample_height(-10.0, 0.0)-
        dune.sample_height(10.0, 0.0)) > 0.3,
        "dunes have real continuous raised silhouettes, not a flat sand plane")
    var original_vertices: PackedVector3Array = verts.duplicate()
    dune.set_optics_strength(0.0)
    check(is_zero_approx(float(
        dune.dune_material.get_shader_parameter("sand_optics_strength"))),
        "optical shading exact reference mode")
    dune.set_optics_strength(1.0)
    dune.set_low_quality(true)
    check(dune.dune_material.get_shader_parameter("low_quality") == true,
        "low-quality bypass")
    dune.set_low_quality(false)
    check(dune.dune_material.get_shader_parameter("low_quality") == false,
        "reversible high-quality selection")
    check(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == original_vertices,
        "sand uniforms never displace dune height geometry")
    check(not dune.dune_mesh.has_node("CollisionShape3D"),
        "dune review does not create gameplay collision")
    dune.queue_free()
    await process_frame
    if failures.is_empty():
        print("DUNE_STUDY_CONTRACT_PASS checks=discrete+mesh+normal+quality")
        quit(0)
    else:
        for failure in failures:
            push_error("DUNE_STUDY_FAIL: " + failure)
        quit(1)
