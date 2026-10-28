extends SceneTree
## Source-original PW-01 shader, now composited on actual Chapter I 3D ship.
## Three complete real physics trials, no magic/save/crew/weather promotion.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const Envelope = preload("res://scripts/cinematic_vfx_envelope.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(test: bool, claim: String) -> void:
    checks += 1
    if not test:
        failures.append(claim)

func _run() -> void:
    check(Envelope.PHASES == [
        "anticipation", "formation", "release", "impact", "aftermath"],
        "original five-phase neutral VFX timing is unchanged")
    check(is_equal_approx(Envelope.DURATION_SECONDS, 2.4),
        "original bounded VFX timing remains intact")
    for mode in ["enabled", "disabled", "interrupted"]:
        var job = Preview.instantiate()
        root.add_child(job)
        await process_frame
        check(not job.launch_flight_review(), "boarding requires actual recruitment")
        check(job.opening.accept_ionia_job(), "captain joins first")
        job._enter_engineering_room()
        for key in ["reference", "containment", "fuel"]:
            job.inspected_items.append(key)
        check(job.opening.complete_engineering_checks(), "preflight checks passed")
        check(job.launch_flight_review(), "legitimate Chapter I flight handoff")
        var flight = job.flight_review
        if flight == null or flight.cinematic_inset == null:
            failures.append("missing real 3D flight stage")
            break
        var inset = flight.cinematic_inset
        check(inset.wide_stage_enabled and inset.viewport.size == Vector2i(960, 442),
            "original-source 3D ship renders in wide stage")
        check(inset.warning_visual != null and inset.warning_visual.shader_material is ShaderMaterial,
            "genuine original PW01 engine lens shader is in combined scene")
        check(inset.warning_visual.get_parent() == inset,
            "lens is a CanvasItem overlay rather than modifying physics hull")
        check(inset.ship_model.has_node("LongHull") and
            inset.ship_model.has_node("WingRig_PortFore") and
            inset.ship_model.has_node("WingRig_StarboardAft"),
            "original source ship geometry remains in genuine World3D")
        check(not inset.warning_visual.active and not inset.warning_visual.visible,
            "engine failure not shown before actual warning state")
        check(not inset.interrupt_warning_visual(),
            "cannot interrupt a nonexistent warning")
        if mode == "disabled":
            inset.set_warning_enabled(false)
        var original: Dictionary = job.opening.snapshot().duplicate(true)
        check(flight.begin_short_test_flight(), "legitimate physical lift")
        check(not inset.warning_visual.active, "no premature phase-effect magic on ascent")
        var warned: bool = false
        for frame in range(180):
            await process_frame
            if flight.phase == "warning":
                warned = true
                break
        check(warned and inset.warning_admitted,
            "effect admitted only by actual phase-warning descriptor")
        check(inset.last_camera_shot == "stern-quarter" and inset.last_grade == "golden-clear",
            "PW01 visual cannot invent first-flight storm or camera")
        check(inset.warning_admission_count == 1, "one warning admission per authentic phase")
        var warning_state: Dictionary = job.opening.snapshot().duplicate(true)
        if mode == "enabled":
            check(inset.warning_visual.active and inset.warning_visual.visible,
                "warning lens visible over 3D ship")
            check(inset.warning_visual.reduced_motion,
                "neutral warning is static by default for accessible viewing")
            check(inset.warning_visual.seek(Envelope.REVIEW_POSITIONS[2]),
                "can inspect deterministic five-phase visual source")
            check(not inset.warning_visual.seek(NAN), "nonfinite VFX seek rejected")
            for frame in range(3):
                flight._refresh_presentation()
            check(inset.warning_visual.activation_count == 1 and
                inset.warning_admission_count == 1,
                "repeated refresh cannot trigger multiple warning effects")
        elif mode == "disabled":
            check(not inset.warning_visual.active and not inset.warning_visual.visible,
                "disabled warning leaves legitimate phase unchanged")
            inset.set_warning_enabled(true)
            check(inset.warning_visual.active, "visual can opt in during true warning")
            inset.set_warning_enabled(false)
            check(not inset.warning_visual.active, "visual can disable again")
        else:
            check(inset.warning_visual.active and inset.interrupt_warning_visual(),
                "first warning can be interrupted")
            for frame in range(3):
                flight._refresh_presentation()
            check(not inset.warning_visual.active and inset.warning_interrupted,
                "interrupted effect cannot auto-restart on real warning")
            inset.set_warning_enabled(false)
            inset.set_warning_enabled(true)
            check(not inset.warning_visual.active,
                "toggle cannot bypass interrupted review warning")
        check(job.opening.snapshot() == warning_state,
            "VFX controls never alter authoritative storyline")
        check(flight.stabilize_for_water_descent(), "Ionia commands genuine 2D descent")
        check(not inset.warning_visual.active and not inset.warning_visual.visible
            and not inset.warning_admitted,
            "engine warning stops immediately when controlled descent starts")
        var reached_water: bool = false
        for k in range(540):
            await process_frame
            if flight.phase == "waterborne":
                reached_water = true
                break
        check(reached_water and flight.contact_observed and flight.stable_float_verified,
            "real Area2D contact and buoyant settle survive VFX mode " + mode)
        check(not inset.warning_visual.active and inset.warning_admission_count == 1,
            "no lingering visual or repeated cue after physical splashdown")
        var snap: Dictionary = flight.review_snapshot()
        check(snap["party"] == ["ender", "ionia"] and snap["fuel_formula"] == "unknown"
            and not snap["production_ocean_verified"],
            "VFX never recruits Lyra or leaks fuel formula/planet ocean claims")
        check(original["active_party_ids"] == job.opening.active_party_ids,
            "original Ionia-first party contract survives full flight")
        job.queue_free()
        await process_frame
    if failures.is_empty():
        print("TSTSS_FIRST_WAKE_WIDE_PW01_PASS checks=", checks,
            " real_physics_trials=3 visual_overlay=2d_on_actual_3d",
            " no_magic=true no_story_mutation=true")
        quit(0)
    else:
        for f in failures:
            push_error("TSTSS_FIRST_WAKE_WIDE_PW01_FAIL: " + f)
        quit(1)
