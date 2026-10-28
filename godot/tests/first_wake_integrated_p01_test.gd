extends SceneTree
## Native integrated playable candidate P-01, NOT acceptance of the full slice.
## The actual existing player scene drives flyer/interview/engineering using its
## ordinary interaction API; the genuine RigidBody/Area detects ocean contact.
## Source recovery checklist is the exact port from review PR #477.
var problems: Array[String] = []
var checks: int = 0
var captured: Array[Image] = []
var capture_requested: bool = false

func _photo(name: String) -> void:
    for index in range(6):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    require(image != null and image.get_size() == Vector2i(960,640),
        "real native GL 960x640 framebuffer for "+name)
    if image == null or image.get_size() != Vector2i(960,640):
        return
    var folder: String = ProjectSettings.globalize_path("res://review-evidence/first-wake-integrated-p01")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        problems.append("cannot create capture folder")
        return
    var file: String = folder.path_join(name+".png")
    require(image.save_png(file) == OK, "native screenshot written "+name)
    captured.append(image.duplicate())
    print("TSTSS_FIRST_WAKE_P01_NATIVE_FRAME: "+file)

func _contrast(a: Image,b: Image) -> float:
    var value: float = 0.0
    for y in range(150,600,12):
        for x in range(55,910,12):
            var aa: Color = a.get_pixel(x,y)
            var bb: Color = b.get_pixel(x,y)
            value += absf(aa.r-bb.r)+absf(aa.g-bb.g)+absf(aa.b-bb.b)
    return value

func require(ok: bool, description: String) -> bool:
    checks += 1
    if not ok:
        problems.append(description)
    return ok

func _initialize() -> void:
    call_deferred("_verify")

func _finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return not world.dialogue_open

