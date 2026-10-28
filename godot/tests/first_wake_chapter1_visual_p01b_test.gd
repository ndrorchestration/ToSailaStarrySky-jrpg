extends SceneTree
## P-01B: real configured Chapter I entry scene, actual save codec, physics and visual-only fixture.
## Noncanonical Lyra visual NEVER grants a party member or changes chapter state.
const SCENE := "res://scenes/first_wake_chapter1_player_preview.tscn"
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const SAVE_PATH := "user://qa/p01b_character_visual_isolation.json"

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("CH1_CHARACTER_P01B_FAIL: " + message)
    quit(code)

func _key(code: int) -> InputEventKey:
    var key := InputEventKey.new()
    key.keycode = code
    key.pressed = true
    return key

func _verify() -> void:
    var packed: PackedScene = load(SCENE)
    if packed == null:
        _fail("actual Chapter I configured main scene missing", 1)
        return
    var stage: Node = packed.instantiate()
    root.add_child(stage)
    await process_frame
    var original_actor: CharacterBody2D = stage.get("ender")
    var original_position: Vector2 = original_actor.global_position
    var original_parent: Node2D = stage.get_node("ChapterOneMigrationActors")
    var original_count: int = original_parent.get_child_count()
    var party_original: Array = stage.get("chapter").desired_active_party_ids().duplicate()
    var initial_snapshot: Dictionary = stage.call("export_save_snapshot")
    var original_json: String = JSON.stringify(initial_snapshot)
    if stage.call("is_character_visual_p01b_enabled") or stage.call("get_character_visual_p01b_actor") != null:
        _fail("prototype visible without explicit opt-in", 2)
        return
    if not (stage.get("character_visual_p01b") as Node).call("route_inside_bounds"):
        _fail("review route outside real chapter save-position envelope", 3)
        return
    if not original_parent.y_sort_enabled:
        _fail("real Chapter I actors are not in the expected depth sorting container", 4)
        return
    stage.call("_unhandled_input", _key(KEY_F6))
    var test_actor: CharacterBody2D = stage.call("get_character_visual_p01b_actor")
    if test_actor == null or not stage.call("is_character_visual_p01b_enabled"):
        _fail("F6 could not install the visual-only actor in real Chapter I", 5)
        return
    if test_actor.get_parent() != original_parent or test_actor.get("character_id") != "Lyra":
        _fail("incorrect parent or character visual source", 6)
        return
    if original_parent.get_child_count() != original_count + 1:
        _fail("unexpected side effects in actual actor hierarchy", 7)
        return
    var sources: Dictionary = test_actor.get("source_sprites")
    if sources.size() != 4:
        _fail("incomplete four-direction Lyra original atlas", 8)
        return
    for facing in FACINGS:
        var sprite: Sprite2D = sources.get(facing)
        if sprite == null or sprite.texture == null or sprite.hframes != 6 or sprite.flip_h:
            _fail("missing original six-phase native sprite " + facing, 9)
            return
        if sprite.texture.resource_path != "res://art-review/lyra-%s-sixphase-v1-unapproved.svg" % facing:
            _fail("art provenance changed " + facing, 10)
            return
    if JSON.stringify(stage.call("export_save_snapshot")) != original_json:
        _fail("snapshot mutated upon enabling an unrecruited visual", 11)
        return
    if stage.get("chapter").desired_active_party_ids() != party_original:
        _fail("character review changed chapter party", 12)
        return
    var visited := {"south": {}, "west": {}, "north": {}, "east": {}}
    var previous: Vector2 = test_actor.global_position
    var ticks := 0
    for i in range(330):
        await physics_frame
        if test_actor.get("completed"):
            break
        ticks += 1
        if test_actor.global_position.distance_to(previous) > 2.2:
            _fail("character fixture teleported during native travel", 13)
            return
        previous = test_actor.global_position
        if not Rect2(Vector2(110.0, 404.0), Vector2(740.0, 118.0)).has_point(previous):
            _fail("character fixture left real chapter player-position bounds", 14)
            return
        visited[test_actor.get("facing")][test_actor.get("current_phase")] = true
    if ticks < 255 or not test_actor.get("completed") or absf(test_actor.get("travel_distance") - 400.0) > 3.0:
        _fail("native First Wake Chapter I four-leg fixture did not finish", 15)
        return
    for facing in FACINGS:
        if visited[facing].size() < 6:
            _fail("not all six phase frames observed in Chapter I: " + facing, 16)
            return
    if original_actor.global_position != original_position or JSON.stringify(stage.call("export_save_snapshot")) != original_json:
        _fail("physical route mutated real Chapter I state", 17)
        return

    # Exercise actual durable save/restore while the review actor exists.
    var store: Object = stage.get("save_store")
    store.call("delete_slot", SAVE_PATH)
    if not stage.call("save_progress_to_disk", SAVE_PATH):
        _fail("real Chapter I snapshot cannot save while review fixture is enabled", 18)
        return
    if not FileAccess.file_exists(SAVE_PATH):
        _fail("native save bytes missing", 19)
        return
    var disk_json: String = FileAccess.get_file_as_string(SAVE_PATH)
    if disk_json.find("P01B") >= 0 or disk_json.find("Lyra") >= 0:
        _fail("noncanonical visual leaked into actual Chapter I save file", 20)
        return
    if not stage.call("load_progress_from_disk", SAVE_PATH):
        _fail("real Chapter I restore fails while review fixture is enabled", 21)
        return
    if JSON.stringify(stage.call("export_save_snapshot")) != original_json:
        _fail("load changed durable chapter identity/progression", 22)
        return
    if stage.get("chapter").desired_active_party_ids() != party_original:
        _fail("visual test accidentally recruited Lyra", 23)
        return
    if not stage.call("is_character_visual_p01b_enabled"):
        _fail("save/load unexpectedly reauthorized or deleted an unrelated in-memory test fixture", 24)
        return
    stage.call("_unhandled_input", _key(KEY_F6))
    await process_frame
    if stage.call("is_character_visual_p01b_enabled") or stage.call("get_character_visual_p01b_actor") != null:
        _fail("F6 off left an active unrecruited actor", 25)
        return
    if original_parent.get_child_count() != original_count or original_actor.global_position != original_position:
        _fail("stage actor roster or original player mutated after visual opt-out", 26)
        return
    if JSON.stringify(stage.call("export_save_snapshot")) != original_json:
        _fail("opt-out changed real player save bytes", 27)
        return
    store.call("delete_slot", SAVE_PATH)
    print("CH1_CHARACTER_P01B_SAVE_PASS:snapshot_bytes_unchanged:Lyra_not_recruited:real_save_load_ok")
    print("CH1_CHARACTER_P01B_WALK_PASS:ChapterI_entry_scene:400px:4 facings:6 phases:physics_move")
    print("CH1_CHARACTER_P01B_PASS:real Chapter I main entry-point scene; F6 isolated; source unchanged; save/party unchanged")
    print("CH1_CHARACTER_P01B_NATIVE_COLLIDING_DECK=NOT_ESTABLISHED")
    print("CH1_CHARACTER_P01B_REVISED_STORY_V2=NOT_EXERCISED")
    quit(0)
