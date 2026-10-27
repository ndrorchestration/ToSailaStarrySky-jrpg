extends SceneTree
## Authored, terrain-anchored faceted highland dressing, never a collider.
const Study = preload("res://main.tscn")
const Terrain = preload("res://terrain.gd")
const Rocks = preload("res://rock_dressing.gd")
var faults: Array[String] = []
var checks: int = 0

func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok: faults.append(note)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    var dressing: MultiMeshInstance3D = visuals.rocks
    check(dressing != null, "one rocky outcrop presentation node")
    if dressing != null:
        check(dressing.name == "VisualRockOutcrops", "outcrop node has review identity")
        check(dressing.multimesh != null, "outcrops use one native MultiMesh")
        if dressing.multimesh != null:
            var n: int = dressing.multimesh.instance_count
            check(n > 4 and n <= Rocks.MAX_OUTCROPS,
                "bounded nonempty highland rocks")
            var placements: Array = dressing.get("poses")
            check(placements.size() == n, "poses and native GPU instance count agree")
            for pose in placements:
                var t: Transform3D = pose
                check(is_equal_approx(t.origin.y,
                    Terrain.sample_height(t.origin.x,t.origin.z)-0.10),
                    "rock base follows single terrain elevation")
                check(Terrain.sample_height(t.origin.x,t.origin.z) >= 9.0,
                    "no rocks scatter across coast or meadow")
            check(dressing.get_child_count() == 0,
                "instanced visual rocks do not spawn physics bodies")
        check(dressing.material_override == visuals.rocky_material,
            "all rocks share one art shader")
        check(visuals.rocky_material.get_shader_parameter(
            "terrain_microdetail") == visuals.texture_resources["terrain"],
            "rock surface reuses original real terrain PNG")
        check(visuals.rocky_material.get_shader_parameter(
            "biome_macrodetail") == visuals.texture_resources["biome"],
            "rock surface reuses original regional PNG")
        check(is_equal_approx(float(visuals.rocky_material.get_shader_parameter(
            "texture_detail_strength")),0.68), "rock grain honors K")
        check(is_equal_approx(float(visuals.rocky_material.get_shader_parameter(
            "biome_layer_strength")),0.78), "rock regional palette honors J")
        visuals.set_texture_detail_enabled(false)
        check(is_zero_approx(float(visuals.rocky_material.get_shader_parameter(
            "texture_detail_strength"))), "K disables rock microtexture")
        visuals.set_biome_layer_enabled(false)
        check(is_zero_approx(float(visuals.rocky_material.get_shader_parameter(
            "biome_layer_strength"))), "J disables rock regional atlas")
        visuals.set_low_quality(true)
        check(not dressing.visible, "V removes whole outcrop instance batch")
        visuals.set_low_quality(false)
        check(dressing.visible, "high detail restores same deterministic rocks")
        check(dressing.multimesh.instance_count <= Rocks.MAX_OUTCROPS,
            "quality toggles do not reallocate rock instances")
    check(scene.terrain.chunk_count() == 64,
        "dressing does not change native terrain mesh budget")
    check(scene.landing_ground != null,
        "landing collider remains independently authoritative")
    scene.queue_free()
    await process_frame
    if faults.is_empty():
        print("GODOT_ROCK_DRESSING_PASS checks=",checks)
        quit(0)
    else:
        for fault in faults:
            push_error("GODOT_ROCK_DRESSING_FAIL: "+fault)
        quit(1)
