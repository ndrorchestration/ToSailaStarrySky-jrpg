extends RefCounted
## Read-only bridge from the real, historical five-track soundtrack to the
## revised First Wake scene cue protocol. Never starts music, grants rights,
## invents the Denith shanty or marks missing MP3s as admitted to Godot.
const CUES_SCHEMA := "tstss.review.first_wake_pipeline.v1"
const INVENTORY_PATH := "res://data/first_wake_existing_music_sources_v1.json"
const ALLOWED := {
    "job_search": ["title_menu", "opening_cinematic"],
    "engineering": ["opening_cinematic"],
    "preflight": ["opening_cinematic"],
    "test_flight": ["opening_cinematic", "world_airship_exploration"],
    "waterborne": ["opening_cinematic"],
    "postflight_diagnosis": ["opening_cinematic"],
    "family_reunion": ["opening_cinematic"],
    "working_theory": ["opening_cinematic"],
}
const ROLES := ["title_menu", "opening_cinematic", "combat_danger", "world_airship_exploration", "ender_first_note_leitmotif"]

static func inventory() -> Dictionary:
    if not FileAccess.file_exists(INVENTORY_PATH):
        return {"ok": false, "error": "music source inventory missing"}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        return {"ok": false, "error": "malformed soundtrack source inventory"}
    if parsed.get("schema", "") != "tstss.review.existing_chapter1_music.v1" or parsed.get("source_commit", "") != "1b1f51806ea9d013433cb98add260bd9c5be79c0":
        return {"ok": false, "error": "historical source identity mismatch"}
    if parsed.get("public_streaming_authorized", true) != false or parsed.get("new_story_music_placements_approved", true) != false:
        return {"ok": false, "error": "soundtrack publication approval is not established"}
    var entries: Array = parsed.get("tracks", [])
    if entries.size() != 5:
        return {"ok": false, "error": "source inventory must contain five original tracks"}
    var seen: Array[String] = []
    for item in entries:
        if typeof(item) != TYPE_DICTIONARY:
            return {"ok": false, "error": "invalid music entry"}
        if item.get("source_role", "") not in ROLES or item.get("source_role", "") in seen:
            return {"ok": false, "error": "unknown or duplicated source music role"}
        if str(item.get("sha256", "")).length() != 64 or int(item.get("bytes", 0)) <= 0:
            return {"ok": false, "error": "missing source music hash/size"}
        if not str(item.get("target_godot_path", "")).begins_with("res://audio/"):
            return {"ok": false, "error": "unapproved migration destination"}
        seen.append(str(item["source_role"]))
    return {"ok": true, "tracks": entries.duplicate(true), "source_commit": str(parsed["source_commit"])}

static func candidate(source: Dictionary, role: String) -> Dictionary:
    if not bool(source.get("ok", false)) or source.get("schema", "") != CUES_SCHEMA:
        return _reject("unknown story cue producer")
    if source.get("authority", "") != "prototype_only" or source.get("chapter", "") != "first_wake":
        return _reject("story cue authority mismatch")
    for flag in ["world_navigation_authorized", "production_ocean_verified", "real_family_meeting_verified", "production_save_write_authorized", "canon_promotion_authorized"]:
        if source.get(flag, true) != false:
            return _reject("production privilege found in cue")
    if source.get("gameplay_combat_grants", [1]) != []:
        return _reject("story music cannot authorize combat")
    var step: String = str(source.get("story_phase", ""))
    if not ALLOWED.has(step):
        return _reject("unknown chapter phase")
    var party: Array = source.get("story_party", [])
    var expected: Array = ["ender"] if step == "job_search" else (["ender", "ionia", "lyra"] if step in ["family_reunion", "working_theory"] else ["ender", "ionia"])
    if party != expected:
        return _reject("party chronology inconsistent with source")
    # Explicit Ender leitmotif is distinct from generic chapter music.
    # It cannot be triggered by phase progression or treated as Denith's tune.
    if role == "ender_first_note_leitmotif":
        return _reject("Ender-theme arrangement needs separately approved character focus")
    if role == "combat_danger":
        return _reject("combat music needs actual independently authorized combat context")
    if role not in ALLOWED[step]:
        return _reject("requested music context does not fit this stage")
    var data: Dictionary = inventory()
    if not bool(data.get("ok", false)):
        return _reject(str(data.get("error", "")))
    for item in data["tracks"]:
        if item["source_role"] == role:
            return {
                "ok": true, "status": "historical_source_candidate_only",
                "track_id": item["id"], "source_title": item["title"],
                "historical_source_sha256": item["sha256"], "historical_source_bytes": item["bytes"],
                "source_commit": data["source_commit"],
                "expected_future_godot_path": item["target_godot_path"],
                "proposed_role": role,
                "scene_placement_approved": false,
                "public_streaming_authorized": false,
                "native_audio_playback_proven": false,
                "story_shanty_composition_verified": false,
                "may_autoplay": false,
                "may_write_save": false,
            }
    return _reject("unknown role")

static func verify_local_audio(source: Dictionary) -> Dictionary:
    if not bool(source.get("ok", false)) or source.get("status", "") != "historical_source_candidate_only":
        return _reject("not a governed source candidate")
    var path: String = str(source.get("expected_future_godot_path", ""))
    if not path.begins_with("res://audio/"):
        return _reject("forbidden resource location")
    if not FileAccess.file_exists(path):
        return {"ok": false, "status": "missing_in_forward_godot", "track_id": str(source.get("track_id", "")), "may_play": false}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return _reject("unreadable audio source")
    var n: int = file.get_length()
    file.close()
    if n != int(source.get("historical_source_bytes", -1)) or FileAccess.get_sha256(path) != str(source.get("historical_source_sha256", "")):
        return _reject("audio binary does not match archival hash and size")
    return {
        "ok": true, "status": "original_audio_bytes_verified_here",
        "track_id": str(source["track_id"]),
        "may_play": false,
        "license_clearance_required": true,
        "native_audio_decode_test_required": true,
        "creator_scene_placement_approval_required": true,
    }

static func _reject(reason: String) -> Dictionary:
    return {"ok": false, "error": reason, "may_play": false}
