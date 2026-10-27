extends RefCounted
## Explicit laboratory-only Resonance grant admission. This is NOT a security
## credential, production story unlock, save field, or magical spell permission.
## An innate Light / party membership is never sufficient to authorize an Art.
const Ability = preload("res://scripts/combat_ability_contract.gd")
const VERSION := "0.1.0"
const SCOPE := "isolated-resonance-review"
const ORIGIN := "explicit-training-control"

var abilities = Ability.new()

func create_training_grant(art_id: String) -> Dictionary:
    var definition: Dictionary = abilities.for_resonance(art_id)
    if definition.is_empty() or not abilities.validate_definition(definition):
        return {}
    if definition.get("runtimeStatus", "") != Ability.REVIEW_STATUS:
        return {}
    return {
        "version": VERSION, "artId": art_id, "scope": SCOPE,
        "origin": ORIGIN, "participants": Array(definition["participants"]).duplicate(),
    }

func check(art_id: String, battle_state: Variant, grants: Variant) -> Dictionary:
    if not (battle_state is Dictionary) or battle_state.get("reviewOnly", null) != true:
        return _deny("review_scope_required")
    if battle_state.get("phase", "") != "player":
        return _deny("wrong_phase")
    var definition: Dictionary = abilities.for_resonance(art_id)
    if definition.is_empty() or not abilities.validate_definition(definition):
        return _deny("unknown_or_invalid_art")
    if not (grants is Array):
        return _deny("invalid_grant_set")
    var seen: Dictionary = {}
    var found: bool = false
    for raw in grants:
        if not (raw is Dictionary):
            return _deny("malformed_grant")
        var grant: Dictionary = raw
        # The whole provided ledger must be coherent: no unrelated entry is
        # silently ignored and no caller-supplied execution flag is accepted.
        if grant.size() != 5:
            return _deny("malformed_grant")
        var grant_id = grant.get("artId", null)
        if not (grant_id is String):
            return _deny("malformed_grant")
        var described: Dictionary = abilities.for_resonance(grant_id)
        if described.is_empty():
            return _deny("unknown_grant_art")
        if str(grant.get("version", "")) != VERSION or                 str(grant.get("scope", "")) != SCOPE or                 str(grant.get("origin", "")) != ORIGIN:
            return _deny("grant_provenance_invalid")
        var members = grant.get("participants", null)
        if not (members is Array) or members != described.get("participants", []):
            return _deny("grant_members_invalid")
        if seen.has(grant_id):
            return _deny("duplicate_grant")
        seen[grant_id] = true
        if grant_id == art_id:
            found = true
    if not found:
        return _deny("art_not_granted_for_review")
    return {
        "ok": true, "reason": "explicit_training_grant",
        "reviewOnly": true, "artId": art_id,
    }

func check_production(_art_id: String, _authority: Variant) -> Dictionary:
    # No producer/signer/story gate has been approved or connected. The review
    # origin is intentionally not convertible into production authority.
    return _deny("production_art_authority_not_implemented")

func _deny(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason, "reviewOnly": true}
