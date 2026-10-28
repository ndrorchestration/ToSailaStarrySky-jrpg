extends SceneTree
## MATERIAL-P0 S4: an actual worldmap scene's mode-5 flight renderer.
const WorldScene = preload("res://scenes/planetary_worldmap.tscn")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const State = preload("res://scripts/planetary/worldmap_state.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
var failures: Array[String]=[]
var checks := 0

func check(ok: bool,msg: String) -> void:
    checks+=1
    if not ok:
        failures.append(msg)

func _press(scene: Variant, code: Key) -> void:
    var k:=InputEventKey.new()
    k.pressed=true
    k.keycode=code
    scene._unhandled_input(k)

func _find_interior(kind: String) -> Dictionary:
    # A tile selected from coarser L5 cartography can change class at L7.
    # Use the actual max-level active renderer sampling frame, preferring
    # contiguous same-biome neighbors instead of misleading coastline strips.
    var weather: String="rain" if kind=="wet_ground" else "clear"
    var best: Dictionary={}
    var best_score: int=-1
    for lat in range(-75,76,5):
        for lon in range(-170,171,10):
            var tile: Dictionary=Tiles.tile_at(float(lat),float(lon),7)
            var center: Vector2=Tiles.tile_center(tile)
            var value: Dictionary=Context.resolve(center.x,center.y,
                weather,0.8 if weather=="rain" else 0.0,WIND,SUN)
            if str(value.get("material",""))!=kind:
                continue
            var score: int=0
            for offset in [Vector2i.RIGHT,Vector2i.LEFT,
                    Vector2i.UP,Vector2i.DOWN]:
                var neighbor: Dictionary=Tiles.neighbor(tile,offset.x,offset.y)
                var near: Vector2=Tiles.tile_center(neighbor)
                var next:Dictionary=Context.resolve(near.x,near.y,
                    weather,0.8 if weather=="rain" else 0.0,WIND,SUN)
                if str(next.get("material",""))==kind:
                    score+=1
            if score>best_score:
                best_score=score
                best={"lat":center.x,"lon":center.y}
            if score==4:
                return best
    return best

func _run() -> void:
    var scene: Variant=WorldScene.instantiate()
    root.add_child(scene)
    await process_frame
    check(scene.get_mode()=="globe","initial scene stays original globe")
    check(not bool(scene.material_review_status().get("enabled",true)),
        "visual study always disabled on scene startup")
    check(not scene.snapshot().has("material_review"),
        "preview save schema excludes ephemeral surface toggle")
    var where: Dictionary=_find_interior("snow")
    check(not where.is_empty(),"native cartography yields a snow tile")
    if where.is_empty():
        scene.queue_free()
        quit(1)
        return
    var saved: Dictionary=scene.snapshot()
    saved["flight"]["latDeg"]=where["lat"]
    saved["flight"]["lonDeg"]=where["lon"]
    saved["flight"]["altitudeKm"]=2.0
    scene._apply_state(saved)
    scene._refresh_chart()
    scene._update_view()
    _press(scene,KEY_5)
    var stream: Variant=scene.get_node("NativeCubedSphereTerrain") as Node3D
    check(scene.get_mode()=="tiles" and stream.visible,
        "actual 5-key opens native cubed-sphere flight view")
    var original_save: String=State.encode(scene.snapshot())
    var before: Dictionary=stream.stats()
    var sample_keys: Array=stream.active_keys()
    var first_node: Node3D=stream.get_child(0)
    var first_land: MeshInstance3D=first_node.get_node("SphericalLand")
    var original_mesh: Mesh=first_land.mesh
    _press(scene,KEY_B)
    var enabled: Dictionary=scene.material_review_status()
    check(bool(enabled["enabled"]),"B enables visual review in real game scene")
    check(str(enabled["selected_material"])=="snow",
        "tile selected from actual spherical snow class")
    check(str(enabled["selected_key"])!="",
        "material selection resolves a native active tile key")
    var assigned := 0
    var weather_meshes: Array[Mesh]=[]
    for node in stream.get_children():
        var land:=node.get_node("SphericalLand") as MeshInstance3D
        weather_meshes.append(land.mesh)
        if land.material_override is ShaderMaterial:
            assigned+=1
            check((land.material_override as ShaderMaterial).shader.resource_path ==
                "res://shaders/planetary_surface_study.gdshader",
                "real tile uses the reviewed P2 optical shader only")
        var sea:=node.get_node_or_null("SphericalOcean") as MeshInstance3D
        if sea!=null:
            check(sea.material_override is ShaderMaterial,
                "all original ocean ShaderMaterials preserved")
    check(assigned==1,"strictly one active spherical land tile receives study")
    check(stream.active_keys()==sample_keys,"B did not recalculate tile keys")
    check(int(stream.stats()["generated"])==int(before["generated"]),
        "B did not generate new terrain or exceed tile cache budget")
    check(original_mesh==first_land.mesh,"toggling preserves real mesh identity")
    check(State.encode(scene.snapshot())==original_save,
        "material review cannot modify worldmap durable save")
    var same: Dictionary=scene.snapshot()
    same["flight"]["lonDeg"]=float(same["flight"]["lonDeg"])+0.012
    scene._apply_state(same)
    scene._refresh_chart()
    scene._update_view()
    check(int(stream.stats()["visible"])<=32 and
        int(stream.stats()["cache_size"])<=64,
        "movement preserves stream and cache budget")
    check(bool(scene.material_review_status()["enabled"]),
        "camera movement retains transient material review")
    _press(scene,KEY_B)
    check(not bool(scene.material_review_status()["enabled"]),
        "B toggle off restores original graphics contract")
    var no_shaders:=true
    for node in stream.get_children():
        var land:=node.get_node("SphericalLand") as MeshInstance3D
        no_shaders=no_shaders and land.material_override is StandardMaterial3D
    check(no_shaders,"every visible tile restored to the exact default material type")
    var old_scene_save: String=State.encode(scene.snapshot())
    _press(scene,KEY_J)
    check(str(scene.material_review_status()["weather"])=="rain",
        "J chooses explicit rain look without deriving it from climate humidity")
    check(State.encode(scene.snapshot())==old_scene_save,
        "J weather review never persists in game save")
    check(not stream.set_material_review(true,"rain",NAN),
        "nonfinite precipitation request rejected without changing controls")
    stream.set_material_review(true,"rain",0.8,true)
    stream.refresh(scene.get_flight_state())
    check(str(stream.review_stats()["selected_key"])=="",
        "V low-quality bypass makes material opt-in entirely invisible")
    var wet: Dictionary=_find_interior("wet_ground")
    check(not wet.is_empty(),"worldmap contains valid explicitly rain-wet land tile")
    if not wet.is_empty():
        var s: Dictionary=scene.snapshot()
        s["flight"]["latDeg"]=wet["lat"]
        s["flight"]["lonDeg"]=wet["lon"]
        scene._apply_state(s)
        scene._refresh_chart()
        _press(scene,KEY_B)
        check(str(scene.material_review_status()["selected_material"])=="wet_ground",
            "real mode-5 flight camera selects wet earth only under explicit rain")
    _press(scene,KEY_1)
    check(scene.get_mode()=="globe" and not stream.visible,
        "other map modes never expose material review tile")
    check(not scene.snapshot().has("weather") and
        not scene.snapshot().has("material_review"),
        "no novel save fields admitted")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_WORLDMAP_MATERIAL_MODE5_PASS checks=",checks,
            " single_active_tile=true weather=volatile source=P2")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_MATERIAL_MODE5_FAIL "+", ".join(failures))
        quit(1)

func _initialize() -> void:
    call_deferred("_run")
