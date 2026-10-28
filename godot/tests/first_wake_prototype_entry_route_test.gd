extends SceneTree
## Runs from the *actual configured default Godot scene* with a genuine
## SceneTree scene change. Verifies opt-in F8 travel and exact legacy v1 return.
const StartupScene = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Route = preload("res://scripts/first_wake_prototype_route.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const SaveStore = preload("res://scripts/first_wake_chapter1_save_store.gd")
const RevisedCodec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if ProjectSettings.get_setting("application/run/main_scene", "") != Route.LEGACY_ENTRY:
        _fail("default main scene was replaced, not bridged")
        return
    var v1_before: String = _sha(SaveStore.DEFAULT_PATH)
    var v2_before: String = _sha(RevisedCodec.SLOT_PATH)
    var err: Error = change_scene_to_packed(StartupScene)
    if err != OK:
        _fail("could not open current default Godot entry")
        return
    await process_frame
    var original = current_scene
    if original == null or original.scene_file_path != Route.LEGACY_ENTRY:
        _fail("original main scene did not instantiate")
        return
    if not InputMap.has_action(InputPolicy.PROTOTYPE_ROUTE):
        _fail("opt-in F8 action was not registered")
        return
    if not original.prototype_hint.text.contains("F8") or not original.prototype_hint.text.contains("PROTOTYPE"):
        _fail("existing main screen lacks a readable opt-in launch hint")
        return

    # An in-progress encounter must not be silently discarded by entering the
    # prototype. Test the actual combat gate before altering any scene.
    if not original.start_formula_review():
        _fail("could not begin real optional formula review")
        return
    if Route.enter(original).get("ok", true):
        _fail("entered revised preview during active combat")
        return
    if not original.close_formula_review():
        _fail("could not close formula review")
        return

    original.review_hull_integrity = 83
    original.review_morale = 62
    original.review_engine_integration = 21
    original.ender.position = Vector2(509, 474)
    var preserved: Dictionary = original.export_save_snapshot()
    if not SaveCodec.validate(preserved).get("ok", false):
        _fail("legacy in-memory return state was not valid v1")
        return
    var f8 = InputEventKey.new()
    f8.keycode = KEY_F8
    f8.pressed = true
    original._unhandled_input(f8)
    await process_frame
    var preview = current_scene
    if preview == null or preview.scene_file_path != Route.REVISED_REVIEW:
        _fail("F8 from startup did not open the playable new opening")
        return
    if preview.opening.active_party_ids != ["ender"] or preview.opening.step_key() != "job_search":
        _fail("preview did not start with Ender only")
        return
    if not preview.resonance_status_label.text.contains("LOCKED"):
        _fail("preview bypassed the pre-Lyra Resonance gate")
        return
    if not preview.hint.text.contains("F8: return"):
        _fail("review screen does not tell player how to return")
        return
    if not has_meta(Route.REVIEW_RETURN_SNAPSHOT) or has_meta(Route.RESTORE_PENDING):
        _fail("volatile original scene snapshot missing or already consumed")
        return
    if _sha(SaveStore.DEFAULT_PATH) != v1_before or _sha(RevisedCodec.SLOT_PATH) != v2_before:
        _fail("navigation unexpectedly wrote persistent v1 or v2 data")
        return

    # Route back through actual F8 event and require an exact original state,
    # not a new chapter or a conversion from the Ionia-first v2 checkpoint.
    preview._unhandled_input(f8)
    await process_frame
    var returned = current_scene
    if returned == null or returned.scene_file_path != Route.LEGACY_ENTRY:
        _fail("F8 did not navigate back to original startup scene")
        return
    if returned.export_save_snapshot() != preserved:
        _fail("volatile v1 snapshot not restored exactly after scene change")
        return
    if returned.dialogue.open or returned.formula_encounter.active:
        _fail("review return unexpectedly kept transient dialogue or combat")
        return
    if not returned.last_message.contains("original Chapter I state restored"):
        _fail("return UI did not make isolated review semantics readable")
        return
    if has_meta(Route.REVIEW_RETURN_SNAPSHOT) or has_meta(Route.REVIEW_RETURN_PATH) or has_meta(Route.RESTORE_PENDING):
        _fail("volatile navigation keys were not cleared on return")
        return
    if _sha(SaveStore.DEFAULT_PATH) != v1_before or _sha(RevisedCodec.SLOT_PATH) != v2_before:
        _fail("return corrupted or rewrote on-disk checkpoint slots")
        return
    if Route.leave(returned).get("ok", true):
        _fail("unrelated legacy scene was accepted as a return source")
        return

    # The bridge must be repeatable without retaining the first session or
    # changing the story parties, class unlocks, or persistent save format.
    returned._unhandled_input(f8)
    await process_frame
    if current_scene == null or current_scene.scene_file_path != Route.REVISED_REVIEW:
        _fail("second opt-in visit was refused after volatile cleanup")
        return
    current_scene._unhandled_input(f8)
    await process_frame
    if current_scene == null or current_scene.export_save_snapshot() != preserved:
        _fail("second review return changed original Chapter I state")
        return

    print("TSTSS_FIRST_WAKE_PROTO_ENTRY_PASS: actual Godot main scene F8 -> revised Ionia-first review -> original v1 state, no disk writes or Resonance unlock")
    quit(0)

func _sha(path: String) -> String:
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_PROTO_ENTRY_FAIL: " + reason)
    quit(1)
