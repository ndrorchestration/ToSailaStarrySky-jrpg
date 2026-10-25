extends RefCounted
## Godot-native port of the isolated planetary geometry contract in PR #349.
## Unit contract: latitude/longitude in degrees, altitude/radius/distance in km.
## No world radius, continent shape, discovery or route is canonized here.

const EPSILON := 1.0e-12

static func valid_radius(radius_km: float) -> bool:
    return is_finite(radius_km) and radius_km > 0.0

static func normalize_longitude(lon_deg: float) -> float:
    assert(is_finite(lon_deg), "GLOBE_LONGITUDE_NONFINITE")
    return fposmod(lon_deg + 180.0, 360.0) - 180.0

static func normalize_lat_lon(lat_deg: float, lon_deg: float) -> Vector2:
    assert(is_finite(lat_deg) and is_finite(lon_deg), "GLOBE_COORD_NONFINITE")
    var lat: float = fposmod(lat_deg + 180.0, 360.0) - 180.0
    var lon: float = lon_deg
    if lat > 90.0:
        lat = 180.0 - lat
        lon += 180.0
    elif lat < -90.0:
        lat = -180.0 - lat
        lon += 180.0
    return Vector2(lat, normalize_longitude(lon))

static func position(lat_deg: float, lon_deg: float, altitude_km: float = 0.0) -> Dictionary:
    assert(is_finite(altitude_km) and altitude_km >= 0.0, "GLOBE_ALTITUDE_INVALID")
    var normalized := normalize_lat_lon(lat_deg, lon_deg)
    return {"latDeg": float(normalized.x), "lonDeg": float(normalized.y), "altitudeKm": altitude_km}

static func separation_rad(a: Dictionary, b: Dictionary) -> float:
    var p := position(float(a["latDeg"]), float(a["lonDeg"]))
    var q := position(float(b["latDeg"]), float(b["lonDeg"]))
    var lat1 := deg_to_rad(float(p["latDeg"]))
    var lat2 := deg_to_rad(float(q["latDeg"]))
    var dlat := lat2 - lat1
    var dlon := deg_to_rad(normalize_longitude(float(q["lonDeg"]) - float(p["lonDeg"])))
    var h := pow(sin(dlat * 0.5), 2.0) + cos(lat1) * cos(lat2) * pow(sin(dlon * 0.5), 2.0)
    return 2.0 * asin(sqrt(clampf(h, 0.0, 1.0)))

static func great_circle_distance_km(a: Dictionary, b: Dictionary, radius_km: float) -> float:
    assert(valid_radius(radius_km), "GLOBE_RADIUS_INVALID")
    return radius_km * separation_rad(a, b)

static func initial_bearing_deg(a: Dictionary, b: Dictionary) -> float:
    var p := position(float(a["latDeg"]), float(a["lonDeg"]))
    var q := position(float(b["latDeg"]), float(b["lonDeg"]))
    var lat1 := deg_to_rad(float(p["latDeg"]))
    var lat2 := deg_to_rad(float(q["latDeg"]))
    var dlon := deg_to_rad(normalize_longitude(float(q["lonDeg"]) - float(p["lonDeg"])))
    var y := sin(dlon) * cos(lat2)
    var x := cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dlon)
    assert(sqrt(x*x + y*y) >= EPSILON, "GLOBE_BEARING_UNDEFINED")
    return fposmod(rad_to_deg(atan2(y, x)), 360.0)

static func destination_point(start: Dictionary, bearing_deg: float, distance_km: float, radius_km: float) -> Dictionary:
    assert(valid_radius(radius_km) and is_finite(bearing_deg), "GLOBE_DESTINATION_INVALID")
    assert(is_finite(distance_km) and distance_km >= 0.0, "GLOBE_DISTANCE_INVALID")
    var p := position(float(start["latDeg"]), float(start["lonDeg"]), float(start.get("altitudeKm", 0.0)))
    if distance_km == 0.0:
        return p
    var lat := deg_to_rad(float(p["latDeg"]))
    var lon := deg_to_rad(float(p["lonDeg"]))
    var bearing := deg_to_rad(bearing_deg)
    var arc := distance_km / radius_km
    var north := cos(bearing) * sin(arc)
    var east := sin(bearing) * sin(arc)
    var step := cos(arc)
    var x := cos(lat)*cos(lon)*step - sin(lat)*cos(lon)*north - sin(lon)*east
    var y := cos(lat)*sin(lon)*step - sin(lat)*sin(lon)*north + cos(lon)*east
    var z := sin(lat)*step + cos(lat)*north
    return position(rad_to_deg(atan2(z, sqrt(x*x + y*y))), rad_to_deg(atan2(y, x)), float(p["altitudeKm"]))

