extends SceneTree
## Real opt-in 2D Chapter I → 3D ship → same 2D Chapter I continuity.
const IntegrationScene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Bridge = preload("res://scripts/first_wake_opt_in_shipboard_3d_review.gd")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_verify")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        errors.append(message)

func _engineering_snapshot() -> Dictionary:
    return {
        "schema": Codec.SCHEMA,
        "step": "engineering",
        "flyer_read": true,
        "room": "engineering",
        "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }

func _step_crew_to(actor: CharacterBody3D, target: float, frames: int = 200) -> bool:
    actor.set_test_direction(Vector2(0, -1 if target < actor.position.z else 1))
    var reached: bool = false
    for step in range(frames):
        await physics_frame
        var front: bool = target < 0.0 and actor.test_direction.y < 0.0
        if (front and actor.position.z <= target) or (
                not front and actor.position.z >= target):
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return reached

func _verify() -> void:
    var scene = IntegrationScene.instantiate()
    root.add_child(scene)
    await process_frame
    var chapter = scene.chapter
    var ship = scene.ship
    check(scene.get_script() == Bridge and Bridge.REVIEW_PRODUCTION_READY == false,
        "review route is real and fail-closed, separate from shipped main scene")
    check(not scene.three_d_review_active and chapter.visible
        and chapter.get_node("ReadableGameplayOverlay").visible
        and not ship.visible,
        "actual first scene launches in original 2D mode")
    check(chapter.opening.active_party_ids == ["ender"] and
        chapter.opening.step_key() == "job_search",
        "real player still starts as Ender searching for work")
    check(not scene.request_3d_ship_review(true)
        and not scene.three_d_review_active,
        "unhired Ender cannot launch or arm 3D ship access")
    check(not scene.inspect_review_helm()
        and not scene.cycle_glass_review()
        and not scene.request_3d_ship_review(false),
        "review controls reject unrelated first scene")
    check(chapter.restore_revised_checkpoint(_engineering_snapshot()),
        "native legitimate v2 fixture reconstructs hired engineering state")
    check(chapter.opening.step_key() == "engineering"
        and chapter.opening.active_party_ids == ["ender", "ionia"],
        "Ionia-first party order preserved before accepting 3D request")
    var baseline: Dictionary = chapter.export_revised_checkpoint()
    var story: Dictionary = chapter.opening.snapshot()
    chapter.dialogue_open = true
    check(not scene.request_3d_ship_review(true),
        "cannot enter 3D during unfinished mandatory dialogue")
    chapter.dialogue_open = false
    check(scene.request_3d_ship_review(true),
        "eligible hired engineering scene genuinely opens 3D ship")
    await process_frame
    await physics_frame
    check(scene.three_d_review_active and ship.visible
        and not chapter.visible
        and not chapter.get_node("ReadableGameplayOverlay").visible,
        "actual chapter 2D scene and independent HUD are hidden in 3D")
    check(chapter.process_mode == Node.PROCESS_MODE_DISABLED
        and ship.process_mode == Node.PROCESS_MODE_INHERIT,
        "only actual 3D walk can process input during bridge review")
    check(ship.crew_camera.current
        and ship.crew_walker.manual_controls_enabled,
        "active real Camera3D and CharacterBody3D control inside root viewport")
    check(scene.transient_review_contract()["story_progression_enabled"] == false
        and scene.transient_review_contract()["ship_space_production_ready"] == false
        and scene.transient_review_contract()["saved_in_chapter1"] == false,
        "bridge remains an opt-in ephemeral review, never canonical gameplay grant")
    check(not scene.inspect_review_helm(), "far crew cannot activate helm remotely")
    var actor: CharacterBody3D = ship.crew_walker
    for i in range(30):
        await physics_frame
    check(actor.is_on_floor(), "physics actor grounded before walkthrough")
    check(await _step_crew_to(actor, -1.52),
        "real controller physically enters geodesic helm from crew cabin")
    check(scene.inspect_review_helm()
        and scene.review_observations == 1
        and scene.last_review_message.contains("unverified"),
        "F helmet station is proximity-restricted and entirely observational")
    check(scene.cycle_glass_review() and ship.glass_review_profile == "source_clear",
        "G toggles only original source glass art review")
    check(scene.cycle_glass_review() and ship.glass_review_profile == "source_low_glare",
        "G reveals preserved low-glare source material")
    check(scene.cycle_glass_review() and ship.glass_review_profile == "metric_proxy",
        "G cycles reversibly, creating no new pressure or story ability")
    ship.set_hatch_open(false)
    await physics_frame
    var z_before: float = actor.position.z
    check(not await _step_crew_to(actor, -3.30, 55)
        and actor.position.z > -2.55
        and actor.position.z < z_before,
        "real actor physically refused through a closed hatch")
    check(ship.request_crew_hatch_interaction() and ship.is_hatch_open(),
        "real E interaction opens the hinged collision hatch at the helm")
    check(await _step_crew_to(actor, -4.30),
        "real crew crosses through physically open hatch onto open deck")
    check(actor.is_on_floor()
        and ship.get_node("AureateMaritimeRailArtReview").visible,
        "avatar grounded on actual timber/brass-guarded foredeck")
    check(not scene.inspect_review_helm(),
        "helm control not usable remotely from the bow")
    var prior_actor_position: Vector3 = actor.position
    var prior_snapshot: Dictionary = chapter.export_revised_checkpoint()
    check(prior_snapshot == baseline and chapter.opening.snapshot() == story,
        "all helm, hatch, art and traversal operations leave v2 save and story unchanged")
    check(scene.request_3d_ship_review(false),
        "player can genuinely return from 3D walkthrough to original 2D chapter")
    await process_frame
    check(chapter.visible and chapter.get_node("ReadableGameplayOverlay").visible
        and chapter.process_mode == Node.PROCESS_MODE_INHERIT
        and not ship.visible and ship.process_mode == Node.PROCESS_MODE_DISABLED,
        "same 2D engineering scene and CanvasLayer restored, 3D fully disabled")
    check(chapter.export_revised_checkpoint() == baseline
        and chapter.opening.snapshot() == story
        and chapter.resonance_status_label.text.contains("LOCKED"),
        "round trip preserves checkpoint, Ionia-first story and Resonance lock")
    check(not scene.inspect_review_helm() and not scene.cycle_glass_review()
        and not ship.crew_walker.manual_controls_enabled,
        "review-only interaction cannot leak into 2D gameplay")
    check(scene.request_3d_ship_review(true) and ship.visible,
        "explicit second B may reenter exactly the same transient review")
    check(actor.position.distance_to(prior_actor_position) < 0.10,
        "reentering review does not unexpectedly teleport the 3D avatar")
    check(scene.request_3d_ship_review(false)
        and chapter.export_revised_checkpoint() == baseline,
        "repeat entry/exit is idempotent for original Chapter I saved state")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("FIRST_WAKE_OPTIONAL_3D_PASS checks=", checks,
            " story=IONIA_FIRST",
            " traversal=ACTUAL_CHARACTERBODY3D",
            " return=SAME_2D_CHECKPOINT",
            " production=BLOCKED")
        quit(0)
    else:
        for error in errors:
            push_error("FIRST_WAKE_OPTIONAL_3D_FAIL: " + error)
        quit(1)
