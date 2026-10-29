extends RefCounted
## Review-only encounter admission validator.
## Only a separately supplied, exact-bound permit can yield a playable
## transaction preview; this does not mint permits or approve scene placement.
const PartyPreview = preload("res://scripts/combat/first_wake_party_preview.gd")

static func validate_permit(opening: RefCounted, roster: Dictionary,
        crew: Array[String], opponents: Array[String], permit: Dictionary) -> Dictionary:
    var preview: Dictionary = PartyPreview.preview_party(opening, roster, crew, opponents)
    if not preview.get("ok", false):
        return preview
    if not permit.has_all(["encounter_id", "story_step", "crew_ids", "opponent_ids", "approved_for_review"]):
        return {"ok": false, "reason": "permit_incomplete"}
    if permit.get("approved_for_review") != true:
        return {"ok": false, "reason": "permit_not_approved"}
    if typeof(permit["encounter_id"]) != TYPE_STRING or str(permit["encounter_id"]).is_empty():
        return {"ok": false, "reason": "invalid_encounter_id"}
    if typeof(permit["story_step"]) != TYPE_STRING or permit["story_step"] != preview["story_step"]:
        return {"ok": false, "reason": "story_step_mismatch"}
    if typeof(permit["crew_ids"]) != TYPE_ARRAY or typeof(permit["opponent_ids"]) != TYPE_ARRAY:
        return {"ok": false, "reason": "invalid_permit_roster"}
    if permit["crew_ids"] != crew or permit["opponent_ids"] != opponents:
        return {"ok": false, "reason": "participant_mismatch"}
    return {
        "ok": true,
        "encounter_id": permit["encounter_id"],
        "preview": preview,
        "review_only": true,
        "production_encounter_authorized": false
    }
