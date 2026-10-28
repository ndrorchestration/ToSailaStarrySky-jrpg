extends SceneTree
## Native S4 visual evidence in the real worldmap scene + actual mode-5 flight
## camera. Hud labels differ on B toggle so compare only central terrain ROI.
const World = preload("res://scenes/planetary_worldmap.tscn")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
var failed:=false

func _initialize() -> void:
    call_deferred("_run")

func _press(node: Node3D,code: Key) -> void:
    var event:=InputEventKey.new()
    event.pressed=true
    event.keycode=code
    node._unhandled_input(event)

func _capture() -> Image:
    for i in range(6):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _diff(a: Image,b: Image) -> int:
    var changed:=0
    for y in range(140,535,2):
        for x in range(50,910,2):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):
                changed+=1
    return changed

func _save(img: Image,kind: String) -> void:
    var file:String=ProjectSettings.globalize_path(
        "res://evidence/mode5-material-review/"+kind+".png")
    if img.get_size()!=Vector2i(960,640) or img.save_png(file)!=OK:
        failed=true
        push_error("MODE5_MATERIAL_CAPTURE_FAIL "+kind)

func _find(kind: String) -> Dictionary:
    var look: String="rain" if kind=="wet_ground" else "clear"
    for lat in range(-75,76,5):
        for lon in range(-170,171,10):
            var tile:=Tiles.tile_at(float(lat),float(lon),5)
            var center:=Tiles.tile_center(tile)
            var material:Dictionary=Context.resolve(center.x,center.y,
                look,0.8 if look=="rain" else 0.0,WIND,SUN)
            if str(material.get("material",""))==kind:
                return {"lat":center.x,"lon":center.y}
    return {}

func _run() -> void:
    var folder:=ProjectSettings.globalize_path("res://evidence/mode5-material-review")
    if DirAccess.make_dir_recursive_absolute(folder)!=OK:
        push_error("MODE5_MATERIAL_FOLDER_FAIL")
        quit(1)
        return
    var scene: Node3D=World.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var total:=0
    for family in ["snow","wet_ground"]:
        var at: Dictionary=_find(family)
        if at.is_empty():
            failed=true
            push_error("MODE5_MATERIAL_NO_BIOME "+family)
            continue
        var st:Dictionary=scene.snapshot()
        st["flight"]["latDeg"]=at["lat"]
        st["flight"]["lonDeg"]=at["lon"]
        st["flight"]["altitudeKm"]=2.0
        st["flight"]["headingDeg"]=90.0
        scene._apply_state(st)
        scene._refresh_chart()
        scene._update_view()
        if scene.get_mode()!="tiles":
            _press(scene,KEY_5)
        if family=="wet_ground":
            _press(scene,KEY_J)
        var cam: Camera3D=scene.get_node("WorldMapOrbitCamera")
        var original_pose:=cam.position
        var original_save:=scene.snapshot()
        var before:Image=await _capture()
        _save(before,family+"-off")
        _press(scene,KEY_B)
        var review:Dictionary=scene.material_review_status()
        if str(review["selected_material"])!=family:
            failed=true
            push_error("MODE5_MATERIAL_NO_SELECTED_TILE "+family)
        var after:Image=await _capture()
        _save(after,family+"-on")
        var difference:=_diff(before,after)
        print("MODE5_NATIVE_MATERIAL_PAIR family=",family," changed=",difference,
            " tile=",review["selected_key"])
        if difference<25 or difference>80000:
            failed=true
            push_error("MODE5_MATERIAL_VISUAL_DELTA_UNBOUNDED "+family)
        if scene.snapshot()!=original_save or cam.position!=original_pose:
            failed=true
            push_error("MODE5_MATERIAL_SAVE_OR_CAMERA_MUTATION "+family)
        var stream:=scene.get_node("NativeCubedSphereTerrain")
        var on_stats:Dictionary=stream.stats()
        stream.set_material_review(true,
            "rain" if family=="wet_ground" else "clear",
            0.8 if family=="wet_ground" else 0.0,true)
        stream.refresh(scene.get_flight_state())
        var low_a:Image=await _capture()
        stream.set_material_review(false,
            "rain" if family=="wet_ground" else "clear",
            0.8 if family=="wet_ground" else 0.0,true)
        stream.refresh(scene.get_flight_state())
        var low_b:Image=await _capture()
        var low_delta:=_diff(low_a,low_b)
        print("MODE5_NATIVE_MATERIAL_LOW family=",family," pixels=",low_delta)
        if low_delta!=0:
            failed=true
            push_error("MODE5_MATERIAL_LOW_DRIFT "+family)
        var refreshed:Dictionary=stream.stats()
        if refreshed["visible"]>32 or refreshed["cache_size"]>64 \
                or refreshed["generated"]!=on_stats["generated"]:
            failed=true
            push_error("MODE5_MATERIAL_TILE_BUDGET_OR_REBUILD "+family)
        # Restore real scene controls to default before another fixture.
        if bool(scene.material_review_status()["enabled"]):
            _press(scene,KEY_B)
        total+=1
    print("GODOT_MODE5_MATERIAL_NATIVE_CAPTURE_PASS cases=",total,
        " real_scene=true mode5_camera=true")
    scene.queue_free()
    await process_frame
    quit(1 if failed or total!=2 else 0)
