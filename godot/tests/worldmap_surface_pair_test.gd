extends SceneTree
## S2: 2 genuine spherical mesh instances from native #367 + material A/B.
## No collider is installed; physical landing MUST remain unapproved.
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Builder = preload("res://scripts/planetary/worldmap_cube_tile_mesh.gd")
const Preview = preload("res://scripts/planetary/worldmap_surface_material_preview.gd")
var checks: int = 0
var errors: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(Preview.build({}) == null,"malformed context rejected")
    var seen: Dictionary = {}
    for kind in ["snow","wet_ground"]:
        var study: Node3D = Study.new()
        root.add_child(study)
        check(study.make_pair(kind),"native paired mesh fixture exists: "+kind)
        if study.instances.size() != 2:
            errors.append("missing real tile meshes: "+kind)
            study.queue_free()
            continue
        check(study.selected_tiles.size() == 2 and
            study.selected_contexts.size() == 2,"two actual tile contexts")
        check(str(study.selected_contexts[0]["material"]) == kind and
            str(study.selected_contexts[1]["material"]) == kind,
            "material resolved from real native cartography at two tile centers")
        check(Tiles.key(study.selected_tiles[1]) ==
            Tiles.key(Tiles.neighbor(study.selected_tiles[0],1,0)),
            "adjacent cubed-sphere neighbors are authentic tile addresses")
        var different_keys := Tiles.key(study.selected_tiles[0]) != \
            Tiles.key(study.selected_tiles[1])
        check(different_keys,"real distinct neighboring spherical tiles")
        for tile_index in range(2):
            var tile: Dictionary = study.selected_tiles[tile_index]
            var node: MeshInstance3D = study.instances[tile_index]
            var old_vertices: PackedVector3Array = study.mesh_stats[tile_index]["vertices"]
            check(node.mesh is ArrayMesh and old_vertices.size() == 864,
                "native 12-division triangle mesh is physically present")
            check(int(study.mesh_stats[tile_index]["land_cells"]) +
                int(study.mesh_stats[tile_index]["water_cells"]) == 144,
                "all original source grid cells retained")
            check(node.get_child_count() == 0 and \
                node.find_children("*","CollisionObject3D",true,false).is_empty(),
                "visual-only tile never fabricates a landing collider")
            check(study.materials[tile_index].shader != null and
                study.materials[tile_index].shader.code.find("planet_position") >= 0,
                "actual material samples world-space planet coordinates")
            check(is_zero_approx(float(study.materials[tile_index].get_shader_parameter(
                "effect_strength"))),"original-material A/B baseline is zero")
        study.effect(true)
        for tile_index in range(2):
            var node: MeshInstance3D = study.instances[tile_index]
            var verts: PackedVector3Array = (node.mesh as ArrayMesh).surface_get_arrays(
                0)[Mesh.ARRAY_VERTEX]
            check(verts == study.mesh_stats[tile_index]["vertices"],
                "shader enable does not move real planetary geometry")
            check(is_equal_approx(float(study.materials[tile_index].get_shader_parameter(
                "effect_strength")),1.0),"high-quality material enabled")
        study.effect(false)
        for mat in study.materials:
            check(is_zero_approx(float(mat.get_shader_parameter(
                "effect_strength"))),"reversible zero-strength baseline restored")
        seen[kind]=true
        study.queue_free()
    await process_frame
    check(seen.size() == 2,"snow and wet ground independently reviewed")
    if errors.is_empty():
        print("GODOT_PLANETARY_SURFACE_PAIR_PASS checks=",checks,
            " actual_meshes=4 physics=UNAUTHORIZED source=native_cartography NONCANON")
        quit(0)
    else:
        for error in errors:
            push_error("GODOT_PLANETARY_SURFACE_PAIR_FAIL: "+error)
        quit(1)
