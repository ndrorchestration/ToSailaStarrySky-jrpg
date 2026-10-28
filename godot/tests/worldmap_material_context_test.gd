extends SceneTree
## MATERIAL-P0 S1: exact native globe biome data -> non-authoritative
## surface-material intent. Deliberately DOES NOT instantiate a shader.
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
var failed: Array[String] = []
var checks: int = 0

func check(ok: bool, label: String) -> void:
    checks+=1
    if not ok:
        failed.append(label)

func _initialize() -> void:
    var selected: Dictionary = {}
    for lat in [-89.0,-65.0,-35.0,0.0,20.0,50.0,82.0]:
        for lon in range(-180,180,12):
            var sample: Dictionary = Cart.sample(lat,float(lon))
            var kind: String = str(sample["biome"])
            if not selected.has(kind):
                selected[kind]=Vector2(lat,float(lon))
    check(selected.has("snow"),"sampled real fixture includes snow")
    check(selected.has("arid") or selected.has("shore"),"sampled real fixture includes sand")
    check(selected.has("woodland") or selected.has("grassland") or selected.has("rainforest"),
        "sampled real fixture includes rain-wet land")
    check(selected.has("deep_ocean") or selected.has("open_ocean") or selected.has("sea_ice"),
        "sampled real fixture includes excluded water classes")
    var first_sand: String = "arid" if selected.has("arid") else "shore"
    var sand: Vector2 = selected.get(first_sand,Vector2.ZERO)
    var dry: Dictionary = Context.resolve(sand.x,sand.y,"clear",0.0,WIND,SUN)
    check(dry.get("material","") == "sand","arid or shore maps to sand optics")
    check(is_zero_approx(float(dry.get("wetness_request",-1))),"dry sand is not fabricated wet")
    var repeated: Dictionary = Context.resolve(sand.x,sand.y,"clear",0.0,WIND,SUN)
    check(dry == repeated,"material intent deterministic")
    var snow_point: Vector2 = selected.get("snow",Vector2.ZERO)
    var snow: Dictionary = Context.resolve(snow_point.x,snow_point.y,
        "clear",0.0,WIND,SUN)
    check(snow.get("material","")=="snow","native globe snow selects crust mode")
    var wet_snow: Dictionary = Context.resolve(snow_point.x,snow_point.y,
        "rain",1.0,WIND,SUN)
    check(wet_snow.get("material","")=="snow",
        "temporary weather cannot rewrite existing snow biome")
    var earth_class: String = "woodland" if selected.has("woodland") else (
        "grassland" if selected.has("grassland") else "rainforest")
    var earth: Vector2 = selected.get(earth_class,Vector2.ZERO)
    var temperate: Dictionary = Context.resolve(earth.x,earth.y,"clear",0.0,WIND,SUN)
    check(temperate.get("material","")=="base",
        "humid land without rain does not become wet")
    var raining: Dictionary = Context.resolve(earth.x,earth.y,"rain",0.75,WIND,SUN)
    check(raining.get("material","")=="wet_ground",
        "explicit rain enables earth/stone wet optics")
    check(is_equal_approx(float(raining.get("wetness_request",-1)),0.75),
        "wetness intensity supplied only by explicit weather")
    check(bool(raining.get("fog_requested",false)),
        "visual environment requests fog from weather controller")
    var mist: Dictionary=Context.resolve(earth.x,earth.y,"mist",0.0,WIND,SUN)
    check(mist.get("material","")=="base",
        "mist alone does not paint wet ground")
    check(bool(mist.get("fog_requested",false)),
        "mist atmosphere is separate from terrain shader")
    var ocean_class: String = "sea_ice" if selected.has("sea_ice") else (
        "open_ocean" if selected.has("open_ocean") else "deep_ocean")
    var water_pos: Vector2=selected.get(ocean_class,Vector2.ZERO)
    var ocean: Dictionary=Context.resolve(water_pos.x,water_pos.y,
        "storm",1.0,WIND,SUN)
    check(ocean.get("material","")=="base",
        "ocean and sea ice are not covered in rainy land material")
    check(is_zero_approx(float(ocean.get("wetness_request",-1))),
        "ocean not disguised as wet soil")
    var cheap: Dictionary=Context.resolve(earth.x,earth.y,
        "rain",0.75,WIND,SUN,true,true)
    check(is_zero_approx(float(cheap.get("optics_strength",-1))),
        "low-quality mode bypasses all additional optics")
    check(bool(cheap.get("reduced_motion",false)),"frozen motion flag carried forward")
    var wind_axis: Vector2=dry.get("wind_tangent",Vector2.ZERO)
    check(is_equal_approx(wind_axis.length(),1.0),
        "wind normalized in actual local east/north tangent frame")
    for lat in [-90.0,-64.0,0.0,36.0,90.0]:
        var a: Dictionary=Context.resolve(lat,-180.0,
            "rain",0.75,WIND,SUN)
        var z: Dictionary=Context.resolve(lat,180.0,
            "rain",0.75,WIND,SUN)
        check(a.get("biome","") == z.get("biome",""),
            "original cartography cross-date-line biome invariant")
        check(a.get("material","") == z.get("material",""),
            "material intent cross-date-line invariant")
        check((a.get("wind_tangent",Vector2.ZERO) as Vector2).distance_to(
            z.get("wind_tangent",Vector2.ZERO)) < 0.00001,
            "tangent ripple axis cross-date-line continuous")
    for lat in [-90.0,90.0]:
        var pole_a: Dictionary=Context.resolve(lat,-70.0,"clear",0.0,WIND,SUN)
        var pole_b: Dictionary=Context.resolve(lat,132.0,"clear",0.0,WIND,SUN)
        check(pole_a["material"]==pole_b["material"],
            "exact pole material invariant")
        check((pole_a["wind_tangent"] as Vector2).distance_to(
            pole_b["wind_tangent"]) < 0.00001,"polar tangent convention stable")
    check(Context.resolve(99.0,0.0,"clear",0.0,WIND,SUN).is_empty(),
        "reject invalid latitude without calling cartography assert")
    check(Context.resolve(30.0,0.0,"blizzard",0.0,WIND,SUN).is_empty(),
        "reject unknown weather instead of inventing simulation")
    check(Context.resolve(30.0,0.0,"rain",NAN,WIND,SUN).is_empty(),
        "nonfinite rain fails closed")
    check(Context.resolve(30.0,0.0,"clear",0.0,Vector3.ZERO,SUN).is_empty(),
        "zero wind fails closed")
    check(Context.resolve(30.0,0.0,"clear",0.0,WIND,Vector3.ZERO).is_empty(),
        "zero light fails closed")
    if failed.is_empty():
        print("GODOT_WORLDMAP_MATERIAL_CONTEXT_PASS checks=",checks,
            " source=cartography read_only=true scene_material_applied=false")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_MATERIAL_CONTEXT_FAIL: "+", ".join(failed))
        quit(1)
