extends RefCounted
## First-flight checkpoint format. Deliberately INCOMPATIBLE with the older
## signal/crossing Chapter I save contract: there is no silent migration.
## The native scene must observe real water contact before it can write this.
const SCHEMA := "tstss.first-wake.first-flight.v1"
const DEFAULT_PATH := "user://first_wake_first_flight_v1.json"
const STAGE := "postflight_diagnosis"
const PARTY := ["ender", "ionia"]

static func snapshot() -> Dictionary:
    return {
        "schema": SCHEMA,
        "stage": STAGE,
        "party": PARTY.duplicate(),
        "evidence": {
            "actual_2d_water_contact_at_checkpoint": true,
            "stable_local_buoyancy_at_checkpoint": true,
            "postflight_reserve_inspected": true,
        },
        "fuel_explanation_status": "unknown",
        "lyra_joined": false,
        "production_ocean_verified": false,
    }

static func validate(data: Dictionary) -> bool:
    if data.size() != 7:
        return false
    if typeof(data.get("schema")) != TYPE_STRING or data["schema"] != SCHEMA:
        return false
    if typeof(data.get("stage")) != TYPE_STRING or data["stage"] != STAGE:
        return false
    if data.get("party") != PARTY:
        return false
    if data.get("fuel_explanation_status") != "unknown":
        return false
    for flag in ["lyra_joined", "production_ocean_verified"]:
        if typeof(data.get(flag)) != TYPE_BOOL or data[flag]:
            return false
    if not data.get("evidence") is Dictionary:
        return false
    var facts: Dictionary = data["evidence"]
    if facts.size() != 3:
        return false
    for flag in [
        "actual_2d_water_contact_at_checkpoint",
        "stable_local_buoyancy_at_checkpoint",
        "postflight_reserve_inspected",
    ]:
        if typeof(facts.get(flag)) != TYPE_BOOL or not facts[flag]:
            return false
    return true

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var text_data: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text_data)
    if parsed is Dictionary and validate(parsed):
        return parsed
    return {}

static func save(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
    if not validate(data):
        return false
    var temporary := path + ".tmp"
    var backup := path + ".bak"
    var old: Dictionary = _read(path)
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    if _read(temporary).is_empty():
        DirAccess.remove_absolute(temporary)
        return false
    # Preserve a valid earlier primary as fallback; never trust corrupt bytes.
    if not old.is_empty():
        if DirAccess.copy_absolute(path, backup) != OK or _read(backup).is_empty():
            DirAccess.remove_absolute(temporary)
            return false
    if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
        DirAccess.remove_absolute(temporary)
        return false
    if DirAccess.rename_absolute(temporary, path) != OK:
        if not old.is_empty() and FileAccess.file_exists(backup):
            DirAccess.copy_absolute(backup, path)
        return false
    return not _read(path).is_empty()

static func load(path: String = DEFAULT_PATH) -> Dictionary:
    var primary: Dictionary = _read(path)
    if not primary.is_empty():
        return primary
    return _read(path + ".bak")
