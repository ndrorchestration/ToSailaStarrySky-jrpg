extends SceneTree
## Authentic Godot OpenGL/Xvfb screenshots of the local recovery and family
## REVIEW stage. Frames are runner-only visual evidence, NOT approved art.
const FlightScene = preload("res://scenes/first_wake_flight_water_review.tscn")
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _shot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("TSTSS_RECOVERY_NATIVE_CAPTURE_FAIL: invalid viewport for " + name)
        return null
    var path: String = OUTPUT + name
    if image.save_png(path) != OK:
        push_error("TSTSS_RECOVERY_NATIVE_CAPTURE_FAIL: could not write " + name)
        return null
    print("TSTSS_RECOVERY_NATIVE_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(path))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot make isolated runner-only screenshot directory")
        return
    var story = Opening.new()
    if not story.accept_ionia_job() or not story.complete_engineering_checks():
        _fail("opening review fixture cannot meet checked preflight")
        return
    var flight = FlightScene.instantiate()
    if not flight.configure_preflight(story):
        _fail("actual flight scene denied valid Ionia-first preflight")
        return
    root.add_child(flight)
    await process_frame
    if not flight.interact():
        _fail("first flight could not begin")
        return
    var warning := false
    for i in range(220):
        await process_frame
        if flight.phase == "warning":
            warning = true
            break
    if not warning or not flight.interact():
        _fail("local phase warning or safe descent was not available")
        return
    var floating := false
    for i in range(630):
        await process_frame
        if flight.phase == "waterborne":
            floating = true
            break
    if not floating or not flight.contact_observed or not flight.stable_float_verified:
        _fail("real water physics never achieved safe flotation")
        return
    var afloat: Image = await _shot("first-wake-waterborne-review-native-960x640.png")
    if afloat == null:
        quit(2)
        return
    if not flight.interact() or not flight.interact() or flight.phase != "recovery_approach":
        _fail("observed reserve and requested assisted approach were unavailable")
        return
    var approach: Image = await _shot("first-wake-recovery-approach-native-960x640.png")
    if approach == null:
        quit(3)
        return
    var contact := false
    for i in range(420):
        await physics_frame
        if flight.phase == "berth_contact":
            contact = true
            break
    if not contact or not flight.berth_area.overlaps_body(flight.ship_body):
        _fail("moving hull never made actual Godot berth sensor contact")
        return
    var contact_frame: Image = await _shot("first-wake-berth-contact-native-960x640.png")
    if contact_frame == null:
        quit(4)
        return
    if not flight.interact() or flight.phase != "berth_securing":
        _fail("player could not secure the lines")
        return
    var secured := false
    for i in range(230):
        await physics_frame
        if flight.phase == "berth_ready":
            secured = true
            break
    if not secured or not flight.review_snapshot()["local_2d_berth_approach_verified"]:
        _fail("real low-speed 2D berth stabilization was not observed")
        return
    var secure_frame: Image = await _shot("first-wake-berth-secured-native-960x640.png")
    if secure_frame == null:
        quit(5)
        return
    if not flight.interact() or flight.family_review == null:
        _fail("safe mooring did not reveal family meeting")
        return
    await process_frame
    var family_frame: Image = await _shot("first-wake-family-meeting-native-960x640.png")
    if family_frame == null:
        quit(6)
        return
    var family = flight.family_review
    if story.active_party_ids != ["ender", "ionia"] or family.scene_phase != "family_arrival":
        _fail("screenshot captured a prematurely recruited Lyra")
        return
    family.ender.position = family.LYRA_POSITION
    if not family.interact():
        _fail("mandatory family dialogue not interactable")
        return
    var budget := 20
    while family.dialogue_open and budget > 0:
        if not family.interact():
            _fail("family dialogue stopped unexpectedly")
            return
        budget -= 1
    if story.active_party_ids != ["ender", "ionia", "lyra"] or "talen" in story.active_party_ids:
        _fail("family visual study violated party chronology or Talen safety")
        return
    await process_frame
    var reunion: Image = await _shot("first-wake-lyra-joined-native-960x640.png")
    if reunion == null:
        quit(7)
        return

    var berth_crop := Rect2i(685, 286, 245, 252)
    if approach.get_region(berth_crop).get_data() == contact_frame.get_region(berth_crop).get_data():
        _fail("ship approach did not produce a genuinely different berth-region frame")
        return
    if contact_frame.get_region(berth_crop).get_data() == secure_frame.get_region(berth_crop).get_data():
        _fail("securing lines and stabilized mooring are visually indistinguishable")
        return
    var people_crop := Rect2i(20, 15, 930, 121)
    if family_frame.get_region(people_crop).get_data() == reunion.get_region(people_crop).get_data():
        _fail("Lyra's completed second-join party state is visually indistinguishable")
        return
    print("TSTSS_RECOVERY_NATIVE_CAPTURE_PASS: genuine renderer 960x640 ship afloat/approaching/berth contact/secured lines/family encounter/Lyra joined, distinct review frames")
    print("TSTSS_RECOVERY_ART_ACCEPTANCE=PENDING")
    flight.queue_free()
    await process_frame
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_RECOVERY_NATIVE_CAPTURE_FAIL: " + reason)
    quit(1)
