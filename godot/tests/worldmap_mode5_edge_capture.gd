extends SceneTree
## True real-worldmap mode-5 camera, one actual wet tile:
## source -> hard-edged old effect -> new smooth edge blend.
const World = preload("res://scenes/planetary_worldmap.tscn")
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
var failed:=false

func _initialize()->void:
    call_deferred("_run")

func _frame()->Image:
    for i in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _diff(a:Image,b:Image)->int:
    var changed:=0
    for y in range(108,560,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):
                changed+=1
    return changed

func _top_sky_drift(a:Image,b:Image)->int:
    var changed:=0
    for y in range(0,36,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):
                changed+=1
    return changed

func _save(image:Image,name:String)->void:
    var path:String=ProjectSettings.globalize_path(
        "res://evidence/mode5-edge-review/"+name)
    if image.get_size()!=Vector2i(960,640) or image.save_png(path)!=OK:
        failed=true
        push_error("MODE5_EDGE_IMAGE_FAIL "+name)

func _run()->void:
    var dir:String=ProjectSettings.globalize_path("res://evidence/mode5-edge-review")
    if DirAccess.make_dir_recursive_absolute(dir)!=OK:
        push_error("MODE5_EDGE_FOLDER_FAIL")
        quit(1)
        return
    var pair:Array[Dictionary]=Study.find_pair("wet_ground")
    if pair.size()!=2:
        push_error("MODE5_EDGE_NO_WET_PAIR")
        quit(1)
        return
    var coord:Vector2=Tiles.tile_center(pair[0])
    var world:Node3D=World.instantiate()
    root.add_child(world)
    await process_frame
    world.set_process(false)
    var state:Dictionary=world.call("snapshot")
    state["flight"]["latDeg"]=coord.x
    state["flight"]["lonDeg"]=coord.y
    state["flight"]["altitudeKm"]=2.0
    state["flight"]["headingDeg"]=90.0
    state["mode"]="tiles"
    world.call("_apply_state",state)
    world.call("_refresh_chart")
    world.call("_update_view")
    var hud:=world.get_node_or_null("WorldMapUI") as CanvasLayer
    if hud!=null:
        hud.visible=false # Only remove changing labels from image QA.
    var stream:Node3D=world.get_node("NativeCubedSphereTerrain")
    var original:Image=await _frame()
    _save(original,"wet-original.png")
    var orig_save:Dictionary=world.call("snapshot")
    if not world.call("set_surface_review","wet_ground",false):
        failed=true
        push_error("MODE5_EDGE_SET_REVIEW_FAIL")
    var selected_key:String=str(stream.call("stats")["review_key"])
    if selected_key=="":
        failed=true
        push_error("MODE5_EDGE_MISSING_LIVE_TILE")
        world.queue_free()
        quit(1)
        return
    var target:Node3D=null
    for node in stream.get_children():
        if node.has_meta("surface_review_tile"):
            var tile:Dictionary=node.get_meta("surface_review_tile")
            if Tiles.key(tile)==selected_key:
                target=node
                break
    if target==null:
        push_error("MODE5_EDGE_TARGET_NOT_FOUND")
        world.queue_free()
        quit(1)
        return
    var land:=target.get_node("SphericalLand") as MeshInstance3D
    var original_mesh:Mesh=land.mesh
    var mat:=land.material_override as ShaderMaterial
    if mat==null:
        push_error("MODE5_EDGE_SHADER_MISSING")
        world.queue_free()
        quit(1)
        return
    mat.set_shader_parameter("tile_edge_blend_width",0.0)
    var old_hard:Image=await _frame()
    _save(old_hard,"wet-hard-tile.png")
    mat.set_shader_parameter("tile_edge_blend_width",0.08)
    var feather_08:Image=await _frame()
    _save(feather_08,"wet-feather-08.png")
    _save(feather_08,"wet-feathered-tile.png") # Actual live default
    var new_soft:Image=feather_08
    mat.set_shader_parameter("tile_edge_blend_width",0.14)
    var feather_14:Image=await _frame()
    _save(feather_14,"wet-feather-14.png")
    mat.set_shader_parameter("tile_edge_blend_width",0.22)
    var feather_22:Image=await _frame()
    _save(feather_22,"wet-feather-22.png")
    mat.set_shader_parameter("tile_edge_blend_width",0.08)
    var change:int=_diff(old_hard,new_soft)
    var effect:int=_diff(original,new_soft)
    var sky_changed:int=_top_sky_drift(old_hard,new_soft)
    print("MODE5_EDGE_WIDTH_SWEEP width08_from_original=",_diff(original,feather_08),
        " width14_from_original=",_diff(original,feather_14),
        " width22_from_original=",_diff(original,feather_22))
    print("MODE5_EDGE_A_B_CHANGED pixels=",change,
        " source_to_feather=",effect,
        " sky_drift=",sky_changed," selected_key=",selected_key)
    if change<40 or effect<25 or sky_changed!=0:
        failed=true
        push_error("MODE5_EDGE_A_B_UNREADABLE_OR_SKY_DRIFT")
    if world.call("snapshot")!=orig_save or land.mesh!=original_mesh:
        failed=true
        push_error("MODE5_EDGE_STATE_OR_MESH_MUTATED")
    if not world.call("set_surface_review","",false):
        failed=true
        push_error("MODE5_EDGE_RESTORE_REJECTED")
    if land.material_override is not StandardMaterial3D:
        failed=true
        push_error("MODE5_EDGE_ORIGINAL_NOT_RESTORED")
    print("GODOT_MODE5_EDGE_NATIVE_REVIEW_PASS frames=6 real_scene=true",
        " actual_cube_tile=true")
    world.queue_free()
    await process_frame
    quit(1 if failed else 0)
