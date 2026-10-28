extends SceneTree
## MATERIAL-P0 S2 native mesh/material integrity. Real mode-4 worldmap
## geometry, not a separate candidate dune mesh.
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const Adapter = preload("res://scripts/planetary/worldmap_material_render_adapter.gd")
const LocalPatch = preload("res://scripts/planetary/worldmap_local_terrain.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
var failures: Array[String]=[]
var checked: int=0

func check(value: bool, reason: String) -> void:
    checked+=1
    if not value:
        failures.append(reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var kinds: Dictionary={}
    for lat in [-89.0,-65.0,-35.0,0.0,20.0,50.0,82.0]:
        for lon in range(-180,180,12):
            var biome: String=str(Cart.sample(lat,float(lon))["biome"])
            if not kinds.has(biome):
                kinds[biome]=Vector2(lat,float(lon))
    var chosen: Array[Dictionary]=[]
    for candidates in [["snow"],["arid","shore"],
            ["woodland","grassland","rainforest"]]:
        for kind in candidates:
            if kinds.has(kind):
                var coord: Vector2=kinds[kind]
                var weather: String="rain" if candidates.size()==3 else "clear"
                chosen.append({"pos":coord,"weather":weather})
                break
    check(chosen.size()>=3,"actual native Cart contains three test biomes")
    for entry in chosen:
        var coord: Vector2=entry["pos"]
        var patch := LocalPatch.new()
        root.add_child(patch)
        await process_frame
        patch.rebuild({"latDeg":coord.x,"lonDeg":coord.y},24.0,32)
        var land:=patch.get_node("CurvedTerrainMesh") as MeshInstance3D
        var ocean:=patch.get_node("OceanSurface") as MeshInstance3D
        var initial: PackedVector3Array = (land.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        var vertex_copy:=initial.duplicate()
        var water_ref: Mesh=ocean.mesh
        var state: Dictionary=Context.resolve(coord.x,coord.y,str(entry["weather"]),
            0.7 if str(entry["weather"])=="rain" else 0.0,WIND,SUN)
        var mat: ShaderMaterial=Adapter.attach_to_review_patch(patch,state,coord.x,coord.y)
        check(mat!=null,"actual curved local patch receives real ShaderMaterial")
        if mat!=null:
            check(mat.shader.resource_path=="res://shaders/worldmap_material_optics.gdshader",
                "shader resource is original limited native material adapter")
            var mode: int=int(mat.get_shader_parameter("surface_mode"))
            var expected_mode: int=int(Adapter.MODES.get(str(state["material"]),0))
            check(mode==expected_mode,"native Cart S1 is the authoritative material selector")
            var view_sun: Vector3=mat.get_shader_parameter("sun_direction")
            check(view_sun.is_finite() and absf(view_sun.length()-1.0)<0.00001,
                "world-space sunlight projected onto actual local tangent frame")
            check(Adapter.attach_to_review_patch(patch,state,coord.x,coord.y)==null,
                "adapter refuses to overwrite existing assigned material")
            mat.set_shader_parameter("optics_strength",0.0)
            check(is_zero_approx(float(mat.get_shader_parameter("optics_strength"))),
                "same native mesh material can revert to baseline 0")
            mat.set_shader_parameter("optics_strength",1.0)
            mat.set_shader_parameter("low_quality",true)
            check(mat.get_shader_parameter("low_quality")==true,
                "native worldmap A/B supports V low cost")
        var later: PackedVector3Array=(land.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        check(later==vertex_copy,"terrain vertex heights/indices remain unchanged")
        check(ocean.mesh==water_ref,"real low-sky ocean is unmodified")
        check(patch.get_node_or_null("StaticBody3D")==null,
            "no new gameplay collider installed into map preview")
        check(Adapter.release_review_patch(patch,mat),
            "review material cleanly detaches and restores baseline")
        check(land.material_override==null,"baseline material fully restored")
        patch.queue_free()
        await process_frame
    for lat in [-90.0,-67.0,0.0,38.0,90.0]:
        var a: Vector3=Adapter.local_sun_direction(lat,-180.0,SUN)
        var z: Vector3=Adapter.local_sun_direction(lat,180.0,SUN)
        check(a.distance_to(z)<0.000001,
            "actual local sun direction continuous at date line/poles")
    if failures.is_empty():
        print("GODOT_WORLDMAP_MATERIAL_RENDER_CONTRACT_PASS checks=",checked,
            " geometry=unchanged water=unchanged stage=S2 scene=detached_local_patch")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_MATERIAL_RENDER_CONTRACT_FAIL: "+", ".join(failures))
        quit(1)
