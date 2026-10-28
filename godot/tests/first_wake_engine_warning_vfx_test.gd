extends SceneTree
## PW-01: real first-flight scene + bounded neutral VFX with disabled/interrupt
## A/B, actual physics splashdown, and no story/combat/save authority.
const Review = preload("res://scenes/first_wake_engine_warning_review.tscn")
const Handoff = preload("res://scripts/first_wake_cinematic_handoff.gd")
const Envelope = preload("res://scripts/cinematic_vfx_envelope.gd")

var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
    checks += 1
    if not condition:
        push_error("TSTSS_PW01_ENGINE_VFX_FAIL: " + message)
        quit(1)
        return false
    return true

func _run() -> void:
    if not _check(Envelope.PHASES == ["anticipation", "formation", "release", "impact", "aftermath"], "VFX five-phase lineage drift"):
        return
    if not _check(Envelope.REVIEW_POSITIONS == [0.08, 0.29, 0.49, 0.67, 0.89], "VFX snapshot phase indices drift"):
        return
    for mode in ["enabled", "disabled", "interrupted"]:
        var review = Review.instantiate()
        root.add_child(review)
        await process_frame
        if not _check(review.flight != null and review.warning_visual != null, "real native scene creation"):
            return
        if not _check(review.opening.active_party_ids == ["ender", "ionia"], "Ionia-first party"):
            return
        if not _check(not review.warning_visual.visible and not review.warning_visual.active, "no premature engine alarm"):
            return
        if not _check(not review.set_detail_level(3) and review.detail_level == 0, "quality tier validation"):
            return
        var baseline: Dictionary = review.opening.snapshot().duplicate(true)
        if mode == "disabled":
            review.set_visual_enabled(false)
        if not _check(review.flight.begin_short_test_flight(), "real launch"):
            return
        var reached_warning: bool = false
        for frame in range(180):
            await process_frame
            if review.flight.phase == "warning":
                reached_warning = true
                break
        if not _check(reached_warning and review.synchronize_visual(), "real engine warning phase"):
            return
        var before_visual: Dictionary = review.opening.snapshot().duplicate(true)
        if mode == "enabled":
            if not _check(review.warning_visual.active and review.warning_visual.visible, "enabled visual not presented"):
                return
            var count: int = review.warning_visual.activation_count
            for frame in range(3):
                review.synchronize_visual()
            if not _check(review.warning_visual.activation_count == count and review.admission_count == 1, "warning repeatedly activated"):
                return
            if not _check(review.warning_visual.reduced_motion and not review.warning_visual.is_processing(), "reduced motion not static"):
                return
            if not _check(not review.warning_visual.seek(float("nan")), "NaN phase accepted"):
                return
            if not _check(review.warning_visual.seek(Envelope.REVIEW_POSITIONS[3]) and review.warning_visual.phase == "impact", "deterministic phase preview"):
                return
        elif mode == "disabled":
            if not _check(not review.warning_visual.active and review.admission_count == 1, "disabled effect still running"):
                return
            review.set_visual_enabled(true)
            if not _check(review.warning_visual.active and review.warning_visual.activation_count == 1, "reenabling effect failed"):
                return
            review.set_visual_enabled(false)
        else:
            if not _check(review.warning_visual.active and review.interrupt_visual(), "interrupt not admitted"):
                return
            for frame in range(3):
                review.synchronize_visual()
            if not _check(not review.warning_visual.active and not review.warning_visual.visible, "interrupted effect silently restarted"):
                return
            review.set_visual_enabled(false)
            review.set_visual_enabled(true)
            if not _check(not review.warning_visual.active, "toggle bypassed interrupted state"):
                return
        if not _check(review.opening.snapshot() == before_visual, "presentation altered original story state"):
            return
        if not _check(review.flight.stabilize_for_water_descent(), "real controlled descent refused"):
            return
        await process_frame
        if not _check(review.flight.phase == "descent" and not review.warning_visual.active and not review.warning_visual.visible, "cue incorrectly persisted through descent"):
            return
        var reached_water: bool = false
        for frame in range(540):
            await process_frame
            if review.flight.phase == "waterborne":
                reached_water = true
                break
        if not _check(reached_water, "real native physics splashdown blocked in " + mode):
            return
        var after: Dictionary = review.flight.review_snapshot()
        if not _check(bool(after["actual_2d_area_contact_observed"]) and bool(after["stable_buoyant_hull_observed"]), "water contact or afloat fabricated"):
            return
        if not _check(after["party"] == ["ender", "ionia"] and after["fuel_formula"] == "unknown" and not after["production_ocean_verified"], "story or ocean authority drift"):
            return
        if not _check(not review.warning_visual.active and not review.warning_visual.visible and review.admission_count == 1, "visual leaked beyond authentic warning"):
            return
        if not _check(baseline["active_party_ids"] == review.opening.active_party_ids, "visual changed party"):
            return
        var handoff: Dictionary = Handoff.build(after)
        if not _check(bool(handoff.get("admitted_for_review", false)) and handoff.get("scene_phase", "") == "waterborne", "actual presentation handoff lost after VFX"):
            return
        review.queue_free()
        await process_frame
    print("TSTSS_PW01_ENGINE_VFX_PASS: 3 actual physics splashdowns (enabled/disabled/interrupted), bounded native engine cue, no magic or story state drift; checks=", checks)
    print("TSTSS_PW01_ENGINE_VFX_ART_APPROVAL=PENDING")
    quit(0)
