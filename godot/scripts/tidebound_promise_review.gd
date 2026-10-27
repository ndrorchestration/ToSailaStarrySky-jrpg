extends RefCounted
## Isolated, playable design study. NEVER attach to First Wake's production
## combat resolver, action permission map, save codec, or Chapter I progression.
## Focus points and damage coefficients below are local fixtures, NOT Arete/Echo canon.
const Catalog = preload("res://scripts/party_resonance_catalog.gd")
const ART_ID := "tidebound_promise"
const REVIEW_ONLY := true
const FOCUS_COST := 1
const WARD_CAPACITY := 4
const DEFAULT_STRIKE := 8
const MAX_FIXTURE_STRIKE := 12
const PARTICIPANTS := ["ender", "lyra"]

var party: Dictionary = {}
var phase: String = "player"
var ward_capacity: int = 0
var turns: int = 0
var enemy_turns: int = 0
var last_outcome: Dictionary = {}
var log: Array[String] = []
var catalog = Catalog.new()

func _init() -> void:
    reset()

func reset() -> void:
    party = {
        "ender": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
        "lyra": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
    }
    phase = "player"
    ward_capacity = 0
    turns = 0
    enemy_turns = 0
    last_outcome = {}
    log = ["Isolated training encounter. Proposed Tidebound Promise is ready."]

func snapshot() -> Dictionary:
    return {
        "reviewOnly": true, "phase": phase, "party": party.duplicate(true),
        "wardCapacity": ward_capacity, "turns": turns, "enemyTurns": enemy_turns,
        "lastOutcome": last_outcome.duplicate(true), "log": log.duplicate(),
    }

func configure_fixture(actor_id: String, values: Dictionary) -> bool:
    # Controlled fixture mutation is available only prior to the first turn.
    if phase != "player" or turns != 0 or not party.has(actor_id):
        return false
    if values.is_empty():
        return false
    for key in values.keys():
        if key not in ["hp", "focus", "canAct"]:
            return false
    var next: Dictionary = party.duplicate(true)
    var actor: Dictionary = next[actor_id]
    if values.has("hp"):
        if not (values["hp"] is int) or values["hp"] < 0 or values["hp"] > actor["maxHp"]:
            return false
        actor["hp"] = int(values["hp"])
        actor["alive"] = actor["hp"] > 0
    if values.has("focus"):
        if not (values["focus"] is int) or values["focus"] < 0 or values["focus"] > 2:
            return false
        actor["focus"] = int(values["focus"])
    if values.has("canAct"):
        if not (values["canAct"] is bool):
            return false
        actor["canAct"] = values["canAct"]
    party = next
    return true

func admission() -> Dictionary:
    if not catalog.validate_catalog():
        return _reject("invalid_catalog")
    if phase != "player":
        return _reject("wrong_phase")
    var art: Dictionary = catalog.definition_for(ART_ID)
    if art.is_empty() or art.get("sourceKind", "") != "dual" or art.get("participants", []) != PARTICIPANTS:
        return _reject("invalid_art")
    var states: Dictionary = {}
    for actor_id in PARTICIPANTS:
        if not party.has(actor_id) or not (party[actor_id] is Dictionary):
            return _reject("missing_actor")
        var actor: Dictionary = party[actor_id]
        if not _valid_actor(actor):
            return _reject("invalid_actor_state")
        states[actor_id] = {
            "alive": actor["alive"],
            "canAct": actor["canAct"],
        }
    var design: Dictionary = catalog.inspect_candidate(ART_ID, PARTICIPANTS, states, [ART_ID])
    if not bool(design.get("canPreview", false)):
        return _reject(str(design.get("reason", "catalog_denied")))
    for actor_id in PARTICIPANTS:
        var actor: Dictionary = party[actor_id]
        if int(actor["focus"]) < FOCUS_COST:
            return _reject("insufficient_review_focus:" + actor_id)
    # The DESIGN_ONLY catalog is deliberately never authorized for production.
    # This opt-in review controller has its own local fixture permission only.
    return {"ok": true, "reason": "isolated_fixture_admitted", "reviewOnly": true}

