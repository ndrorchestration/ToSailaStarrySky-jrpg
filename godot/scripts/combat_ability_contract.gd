extends RefCounted
## A shared *metadata* contract across the admitted native JRPG formula subset and
## proposal-only party Arts. This registry does not execute combat, spend costs,
## authorize turns, persist saves, or grant learned spells.
const Formula = preload("res://scripts/first_wake_combat_formula.gd")
const Resonance = preload("res://scripts/party_resonance_catalog.gd")
const VERSION := "0.1.0"
const VALID_KINDS := ["formula", "dual", "triple"]
const REVIEW_STATUS := "DESIGN_ONLY"
const FORMULA_STATUS := "EXTERNAL_AUTHORITY_REQUIRED"

var formula = Formula.new()
var resonance = Resonance.new()

func for_formula(action_id: String) -> Dictionary:
    if action_id not in Formula.AUTHORIZED_FORMULA_ACTIONS:
        return {}
    var metadata: Dictionary = formula.get_formula(action_id)
    if metadata.is_empty() or str(metadata.get("id", "")) != action_id:
        return {}
    var result := {
        "version": VERSION,
        "id": action_id, "sourceKind": "formula",
        "runtimeStatus": FORMULA_STATUS, "participants": [],
        "sigils": [], "targeting": "formula-owned",
        "effectIntent": str(metadata.get("kind", "")),
        "resolution": {"model": "jrpg-stat-formula", "formulaId": action_id},
        "canExecute": false,
    }
    return result if validate_definition(result) else {}

func for_resonance(art_id: String) -> Dictionary:
    if not resonance.validate_catalog():
        return {}
    var art: Dictionary = resonance.definition_for(art_id)
    if art.is_empty():
        return {}
    var result := {
        "version": VERSION,
        "id": art_id, "sourceKind": str(art.get("sourceKind", "")),
        "runtimeStatus": str(art.get("runtimeStatus", "")),
        "participants": Array(art.get("participants", [])).duplicate(),
        "sigils": Array(art.get("sigils", [])).duplicate(),
        "targeting": str(art.get("targeting", "")),
        "effectIntent": str(art.get("emergentIntent", "")),
        "resolution": {"model": "design-only", "effectId": art_id},
        "canExecute": false,
    }
    return result if validate_definition(result) else {}

func validate_definition(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    var d: Dictionary = value
    if str(d.get("version", "")) != VERSION:
        return false
    var action_id = d.get("id", null)
    if not (action_id is String) or action_id.strip_edges().is_empty():
        return false
    if not (d.get("canExecute", null) is bool) or bool(d["canExecute"]):
        return false
    var kind: String = str(d.get("sourceKind", ""))
    if kind not in VALID_KINDS:
        return false
    var participants = d.get("participants", null)
    var sigils = d.get("sigils", null)
    if not (participants is Array and sigils is Array):
        return false
    if str(d.get("targeting", "")).is_empty() or str(d.get("effectIntent", "")).is_empty():
        return false
    var resolution = d.get("resolution", null)
    if not (resolution is Dictionary):
        return false
    if kind == "formula":
        return participants.is_empty() and sigils.is_empty() \
            and d.get("runtimeStatus", "") == FORMULA_STATUS \
            and d["resolution"].get("model", "") == "jrpg-stat-formula" \
            and d["resolution"].get("formulaId", "") == action_id \
            and action_id in Formula.AUTHORIZED_FORMULA_ACTIONS
    if d.get("runtimeStatus", "") != REVIEW_STATUS or d["resolution"].get("model", "") != "design-only":
        return false
    if d["resolution"].get("effectId", "") != action_id:
        return false
    var expected: int = 2 if kind == "dual" else 3
    if participants.size() != expected or sigils.size() != expected:
        return false
    var seen: Dictionary = {}
    for index in range(expected):
        var actor = participants[index]
        if not (actor is String) or seen.has(actor):
            return false
        if not Resonance.CREATOR_SIGILS.has(actor) or sigils[index] != Resonance.CREATOR_SIGILS[actor]:
            return false
        seen[actor] = true
    # No fabricated art ID can pass by copying legitimate participant metadata.
    var established: Dictionary = resonance.definition_for(action_id)
    return not established.is_empty() \
        and established.get("participants", []) == participants \
        and established.get("sourceKind", "") == kind \
        and established.get("emergentIntent", "") == d["effectIntent"]
