extends SceneTree
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
var failed: Array[String] = []

func check(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label)

func _initialize() -> void:
    var biomes: Dictionary = {}
    var land := 0
    var ocean := 0
    for lat in [-89.0,-65.0,-35.0,0.0,20.0,50.0,82.0]:
        for lon in range(-180,180,12):
            var a := Cart.sample(lat,float(lon))
            var b := Cart.sample(lat,float(lon))
            check(a["biome"] == b["biome"],"deterministic cell")
            check(a["color"] == b["color"],"deterministic color")
            var tone: Color = a["color"]
            check(is_finite(tone.r) and is_finite(tone.g) and is_finite(tone.b) and is_finite(tone.a),"finite RGBA")
            biomes[str(a["biome"])] = true
            if a["land"]:
                land += 1
            else:
                ocean += 1
    check(biomes.size() >= 5,"diverse biomes")
    check(land > 0 and ocean > 0,"land and ocean coexist")
    for lat in [-90.0,-80.0,-45.0,0.0,35.0,90.0]:
        var left := Cart.sample(lat,-180.0)
        var right := Cart.sample(lat,180.0)
        check(absf(float(left["elevation"])-float(right["elevation"])) < 1.0e-6,
                "antimeridian periodic")
        check(left["biome"] == right["biome"],"biome seam continuity")
    for lat in [-90.0,90.0]:
        var pole_a := Cart.sample(lat,-90.0)
        var pole_b := Cart.sample(lat,72.0)
        check(pole_a["biome"] == pole_b["biome"],"pole longitude invariant")
        check(absf(float(pole_a["elevation"])-float(pole_b["elevation"])) < 1.0e-9,
                "pole elevation invariant")
    var image := Cart.render_equirect(64,32)
    check(image.get_width() == 64 and image.get_height() == 32,"global atlas raster")
    for y in range(32):
        check(image.get_pixel(0,y) == image.get_pixel(63,y),"atlas seam identical")
    var local := Cart.render_local({"latDeg":20.0,"lonDeg":-117.0,"altitudeKm":2.0},
            180.0,6371.0,64)
    check(local.get_width() == 64,"local survey raster")
    check(local.get_pixel(0,0) == Color("#061321"),"outside horizon disk masked")
    check(local.get_pixel(32,32) != Color("#061321"),"inside disk painted")
    if failed.is_empty():
        print("GODOT_WORLDMAP_CARTOGRAPHY_PASS: deterministic, biome diversity, seam/poles, globe/local raster")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_CARTOGRAPHY_FAIL: " + ", ".join(failed))
        quit(1)
