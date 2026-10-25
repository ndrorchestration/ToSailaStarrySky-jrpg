extends SceneTree
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const R := 6371.0 # Non-canon regression fixture only.
var failures: Array[String] = []

func check(ok: bool, description: String) -> void:
    if not ok:
        failures.append(description)

func _initialize() -> void:
    var equator := Geo.position(0.0, 0.0)
    var east := Geo.position(0.0, 1.0)
    check(absf(Geo.great_circle_distance_km(equator, east, R) - 111.1949266) < 0.002, "one-degree equatorial arc")
    check(absf(Geo.initial_bearing_deg(equator, east) - 90.0) < 0.00001, "initial east bearing")
    check(absf(Geo.normalize_longitude(181.0) + 179.0) < 0.0001, "antimeridian wraps")
    check(absf(Geo.normalize_lat_lon(100.0, 15.0).x - 80.0) < 0.0001, "north-pole reflection")
    check(absf(Geo.normalize_lat_lon(100.0, 15.0).y + 165.0) < 0.0001, "pole rotates longitude")
    var at_seam := Geo.destination_point(Geo.position(0.0, 179.5), 90.0, 111.1949266, R)
    check(absf(float(at_seam["lonDeg"]) + 179.5) < 0.002, "east across date line")
    check(Geo.has_line_of_sight(equator, east, R) == false, "surface hides distant location")
    check(Geo.has_line_of_sight(Geo.position(0.0, 0.0, 2.0), east, R), "raised observer horizon")
    check(Geo.horizon_distance_km(20.0, R) > Geo.horizon_distance_km(2.0, R), "altitude increases horizon")
    var pole := Geo.destination_point(Geo.position(90.0, 0.0), 180.0, 75.0, R)
    check(is_finite(float(pole["latDeg"])) and is_finite(float(pole["lonDeg"])), "pole-safe destination")
    var xyz := Geo.to_cartesian(Geo.position(23.0, -71.0, 2.0), R)
    var inverse := Geo.from_cartesian(xyz, R)
    check(absf(float(inverse["latDeg"]) - 23.0) < 0.02, "Cartesian inverse latitude")
    check(absf(float(inverse["lonDeg"]) + 71.0) < 0.02, "Cartesian inverse longitude")
    var local := Geo.to_local_km(equator, Geo.position(1.0, 0.5), R)
    var restored := Geo.from_local_km(equator, local.x, local.y, R)
    check(Geo.great_circle_distance_km(restored, Geo.position(1.0, 0.5), R) < 0.01, "local round trip")
    if failures.is_empty():
        print("GODOT_PLANETARY_GEOMETRY_PASS (13 assertions)")
        quit(0)
    else:
        push_error("GODOT_PLANETARY_GEOMETRY_FAIL: " + ", ".join(failures))
        quit(1)
