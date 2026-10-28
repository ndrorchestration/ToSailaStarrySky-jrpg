extends SceneTree
## P2B edge-fade contract on original cubed-sphere mesh and real mode-5 scene.
const World = preload("res://scenes/planetary_worldmap.tscn")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Builder = preload("res://scripts/planetary/worldmap_cube_tile_mesh.gd")
const Surface = preload("res://scripts/planetary/worldmap_surface_material_preview.gd")
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
var failed: Array[String]=[]
var checks:=0

func check(value:bool,why:String)->void:
    checks+=1
    if not value:
        failed.append(why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for face in ["px","nx","py","ny","pz","nz"]:
        var tile:Dictionary=Tiles.address(face,0.13,-0.17,5)
        var middle:Vector3=Builder.sample_border(tile,6,6,12)
        check(Surface.tile_edge_fraction(tile,middle)>0.45,
            "face "+face+" center remains full-strength")
        for ix in [0,12]:
            var corner:Vector3=Builder.sample_border(tile,ix,6,12)
            check(Surface.tile_edge_fraction(tile,corner)<0.00002,
                "face "+face+" side edge fades to source")
        for iy in [0,12]:
            var top:Vector3=Builder.sample_border(tile,6,iy,12)
            check(Surface.tile_edge_fraction(tile,top)<0.00002,
                "face "+face+" top/bottom edge fades to source")
    var pair:Array[Dictionary]=Study.find_pair("wet_ground")
    check(pair.size()==2,"reviewable real contiguous wet globe tiles exist")
    if pair.is_empty():
        push_error("MODE5_EDGE_FADE_FAIL missing wet tile fixture")
        quit(1)
        return
    var center:Vector2=Tiles.tile_center(pair[0])
    var world:Node3D=World.instantiate()
    root.add_child(world)
    await process_frame
    var state:Dictionary=world.call("snapshot")
    state["flight"]["latDeg"]=center.x
    state["flight"]["lonDeg"]=center.y
    state["flight"]["altitudeKm"]=2.0
    state["flight"]["headingDeg"]=90.0
    state["mode"]="tiles"
    world.call("_apply_state",state)
    world.call("_refresh_chart")
    world.call("_update_view")
    var stream:Node3D=world.get_node("NativeCubedSphereTerrain")
    var original:Dictionary=world.call("snapshot")
    var old_stats:Dictionary=stream.call("stats")
    check(world.call("set_surface_review","wet_ground"),
        "real globe accepts one explicit wet look")
    var current:Dictionary=stream.call("stats")
    check(str(current["review_key"])!="","exact one active tile receives new candidate")
    var shaded:=0
    for tile_node in stream.get_children():
        var land:=tile_node.get_node_or_null("SphericalLand") as MeshInstance3D
        if land==null:
            continue
        if land.material_override is ShaderMaterial:
            shaded+=1
            var mat:ShaderMaterial=land.material_override
            check(is_equal_approx(float(
                mat.get_shader_parameter("tile_edge_blend_width")),0.08),
                "live shader receives bounded 8pct face-UV edge fade")
            var tile:Dictionary=tile_node.get_meta("surface_review_tile")
            var bounds:Vector4=mat.get_shader_parameter("tile_face_bounds")
            var count:int=Tiles.validate_tile(tile)
            var step:float=2.0/float(count)
            check(is_equal_approx(bounds.y-bounds.x,step)
                and is_equal_approx(bounds.w-bounds.z,step),
                "shader edge-UV bounds reflect true tile level")
            var original_mesh:Mesh=land.mesh
            mat.set_shader_parameter("tile_edge_blend_width",0.0)
            check(is_zero_approx(float(mat.get_shader_parameter("tile_edge_blend_width"))),
                "same shader exactly reproduces previous unfeathered P2")
            mat.set_shader_parameter("tile_edge_blend_width",0.22)
            check(land.mesh==original_mesh,
                "edge blend does not rebuild or move terrain vertices")
    check(shaded==1,"exactly one original active globe tile is affected")
    check(int(current["visible"])<=32 and int(current["cache_size"])<=64,
        "32/64 original budget unchanged by edge fade")
    check(int(current["generated"])==int(old_stats["generated"]),
        "no mesh generated merely by selecting material")
    check(world.call("snapshot")==original,
        "no navigation, save or discovery state mutated")
    stream.call("refresh",world.call("get_flight_state"))
    var unchanged:Dictionary=stream.call("stats")
    check(str(unchanged["review_key"])==str(current["review_key"]),
        "same selected wet tile survives stream refresh")
    check(world.call("set_surface_review","",false),
        "original surface material can be restored")
    var all_restored:=true
    for tile_node in stream.get_children():
        var land:=tile_node.get_node_or_null("SphericalLand") as MeshInstance3D
        if land!=null:
            all_restored=all_restored and land.material_override is StandardMaterial3D
    check(all_restored,"all original tile material instances restored")
    check(world.call("snapshot")==original,"restoring material does not mutate save")
    # Explicit regression: previous P2 snow rendering remains unfeathered.
    var snow_pairs:Array[Dictionary]=Study.find_pair("snow")
    check(snow_pairs.size()==2,"original P2 snow tile test remains available")
    if snow_pairs.size()==2:
        var snow:Vector2=Tiles.tile_center(snow_pairs[0])
        var snow_state:Dictionary=world.call("snapshot")
        snow_state["flight"]["latDeg"]=snow.x
        snow_state["flight"]["lonDeg"]=snow.y
        world.call("_apply_state",snow_state)
        world.call("_refresh_chart")
        check(world.call("set_surface_review","snow"),
            "original P2 snow look can still be selected")
        var snow_count:=0
        for node in stream.get_children():
            var land_snow:=node.get_node_or_null("SphericalLand") as MeshInstance3D
            if land_snow!=null and land_snow.material_override is ShaderMaterial:
                snow_count+=1
                var snow_mat:ShaderMaterial=land_snow.material_override
                check(is_zero_approx(float(snow_mat.get_shader_parameter(
                    "tile_edge_blend_width"))),
                    "snow keeps original fully visible P2 shader")
        check(snow_count==1,"one original snow tile remains available")
    world.queue_free()
    await process_frame
    if failed.is_empty():
        print("GODOT_MODE5_EDGE_FADE_CONTRACT_PASS checks=",checks,
            " globe_faces=6 material_tiles=1 original_geometry=true")
        quit(0)
    else:
        for line in failed:
            push_error("GODOT_MODE5_EDGE_FADE_FAIL "+line)
        quit(1)
