extends RefCounted
## Single-slot durable Chapter I store for the native Godot preview.
## The versioned SaveCodec remains authority for semantic validation.
## Writes are staged to a verified temp file; the last valid primary is kept as
## a backup so interrupted/corrupt primary writes fail closed with recovery.

const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")

const VERSION := "0.1.0"
const DEFAULT_PATH := "user://first_wake_chapter1_save.json"

func save_snapshot(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
    var semantic := SaveCodec.validate(snapshot)
    if not bool(semantic.get("ok", false)):
        return _error("SAVE_SNAPSHOT_INVALID:" + str(semantic.get("error", "unknown")))

    var temp_path := path + ".tmp"
    var backup_path := path + ".bak"
    var backup_candidate_path := backup_path + ".next"
    if not _ensure_parent(path):
        return _error("SAVE_PARENT_CREATE_FAILED")

    _remove_if_exists(temp_path)
    _remove_if_exists(backup_candidate_path)
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return _error("SAVE_TEMP_OPEN_FAILED")
    file.store_string(JSON.stringify(snapshot))
    file.flush()
    file.close()

    var temp_read := _read_valid(temp_path)
    if not bool(temp_read.get("ok", false)):
        _remove_if_exists(temp_path)
        return _error("SAVE_TEMP_VERIFY_FAILED:" + str(temp_read.get("error", "unknown")))
    var temp_sha := FileAccess.get_sha256(temp_path)
    if temp_sha.is_empty():
        _remove_if_exists(temp_path)
        return _error("SAVE_TEMP_HASH_FAILED")

    # Preserve only a semantically valid previous primary. Stage and verify the
    # replacement backup before touching any already-known-good .bak generation.
    var previous := _read_valid(path)
    var previous_sha := ""
    if bool(previous.get("ok", false)):
        previous_sha = FileAccess.get_sha256(path)
        if previous_sha.is_empty():
            _remove_if_exists(temp_path)
            return _error("SAVE_PREVIOUS_PRIMARY_HASH_FAILED")
        if not _copy(path, backup_candidate_path):
            _remove_if_exists(temp_path)
            return _error("SAVE_BACKUP_CANDIDATE_COPY_FAILED")
        var backup_candidate_read := _read_valid(backup_candidate_path)
        if not bool(backup_candidate_read.get("ok", false)):
            _remove_if_exists(temp_path)
            _remove_if_exists(backup_candidate_path)
            return _error("SAVE_BACKUP_CANDIDATE_VERIFY_FAILED:" + str(backup_candidate_read.get("error", "unknown")))
        var backup_candidate_sha := FileAccess.get_sha256(backup_candidate_path)
        if backup_candidate_sha.is_empty() or backup_candidate_sha != previous_sha:
            _remove_if_exists(temp_path)
            _remove_if_exists(backup_candidate_path)
            return _error("SAVE_BACKUP_CANDIDATE_HASH_MISMATCH")

        # Only after the candidate is proven valid and byte-identical may the
        # old backup rotate.
        _remove_if_exists(backup_path)
        if not _rename(backup_candidate_path, backup_path):
            # The current primary has not yet been touched, so fail closed
            # rather than continuing with an uncertain backup generation.
            _remove_if_exists(temp_path)
            return _error("SAVE_BACKUP_PROMOTE_FAILED")
        var promoted_backup_sha := FileAccess.get_sha256(backup_path)
        if promoted_backup_sha.is_empty() or promoted_backup_sha != previous_sha:
            _remove_if_exists(temp_path)
            return _error("SAVE_BACKUP_PROMOTED_HASH_MISMATCH")

    _remove_if_exists(path)
    if not _rename(temp_path, path):
        if FileAccess.file_exists(backup_path):
            _copy(backup_path, path)
        _remove_if_exists(temp_path)
        return _error("SAVE_PRIMARY_RENAME_FAILED")

    var final_read := _read_valid(path)
    if not bool(final_read.get("ok", false)):
        _remove_if_exists(path)
        if FileAccess.file_exists(backup_path):
            _copy(backup_path, path)
        return _error("SAVE_PRIMARY_VERIFY_FAILED")

    var final_sha := FileAccess.get_sha256(path)
    if final_sha.is_empty() or final_sha != temp_sha:
        _remove_if_exists(path)
        if FileAccess.file_exists(backup_path):
            _copy(backup_path, path)
        return _error("SAVE_PRIMARY_HASH_MISMATCH")

    return {
        "ok": true,
        "error": "",
        "path": path,
        "backup_path": backup_path,
        "schema": str(snapshot.get("schema", "")),
        "primary_sha256": final_sha,
        "backup_sha256": FileAccess.get_sha256(backup_path) if FileAccess.file_exists(backup_path) else "",
    }

func load_snapshot(path: String = DEFAULT_PATH) -> Dictionary:
    var primary := _read_valid(path)
    if bool(primary.get("ok", false)):
        return {
            "ok": true,
            "error": "",
            "snapshot": primary["snapshot"],
            "source": "primary",
            "recovered": false,
            "path": path,
        }

    var backup_path := path + ".bak"
    var backup := _read_valid(backup_path)
    if bool(backup.get("ok", false)):
        return {
            "ok": true,
            "error": "",
            "snapshot": backup["snapshot"],
            "source": "backup",
            "recovered": true,
            "path": backup_path,
        }

    return {
        "ok": false,
        "error": "SAVE_LOAD_FAILED:primary=" + str(primary.get("error", "missing")) + ";backup=" + str(backup.get("error", "missing")),
        "snapshot": {},
        "source": "",
        "recovered": false,
        "path": path,
    }

func has_valid_save(path: String = DEFAULT_PATH) -> bool:
    return bool(load_snapshot(path).get("ok", false))

func delete_slot(path: String = DEFAULT_PATH) -> void:
    _remove_if_exists(path)
    _remove_if_exists(path + ".tmp")
    _remove_if_exists(path + ".bak")
    _remove_if_exists(path + ".bak.next")

func _read_valid(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"ok": false, "error": "missing", "snapshot": {}}
    var text := FileAccess.get_file_as_string(path)
    if text.strip_edges().is_empty():
        return {"ok": false, "error": "empty", "snapshot": {}}
    var parser := JSON.new()
    var parse_error := parser.parse(text)
    if parse_error != OK:
        return {
            "ok": false,
            "error": "invalid_json:" + parser.get_error_message(),
            "snapshot": {},
        }
    var parsed = parser.data
    if not (parsed is Dictionary):
        return {"ok": false, "error": "invalid_json_root", "snapshot": {}}
    var snapshot: Dictionary = parsed
    var semantic := SaveCodec.validate(snapshot)
    if not bool(semantic.get("ok", false)):
        return {"ok": false, "error": "invalid_snapshot:" + str(semantic.get("error", "unknown")), "snapshot": {}}
    return {"ok": true, "error": "", "snapshot": snapshot}

func _ensure_parent(path: String) -> bool:
    var parent := path.get_base_dir()
    if parent.is_empty() or parent == "user://":
        return true
    var absolute_parent := ProjectSettings.globalize_path(parent)
    var err := DirAccess.make_dir_recursive_absolute(absolute_parent)
    return err == OK or err == ERR_ALREADY_EXISTS

func _copy(from_path: String, to_path: String) -> bool:
    var from_abs := ProjectSettings.globalize_path(from_path)
    var to_abs := ProjectSettings.globalize_path(to_path)
    return DirAccess.copy_absolute(from_abs, to_abs) == OK

func _rename(from_path: String, to_path: String) -> bool:
    var from_abs := ProjectSettings.globalize_path(from_path)
    var to_abs := ProjectSettings.globalize_path(to_path)
    return DirAccess.rename_absolute(from_abs, to_abs) == OK

func _remove_if_exists(path: String) -> void:
    if not FileAccess.file_exists(path):
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _error(code: String) -> Dictionary:
    return {"ok": false, "error": code}
