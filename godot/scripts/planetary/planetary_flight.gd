extends RefCounted
## Native GDScript port of PR #349's isolated geodesic flight study.
## Explicitly experimental flight parameters; NOT approved Dragonfly handling.
const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")

const MAX_SPEED_KMH := 950.0
const MIN_ALTITUDE_KM := 0.1
const MAX_ALTITUDE_KM := 1000.0
const TURN_DEG_PER_SECOND := 35.0
const ACCEL_KMH_PER_SECOND := 180.0
const DECEL_KMH_PER_SECOND := 230.0
const CLIMB_KM_PER_SECOND := 1.5

static func create_state(lat_deg: float = 25.0, lon_deg: float = -115.0, altitude_km: float = 2.0,
        heading_deg: float = 90.0, speed_kmh: float = 0.0, distance_km: float = 0.0) -> Dictionary:
    assert(is_finite(heading_deg) and is_finite(speed_kmh) and is_finite(distance_km), "GLOBE_FLIGHT_NONFINITE")
    assert(altitude_km >= MIN_ALTITUDE_KM and altitude_km <= MAX_ALTITUDE_KM, "GLOBE_FLIGHT_ALTITUDE")
    assert(speed_kmh >= 0.0 and speed_kmh <= MAX_SPEED_KMH and distance_km >= 0.0, "GLOBE_FLIGHT_RANGE")
    var result := Geometry.position(lat_deg, lon_deg, altitude_km)
    result["headingDeg"] = fposmod(heading_deg, 360.0)
    result["speedKmh"] = speed_kmh
    result["distanceKm"] = distance_km
    return result

static func advance(state: Dictionary, controls: Dictionary, dt_seconds: float, radius_km: float) -> Dictionary:
    assert(is_finite(dt_seconds) and dt_seconds >= 0.0 and dt_seconds <= 2.0, "GLOBE_FLIGHT_DT")
    assert(Geometry.valid_radius(radius_km), "GLOBE_FLIGHT_RADIUS")
    var current := create_state(float(state["latDeg"]), float(state["lonDeg"]), float(state["altitudeKm"]),
            float(state["headingDeg"]), float(state["speedKmh"]), float(state["distanceKm"]))
    var turn := clampf(float(controls.get("turn", 0.0)), -1.0, 1.0)
    var throttle := clampf(float(controls.get("throttle", 0.0)), -1.0, 1.0)
    var climb := clampf(float(controls.get("climb", 0.0)), -1.0, 1.0)
    var time_scale := float(controls.get("timeScale", 1.0))
    assert(is_finite(turn) and is_finite(throttle) and is_finite(climb), "GLOBE_FLIGHT_INPUT")
    assert(is_finite(time_scale) and time_scale >= 1.0 and time_scale <= 400.0, "GLOBE_FLIGHT_TIME_SCALE")
    var heading := fposmod(float(current["headingDeg"]) + turn * TURN_DEG_PER_SECOND * dt_seconds, 360.0)
    var accel := ACCEL_KMH_PER_SECOND if throttle >= 0.0 else DECEL_KMH_PER_SECOND
    var speed := clampf(float(current["speedKmh"]) + throttle * accel * dt_seconds, 0.0, MAX_SPEED_KMH)
    var altitude := clampf(float(current["altitudeKm"]) + climb * CLIMB_KM_PER_SECOND * dt_seconds * 10.0,
            MIN_ALTITUDE_KM, MAX_ALTITUDE_KM)
    var delta_km := (float(current["speedKmh"]) + speed) * 0.5 * dt_seconds * time_scale / 3600.0
    var p := Geometry.destination_point({"latDeg": current["latDeg"], "lonDeg": current["lonDeg"],
            "altitudeKm": altitude}, heading, delta_km, radius_km)
    var arrival_heading := heading
    if delta_km > 1.0e-8 and delta_km < PI * radius_km - 1.0e-8:
        arrival_heading = fposmod(Geometry.initial_bearing_deg(p, current) + 180.0, 360.0)
    p["headingDeg"] = arrival_heading
    p["speedKmh"] = speed
    p["distanceKm"] = float(current["distanceKm"]) + delta_km
    return p
