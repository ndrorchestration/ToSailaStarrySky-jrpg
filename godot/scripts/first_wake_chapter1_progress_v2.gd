extends RefCounted
## Isolated, fail-closed Chapter One continuation checkpoint. Not a security
## signature or a replacement for v1's real physical-landing evidence.
const V1 = preload("res://scripts/first_wake_game_checkpoint.gd")
const SCHEMA := "tstss.first-wake.chapter1-review.v2"
const DEFAULT_PATH := "user://first_wake_chapter1_review_v2.json"
const PHASES := ["recover","install","retest","listen","repeat","analyze",
    "observe","authorize","verify","candidate"]
const STAGES := ["family_arrival","investigation","working_theory","repair_review"]
const CLUES := ["phase_readings","depleted_reserve","lyra_observation"]
const ITEMS := ["recovered_supply","recovered_part"]
const ROOT_FIELDS := ["schema","stage","parent_schema","parent_sha256",
    "clues","talen_blocks","safe_mooring_review","party","core"]
const CORE_FIELDS := ["phase","recovered","installed","failed_retest","melody_recognized"]

static func _valid_parent(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        return false
    var obj: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    return obj is Dictionary and V1.validate(obj)

static func _digest(path: String) -> String:
    if not _valid_parent(path):
        return ""
    return FileAccess.get_sha256(path)

static func _fields(data: Dictionary, names: Array) -> bool:
    if data.size() != names.size():
        return false
    for key in names:
        if not data.has(key):
            return false
    return true

static func _unique_allowed(value: Variant, names: Array, max_count: int) -> bool:
    if not value is Array or value.size() > max_count:
        return false
    var seen: Dictionary = {}
    for item in value:
        if typeof(item) != TYPE_STRING or item not in names or seen.has(item):
            return false
        seen[item] = true
    return true

static func _core_ok(data: Dictionary) -> bool:
    if not _fields(data,CORE_FIELDS):
        return false
    var phase: Variant = data["phase"]
    if typeof(phase) != TYPE_STRING or phase not in PHASES:
        return false
    if not _unique_allowed(data["recovered"],ITEMS,2) or not _unique_allowed(data["installed"],ITEMS,2):
        return false
    if typeof(data["failed_retest"]) != TYPE_BOOL or typeof(data["melody_recognized"]) != TYPE_BOOL:
        return false
    var idx: int = PHASES.find(phase)
    var rec: Array = data["recovered"]
    var ins: Array = data["installed"]
    if idx == 0 and (rec.size() > 1 or not ins.is_empty()):
        return false
    if idx == 1 and (rec.size() != 2 or ins.size() > 1):
        return false
    if idx >= 2 and (rec.size() != 2 or ins.size() != 2):
        return false
    for item in ins:
        if item not in rec:
            return false
    if data["failed_retest"] != (idx >= 3):
        return false
    if data["melody_recognized"] != (idx >= 6):
        return false
    return true

static func validate(data: Dictionary) -> bool:
    if not _fields(data,ROOT_FIELDS):
        return false
    if data["schema"] != SCHEMA or data["parent_schema"] != V1.SCHEMA:
        return false
    if typeof(data["parent_sha256"]) != TYPE_STRING:
        return false
    var digest: String = data["parent_sha256"]
    if digest.length() != 64:
        return false
    for character in digest:
        if character not in "0123456789abcdef":
            return false
    if typeof(data["stage"]) != TYPE_STRING or data["stage"] not in STAGES:
        return false
    if typeof(data["safe_mooring_review"]) != TYPE_BOOL or not data["safe_mooring_review"]:
        return false
    if typeof(data["talen_blocks"]) != TYPE_BOOL:
        return false
    if not _unique_allowed(data["clues"],CLUES,3):
        return false
    var stage: String = data["stage"]
    var clue_count: int = data["clues"].size()
    if stage == "family_arrival":
        if data["party"] != ["ender","ionia"] or clue_count != 0:
            return false
    else:
        if data["party"] != ["ender","ionia","lyra"]:
            return false
    if stage in ["working_theory","repair_review"] and clue_count < 2:
        return false
    if not data["core"] is Dictionary:
        return false
    if stage == "repair_review":
        return _core_ok(data["core"])
    return data["core"].is_empty()

static func from_scene(family: Node, parent_path: String) -> Dictionary:
    if family == null or family.opening == null or not family.safe_mooring_review:
        return {}
    if family.dialogue_open or family.ender == null:
        return {}
    var sha: String = _digest(parent_path)
    if sha.is_empty():
        return {}
    var report: Dictionary = family.opening.snapshot()
    var stage: String = family.scene_phase
    var core: Dictionary = {}
    if stage == "repair_review":
        if family.repair_review == null or family.repair_review.analysis.open:
            return {}
        core = family.repair_review.core.snapshot()
        core = {
            "phase":core["phase"],"recovered":core["recovered"],
            "installed":core["installed"],"failed_retest":core["failed_retest"],
            "melody_recognized":core["melody_recognized"],
        }
    var state: Dictionary = {
        "schema":SCHEMA,"stage":stage,"parent_schema":V1.SCHEMA,
        "parent_sha256":sha,"clues":report["clues"],
        "talen_blocks":family.child_block_ship_viewed,
        "safe_mooring_review":true,"party":report["active_party_ids"],
        "core":core,
    }
    return state if validate(state) else {}

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed if parsed is Dictionary and validate(parsed) else {}

static func save(state: Dictionary, parent_path: String, path: String = DEFAULT_PATH) -> bool:
    if not validate(state) or state["parent_sha256"] != _digest(parent_path):
        return false
    if path == parent_path or path == parent_path + ".bak":
        return false
    var tmp: String = path + ".tmp"
    var bak: String = path + ".bak"
    var old: Dictionary = _read(path)
    var file := FileAccess.open(tmp,FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(state))
    file.flush()
    file.close()
    if _read(tmp).is_empty():
        DirAccess.remove_absolute(tmp)
        return false
    if not old.is_empty():
        if DirAccess.copy_absolute(path,bak) != OK or _read(bak).is_empty():
            DirAccess.remove_absolute(tmp)
            return false
    if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
        DirAccess.remove_absolute(tmp)
        return false
    if DirAccess.rename_absolute(tmp,path) != OK:
        if not old.is_empty() and FileAccess.file_exists(bak):
            DirAccess.copy_absolute(bak,path)
        return false
    return not _read(path).is_empty()

static func load(parent_path: String, path: String = DEFAULT_PATH) -> Dictionary:
    var digest: String = _digest(parent_path)
    if digest.is_empty():
        return {}
    for source in [path,path+".bak"]:
        var obj: Dictionary = _read(source)
        if not obj.is_empty() and obj["parent_sha256"] == digest:
            return obj
    return {}
