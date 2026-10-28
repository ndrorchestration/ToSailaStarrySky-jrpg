extends RefCounted
## Pure design-only Resonance catalog. No combat execution, resource or save mutations.
## Story Sigils do not grant magic affinity, learned actions, or native turn authority.
const VERSION := "0.1.0"
const CREATOR_SIGILS := {
    "ender": "spirit", "lyra": "water", "ionia": "earth",
    "reson": "fire", "aepex": "air",
}
# PROPOSED names and effects, not canonized / not executable.
const ART_DEFS := {
    "tidebound_promise": {
        "id": "tidebound_promise", "name": "Tidebound Promise", "sourceKind": "dual",
        "participants": ["ender", "lyra"], "sigils": ["spirit", "water"],
        "contributions": ["stabilize-bond", "shape-flow"],
        "interactionMechanism": "flowing ward held by a shared cadence",
        "emergentIntent": "bounded-damage-sharing-ward", "targeting": "allied-party",
        "presentationId": "resonance_tidebound_promise", "runtimeStatus": "DESIGN_ONLY",
    },
    "skyroot_bastion": {
        "id": "skyroot_bastion", "name": "Skyroot Bastion", "sourceKind": "dual",
        "participants": ["ionia", "aepex"], "sigils": ["earth", "air"],
        "contributions": ["anchor-lattice", "route-wind"],
        "interactionMechanism": "wind redirected through a grounded lattice",
        "emergentIntent": "bounded-projectile-interception-zone", "targeting": "allied-field",
        "presentationId": "resonance_skyroot_bastion", "runtimeStatus": "DESIGN_ONLY",
    },
    "embermist_veil": {
        "id": "embermist_veil", "name": "Embermist Veil", "sourceKind": "dual",
        "participants": ["lyra", "reson"], "sigils": ["water", "fire"],
        "contributions": ["shape-water", "control-heat"],
        "interactionMechanism": "controlled phase transition creates obscuring vapor",
        "emergentIntent": "two-sided-targeting-obscuration", "targeting": "battlefield-zone",
        "presentationId": "resonance_embermist_veil", "runtimeStatus": "DESIGN_ONLY",
    },
    "horizon_relay": {
        "id": "horizon_relay", "name": "Horizon Relay", "sourceKind": "triple",
        "participants": ["ender", "ionia", "aepex"], "sigils": ["spirit", "earth", "air"],
        "contributions": ["synchronize", "anchor", "route"],
        "interactionMechanism": "linked anchor channels a momentary safe route",
        "emergentIntent": "bounded-ally-reposition-and-cover", "targeting": "allied-party",
        "presentationId": "resonance_horizon_relay", "runtimeStatus": "DESIGN_ONLY",
    },
}
func definition_for(art_id: String) -> Dictionary:
    if not ART_DEFS.has(art_id):
        return {}
    return Dictionary(ART_DEFS[art_id]).duplicate(true)

func list_definitions() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for art_id in ART_DEFS.keys():
        result.append(definition_for(str(art_id)))
    return result

func validate_catalog() -> bool:
    if CREATOR_SIGILS != {
        "ender": "spirit", "lyra": "water", "ionia": "earth",
        "reson": "fire", "aepex": "air",
    } or ART_DEFS.is_empty():
        return false
    var presentations: Array[String] = []
    for key in ART_DEFS.keys():
        var art: Dictionary = ART_DEFS[key]
        if str(art.get("id", "")) != str(key) or str(art.get("runtimeStatus", "")) != "DESIGN_ONLY":
            return false
        if str(art.get("name", "")).is_empty() or str(art.get("interactionMechanism", "")).is_empty():
            return false
        if str(art.get("emergentIntent", "")).is_empty() or str(art.get("targeting", "")).is_empty():
            return false
        var participants = art.get("participants", null)
        var sigils = art.get("sigils", null)
        var contributions = art.get("contributions", null)
        if not (participants is Array and sigils is Array and contributions is Array):
            return false
        var count: int = participants.size()
        var kind := str(art.get("sourceKind", ""))
        if kind not in ["dual", "triple"] or count != (2 if kind == "dual" else 3):
            return false
        if sigils.size() != count or contributions.size() != count:
            return false
        var seen: Dictionary = {}
        for i in range(count):
            var actor_id: String = str(participants[i])
            if not CREATOR_SIGILS.has(actor_id) or seen.has(actor_id):
                return false
            seen[actor_id] = true
            if str(sigils[i]) != str(CREATOR_SIGILS[actor_id]) or str(contributions[i]).is_empty():
                return false
        var presentation := str(art.get("presentationId", ""))
        if presentation.is_empty() or presentation in presentations:
            return false
        presentations.append(presentation)
    return true

func inspect_candidate(art_id: String, party: Array, states: Dictionary, unlocked: Array) -> Dictionary:
    # Design preview only. Inputs are never treated as runtime action authority.
    var art := definition_for(art_id)
    if art.is_empty():
        return _deny(art_id, "unknown_art")
    if not validate_catalog():
        return _deny(art_id, "invalid_catalog")
    if party.size() > CREATOR_SIGILS.size():
        return _deny(art_id, "invalid_party")
    var membership: Dictionary = {}
    for member in party:
        if not (member is String) or not CREATOR_SIGILS.has(member) or membership.has(member):
            return _deny(art_id, "invalid_party")
        membership[member] = true
    if art_id not in unlocked:
        return _deny(art_id, "art_not_unlocked")
    for actor_id in art["participants"]:
        if not membership.has(actor_id):
            return _deny(art_id, "participant_missing")
        if not states.has(actor_id) or not (states[actor_id] is Dictionary):
            return _deny(art_id, "participant_state_missing")
        var actor: Dictionary = states[actor_id]
        if not (actor.get("alive", null) is bool) or not (actor.get("canAct", null) is bool):
            return _deny(art_id, "participant_state_invalid")
        if not bool(actor["alive"]) or not bool(actor["canAct"]):
            return _deny(art_id, "participant_unavailable")
    return {"artId": art_id, "canPreview": true, "canExecute": false, "reason": "design_only", "definition": art}

func try_execute(art_id: String, _battle_state: Dictionary) -> Dictionary:
    # No-op guard even if the caller forges preview or unlock flags.
    return _deny(art_id, "execution_not_implemented")

func _deny(art_id: String, reason: String) -> Dictionary:
    return {"artId": art_id, "canPreview": false, "canExecute": false, "reason": reason}
