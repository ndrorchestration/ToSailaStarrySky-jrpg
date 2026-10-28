extends RefCounted
## Portable review-only forest LOD contract. NOT loaded by Chapter I scenes.
## This is a semantic bridge from noncanonical flight-slice PR #488,
## not a mesh/terrain/asset importer or gameplay authority.

const PROTOCOL := "forest_visual_bridge_v0_1"
const NEAR: float = 29.0
const FAR: float = 39.0
const MAX_BATCHES: int = 20
const NORMAL_SWAPS: int = 1

static func _reject(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}

static func validate_candidate(candidate: Dictionary) -> Dictionary:
    if candidate.get("protocol", "") != PROTOCOL:
        return _reject("unsupported_protocol")
    if candidate.get("coordinate_space", "") != "local_tangent_study":
        return _reject("coordinate_space_not_admitted")
    if candidate.get("presentation_only", false) != true:
        return _reject("not_presentation_only")
    if candidate.get("canon_approved", true) != false or (
            candidate.get("collision_changes", true) != false) or (
            candidate.get("save_changes", true) != false) or (
            candidate.get("navigation_changes", true) != false):
        return _reject("authority_boundary")
    if candidate.get("asset_status", "") != "unapproved_study":
        return _reject("asset_authority")
    var batches: Variant = candidate.get("batches", null)
    if not (batches is Array) or batches.is_empty() or batches.size() > MAX_BATCHES:
        return _reject("invalid_batch_budget")
    var names: Dictionary = {}
    for batch in batches:
        if not (batch is Dictionary):
            return _reject("invalid_batch_record")
        var id_value: Variant = batch.get("id", null)
        var bounds: Variant = batch.get("local_bounds", null)
        if not (id_value is String) or id_value.is_empty() or (
                names.has(id_value)) or not (bounds is AABB):
            return _reject("invalid_batch_identity_or_bounds")
        if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
            return _reject("invalid_batch_extent")
        if batch.get("species", "") not in ["evergreen", "broadleaf"]:
            return _reject("invalid_species")
        names[id_value] = true
    return {"ok": true, "reason": "review_only_contract"}

static func _batch_distance(observer: Vector3, bounds: AABB) -> float:
    var lower: Vector3 = bounds.position
    var upper: Vector3 = bounds.end
    return observer.distance_to(Vector3(
        clampf(observer.x, lower.x, upper.x),
        clampf(observer.y, lower.y, upper.y),
        clampf(observer.z, lower.z, upper.z)))

static func plan(candidate: Dictionary, previous: Dictionary, observer: Vector3,
        low_quality: bool = false) -> Dictionary:
    var admission: Dictionary = validate_candidate(candidate)
    if not admission["ok"]:
        return admission
    # Copy input state: the caller retains authority and may reject the result.
    var states: Dictionary = previous.duplicate()
    var pending: Array[Dictionary] = []
    var source_ids: Dictionary = {}
    for batch in candidate["batches"]:
        var id_value: String = batch["id"]
        source_ids[id_value] = true
        var old_near: bool = bool(states.get(id_value, false))
        var distance: float = _batch_distance(observer, batch["local_bounds"])
        var want_near: bool = old_near
        if distance < NEAR:
            want_near = true
        elif distance > FAR:
            want_near = false
        if low_quality:
            want_near = false
        if want_near != old_near:
            pending.append({"id": id_value, "distance": distance,
                "old": old_near, "near": want_near})
    for id_value in states.keys():
        if not source_ids.has(id_value):
            return _reject("unexpected_previous_state")
    var changes: Array[Dictionary] = []
    var budget: int = pending.size() if low_quality else NORMAL_SWAPS
    for slot in range(budget):
        if pending.is_empty():
            break
        var chosen_index: int = 0
        for j in range(1, pending.size()):
            var candidate_change: Dictionary = pending[j]
            var chosen: Dictionary = pending[chosen_index]
            if candidate_change["distance"] < chosen["distance"] or (
                    is_equal_approx(candidate_change["distance"], chosen["distance"]) and (
                    candidate_change["id"] < chosen["id"])):
                chosen_index = j
        var picked: Dictionary = pending.pop_at(chosen_index)
        states[picked["id"]] = picked["near"]
        changes.append(picked)
    return {"ok": true, "reason": "review_only_contract",
        "states": states, "swaps": changes, "pending": pending.size(),
        "budget": NORMAL_SWAPS, "runtime_binding": false}