func activate() -> Dictionary:
    var gate: Dictionary = admission()
    if not bool(gate.get("ok", false)):
        return gate
    # Stage all actor costs/turn reservations before mutating the live fixture.
    var next: Dictionary = party.duplicate(true)
    for actor_id in PARTICIPANTS:
        var actor: Dictionary = next[actor_id]
        actor["focus"] = int(actor["focus"]) - FOCUS_COST
        actor["canAct"] = false
    party = next
    ward_capacity = WARD_CAPACITY
    phase = "enemy"
    turns += 1
    last_outcome = {"kind": "ward_created", "capacity": WARD_CAPACITY}
    log.append("Ender anchors a Spirit chord; Lyra shapes Water into one shared ward.")
    return {"ok": true, "reason": "ward_created", "wardCapacity": ward_capacity, "reviewOnly": true}

func pass_without_art() -> Dictionary:
    if phase != "player":
        return _reject("wrong_phase")
    phase = "enemy"
    turns += 1
    for actor_id in PARTICIPANTS:
        party[actor_id]["canAct"] = false
    last_outcome = {"kind": "no_ward"}
    log.append("The party withholds its combined Art. No ward is raised.")
    return {"ok": true, "reason": "baseline_no_ward", "reviewOnly": true}

func resolve_enemy_strike(target_id: String, damage: int) -> Dictionary:
    if phase != "enemy":
        return _reject("wrong_phase")
    if target_id not in PARTICIPANTS or not (damage is int) or damage < 1 or damage > MAX_FIXTURE_STRIKE:
        return _reject("invalid_strike")
    if not _valid_actor(party["ender"]) or not _valid_actor(party["lyra"]):
        return _reject("invalid_actor_state")
    if not bool(party[target_id]["alive"]):
        return _reject("invalid_target")
    var recipient: String = "lyra" if target_id == "ender" else "ender"
    var next: Dictionary = party.duplicate(true)
    var shielded := ward_capacity > 0
    var absorbed := mini(ward_capacity, damage) if shielded else 0
    var residual := damage - absorbed
    var target_damage := residual
    var partner_damage := 0
    if shielded and bool(next[recipient]["alive"]):
        target_damage = (residual + 1) / 2
        partner_damage = residual / 2
    next[target_id]["hp"] = maxi(0, int(next[target_id]["hp"]) - target_damage)
    next[recipient]["hp"] = maxi(0, int(next[recipient]["hp"]) - partner_damage)
    for actor_id in PARTICIPANTS:
        next[actor_id]["alive"] = int(next[actor_id]["hp"]) > 0
    party = next
    # Study intentionally models a one-hit ward, not perpetual mitigation.
    ward_capacity = 0
    phase = "complete"
    enemy_turns += 1
    last_outcome = {
        "kind": "enemy_strike", "target": target_id, "incoming": damage,
        "wardApplied": shielded, "absorbed": absorbed,
        "targetDamage": target_damage, "partnerDamage": partner_damage,
    }
    log.append("Enemy strike: %d incoming, %d warded, %d to %s, %d shared." % [
        damage, absorbed, target_damage, target_id.capitalize(), partner_damage,
    ])
    return {"ok": true, "reason": "enemy_strike_resolved", "outcome": last_outcome.duplicate(true), "reviewOnly": true}

func _valid_actor(actor: Dictionary) -> bool:
    for key in ["hp", "maxHp", "focus"]:
        if not actor.has(key) or not (actor[key] is int):
            return false
    if not (actor.get("alive", null) is bool) or not (actor.get("canAct", null) is bool):
        return false
    return int(actor["maxHp"]) == 12 and int(actor["hp"]) >= 0 and int(actor["hp"]) <= 12 and int(actor["focus"]) >= 0 and int(actor["focus"]) <= 2 and bool(actor["alive"]) == (int(actor["hp"]) > 0)

func _reject(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason, "reviewOnly": true}
