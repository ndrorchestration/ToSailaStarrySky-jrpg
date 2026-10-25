extends SceneTree
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Flight = preload("res://scripts/planetary/planetary_flight.gd")
const R := 6371.0
var failures: Array[String] = []

func check(ok: bool, description: String) -> void:
    if not ok:
        failures.append(description)

func _initialize() -> void:
    var stopped := Flight.create_state()
    var still := Flight.advance(stopped, {}, 0.0, R)
    check(Geo.great_circle_distance_km(stopped, still, R) < 0.00001, "zero delta preserves position")
    var moving := Flight.advance(stopped, {"throttle": 1.0}, 1.0, R)
    check(float(moving["speedKmh"]) == 180.0, "bounded acceleration")
    check(float(moving["distanceKm"]) > 0.0, "traveled distance accumulates")
    var slowing := Flight.advance(moving, {"throttle": -1.0}, 1.0, R)
    check(float(slowing["speedKmh"]) == 0.0, "braking to zero")
    var climbing := Flight.advance(stopped, {"climb": 1.0}, 1.0, R)
    check(float(climbing["altitudeKm"]) == 17.0, "climb control")
    var seam := Flight.create_state(0.0, 179.999, 2.0, 90.0, 900.0)
    var crossed := Flight.advance(seam, {"timeScale": 300.0}, 1.0, R)
    check(float(crossed["lonDeg"]) < 0.0, "seam crossing")
    check(is_finite(float(crossed["headingDeg"])), "arrival heading finite")
    if failures.is_empty():
        print("GODOT_PLANETARY_FLIGHT_PASS (7 assertions)")
        quit(0)
    else:
        push_error("GODOT_PLANETARY_FLIGHT_FAIL: " + ", ".join(failures))
        quit(1)