func _verify() -> void:
    capture_requested = OS.get_cmdline_user_args().has("--capture")
    var packed: PackedScene = load("res://scenes/first_wake_integrated_p01.tscn")
    if not require(packed != null, "actual job preview scene available"):
        _finish()
        return
    var scene = packed.instantiate()
    root.add_child(scene)
    await process_frame
    var before_party: Array = scene.opening.active_party_ids.duplicate()
    require(before_party == ["ender"], "starts with Ender alone")
    require(not scene.launch_flight_review(), "no premature flight or free party")
    scene.ender.position = scene.IONIA_DOCK_POSITION
    require(not scene.interact(), "cannot recruit without flyer")

    scene.ender.position = scene.FLYER_POSITION
    require(scene.interact() and scene.dialogue_open, "player discovers flyer")
    require(_finish_dialogue(scene), "player reads actual flyer dialogue")
    require(scene.flyer_read, "flyer evidence survives finished dialogue")
    scene.ender.position = scene.IONIA_DOCK_POSITION
    require(scene.interact() and scene.dialogue_open, "player interviews captain")
    require(_finish_dialogue(scene), "Ionia hire dialogue completes")
    require(scene.opening.active_party_ids == ["ender", "ionia"], "Ionia joins FIRST")
    scene.ender.position = scene.GANGWAY_POSITION
    require(scene.interact() and scene.room == "engineering", "player uses gangway")
    scene.ender.position = scene.ROOM_POSITIONS["checklist"]
    require(not scene.interact(), "preflight denied before three observations")
    for station in ["fuel", "reference", "containment"]:
        scene.ender.position = scene.ROOM_POSITIONS[station]
        require(scene.interact() and scene.dialogue_open, "physical station "+station)
        require(_finish_dialogue(scene), "station dialogue "+station)
        require(station in scene.inspected_items, "evidence "+station)
    scene.ender.position = scene.ROOM_POSITIONS["checklist"]
    require(scene.interact() and scene.dialogue_open, "authorized safety checklist")
    require(_finish_dialogue(scene), "captain preflight dialogue")
    require(scene.opening.step_key() == "preflight", "preflight gated and complete")
    require(scene.launch_flight_review(), "player enters native flight handoff")
    var flight = scene.flight_review
    require(flight != null and flight.opening == scene.opening,
        "no second story/party owner between scenes")
    require(flight.enable_3d_cinematic_inset, "source-original 3D ship presented")
    require(not flight.begin_recovery_readiness(), "reject recovery before launch")
    require(not flight.start_postflight_inspection(), "reject empty-reserve claim before water")
    require(flight.interact(), "player launches actual local physics flight")
    var warning: bool = false
    for tick in range(200):
        await process_frame
        if flight.phase == "warning":
            warning = true
            break
    require(warning, "flight develops warning after actual physics updates")
    require(not flight.begin_recovery_readiness(), "warning cannot open recovery")
    require(flight.interact() and flight.opening.failure_logged,
        "player orders controlled descent after warnings")
    require(not flight.start_postflight_inspection(), "descent cannot claim waterborne diagnosis")
    var afloat: bool = false
    for tick in range(650):
        await process_frame
        if flight.phase == "waterborne":
            afloat = true
            break
    if not require(afloat, "real Area2D contact and stable buoyancy"):
        scene.queue_free()
        _finish()
        return
    var receipt: Dictionary = flight.review_snapshot()
    require(receipt["actual_2d_area_contact_observed"], "real water sensor receipt")
    require(receipt["stable_buoyant_hull_observed"], "settled 2D buoyancy")
    require(not receipt["production_ocean_verified"], "no false planetary sea claim")
    require(receipt["story_step"] == "waterborne", "same authoritative story reached water")
    require(not flight.begin_recovery_readiness(), "recovery not offered before inspection")
    if capture_requested:
        await _photo("01-waterborne-actual-physics")
    require(not flight.advance_postflight_inspection(), "cannot finish nonstarted dialogue")
    require(flight.interact(), "player starts postflight reserve inspection")
    require(not flight.begin_recovery_readiness(), "dialogue prevents recovery shortcut")
    for n in range(flight.POSTFLIGHT_INSPECTION_LINES.size()):
        require(flight.interact(), "read postflight observation "+str(n))
    receipt = flight.review_snapshot()
    require(receipt["story_step"] == "postflight_diagnosis",
        "reserve dialogue completes actual story progression")
    require(receipt["postflight_reserve_observed"],
        "diagnosis receipt persisted from player reading")
    require(not receipt["inspection_dialogue_open"], "no open diagnostic dialogue")
    if capture_requested:
        await _photo("02-engine-reserve-diagnosis")
    require(flight.begin_recovery_readiness(), "authorized recovery readiness follows diagnosis")
    require(not flight.begin_recovery_readiness(), "cannot start duplicate recovery")
    var readiness = flight.recovery_review
    require(readiness != null and readiness.opening == scene.opening,
        "recovery consumes SAME source story object")
    require(not flight.flight_overlay.visible, "no conflicting flight HUD over checklist")
    require(readiness.phase == "inspect", "review starts with zero completed checks")
    require(not readiness.interact(), "checklist cannot complete without selecting station")
    require(not readiness.inspect_station("unknown"), "invalid station denied")
    for station in ["systems_isolation", "crew_accounting", "contact_plan"]:
        require(readiness.inspect_station(station), "player chooses "+station)
        require(station not in readiness.completed_stations, "station not awarded early")
        var lines: Array[String] = readiness._station_lines(station)
        for line in range(lines.size()):
            require(readiness.interact(), "player reads station "+station+" "+str(line))
        require(station in readiness.completed_stations, "station earned after dialogue")
        require(not readiness.inspect_station(station), "no duplicate evidence "+station)
    var finish: Dictionary = readiness.review_snapshot()
    require(finish["readiness_review_complete"], "three observed readiness checks")
    require(finish["phase"] == "ready_for_route_review", "ends at honest route hold")
    require(finish["route_status"] == "awaiting_creator_geography", "geography NOT invented")
    for forbidden in ["actual_sailing_route_verified", "message_delivered",
            "safe_family_meeting_verified", "recovery_success_certified",
            "fuel_formula_verified"]:
        require(not finish[forbidden], "no unearned claim "+forbidden)
    require(finish["party"] == ["ender", "ionia"], "Lyra waits for safe meeting")
    require("talen" not in finish["party"], "Talen remains a noncombat child")
    require(scene.opening.step_key() == "postflight_diagnosis",
        "recovery checklist does NOT silently advance story or fuel formula")
    require(not readiness.interact(), "route-hold finish cannot progress without approved geography")
    require(flight.ship_body.freeze and flight.contact_observed,
        "physical hull remains settled at route hold")
    if capture_requested:
        await _photo("03-crew-recovery-route-hold")
        require(captured.size() == 3, "all three native GL proof frames exist")
        if captured.size() == 3:
            var diagnosis_delta: float = _contrast(captured[0], captured[1])
            var recovery_delta: float = _contrast(captured[1], captured[2])
            print("TSTSS_FIRST_WAKE_P01_DELTAS diagnosis=",diagnosis_delta,
                " recovery=",recovery_delta)
            require(diagnosis_delta > 0.2, "postflight inspection changes actual UI")
            require(recovery_delta > 8.0, "recovery scene draws its own visual state")
    scene.queue_free()
    await process_frame
    _finish()

func _finish() -> void:
    if problems.is_empty():
        if capture_requested:
            print("TSTSS_FIRST_WAKE_INTEGRATED_P01_GL_PASS frames=3")
        print("TSTSS_FIRST_WAKE_INTEGRATED_P01_PASS checks=",checks,
            " route=job_flyer/ionia_hire/engineering/preflight/native_flight/",
            "physics_waterborne/observed_reserve/recovery_3_checks/geography_hold")
        quit(0)
    else:
        for issue in problems:
            push_error("TSTSS_FIRST_WAKE_INTEGRATED_P01_FAIL: "+issue)
        quit(1)
