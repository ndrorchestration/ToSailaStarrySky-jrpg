extends SceneTree
## Genuine Chapter I scene state -> visual-plan seam. Rendered flight assets
## are deliberately NOT imported. Test does not grant cinematic art approval.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Handoff = preload("res://scripts/first_wake_cinematic_handoff.gd")
const Scene = preload("res://scenes/first_wake_flight_water_review.tscn")

var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, reason: String) -> void:
    checks += 1
    if not value:
        errors.append(reason)

func _run() -> void:
    var manifest_path := "res://prototypes/first_wake_visual_handoff.v1.json"
    var f: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
    if f == null:
        _fail("handoff provenance manifest missing")
        return
    var manifest = JSON.parse_string(f.get_as_text())
    if not manifest is Dictionary:
        _fail("handoff provenance manifest malformed")
        return
    check(int(manifest.get("schema_version", 0)) == 1, "versioned review manifest")
    check(str(manifest.get("native_target", "")) == "Godot 4.7.2", "target engine locked")
    var source: Dictionary = manifest.get("source", {})
    check(int(source.get("visual_pr", 0)) == Handoff.FROZEN_VISUAL_PR,
        "actual source PR bound")
    check(str(source.get("visual_sha", "")) == Handoff.FROZEN_VISUAL_HEAD,
        "exact native visual source SHA bound")
    check(int(source.get("native_ci_run", 0)) == Handoff.FROZEN_VISUAL_RUN,
        "real native evidence run bound")
    check(manifest.get("camera_shots", []) == Handoff.VALID_SHOTS,
        "only actually captured review camera IDs are advertised")
    check(bool(manifest["non_authority"]["blocks_progression"]) == false,
        "visual presentation is never gameplay authority")
    check(not bool(manifest["outputs"]["scene_capture_imported"]),
        "cannot claim native visual media has been imported")
    check(not bool(manifest["outputs"]["execute_3d_scene"]),
        "cannot claim 3D chapter+flight runtime already integrated")

    var original = Opening.new()
    var invalid: Dictionary = Handoff.build({
        "party": ["ender"],
        "phase": "awaiting_launch",
        "story_step": "preflight",
        "production_ocean_verified": false,
        "fuel_formula": "unknown",
    })
    check(not invalid["admitted_for_review"], "Ender-only request fails closed")

    check(original.accept_ionia_job(), "Ionia-first join")
    check(original.complete_engineering_checks(), "actual preflight contract")
    var flight = Scene.instantiate()
    check(flight.configure_preflight(original), "real scene accepts authoritative preflight")
    root.add_child(flight)
    await process_frame

    var before: Dictionary = original.snapshot().duplicate(true)
    var first: Dictionary = Handoff.build(flight.review_snapshot())
    check(bool(first.get("admitted_for_review", false)), "preflight admits visuals only")
    check(first.get("camera_shot_id", "") == "bow-quarter", "actual bow reference camera")
    check(first.get("visual_grade_id", "") == "golden-clear", "do not canonize storm weather")
    check(first.get("storm_depth_study_strength", -1.0) == 0.0,
        "optional darkening OFF by default")
    check(first.get("blocks_progression", true) == false
        and first.get("executes_visuals", true) == false
        and first.get("modifies_story_state", true) == false
        and first.get("changes_saves", true) == false, "presentation-only contracts")

    var reduced: Dictionary = Handoff.build(flight.review_snapshot(), true, true, true)
    check(bool(reduced.get("admitted_for_review", false))
        and bool(reduced["reduced_motion"]) and bool(reduced["low_detail"]),
        "accessibility/quality flags flow into candidate shot plan")
    check(reduced["visual_grade_id"] == "storm-night-study"
        and reduced["storm_depth_study_strength"] == 1.0,
        "storm is clearly opt-in review, never story fact")
    check(original.snapshot() == before, "visual selection never mutates story FSM")

    var forged: Dictionary = flight.review_snapshot().duplicate(true)
    forged["phase"] = "waterborne"
    forged["story_step"] = "waterborne"
    check(not Handoff.build(forged)["admitted_for_review"],
        "forged waterborne label without collision and float rejected")
    forged["actual_2d_area_contact_observed"] = true
    check(not Handoff.build(forged)["admitted_for_review"],
        "contact alone cannot grant stable waterborne state")
    forged["stable_buoyant_hull_observed"] = true
    forged["party"] = ["ender", "ionia", "lyra"]
    check(not Handoff.build(forged)["admitted_for_review"],
        "early Lyra is never accepted by image sequencing")
    forged["party"] = ["ender", "ionia"]
    forged["fuel_formula"] = "definitive"
    check(not Handoff.build(forged)["admitted_for_review"],
        "render stage cannot assert invented fuel formula")
    forged["fuel_formula"] = "unknown"
    forged["production_ocean_verified"] = true
    check(not Handoff.build(forged)["admitted_for_review"],
        "review cannot upgrade local 2D water to final planetary ocean")
    check(original.snapshot() == before, "forged visual state never mutates story")

    check(flight.begin_short_test_flight(), "real local physics review launched")
    var ascent: Dictionary = Handoff.build(flight.review_snapshot())
    check(bool(ascent.get("admitted_for_review", false))
        and ascent.get("camera_shot_id", "") == "wing-planform",
        "authentic ascent maps to original wing camera without changing flight")
    var warned := false
    for i in range(180):
        await process_frame
        if flight.phase == "warning":
            warned = true
            break
    check(warned, "real scene reaches phase-drift warning")
    if warned:
        var warning: Dictionary = Handoff.build(flight.review_snapshot())
        check(bool(warning.get("admitted_for_review", false))
            and warning.get("camera_shot_id", "") == "stern-quarter",
            "warning maps to original stern/engineering camera")
        check(flight.stabilize_for_water_descent(), "authorized controlled descent")
        var descent: Dictionary = Handoff.build(flight.review_snapshot())
        check(bool(descent.get("admitted_for_review", false))
            and descent.get("camera_shot_id", "") == "bow-quarter",
            "descent camera never establishes contact")
        check(not bool(descent.get("local_water_contact_observed", true)),
            "descent cue cannot fake sea contact")
        var settled := false
        for k in range(540):
            await process_frame
            if flight.phase == "waterborne":
                settled = true
                break
        check(settled, "native RigidBody2D/Area2D contact and buoyant settle")
        if settled:
            var water: Dictionary = Handoff.build(flight.review_snapshot())
            check(bool(water.get("admitted_for_review", false)), "post-contact shot admitted")
            check(water.get("scene_phase", "") == "waterborne"
                and bool(water.get("local_water_contact_observed", false))
                and bool(water.get("local_stable_float_observed", false)),
                "real physical water evidence remains distinct from presentation")
            check(water.get("production_ocean_verified", true) == false,
                "local 2D buoyancy cannot certify production ocean")
            check(original.active_party_ids == ["ender", "ionia"],
                "no unauthorized Lyra join via cinematic bridge")
    flight.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_FIRST_WAKE_VISUAL_HANDOFF_PASS checks=", checks,
            " bridge=review-only actual-2d-physics=true imported-3d=false")
        quit(0)
    else:
        for error in errors:
            push_error("TSTSS_FIRST_WAKE_VISUAL_HANDOFF_FAIL: " + error)
        quit(1)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_VISUAL_HANDOFF_FAIL: " + reason)
    quit(1)
