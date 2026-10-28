extends SceneTree
## TEST-ONLY generated fixtures prove the 4-way art contract, NOT visual quality.
const Motion = preload("res://scripts/creator_motion_pack.gd")
const Game = preload("res://scenes/first_wake_game.tscn")
var errors: Array[String] = []
var assertions := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    assertions += 1
    if not ok:
        errors.append(reason)
        push_error("TSTSS_AUTHORED_MOTION_CONTRACT_FAIL:" + reason)

func _image(direction: int, index: int) -> Image:
    var img := Image.create(96, 144, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var main := [
        Color("#6d8eb3"), Color("#5b8365"), Color("#8e6c5e"), Color("#8882ad")
    ][direction] as Color
    # Synthetic stick-person fixture, deliberately NOT a source-faithful sprite.
    for y in range(13, 38):
        for x in range(35, 60):
            img.set_pixel(x, y, Color("#ddba9b"))
    for y in range(38, 113):
        for x in range(29, 67):
            img.set_pixel(x, y, main)
    # Different authored pixel patterns per frame: two moving boot silhouettes.
    var offset: int = index * 3 - 8
    for y in range(112, 143):
        for x in range(33 + offset, 46 + offset):
            if x >= 0 and x < 96:
                img.set_pixel(x, y, Color("#3b3334"))
        for x in range(54 - offset, 66 - offset):
            if x >= 0 and x < 96:
                img.set_pixel(x, y, Color("#4e3830"))
    # Direction-dependent detail, with independent non-mirrored pixels.
    for y in range(45, 104):
        img.set_pixel(38 + direction * 5 + index, y, Color("#e2b372"))
    return img

func _write_json(path: String, value: Dictionary) -> bool:
    var io := FileAccess.open(path, FileAccess.WRITE)
    if io == null:
        return false
    io.store_string(JSON.stringify(value, "  "))
    io.close()
    return true

func _make_fixture(person: String) -> String:
    var root_path: String = "user://tstss_motion_fixture_contract_" + person
    var manifest := {
        "schema_version": 1,
        "character": person,
        "intent": "review_only",
        "source_reference": "TEST_FIXTURE_ONLY_not_creator_art",
        "directions": {}
    }
    for d in Motion.DIRECTIONS:
        var folder := root_path.path_join(d)
        if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK:
            check(false, "cannot create synthetic test fixture folder")
            return ""
        var hashes: Array[String] = []
        for i in range(Motion.FRAME_COUNT):
            var img := _image(Motion.DIRECTIONS.find(d), i)
            var filename := folder.path_join("%02d.png" % i)
            check(img.save_png(filename) == OK, "failed creating synthetic review-only fixture")
            hashes.append(FileAccess.get_sha256(filename))
        manifest["directions"][d] = hashes
    check(_write_json(root_path.path_join("manifest.json"), manifest),
        "could not write fixture manifest")
    return root_path

func _read_json(path: String) -> Dictionary:
    var data = JSON.parse_string(FileAccess.get_file_as_string(path))
    return data if data is Dictionary else {}

func _run() -> void:
    var root_ender: String = _make_fixture("ender")
    var root_ionia: String = _make_fixture("ionia")
    if root_ender.is_empty() or root_ionia.is_empty():
        quit(1)
        return
    var a = Motion.new()
    check(a.load_from_directory(root_ender, "ender"), "complete 24-frame fixture should import: " + a.error_message)
    check(a.loaded and a.frame_count() == 24, "not exactly 24 frames loaded")
    check(a.source_reference.begins_with("TEST_FIXTURE"), "test fixture source provenance discarded")
    check(a.snapshot().get("approved_for_production") == false, "test pack falsely approved")
    check(a.get_frame("south", 0) != null and a.get_frame("north", 5) != null,
        "authored direction frames are inaccessible")
    check(a.get_frame("south", 2) != a.get_frame("south", 3),
        "different source frames collapsed into one object")
    check(a.get_frame("up", 3) == null and a.get_frame("west", 6) == null,
        "undefined directions/phases were incorrectly invented")
    var wrong = Motion.new()
    check(not wrong.load_from_directory(root_ender, "ionia"), "wrong actor identity accepted")
    var empty = Motion.new()
    check(not empty.load_from_directory("user://nonexistent_authored_motion", "ender"),
        "missing creator asset must fail closed")

    var scene = Game.instantiate()
    root.add_child(scene)
    await process_frame
    check(scene.job != null and scene.postflight == null, "true First Wake entry broken")
    if scene.job != null:
        var dock = scene.job
        var ender = dock.ender
        var ionia = dock.ionia
        check(not ender.creator_motion_enabled and not ionia.creator_motion_enabled,
            "no optional motion should be enabled on ordinary F5")
        var o_key := InputEventKey.new()
        o_key.pressed = true
        o_key.keycode = KEY_O
        dock._unhandled_input(o_key)
        check(not ender.creator_motion_enabled and not ionia.creator_motion_enabled,
            "O must not invent missing private art in F5")
        check("both complete" in dock.last_message, "missing assets not clearly explained")
        ender.creator_motion_root_override = root_ender
        ionia.creator_motion_root_override = root_ionia
        dock._unhandled_input(o_key)
        check(ender.creator_motion_enabled and ionia.creator_motion_enabled,
            "O could not enable fully verified local frames on both true actors")
        check(ender.creator_motion_snapshot().get("frames_loaded") == 24 and
            ionia.creator_motion_snapshot().get("frames_loaded") == 24,
            "motion preview did not bind all 48 test-only frames")
        check(ender.creator_motion_sprite != null and
            ender.creator_motion_sprite.texture != null and
            ender.creator_motion_sprite.visible,
            "real physics actor did not display a motion frame")
        check(not ender.walk_review_sprite.visible and
            not ionia.ionia_front_walk_sprite.visible,
            "provisional/rejected art leaked through verified authoring fixture")
        var collider_count := 0
        for child in ender.get_children():
            if child is CollisionShape2D:
                collider_count += 1
        check(collider_count == 1, "motion system added or removed collision shapes")
        ender.walk_facing = "west"
        ender.travel_distance = ender.PIXELS_PER_STEP * 3.2
        ender._sync_creator_motion_frame()
        check(ender.creator_motion_sprite.texture ==
            ender.creator_motion_pack.get_frame("west", 3),
            "distance-driven frame does not use authored west phase 3")
        ionia.ionia_facing = "north"
        ionia.travel_distance = ionia.PIXELS_PER_STEP * 5.2
        ionia._sync_creator_motion_frame()
        check(ionia.creator_motion_sprite.texture ==
            ionia.creator_motion_pack.get_frame("north", 5),
            "Ionia actor cannot independently resolve authored north frame")
        # Observe actual CharacterBody2D displacement and frame selection under
        # Godot's physics loop; don't infer movement from a timer or UI animation.
        var start_x: float = ender.position.x
        Input.action_press("ui_right")
        for tick in range(24):
            await physics_frame
        Input.action_release("ui_right")
        await physics_frame
        check(ender.position.x > start_x + 10.0, "player actor did not physically move")
        check(ender.walk_facing == "east", "real movement did not update facing")
        var physical_frame: int = int(ender.travel_distance / ender.PIXELS_PER_STEP) % 6
        check(ender.creator_motion_sprite.texture ==
            ender.creator_motion_pack.get_frame("east", physical_frame),
            "actual distance-driven movement did not select the matching authored frame")
        check(absf(ender.creator_motion_sprite.position.y + 72.0 * 0.78) < 0.01,
            "render-only motion sprite drifted away from ground origin")
        # Ionia's existing scripted walk route remains a real physics trajectory.
        ionia.set_ionia_route_review_enabled(true)
        var start_ionia: Vector2 = ionia.position
        for tick in range(18):
            await physics_frame
        check(ionia.position.distance_to(start_ionia) > 5.0,
            "Ionia route must physically move, not advance a fake animation timer")
        check(ionia.creator_motion_sprite.texture ==
            ionia.creator_motion_pack.get_frame(ionia.ionia_facing,
                int(ionia.travel_distance / ionia.PIXELS_PER_STEP) % 6),
            "Ionia active route did not synchronize with source-authored frame atlas")
        ionia.set_ionia_route_review_enabled(false)
        ionia.set_ionia_stage_art_enabled(true, ionia.ionia_facing)
        check(scene.session.opening.active_party_ids == ["ender"],
            "source art preview recruited a party member")
        check(not scene.session.can_checkpoint(), "motion preview granted save checkpoint")
        dock._unhandled_input(o_key)
        check(not ender.creator_motion_enabled and not ionia.creator_motion_enabled,
            "O cannot revert motion preview")
        check(ender.walk_review_sprite.visible and ionia.ionia_front_walk_sprite.visible,
            "O did not restore current legacy field actors after actual physical movement")
        # Optional genuine creator still source check on the artist's private
        # Windows worktree. Public CI has no private JPEGs/PNGs and skips only
        # this *source-dependent* restore assertion, not the motion contract.
        if ender.has_creator_standee() and ionia.has_creator_standee():
            check(ender.enable_creator_standee(true) and
                ionia.enable_creator_standee(true), "private static source did not load")
            dock._unhandled_input(o_key)
            check(ender.creator_motion_enabled and ionia.creator_motion_enabled and
                not ender.creator_standee_enabled and not ionia.creator_standee_enabled,
                "O should temporarily replace static preview with verified authored frames")
            dock._unhandled_input(o_key)
            check(not ender.creator_motion_enabled and not ionia.creator_motion_enabled and
                ender.creator_standee_enabled and ionia.creator_standee_enabled,
                "O did not restore the exact creator static preview state")
            ender.enable_creator_standee(false)
            ionia.enable_creator_standee(false)

    # Tamper checks are performed AFTER the live test so fixture changes cannot
    # give false success to the actual actor integration.
    var original: Dictionary = _read_json(root_ender.path_join("manifest.json"))
    var duplicate: Dictionary = original.duplicate(true)
    duplicate["directions"]["south"][1] = duplicate["directions"]["south"][0]
    check(_write_json(root_ender.path_join("manifest.json"), duplicate), "duplicate manifest write")
    var repeated = Motion.new()
    check(not repeated.load_from_directory(root_ender, "ender"),
        "duplicate still frame incorrectly accepted as authored movement")
    var missing: Dictionary = original.duplicate(true)
    missing["directions"].erase("north")
    check(_write_json(root_ender.path_join("manifest.json"), missing), "missing direction write")
    var partial = Motion.new()
    check(not partial.load_from_directory(root_ender, "ender"),
        "three-direction pack incorrectly accepted")
    check(_write_json(root_ender.path_join("manifest.json"), original), "restore fixture")
    var bad_image := _image(0, 0)
    bad_image.set_pixel(4, 4, Color.RED)
    check(bad_image.save_png(root_ender.path_join("south/00.png")) == OK, "tamper image write")
    var tampered = Motion.new()
    check(not tampered.load_from_directory(root_ender, "ender"),
        "changed pixel without matching original digest accepted")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_AUTHORED_MOTION_CONTRACT_PASS checks=", assertions,
            " frames=48 fixture_only=true input_O=true 4way_6frames=true source_qa_hold=true story_unchanged=true")
    quit(0 if errors.is_empty() else 1)
