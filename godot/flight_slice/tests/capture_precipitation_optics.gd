extends SceneTree
## Actual 960x640 Compatibility OpenGL receipts. No gameplay world or scene edits.
const Study = preload("res://precipitation_study.gd")
var failed: bool = false

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> Image:
    for step in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _changed(a: Image, b: Image) -> int:
    var delta: int = 0
    for y in range(110,640,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y) != b.get_pixel(x,y):
                delta += 1
    return delta

func _sky_changed(a: Image,b: Image) -> int:
    var delta: int=0
    for y in range(0,72,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y) != b.get_pixel(x,y):
                delta+=1
    return delta

func _save(image: Image,name: String) -> void:
    var filepath: String = ProjectSettings.globalize_path(
        "res://evidence/precipitation-review/"+name)
    if image == null or image.get_size() != Vector2i(960,640) \
            or image.save_png(filepath) != OK:
        failed=true
        push_error("PRECIPITATION_CAPTURE_FAIL: "+name)
    else:
        print("NATIVE_PRECIPITATION_CAPTURE: ",name," 960x640 NONCANON")

func _capture() -> void:
    var folder: String = ProjectSettings.globalize_path(
        "res://evidence/precipitation-review")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("PRECIPITATION_CAPTURE_FOLDER_FAIL")
        quit(1)
        return
    var scene:=Node3D.new()
    root.add_child(scene)
    var study:=Study.new()
    scene.add_child(study)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color(0.29,0.40,0.52)
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color(0.55,0.68,0.82)
    environment.ambient_light_energy=0.68
    environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled=false
    environment.fog_light_color=Color(0.43,0.54,0.62)
    environment.fog_density=0.028
    environment.fog_sky_affect=0.0
    var world_environment:=WorldEnvironment.new()
    world_environment.environment=environment
    scene.add_child(world_environment)
    var sun:=DirectionalLight3D.new()
    sun.light_color=Color(0.89,0.91,0.98)
    sun.light_energy=1.07
    scene.add_child(sun)
    sun.look_at(-Study.SUN_DIRECTION.normalized(),Vector3.UP)
    var camera:=Camera3D.new()
    scene.add_child(camera)
    camera.current=true
    camera.fov=58.0
    camera.far=145.0
    camera.position=Vector3(-6.0,11.0,25.0)
    camera.look_at(Vector3(0.0,2.1,-1.0),Vector3.UP)
    study.set_weather_mode(0)
    study.set_optics_strength(0.0)
    var snow_base: Image=await _frame()
    study.set_optics_strength(1.0)
    var snow_optics: Image=await _frame()
    _save(snow_base,"snow-plain.png")
    _save(snow_optics,"snow-crust.png")
    var snow_delta: int=_changed(snow_base,snow_optics)
    var snow_sky_delta: int=_sky_changed(snow_base,snow_optics)
    print("NATIVE_SNOW_OPTICS_PAIR_DELTA pixels=",snow_delta,
        " sky_drift=",snow_sky_delta)
    if snow_delta < 200 or snow_sky_delta != 0:
        failed=true
        push_error("NATIVE_SNOW_OPTICS_UNREADABLE_OR_SKY_DRIFT")
    study.set_low_quality(true)
    study.set_optics_strength(0.0)
    var snow_low_old: Image=await _frame()
    study.set_optics_strength(1.0)
    var snow_low_new: Image=await _frame()
    var snow_low_delta: int=_changed(snow_low_old,snow_low_new)
    print("NATIVE_SNOW_LOW_DELTA pixels=",snow_low_delta)
    if snow_low_delta != 0:
        failed=true
        push_error("NATIVE_SNOW_LOW_QUALITY_CHANGED")
    study.set_low_quality(false)
    study.set_weather_mode(1)
    study.set_optics_strength(0.0)
    var dry_ground: Image=await _frame()
    study.set_optics_strength(1.0)
    var rain_wet: Image=await _frame()
    _save(dry_ground,"rain-dry-ground.png")
    _save(rain_wet,"rain-soaked-ground.png")
    var rain_delta: int=_changed(dry_ground,rain_wet)
    var rain_sky_delta: int=_sky_changed(dry_ground,rain_wet)
    print("NATIVE_RAIN_GROUND_PAIR_DELTA pixels=",rain_delta,
        " sky_drift=",rain_sky_delta)
    if rain_delta < 200 or rain_sky_delta != 0:
        failed=true
        push_error("NATIVE_RAIN_WETNESS_UNREADABLE_OR_SKY_DRIFT")
    study.set_low_quality(true)
    study.set_optics_strength(0.0)
    var rain_low_old: Image=await _frame()
    study.set_optics_strength(1.0)
    var rain_low_new: Image=await _frame()
    var rain_low_delta: int=_changed(rain_low_old,rain_low_new)
    print("NATIVE_RAIN_LOW_DELTA pixels=",rain_low_delta)
    if rain_low_delta != 0:
        failed=true
        push_error("NATIVE_RAIN_LOW_QUALITY_CHANGED")
    study.set_low_quality(false)
    # The fog belongs to environmental presentation, never terrain geometry.
    environment.fog_enabled=true
    var misty_ground: Image=await _frame()
    _save(misty_ground,"rain-mist-ground.png")
    var mist_delta: int=_changed(rain_wet,misty_ground)
    print("NATIVE_RAIN_MIST_PAIR_DELTA pixels=",mist_delta)
    if mist_delta < 300:
        failed=true
        push_error("NATIVE_RAIN_MIST_NOT_VISIBLE")
    camera.position=Vector3(13.0,5.8,27.0)
    camera.look_at(Vector3(0.0,2.0,-1.0),Vector3.UP)
    var grazing: Image=await _frame()
    _save(grazing,"rain-mist-grazing.png")
    print("NATIVE_PRECIPITATION_REVIEW_PASS modes=2 mist=detached")
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
