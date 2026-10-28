extends SceneTree
## Original runner-local Godot screenshots for the two-area Chapter I
## material search. The opening story state below is a render fixture ONLY.
## No official world locations, final art or durable inventory is claimed.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Scene = preload("res://scenes/first_wake_salvage_review.tscn")
const OUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _shot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img == null or img.is_empty() or img.get_size() != Vector2i(960, 640):
        push_error("TSTSS_SALVAGE_NATIVE_CAPTURE_FAIL: invalid 960x640 view")
        return null
    var path: String = OUT + name
    if img.save_png(path) != OK:
        push_error("TSTSS_SALVAGE_NATIVE_CAPTURE_FAIL: PNG write error " + name)
        return null
    print("TSTSS_SALVAGE_NATIVE_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(path))
    return img

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        _fail("runner-only review output path unavailable")
        return
    var story = Opening.new()
    story.accept_ionia_job()
    story.complete_engineering_checks()
    story.begin_test_flight()
    story.record_engine_failure(true, true, true)
    story.complete_ocean_splashdown(true, true)
    story.inspect_postflight_reserve(true)
    story.introduce_lyra_and_talen(true)
    story.record_clue("phase_readings")
    story.record_clue("lyra_observation")
    story.form_working_fuel_theory()
    var world = Scene.instantiate()
    if not world.configure_after_theory(story):
        _fail("source scene rejected legitimate family theory fixture")
        return
    root.add_child(world)
    await process_frame
    var quay_before: Image = await _shot("first-wake-salvage-quay-before-native-960x640.png")
    if quay_before == null:
        quit(2)
        return
    world.ender.position = world.QUAY_SUPPLY
    if not world.interact():
        _fail("visible quay salvage item not collectible")
        return
    await process_frame
    var quay_after: Image = await _shot("first-wake-salvage-quay-collected-native-960x640.png")
    if quay_after == null:
        quit(3)
        return
    world.ender.position = world.QUAY_TO_DEPOT
    if not world.interact() or world.region != world.DEPOT:
        _fail("salvage transition to depot not available")
        return
    await process_frame
    var depot: Image = await _shot("first-wake-salvage-depot-native-960x640.png")
    if depot == null:
        quit(4)
        return
    world.ender.position = world.DEPOT_PART
    if not world.interact():
        _fail("depot physical replacement part not collectible")
        return
    world.ender.position = world.DEPOT_TO_QUAY
    if not world.interact() or world.region != world.QUAY:
        _fail("cannot return with item to source quay")
        return
    await process_frame
    var return_frame: Image = await _shot("first-wake-salvage-return-native-960x640.png")
    if return_frame == null:
        quit(5)
        return
    world.ender.position = world.RETURN_TO_WAKE
    if not world.interact() or world.workshop == null:
        _fail("returned physical inventory not accepted by workshop")
        return
    await process_frame
    var repair: Image = await _shot("first-wake-salvage-installed-pending-native-960x640.png")
    if repair == null:
        quit(6)
        return

    var quarry_rect := Rect2i(195, 270, 220, 260)
    if quay_before.get_region(quarry_rect).get_data() == quay_after.get_region(quarry_rect).get_data():
        _fail("quay collected item did not visibly change in actual native pixels")
        return
    var area_rect := Rect2i(50, 230, 860, 304)
    if quay_after.get_region(area_rect).get_data() == depot.get_region(area_rect).get_data():
        _fail("quay and annex environments are not distinguishable in native pixels")
        return
    var item_rect := Rect2i(10, 10, 940, 152)
    if quay_after.get_region(item_rect).get_data() == return_frame.get_region(item_rect).get_data():
        _fail("carried two-item HUD did not differ from one-item HUD")
        return
    if return_frame.get_region(area_rect).get_data() == repair.get_region(area_rect).get_data():
        _fail("return to ship and real installation workshop not visually different")
        return
    if world.workshop.core != world.core or world.workshop.core.snapshot()["phase"] != "install":
        _fail("screenshot captured a fabricated or already installed core")
        return
    print("TSTSS_SALVAGE_NATIVE_CAPTURE_PASS: five real Godot 960x640 different quay, pickup, depot, return and engine workshop frames")
    print("TSTSS_SALVAGE_ART_ACCEPTANCE=PENDING; TSTSS_SALVAGE_ARTIFACT_DISTRIBUTION=RUNNER_ONLY")
    world.queue_free()
    await process_frame
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_SALVAGE_NATIVE_CAPTURE_FAIL: " + reason)
    quit(1)
