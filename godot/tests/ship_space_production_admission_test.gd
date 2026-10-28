extends SceneTree
## Executable Godot 4.7.2 promotion gate; checks reject forged readiness.
## Positive gate means NEXT PROTOTYPE ASSET REVIEW ONLY, not production.
const Gate = preload("res://scripts/ship_space_production_admission_gate.gd")
const Handoff = preload("res://scripts/first_wake_ship_spaces_handoff.gd")
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(condition: bool, note: String) -> void:
    checks += 1
    if not condition:
        failures.append(note)

func reject(doc: Dictionary, observed: Dictionary, code: String) -> void:
    var result: Dictionary = Gate.assess(doc, observed)
    verify(not result["manifest_valid"]
        and not result["next_prototype_review_allowed"]
        and not result["production_ready"]
        and result["disposition"] == "ADMISSION_REJECTED"
        and result["errors"].has(code),
        "tamper must be rejected: " + code)

func _run() -> void:
    var manifest: Dictionary = Gate.load_manifest()
    verify(not manifest.is_empty(), "native target loads versioned source-locked JSON")
    var scene = Preview.instantiate()
    root.add_child(scene)
    await process_frame
    var handoff = scene.ship_spaces_handoff as Handoff
    verify(handoff != null and not handoff.visible,
        "production gate binds the actual native Chapter I scene, default off")
    var observed: Dictionary = handoff.source_contract()
    var baseline: Dictionary = scene.opening.snapshot()
    var save_before: Dictionary = scene.export_revised_checkpoint()
    verify(observed["source_head"] == Gate.SOURCE_SHA
        and observed["admission"] == Handoff.ADMISSION_STATUS,
        "source evidence comes from exact inspected Chapter I runtime component")

    var good: Dictionary = Gate.assess(manifest, observed)
    verify(good["manifest_valid"] and good["next_prototype_review_allowed"],
        "provenance and storyboard are admissible ONLY to next native asset study")
    verify(not good["production_ready"] and not good["physical_bridge_approved"]
        and not good["release_authorized"],
        "valid manifest cannot certify a physical 3D hull, art or release")
    verify(good["disposition"] == "PROTOTYPE_REVIEW_ONLY"
        and good["errors"].is_empty(),
        "valid prototype remains visibly separate from production acceptance")

    var changed: Dictionary = manifest.duplicate(true)
    changed["schema"] = "unversioned"
    reject(changed, observed, "invalid_schema")
    changed = manifest.duplicate(true)
    changed["source"]["ship_lab_head"] = "0000000000000000000000000000000000000000"
    reject(changed, observed, "source_provenance_mismatch")
    changed = manifest.duplicate(true)
    changed["source"]["chapter_handoff_native_run"] = 1
    reject(changed, observed, "unknown_scene_evidence")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["physical_doorway_usable"] = true
    reject(changed, observed, "prohibited_promotion_physical_doorway_usable")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["production_art_approved"] = true
    reject(changed, observed, "prohibited_promotion_production_art_approved")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["windows_acceptance_passed"] = true
    reject(changed, observed, "prohibited_promotion_windows_acceptance_passed")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["creator_merge_authorized"] = true
    reject(changed, observed, "prohibited_promotion_creator_merge_authorized")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["release_authorized"] = true
    reject(changed, observed, "prohibited_promotion_release_authorized")
    changed = manifest.duplicate(true)
    changed["components"][3]["stage"] = "physically_traversable"
    reject(changed, observed, "unverified_stage_bridge_to_foredeck_egress")
    changed = manifest.duplicate(true)
    changed["components"].append({
        "id": "unreleased_route", "stage": "done",
        "next": "production", "production_ready": true
    })
    reject(changed, observed, "component_count_changed")
    changed = manifest.duplicate(true)
    changed["components"][1]["production_ready"] = true
    reject(changed, observed, "premature_art_admission_geodesic_glass_material")
    changed = manifest.duplicate(true)
    changed["admission"]["physical_access_ready"] = true
    reject(changed, observed, "unsafe_global_admission")
    changed = manifest.duplicate(true)
    changed["admission"]["dimensional_review"]["reference_only"] = false
    reject(changed, observed, "study_dimensions_claimed_as_final")
    changed = manifest.duplicate(true)
    changed["admission"]["dimensional_review"]["dome_diameter_m"] = 2.0
    reject(changed, observed, "dome_width_drift")
    changed = manifest.duplicate(true)
    changed["admission"]["dimensional_review"]["dome_peak_above_deck_m"] = 2.4
    reject(changed, observed, "headroom_drift")
    changed = manifest.duplicate(true)
    changed["entry_evidence"]["reviewed_character_order"] = "lyra_before_ionia"
    reject(changed, observed, "chapter_order_conflict")
    var wrong_observation: Dictionary = observed.duplicate(true)
    wrong_observation["water_seal_verified"] = true
    reject(manifest, wrong_observation, "live_scene_premature_hull_claim")
    wrong_observation = observed.duplicate(true)
    wrong_observation["source_head"] = "modified"
    reject(manifest, wrong_observation, "source_provenance_mismatch")

    verify(scene.opening.snapshot() == baseline
        and scene.export_revised_checkpoint() == save_before,
        "promotion gate cannot change story roster, save or timeline state")
    verify(not scene.ship_spaces_handoff.visible
        and scene.resonance_status_label.text.contains("LOCKED"),
        "running all admission tests cannot expose UI or grant early abilities")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("SHIP_SPACE_PRODUCTION_ADMISSION_PASS checks=", checks,
            " disposition=PROTOTYPE_ONLY production=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("SHIP_SPACE_PRODUCTION_ADMISSION_FAIL: " + failure)
        quit(1)
