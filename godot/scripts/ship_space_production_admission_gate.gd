extends RefCounted
## Fail-closed bridge from verified PROTOTYPE evidence to an asset-staging review.
## It does not approve art, gameplay, a physical hull, or a release.
const Handoff = preload("res://scripts/first_wake_ship_spaces_handoff.gd")
const MANIFEST := "res://data/ship_space_production_admission.v1.json"
const SCHEMA := "tstss.ship-space-admission.v1"
const SOURCE_SHA := "8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9"
const HANDOFF_SHA := "d341d367c005b3c00d758336982d0e34d5e95839"
const NEXT := "prototype_asset_staging_review"

const EXPECTED_STAGES := {
    "semantic_ship_space_ids": "ch1_native_prototype_verified",
    "geodesic_glass_material": "isolated_lab_native_verified",
    "foredeck_ordinary_layout": "isolated_lab_native_verified",
    "bridge_to_foredeck_egress": "blocked_on_scale_and_aperture",
    "weather_and_habitable_protection": "unverified_as_physical_system"
}
const EXPECTED_NEXT := {
    "semantic_ship_space_ids": "production_scene_schema_review",
    "geodesic_glass_material": "quarantined_native_asset_import",
    "foredeck_ordinary_layout": "unified_hull_scale_and_actor_clearance",
    "bridge_to_foredeck_egress": "single_scene_physics_capsule_and_exit_test",
    "weather_and_habitable_protection": "separate_environmental_and_safety_validation"
}
const MUST_REMAIN_FALSE := [
    "save_schema_changed", "player_abilities_granted",
    "physical_doorway_usable", "production_asset_imported",
    "exact_hull_scale_proven", "production_art_approved",
    "windows_acceptance_passed", "creator_merge_authorized",
    "release_authorized"
]

static func load_manifest() -> Dictionary:
    var file := FileAccess.open(MANIFEST, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        return parsed
    return {}

static func assess(manifest: Dictionary, observed: Dictionary) -> Dictionary:
    var errors: Array[String] = []
    if manifest.get("schema") != SCHEMA:
        errors.append("invalid_schema")
    if manifest.get("authority") != "public_safe_engineering_review":
        errors.append("unauthorized_scope")
    if manifest.get("target_project") != "godot/project.godot":
        errors.append("wrong_native_target")
    if manifest.get("target_scene") != "res://scenes/first_wake_job_preview.tscn":
        errors.append("wrong_real_scene")

    var source: Dictionary = _subdictionary(manifest, "source")
    if int(source.get("ship_lab_pr", -1)) != Handoff.SHIP_ART_SOURCE_PR or (
            str(source.get("ship_lab_head", "")) != SOURCE_SHA
            or str(observed.get("source_head", "")) != SOURCE_SHA):
        errors.append("source_provenance_mismatch")
    if int(source.get("ship_lab_native_run", -1)) != 40608998147:
        errors.append("unknown_lab_evidence")
    if int(source.get("chapter_handoff_pr", -1)) != 497 or (
            str(source.get("chapter_handoff_head", "")) != HANDOFF_SHA):
        errors.append("unknown_chapter_handoff")
    if int(source.get("chapter_handoff_native_run", -1)) != 40613875428:
        errors.append("unknown_scene_evidence")

    var entry: Dictionary = _subdictionary(manifest, "entry_evidence")
    if entry.get("reviewed_character_order") != (
            "ender_ionia_first_lyra_after_splashdown"):
        errors.append("chapter_order_conflict")
    if entry.get("visibility") != "explicit_review_only" or (
            observed.get("review_only") != true):
        errors.append("unapproved_gameplay_visibility")
    for key in MUST_REMAIN_FALSE:
        if typeof(entry.get(key)) != TYPE_BOOL or entry[key] != false:
            errors.append("prohibited_promotion_" + key)

    var list_value: Variant = manifest.get("components", null)
    if not (list_value is Array):
        errors.append("invalid_component_registry")
    else:
        var components: Array = list_value
        var seen: Dictionary = {}
        if components.size() != EXPECTED_STAGES.size():
            errors.append("component_count_changed")
        for item in components:
            if not (item is Dictionary):
                errors.append("invalid_component_item")
                continue
            var component: Dictionary = item
            var id: String = str(component.get("id", ""))
            if not EXPECTED_STAGES.has(id) or seen.has(id):
                errors.append("unknown_or_duplicate_component")
                continue
            seen[id] = true
            if component.get("stage") != EXPECTED_STAGES[id]:
                errors.append("unverified_stage_" + id)
            if component.get("next") != EXPECTED_NEXT[id]:
                errors.append("unapproved_next_action_" + id)
            if typeof(component.get("production_ready")) != TYPE_BOOL or (
                    component["production_ready"] != false):
                errors.append("premature_art_admission_" + id)
        if seen.size() != EXPECTED_STAGES.size():
            errors.append("missing_component")

    var admission: Dictionary = _subdictionary(manifest, "admission")
    if admission.get("next_stage") != NEXT or (
            admission.get("production_ready") != false
            or admission.get("physical_access_ready") != false
            or admission.get("engineering_reconciliation_required") != true):
        errors.append("unsafe_global_admission")
    if observed.get("admission") != Handoff.ADMISSION_STATUS or (
            observed.get("can_traverse") != false
            or observed.get("water_seal_verified") != false):
        errors.append("live_scene_premature_hull_claim")

    var dimensions: Dictionary = _subdictionary(admission, "dimensional_review")
    if dimensions.get("reference_only") != true:
        errors.append("study_dimensions_claimed_as_final")
    if not _same(float(dimensions.get("dome_diameter_m", 0.0)),
            float(observed.get("dome_diameter_study_m", -1.0))):
        errors.append("dome_width_drift")
    if not _same(float(dimensions.get("cabin_width_m", 0.0)),
            float(observed.get("cabin_width_study_m", -1.0))):
        errors.append("threshold_width_drift")
    if not _same(float(dimensions.get("standing_review_min_m", 0.0))
            - float(dimensions.get("dome_peak_above_deck_m", 0.0)),
            float(observed.get("roof_shortfall_study_m", -1.0))):
        errors.append("headroom_drift")
    if float(dimensions.get("dome_diameter_m", 0.0)) <= (
            float(dimensions.get("cabin_width_m", 0.0))) or (
            float(dimensions.get("dome_peak_above_deck_m", 0.0)) >=
            float(dimensions.get("standing_review_min_m", 0.0))):
        errors.append("false_resolution_of_scale_conflict")
    # A green assessment authorizes the NEXT PROTOTYPE REVIEW ONLY, never production.
    return {
        "manifest_valid": errors.is_empty(),
        "next_prototype_review_allowed": errors.is_empty(),
        "production_ready": false,
        "physical_bridge_approved": false,
        "release_authorized": false,
        "disposition": "PROTOTYPE_REVIEW_ONLY" if errors.is_empty() else "ADMISSION_REJECTED",
        "errors": errors
    }

static func _subdictionary(record: Dictionary, key: String) -> Dictionary:
    var candidate: Variant = record.get(key, null)
    return candidate if candidate is Dictionary else {}

static func _same(a: float, b: float) -> bool:
    return is_equal_approx(a, b)
