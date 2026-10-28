extends SceneTree
## NON-CANON: native Godot 4.7.2 admission of a Node planetary surface JSON.
## No mesh, collider, saved game, secret route, terrain height, or world radius.
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _number(value: Variant, lo: float, hi: float) -> bool:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return false
    var n: float = float(value)
    return is_finite(n) and n >= lo and n <= hi

func _integer(value: Variant, lo: int, hi: int) -> bool:
    if not _number(value, float(lo), float(hi)):
        return false
    return float(value) == floorf(float(value))

func _position(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var p: Dictionary = value
    return _number(p.get("latDeg"), -90.0, 90.0) and \
        _number(p.get("lonDeg"), -180.0, 180.0) and \
        float(p["lonDeg"]) < 180.0

func _no_authority(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var a: Dictionary = value
    if a.size() != 6:
        return false
    for key in ["elevation", "collision", "landable", "discovery", "route", "story"]:
        if not a.has(key) or a[key] != "UNSPECIFIED":
            return false
    return true

func _valid_surface(value: Variant, quality: String) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var s: Dictionary = value
    if not _position(s.get("coordinate")):
        return false
    if typeof(s.get("biome")) != TYPE_STRING or String(s["biome"]).is_empty():
        return false
    if typeof(s.get("land")) != TYPE_BOOL or not _no_authority(s.get("authority")):
        return false
    if s.has("heightMeters") or s.has("canLand") or s.has("collision"):
        return false
    if typeof(s.get("provenance")) != TYPE_DICTIONARY:
        return false
    var prov: Dictionary = s["provenance"]
    if prov.get("studyOnly") != true or prov.get("heightUnit") != "NONE":
        return false
    if prov.get("source") != "planetary-cartography.sample":
        return false
    if typeof(s.get("material")) != TYPE_DICTIONARY:
        return false
    var m: Dictionary = s["material"]
    if m.get("quality") != quality:
        return false
    if not ["water", "polar-ice", "ice", "alpine-rock", "woodland", "ground"].has(m.get("family")):
        return false
    if not _number(m.get("reliefColorHint"), 0.0, 1.0):
        return false
    var rgb: Variant = m.get("baseColorRgb")
    if typeof(rgb) != TYPE_ARRAY or rgb.size() != 3:
        return false
    for channel in rgb:
        if not _integer(channel, 0, 255):
            return false
    var cliff: Variant = m.get("cliffProjection")
    var snow: Variant = m.get("snowRockBlend")
    if m["family"] == "alpine-rock" and quality == "high":
        if cliff != "REQUIRES_LOCAL_NORMAL" or snow != "REQUIRES_LOCAL_ELEVATION":
            return false
    elif cliff != "OFF" or snow != "OFF":
        return false
    return true

func _valid_tile(value: Variant, lod: int, quality: String) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var t: Dictionary = value
    if typeof(t.get("tile")) != TYPE_DICTIONARY:
        return false
    var id: Dictionary = t["tile"]
    if not ["px", "nx", "py", "ny", "pz", "nz"].has(id.get("face")):
        return false
    if not _integer(id.get("level"), lod, lod):
        return false
    var size: int = 1 << lod
    if not _integer(id.get("x"), 0, size - 1) or not _integer(id.get("y"), 0, size - 1):
        return false
    var expected: String = "%s/%d/%d/%d" % [id["face"], lod, int(id["x"]), int(id["y"])]
    if t.get("tileKey") != expected:
        return false
    if not _position(t.get("center")) or not _valid_surface(t.get("surface"), quality):
        return false
    var center: Dictionary = t["center"]
    var coord: Dictionary = t["surface"]["coordinate"]
    if absf(float(center["latDeg"]) - float(coord["latDeg"])) > 0.000001:
        return false
    if absf(float(center["lonDeg"]) - float(coord["lonDeg"])) > 0.000001:
        return false
    return true

func _valid_manifest(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var root_data: Dictionary = value
    if root_data.get("schema") != "planetary-surface-admission/v1":
        return false
    if root_data.get("fixtureOnly") != true or root_data.get("authority") != "NONE":
        return false
    if root_data.has("planetRadiusCanonKm") or root_data.has("save") or root_data.has("routes"):
        return false
    var cases: Variant = root_data.get("cases")
    if typeof(cases) != TYPE_ARRAY or cases.size() != 4:
        return false
    var named: Dictionary = {}
    for candidate in cases:
        if typeof(candidate) != TYPE_DICTIONARY:
            return false
        var c: Dictionary = candidate
        var title: Variant = c.get("id")
        var quality: Variant = c.get("quality")
        if typeof(title) != TYPE_STRING or String(title).is_empty() or named.has(title):
            return false
        named[title] = true
        if not ["high", "low"].has(quality):
            return false
        if typeof(c.get("plan")) != TYPE_DICTIONARY:
            return false
        var p: Dictionary = c["plan"]
        if p.get("schema") != "0.1.0-noncanon-handoff" or p.get("studyOnly") != true:
            return false
        if not _no_authority(p.get("authority")) or not _position(p.get("observer")):
            return false
        if not _number(p.get("horizonKm"), 0.0, 100000.0):
            return false
        if not _integer(p.get("lodLevel"), 0, 12):
            return false
        if typeof(p.get("lodDowngraded")) != TYPE_BOOL:
            return false
        if typeof(p.get("tiles")) != TYPE_ARRAY:
            return false
        var requests: Array = p["tiles"]
        if not _integer(p.get("tileCount"), 1, 64) or int(p["tileCount"]) != requests.size():
            return false
        var seen: Dictionary = {}
        for request in requests:
            if not _valid_tile(request, int(p["lodLevel"]), str(quality)):
                return false
            var key: String = request["tileKey"]
            if seen.has(key):
                return false
            seen[key] = true
    return named.has("coastal-high") and named.has("antimeridian-high") and \
        named.has("north-pole-high") and named.has("south-pole-low")

func _run() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("PLANETARY_SURFACE_ADMISSION_FAIL: missing generated JSON manifest")
        quit(1)
        return
    var content: String = FileAccess.get_file_as_string(args[0])
    var document: Variant = JSON.parse_string(content)
    _check(_valid_manifest(document), "exact Node manifest admitted in Godot")
    if typeof(document) == TYPE_DICTIONARY and _valid_manifest(document):
        var altered: Dictionary = document.duplicate(true)
        altered["cases"][0]["plan"]["tiles"][0]["surface"]["authority"]["landable"] = "ALLOW"
        _check(not _valid_manifest(altered), "tampered landability fails closed")
        altered = document.duplicate(true)
        altered["cases"][0]["plan"]["tiles"][0]["tileKey"] = "px/0/0/0"
        _check(not _valid_manifest(altered), "corrupted spherical tile identity rejected")
        altered = document.duplicate(true)
        altered["cases"][0]["plan"]["tiles"][0]["surface"]["material"]["cliffProjection"] = "AUTHORISED"
        _check(not _valid_manifest(altered), "unapproved cliff material execution rejected")
        altered = document.duplicate(true)
        altered["planetRadiusCanonKm"] = 6371
        _check(not _valid_manifest(altered), "fixture world radius cannot be upgraded to canon")
        altered = document.duplicate(true)
        altered["cases"][0]["plan"]["tiles"][0]["surface"]["heightMeters"] = 1024
        _check(not _valid_manifest(altered), "render hint cannot invent physical terrain height")
    if failures.is_empty():
        print("PLANETARY_SURFACE_GODOT_ADMISSION_PASS checks=", checks,
            " cases=", document["cases"].size(), " NONCANON")
        quit(0)
    else:
        for message in failures:
            push_error("PLANETARY_SURFACE_ADMISSION_FAIL: " + message)
        quit(1)
