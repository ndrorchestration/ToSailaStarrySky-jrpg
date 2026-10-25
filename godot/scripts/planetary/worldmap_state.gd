extends RefCounted
## Isolated, opt-in worldmap preview persistence. Never touches First Wake saves.
## Invalid JSON, unknown schema/fields, non-finite numerics or forged discoveries
## fail closed without mutating the live state.
const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")
const Flight = preload("res://scripts/planetary/planetary_flight.gd")
const VERSION := 1
const PATH := "user://starry_worldmap_preview_v1.json"
const MODES := ["globe","chart","local","flight"]
const MARKERS := ["survey_a","survey_b","survey_c","survey_d"]
const LIMIT_BYTES := 8192

static func defaults() -> Dictionary:
    return {"flight": Flight.create_state(), "mode": "globe",
            "discovered": [], "waypoint": {}}

static func _finite_number(v: Variant) -> bool:
    return (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v))

static func validate(raw: Variant) -> Dictionary:
    if typeof(raw) != TYPE_DICTIONARY:
        return {}
    var state: Dictionary = raw
    if not state.has("flight") or typeof(state["flight"]) != TYPE_DICTIONARY:
        return {}
    var flight: Dictionary = state["flight"]
    for k in ["latDeg","lonDeg","altitudeKm","headingDeg","speedKmh","distanceKm"]:
        if not flight.has(k) or not _finite_number(flight[k]):
            return {}
    var lat := float(flight["latDeg"])
    var lon := float(flight["lonDeg"])
    var alt := float(flight["altitudeKm"])
    var heading := float(flight["headingDeg"])
    var speed := float(flight["speedKmh"])
    var distance := float(flight["distanceKm"])
    if lat < -90.0 or lat > 90.0 or lon < -180.0 or lon >= 180.0:
        return {}
    if alt < Flight.MIN_ALTITUDE_KM or alt > Flight.MAX_ALTITUDE_KM:
        return {}
    if heading < 0.0 or heading >= 360.0 or speed < 0.0 or speed > Flight.MAX_SPEED_KMH:
        return {}
    if distance < 0.0 or distance > 1.0e12:
        return {}
    var mode: Variant = state.get("mode","globe")
    if typeof(mode) != TYPE_STRING or not MODES.has(mode):
        return {}
    var discovered: Variant = state.get("discovered",[])
    if typeof(discovered) != TYPE_ARRAY or discovered.size() > MARKERS.size():
        return {}
    var unique: Dictionary = {}
    var valid_discovered: Array[String] = []
    for item in discovered:
        if typeof(item) != TYPE_STRING or not MARKERS.has(item) or unique.has(item):
            return {}
        unique[item] = true
        valid_discovered.append(item)
    var waypoint: Variant = state.get("waypoint",{})
    if typeof(waypoint) != TYPE_DICTIONARY:
        return {}
    var valid_waypoint: Dictionary = {}
    if not waypoint.is_empty():
        if not waypoint.has("latDeg") or not waypoint.has("lonDeg"):
            return {}
        if not _finite_number(waypoint["latDeg"]) or not _finite_number(waypoint["lonDeg"]):
            return {}
        if float(waypoint["latDeg"]) < -90.0 or float(waypoint["latDeg"]) > 90.0:
            return {}
        if float(waypoint["lonDeg"]) < -180.0 or float(waypoint["lonDeg"]) >= 180.0:
            return {}
        valid_waypoint = Geometry.position(float(waypoint["latDeg"]), float(waypoint["lonDeg"]))
    return {"flight": Flight.create_state(lat,lon,alt,heading,speed,distance),
            "mode":mode, "discovered":valid_discovered, "waypoint":valid_waypoint}

static func encode(state: Dictionary) -> String:
    var value := validate(state)
    if value.is_empty():
        return ""
    return JSON.stringify({"version":VERSION, "state":value})

static func decode(payload: String) -> Dictionary:
    if payload.length() < 8 or payload.to_utf8_buffer().size() > LIMIT_BYTES:
        return {}
    var json := JSON.new()
    if json.parse(payload) != OK:
        return {}
    if typeof(json.data) != TYPE_DICTIONARY:
        return {}
    var body: Dictionary = json.data
    if body.get("version", -1) != VERSION:
        return {}
    return validate(body.get("state",null))

static func save_preview(state: Dictionary) -> bool:
    var payload := encode(state)
    if payload.is_empty():
        return false
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(payload)
    file.flush()
    return file.get_error() == OK

static func load_preview() -> Dictionary:
    if not FileAccess.file_exists(PATH):
        return {}
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null or file.get_length() > LIMIT_BYTES:
        return {}
    return decode(file.get_as_text())
