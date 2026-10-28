extends RefCounted
## Explicit review-only navigation between the existing Godot startup scene
## and the isolated, Ionia-first opening. This is NEVER a quest transition.
## Carries the validated original v1 state in SceneTree memory, not on disk.
## A v2 review checkpoint stays in its independent existing save slot.
const LegacyCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const LEGACY_ENTRY := "res://scenes/first_wake_chapter1_player_preview.tscn"
const REVISED_REVIEW := "res://scenes/first_wake_job_preview.tscn"
const REVIEW_RETURN_SNAPSHOT := "tstss_review_route_original_v1"
const REVIEW_RETURN_PATH := "tstss_review_route_original_scene"
const RESTORE_PENDING := "tstss_review_route_restore_pending"

static func enter(source: Node) -> Dictionary:
    if source == null or source.get_tree() == null:
        return _deny("missing_live_scene")
    var tree: SceneTree = source.get_tree()
    if tree.current_scene != source or source.scene_file_path != LEGACY_ENTRY:
        return _deny("not_current_native_chapter_entry")
    if tree.has_meta(REVIEW_RETURN_SNAPSHOT) or tree.has_meta(RESTORE_PENDING):
        return _deny("prototype_route_already_active")
    if not source.has_method("export_save_snapshot"):
        return _deny("legacy_save_export_not_supported")
    if source.dialogue.open or source.formula_encounter.active:
        return _deny("close_dialogue_or_combat_first")
    var old_snapshot: Dictionary = source.export_save_snapshot()
    if not bool(LegacyCodec.validate(old_snapshot).get("ok", false)):
        return _deny("legacy_checkpoint_invalid")
    # No original v1 save is written. A volatile bridge retains the exact
    # current state and returns to the same original scene if F8 is pressed.
    tree.set_meta(REVIEW_RETURN_SNAPSHOT, old_snapshot.duplicate(true))
    tree.set_meta(REVIEW_RETURN_PATH, LEGACY_ENTRY)
    var error: Error = tree.change_scene_to_file(REVISED_REVIEW)
    if error != OK:
        _clear(tree)
        return _deny("review_scene_change_failed")
    return {"ok": true, "reason": "opt_in_revised_opening_prototype", "reviewOnly": true}

static func leave(source: Node) -> Dictionary:
    if source == null or source.get_tree() == null:
        return _deny("missing_live_scene")
    var tree: SceneTree = source.get_tree()
    if tree.current_scene != source or source.scene_file_path != REVISED_REVIEW:
        return _deny("not_current_revised_review")
    if not tree.has_meta(REVIEW_RETURN_SNAPSHOT):
        return _deny("no_valid_prototype_return")
    if not tree.has_meta(REVIEW_RETURN_PATH) or tree.get_meta(REVIEW_RETURN_PATH) != LEGACY_ENTRY:
        return _deny("invalid_original_entry")
    var old: Variant = tree.get_meta(REVIEW_RETURN_SNAPSHOT)
    if not (old is Dictionary) or not bool(LegacyCodec.validate(old).get("ok", false)):
        return _deny("original_v1_state_invalid")
    tree.set_meta(RESTORE_PENDING, true)
    var error: Error = tree.change_scene_to_file(LEGACY_ENTRY)
    if error != OK:
        tree.remove_meta(RESTORE_PENDING)
        return _deny("legacy_scene_change_failed")
    return {"ok": true, "reason": "returning_to_legacy_review", "reviewOnly": true}

static func restore_pending(source: Node) -> Dictionary:
    # Called only after the original scene has built its UI and actors.
    if source == null or source.get_tree() == null:
        return _deny("missing_live_scene")
    var tree: SceneTree = source.get_tree()
    if not tree.has_meta(RESTORE_PENDING):
        return _deny("no_pending_review_return")
    if source.scene_file_path != LEGACY_ENTRY or not source.has_method("restore_save_snapshot"):
        return _deny("invalid_return_destination")
    var old: Variant = tree.get_meta(REVIEW_RETURN_SNAPSHOT, null)
    if not (old is Dictionary) or not bool(LegacyCodec.validate(old).get("ok", false)):
        return _deny("original_v1_state_invalid")
    if not source.restore_save_snapshot(old):
        return _deny("original_v1_restore_failed")
    _clear(tree)
    return {"ok": true, "reason": "original_v1_restored_in_memory", "reviewOnly": true}

static func _clear(tree: SceneTree) -> void:
    for key in [REVIEW_RETURN_SNAPSHOT, REVIEW_RETURN_PATH, RESTORE_PENDING]:
        if tree.has_meta(key):
            tree.remove_meta(key)

static func _deny(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason, "reviewOnly": true}
