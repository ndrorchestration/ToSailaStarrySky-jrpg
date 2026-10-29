extends RefCounted
## Read-only bridge from the authored First Wake party contract to a proposed
## combat setup. Does NOT grant encounter authorization or start combat.
const Turns = preload("res://scripts/combat/turn_queue.gd")

static func preview_party(opening: RefCounted, roster: Dictionary,
        requested_crew: Array[String], opponent_ids: Array[String]) -> Dictionary:
    if opening == null or not opening.has_method("snapshot"):
        return {"ok": false, "reason": "opening_required"}
    var snapshot: Variant = opening.snapshot()
    if typeof(snapshot) != TYPE_DICTIONARY or not snapshot.has("active_party_ids"):
        return {"ok": false, "reason": "invalid_story_snapshot"}
    if typeof(snapshot["active_party_ids"]) != TYPE_ARRAY:
        return {"ok": false, "reason": "invalid_party"}
    if requested_crew.is_empty() or requested_crew.size() > 3 or opponent_ids.is_empty():
        return {"ok": false, "reason": "invalid_group_size"}
    var authorized: Array = snapshot["active_party_ids"]
    var seen := {}
    for id in requested_crew:
        if id.is_empty() or id not in authorized or seen.has(id):
            return {"ok": false, "reason": "crew_not_recruited_or_duplicate"}
        seen[id] = true
    for id in opponent_ids:
        if id.is_empty() or seen.has(id):
            return {"ok": false, "reason": "invalid_opponent"}
        seen[id] = true
    var order: Array[String] = []
    order.append_array(requested_crew)
    order.append_array(opponent_ids)
    var result: Dictionary = Turns.begin(roster, order)
    if not result.get("ok", false):
        return result
    var factions := {}
    for id in requested_crew:
        factions[id] = "crew"
    for id in opponent_ids:
        factions[id] = "opponent"
    return {
        "ok": true,
        "state": result,
        "factions": factions,
        "story_step": snapshot.get("step", ""),
        "encounter_authorized": false,
        "review_only": true
    }
