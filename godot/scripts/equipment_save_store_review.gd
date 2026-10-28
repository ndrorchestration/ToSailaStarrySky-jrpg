extends RefCounted
## P-03 ISOLATED FILESYSTEM EXPERIMENT. Fixed user://aetherwake-tests/
## location; NEVER reads or writes First Wake's active save file.
## Based on existing fail-closed native Chapter I staged-write discipline.
## Does not authorize permanent item inventory or release storage.

const Codec = preload("res://scripts/equipment_save_contract_review.gd")
const PATH := "user://aetherwake-tests/equipment-p03-study.json"

func save_review(candidate: Dictionary) -> Dictionary:
    if not bool(Codec.validate(candidate).get("ok", false)):
        return _fail("invalid_candidate")
    var directory: String = ProjectSettings.globalize_path(PATH.get_base_dir())
    if DirAccess.make_dir_recursive_absolute(directory) not in [OK, ERR_ALREADY_EXISTS]:
        return _fail("cannot_create_test_directory")
    var temp := PATH + ".tmp"
    var backup := PATH + ".bak"
    var candidate_backup := PATH + ".bak.next"
    _remove(temp)
    _remove(candidate_backup)

    var file := FileAccess.open(temp, FileAccess.WRITE)
    if file == null:
        return _fail("temp_open_failed")
    file.store_string(JSON.stringify(candidate))
    file.flush()
    file.close()
    var staged := _read_valid(temp)
    var stage_sha := FileAccess.get_sha256(temp)
    if not bool(staged.get("ok", false)) or stage_sha.is_empty():
        _remove(temp)
        return _fail("temp_validation_or_hash_failed")

    var current := _read_valid(PATH)
    if bool(current.get("ok", false)):
        var previous_sha := FileAccess.get_sha256(PATH)
        if previous_sha.is_empty() or not _copy(PATH, candidate_backup):
            _remove(temp)
            _remove(candidate_backup)
            return _fail("backup_stage_failed")
        if not bool(_read_valid(candidate_backup).get("ok", false)) or FileAccess.get_sha256(candidate_backup) != previous_sha:
            _remove(temp)
            _remove(candidate_backup)
            return _fail("backup_verify_failed")
        # A valid existing primary is still in place at this point.
        _remove(backup)
        if not _rename(candidate_backup, backup):
            _remove(temp)
            return _fail("backup_promote_failed")
        if FileAccess.get_sha256(backup) != previous_sha:
            _remove(temp)
            return _fail("backup_hash_failed")

    # A corrupt primary cannot overwrite a previously valid .bak.
    _remove(PATH)
    if not _rename(temp, PATH):
        if FileAccess.file_exists(backup):
            _copy(backup, PATH)
        _remove(temp)
        return _fail("primary_promote_failed")
    if not bool(_read_valid(PATH).get("ok", false)) or FileAccess.get_sha256(PATH) != stage_sha:
        _remove(PATH)
        if FileAccess.file_exists(backup):
            _copy(backup, PATH)
        return _fail("primary_verify_failed")
    return {
        "ok": true, "path": PATH, "primary_sha256": stage_sha,
        "backup_sha256": FileAccess.get_sha256(backup) if FileAccess.file_exists(backup) else "",
    }

func load_review() -> Dictionary:
    var current := _read_valid(PATH)
    if bool(current.get("ok", false)):
        return {
            "ok": true, "error": "", "source": "primary", "recovered": false,
            "snapshot": Dictionary(current["snapshot"]).duplicate(true),
        }
    var previous := _read_valid(PATH + ".bak")
    if bool(previous.get("ok", false)):
        return {
            "ok": true, "error": "", "source": "backup", "recovered": true,
            "snapshot": Dictionary(previous["snapshot"]).duplicate(true),
        }
    return _fail("both_generations_invalid")

func delete_review() -> void:
    _remove(PATH)
    _remove(PATH + ".tmp")
    _remove(PATH + ".bak")
    _remove(PATH + ".bak.next")

func _read_valid(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return _fail("missing")
    var raw_text := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(raw_text)
    if not (parsed is Dictionary):
        return _fail("invalid_json")
    if not bool(Codec.validate(parsed).get("ok", false)):
        return _fail("invalid_semantic_payload")
    return {"ok": true, "snapshot": parsed}

func _rename(from_path: String, to_path: String) -> bool:
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(from_path), ProjectSettings.globalize_path(to_path)) == OK

func _copy(from_path: String, to_path: String) -> bool:
    return DirAccess.copy_absolute(ProjectSettings.globalize_path(from_path), ProjectSettings.globalize_path(to_path)) == OK

func _remove(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _fail(message: String) -> Dictionary:
    return {"ok": false, "error": message, "snapshot": {}}
