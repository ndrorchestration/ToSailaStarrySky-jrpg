extends SceneTree
## MATERIAL-P0 S3: actual curved 3D native worldmap mode-4 mesh, matched
## Compatibility GL weather/surface A/B. Does not enter main world scene.
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const Adapter = preload("res://scripts/planetary/worldmap_material_render_adapter.gd")
const LocalPatch = preload("res://scripts/planetary/worldmap_local_terrain.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
var failed: bool=false

func _initialize() -> void:
    call_deferred("_run")

func _frame() -> Image:
    for i in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _delta(a: Image,b: Image) -> int:
    var changes: int=0
    for y in range(0,640,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):
                changes+=1
    return changes

func _sky_delta(a: Image,b: Image) -> int:
    var changes: int=0
    for y in range(0,70,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):
                changes+=1
    return changes

func _foreground_pixels(frame: Image) -> int:
    # Guard against the exact all-sky failure that can falsely return a
    # low-quality pixel-perfect image without rendering any native terrain.
    var background: Color=frame.get_pixel(0,0)
    var changed: int=0
    for y in range(0,640,2):
        for x in range(0,960,2):
            if frame.get_pixel(x,y)!=background:
                changed+=1
    return changed

func _save(img: Image,name: String) -> void:
    var file: String=ProjectSettings.globalize_path("res://evidence/material-review/"+name)
    if img==null or img.get_size()!=Vector2i(960,640) or img.save_png(file)!=OK:
        failed=true
        push_error("WORLDMAP_MATERIAL_VISUAL_SAVE_FAIL "+name)
    else:
        print("WORLDMAP_MATERIAL_CAPTURE: ",name," 960x640 native mode4-geometry")

func _pick(kind: Array[String]) -> Vector2:
    for lat in [-89.0,-65.0,-35.0,0.0,20.0,50.0,82.0]:
        for lon in range(-180,180,12):
            if kind.has(str(Cart.sample(lat,float(lon))["biome"])):
                return Vector2(lat,float(lon))
    return Vector2(999.0,999.0)

func _run() -> void:
    var dir: String=ProjectSettings.globalize_path("res://evidence/material-review")
    if DirAccess.make_dir_recursive_absolute(dir)!=OK:
        push_error("WORLDMAP_MATERIAL_VISUAL_FOLDER_FAIL")
        quit(1)
        return
    var world:=Node3D.new()
    world.name="NoncanonicalNativeLowSkyMaterialReview"
    root.add_child(world)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color(0.25,0.39,0.53)
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color(0.64,0.72,0.83)
    environment.ambient_light_energy=0.76
    environment.fog_enabled=false
    environment.fog_light_color=Color(0.50,0.61,0.68)
    environment.fog_density=0.026
    environment.fog_sky_affect=0.0
    var sky:=WorldEnvironment.new()
    sky.environment=environment
    world.add_child(sky)
    var key:=DirectionalLight3D.new()
    key.light_color=Color(1.0,0.90,0.78)
    key.light_energy=1.20
    world.add_child(key)
    var camera:=Camera3D.new()
    world.add_child(camera)
    camera.current=true
    camera.fov=61.0
    camera.near=0.01
    camera.far=45.0
    camera.position=Vector3(0.12,0.62,1.22)
    camera.look_at(Vector3(0.0,-0.016,-0.12),Vector3.UP)
    var cases: Array[Dictionary]=[
        {"name":"snow","kinds":["snow"],"weather":"clear","rain":0.0},
        {"name":"sand","kinds":["arid","shore"],"weather":"clear","rain":0.0},
        {"name":"rain","kinds":["woodland","grassland","rainforest"],
            "weather":"rain","rain":0.75}
    ]
    var checks: int=0
    for item in cases:
        environment.fog_enabled=false
        var name: String=str(item["name"])
        var classes: Array[String]=[]
        for s in item["kinds"]:
            classes.append(str(s))
        var coord: Vector2=_pick(classes)
        if coord.x>90.0:
            failed=true
            push_error("WORLDMAP_MATERIAL_VISUAL_BIOME_MISSING "+name)
            continue
        var context: Dictionary=Context.resolve(coord.x,coord.y,
            str(item["weather"]),float(item["rain"]),WIND,SUN)
        var patch:=LocalPatch.new()
        world.add_child(patch)
        # LowSkyTerrainDevelopmentPatch deliberately defaults to invisible
        # because the actual game scene enables it only in mode 4. This
        # detached native GL fixture must make that single mode explicit.
        patch.visible=true
        patch.position=Vector3.ZERO
        patch.rebuild({"latDeg":coord.x,"lonDeg":coord.y},30.0,48)
        var land:=patch.get_node("CurvedTerrainMesh") as MeshInstance3D
        var original_mesh: Mesh=land.mesh
        var ocean: Mesh=(patch.get_node("OceanSurface") as MeshInstance3D).mesh
        var mat: ShaderMaterial=Adapter.attach_to_review_patch(
            patch,context,coord.x,coord.y)
        if mat==null or str(context.get("material",""))=="base":
            failed=true
            push_error("WORLDMAP_MATERIAL_VISUAL_BIND_FAIL "+name)
            patch.queue_free()
            await process_frame
            continue
        # One light in exactly the same local frame as shader sun.
        var local_sun: Vector3=mat.get_shader_parameter("sun_direction")
        key.look_at(-local_sun,Vector3.UP)
        mat.set_shader_parameter("optics_strength",0.0)
        var baseline: Image=await _frame()
        var foreground: int=_foreground_pixels(baseline)
        print("WORLDMAP_MATERIAL_FOREGROUND name=",name,
            " pixels=",foreground)
        if foreground<1300:
            failed=true
            push_error("WORLDMAP_MATERIAL_INVISIBLE_TERRAIN "+name)
        mat.set_shader_parameter("optics_strength",1.0)
        var candidate: Image=await _frame()
        _save(baseline,"worldmap-"+name+"-plain.png")
        _save(candidate,"worldmap-"+name+"-optics.png")
        var changed: int=_delta(baseline,candidate)
        var sky_changed: int=_sky_delta(baseline,candidate)
        print("WORLDMAP_MATERIAL_PAIR name=",name," pixels=",changed,
            " sky_drift=",sky_changed," biome=",context["biome"])
        if changed<60 or sky_changed!=0:
            failed=true
            push_error("WORLDMAP_MATERIAL_VISUAL_MISSING_OR_SKY_DRIFT "+name)
        mat.set_shader_parameter("low_quality",true)
        mat.set_shader_parameter("optics_strength",0.0)
        var low_old: Image=await _frame()
        mat.set_shader_parameter("optics_strength",1.0)
        var low_new: Image=await _frame()
        var low_delta: int=_delta(low_old,low_new)
        print("WORLDMAP_MATERIAL_LOW name=",name," pixels=",low_delta)
        if low_delta!=0:
            failed=true
            push_error("WORLDMAP_MATERIAL_VISUAL_LOW_DRIFT "+name)
        mat.set_shader_parameter("low_quality",false)
        if name=="rain":
            environment.fog_enabled=true
            var mist: Image=await _frame()
            _save(mist,"worldmap-rain-mist.png")
            var fog_change: int=_delta(candidate,mist)
            print("WORLDMAP_MATERIAL_FOG pixels=",fog_change)
            if fog_change<200:
                failed=true
                push_error("WORLDMAP_MATERIAL_FOG_NOT_VISIBLE")
        checks+=1
        if land.mesh != original_mesh or (patch.get_node("OceanSurface") as MeshInstance3D).mesh != ocean:
            failed=true
            push_error("WORLDMAP_MATERIAL_GEOMETRY_MUTATION")
        if not Adapter.release_review_patch(patch,mat):
            failed=true
            push_error("WORLDMAP_MATERIAL_ROLLBACK_FAIL")
        patch.queue_free()
        await process_frame
    print("GODOT_WORLDMAP_MATERIAL_VISUAL_PASS cases=",checks,
        " actual_curved_mode4=true game_scene_modified=false")
    world.queue_free()
    await process_frame
    quit(1 if failed or checks!=3 else 0)