static func horizon_angle_rad(altitude_km: float, radius_km: float) -> float:
    assert(valid_radius(radius_km), "GLOBE_RADIUS_INVALID")
    assert(is_finite(altitude_km) and altitude_km >= 0.0, "GLOBE_ALTITUDE_INVALID")
    return acos(radius_km / (radius_km + altitude_km))

static func horizon_distance_km(altitude_km: float, radius_km: float) -> float:
    return radius_km * horizon_angle_rad(altitude_km, radius_km)

static func has_line_of_sight(observer: Dictionary, target: Dictionary, radius_km: float) -> bool:
    var a := float(observer.get("altitudeKm", 0.0))
    var b := float(target.get("altitudeKm", 0.0))
    var angular_limit := horizon_angle_rad(a, radius_km) + horizon_angle_rad(b, radius_km)
    return separation_rad(observer, target) <= angular_limit + EPSILON

static func to_cartesian(point_data: Dictionary, radius_km: float) -> Vector3:
    assert(valid_radius(radius_km), "GLOBE_RADIUS_INVALID")
    var p := position(float(point_data["latDeg"]), float(point_data["lonDeg"]), float(point_data.get("altitudeKm", 0.0)))
    var lat := deg_to_rad(float(p["latDeg"]))
    var lon := deg_to_rad(float(p["lonDeg"]))
    var radial := radius_km + float(p["altitudeKm"])
    # Godot Y-up: original geometry's XY equatorial plane maps to Godot XZ.
    return Vector3(radial*cos(lat)*cos(lon), radial*sin(lat), radial*cos(lat)*sin(lon))

static func from_cartesian(vector: Vector3, radius_km: float) -> Dictionary:
    assert(valid_radius(radius_km) and vector.is_finite(), "GLOBE_VECTOR_INVALID")
    var distance := vector.length()
    assert(distance >= radius_km * (1.0 - 1.0e-12), "GLOBE_INSIDE_PLANET")
    return position(rad_to_deg(atan2(vector.y, sqrt(vector.x*vector.x + vector.z*vector.z))),
            rad_to_deg(atan2(vector.z, vector.x)), maxf(0.0, distance - radius_km))

static func to_local_km(anchor: Dictionary, target: Dictionary, radius_km: float) -> Vector2:
    assert(valid_radius(radius_km), "GLOBE_RADIUS_INVALID")
    var arc := separation_rad(anchor, target)
    assert(arc < PI * 0.5 - EPSILON, "GLOBE_LOCAL_RANGE_EXCEEDED")
    if arc <= EPSILON:
        return Vector2.ZERO
    var bearing := deg_to_rad(initial_bearing_deg(anchor, target))
    return Vector2(radius_km * arc * sin(bearing), radius_km * arc * cos(bearing))

static func from_local_km(anchor: Dictionary, east_km: float, north_km: float, radius_km: float) -> Dictionary:
    assert(valid_radius(radius_km) and is_finite(east_km) and is_finite(north_km), "GLOBE_LOCAL_INVALID")
    var distance := sqrt(east_km*east_km + north_km*north_km)
    assert(distance < radius_km * (PI * 0.5 - EPSILON), "GLOBE_LOCAL_RANGE_EXCEEDED")
    if distance == 0.0:
        return position(float(anchor["latDeg"]), float(anchor["lonDeg"]), float(anchor.get("altitudeKm", 0.0)))
    return destination_point(anchor, rad_to_deg(atan2(east_km, north_km)), distance, radius_km)
