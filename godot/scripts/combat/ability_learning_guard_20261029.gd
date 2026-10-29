extends RefCounted
## Fail-closed character-learning gate preceding the review-only ability adapter.
## Learned abilities are supplied by the owning progression system; no unlocks inferred.
const Adapter = preload("res://scripts/combat/ability_turn_adapter.gd")

static func use_learned_ability(state: Dictionary, actor_id: String, target_id: String,
        ability_id: String, catalog: Dictionary, factions: Dictionary,
        learned_by_actor: Dictionary) -> Dictionary:
    if actor_id.is_empty() or ability_id.is_empty():
        return {"ok": false, "reason": "missing_identity_or_ability"}
    if not learned_by_actor.has(actor_id):
        return {"ok": false, "reason": "actor_learning_unavailable"}
    var learned: Variant = learned_by_actor[actor_id]
    if typeof(learned) != TYPE_ARRAY:
        return {"ok": false, "reason": "invalid_learning_record"}
    for known in learned:
        if typeof(known) != TYPE_STRING or known.is_empty():
            return {"ok": false, "reason": "invalid_learning_record"}
    if ability_id not in learned:
        return {"ok": false, "reason": "ability_not_learned"}
    return Adapter.use_ability(state, actor_id, target_id, ability_id, catalog, factions)
