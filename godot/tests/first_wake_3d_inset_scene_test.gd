extends SceneTree
## Live Chapter I Godot scene test: actual 3D SubViewport and exact original
## procedural Aureate Wake ship mesh, with the 2D water/plot contract unchanged.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const Handoff = preload("res://scripts/first_wake_cinematic_handoff.gd")
var checks: int = 0
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        problems.append(message)

func _run() -> void:
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    check(not world.launch_flight_review(), "cannot access ship before hiring Ionia")
    check(world.opening.accept_ionia_job(), "actual creator-directed Ionia recruitment")
    world._enter_engineering_room()
    for item in ["reference", "containment", "fuel"]:
        world.inspected_items.append(item)
    check(world.opening.complete_engineering_checks(), "real first-flight preflight")
    check(world.launch_flight_review(), "actual job scene attaches local flight review")
    var flight = world.flight_review
    check(flight != null, "actual 2D flight controller exists")
    if flight == null:
        _fail("missing authoritative flight")
        return
    check(flight.enable_3d_cinematic_inset, "full native review enables 3D inset")
    check(world.opening.active_party_ids == ["ender", "ionia"], "correct crew in first flight")
    check(flight.ship_body is RigidBody2D and flight.sea_area is Area2D,
        "physics contact authority still belongs exclusively to original native 2D")
    check(flight.cinematic_inset != null, "Godot 3D view actually mounted in flight UI")
    if flight.cinematic_inset == null:
        _fail("inset did not mount")
        return
    var inset = flight.cinematic_inset
    var snapshot: Dictionary = flight.visual_review_snapshot()
    check(snapshot.get("is_actual_native_3d_subviewport", false),
        "real native SubViewport and original ship actually instantiated")
    check(snapshot.get("ship_mesh_present", false), "original 3D lofted hull is present")
    check(snapshot.get("camera_shot", "") == "bow-quarter", "real preflight camera matches mapping")
    check(snapshot.get("visual_grade", "") == "golden-clear",
        "no canonical storm added to first flight")
    check(not snapshot.get("visual_water_has_physics", true), "inset water must never own physics")
    check(not snapshot.get("original_study_weather_shaders_imported", true),
        "ported ship mesh does not falsely claim all original world shaders")
    check(inset.viewport is SubViewport and inset.viewport.own_world_3d,
        "isolated actual Godot World3D; no physics-world sharing")
    check(inset.shot_camera is Camera3D and inset.shot_camera.current,
        "rendering camera is genuine and active")
    for name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        check(inset.ship_model.has_node("WingRig_" + name), "actual original wing " + name)
    check(inset.ship_model.has_node("LongHull"), "actual original rootwood hull")
    var origin: Transform2D = flight.ship_body.transform
    var fsm: Dictionary = world.opening.snapshot().duplicate(true)
    var shader_preview: Dictionary = Handoff.build(flight.review_snapshot(), true, true, true)
    check(inset.set_visual_intent(shader_preview), "opt-in review lighting and accessibility applied")
    check(inset.last_grade == "storm-night-study" and inset.use_reduced_motion
        and inset.use_low_detail, "inset honors experimental grade and reduced-motion controls")
    check(flight.ship_body.transform == origin, "changing only 3D camera preserves physics body")
    check(world.opening.snapshot() == fsm, "changing only 3D lighting preserves story state")
    var forged: Dictionary = shader_preview.duplicate(true)
    forged["blocks_progression"] = true
    check(not inset.set_visual_intent(forged), "disallowed visual descriptor fails closed")
    forged = shader_preview.duplicate(true)
    forged["visual_source_pr"] = 999
    check(not inset.set_visual_intent(forged), "unknown visual source rejected")
    # Restore gold/default and leave all original state transitions authoritative.
    var gold: Dictionary = Handoff.build(flight.review_snapshot())
    check(inset.set_visual_intent(gold), "gold/day source restored")
    check(flight.begin_short_test_flight(), "real physical first lift")
    snapshot = flight.visual_review_snapshot()
    check(snapshot.get("camera_shot", "") == "wing-planform", "3D camera follows real lift phase")
    var warned := false
    for i in range(180):
        await process_frame
        if flight.phase == "warning":
            warned = true
            break
    check(warned, "physics flight reaches actual phase warning")
    if warned:
        check(flight.visual_review_snapshot().get("camera_shot", "") == "stern-quarter",
            "warning changes only real 3D camera")
        check(flight.stabilize_for_water_descent(), "controlled 2D descent authoritatively accepted")
        check(flight.visual_review_snapshot().get("camera_shot", "") == "bow-quarter",
            "descent switches visual source without asserting water")
        var landed := false
        for i in range(540):
            await process_frame
            if flight.phase == "waterborne":
                landed = true
                break
        check(landed, "actual RigidBody2D/Area2D contact plus flotation achieved")
        if landed:
            check(flight.contact_observed and flight.stable_float_verified,
                "native 2D physics verified independently of viewport")
            check(flight.visual_review_snapshot().get("camera_shot", "") == "stern-quarter",
                "final 3D view selects only a retrospective stern image")
            check(world.opening.active_party_ids == ["ender", "ionia"],
                "no premature Lyra party joins")
            check(not flight.review_snapshot()["production_ocean_verified"],
                "full 3D production ocean not certified")
    world.queue_free()
    await process_frame
    if problems.is_empty():
        print("TSTSS_FIRST_WAKE_3D_INSET_PASS checks=", checks,
            " actual-native-3d=true 2d-water-physics=true canon-admitted=false")
        quit(0)
    else:
        for problem in problems:
            push_error("TSTSS_FIRST_WAKE_3D_INSET_FAIL: " + problem)
        quit(1)

func _fail(message: String) -> void:
    push_error("TSTSS_FIRST_WAKE_3D_INSET_FAIL: " + message)
    quit(1)
