extends SceneTree
## Evidence: chronology-aware story roster is necessary, NEVER sufficient
## for a production Resonance Art. No live Chapter I state or saves modified.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Gate = preload("res://scripts/first_wake_resonance_roster_gate.gd")
const ENDER_LYRA := ["ender", "lyra"]
const ENDER_IONIA := ["ender", "ionia"]
const THREE := ["ender", "ionia", "lyra"]

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var gate = Gate.new()
    var opening = Opening.new()
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not _expect_denial(gate, opening, ENDER_IONIA, "participant_not_yet_joined:ionia"):
        return
    if not _expect_denial(gate, opening, THREE, "lyra_not_joined"):
        return
    if not _expect_denial(gate, opening, ["ender", "ender"], "duplicate_protagonist"):
        return
    if not _expect_denial(gate, opening, ["ender", "talen"], "unknown_protagonist"):
        return
    if not _expect_denial(gate, opening, ["ender"], "invalid_participant_count"):
        return
    if not _expect_denial(gate, opening, ["ender", "ionia", "lyra", "aepex"], "invalid_participant_count"):
        return
    if not _expect_denial(gate, opening, ["ender", "aepex"], "participant_not_yet_joined:aepex"):
        return
    if not _expect_denial(gate, opening, ["ender", "reson"], "participant_not_yet_joined:reson"):
        return
    if not _expect_denial(gate, {}, ENDER_LYRA, "unrecognized_story_contract"):
        return
    if not _expect_denial(gate, RefCounted.new(), ENDER_LYRA, "unrecognized_story_contract"):
        return
    if not _expect_denial(gate, opening, "ender,lyra", "invalid_participants"):
        return

    # Ionia is the first recruit; this does NOT establish a playable combo.
    if not opening.accept_ionia_job():
        _fail("Ionia-first recruitment failed")
        return
    if not _expect_presence(gate, opening, ENDER_IONIA, "engineering"):
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.complete_engineering_checks():
        _fail("engineering preflight progression failed")
        return
    if not _expect_presence(gate, opening, ENDER_IONIA, "preflight"):
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.begin_test_flight():
        _fail("test flight transition failed")
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.record_engine_failure(true, true, true):
        _fail("review-model engine failure gate failed")
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.complete_ocean_splashdown(true, true):
        _fail("recorded seaworthy splashdown rejected")
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.inspect_postflight_reserve(true):
        _fail("postflight reserve evidence gate failed")
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if opening.introduce_lyra_and_talen(false):
        _fail("unsafe reunion was admitted")
        return
    if not _expect_denial(gate, opening, ENDER_LYRA, "lyra_not_joined"):
        return
    if not opening.introduce_lyra_and_talen(true):
        _fail("safe reunion was rejected")
        return
    if not _expect_presence(gate, opening, ENDER_LYRA, "family_reunion"):
        return
    if not _expect_presence(gate, opening, THREE, "family_reunion"):
        return
    if not _expect_denial(gate, opening, ["lyra", "aepex"], "participant_not_yet_joined:aepex"):
        return
    # A party member's presence never grants a spell, saved unlock, or action.
    if not opening.record_clue("phase_readings") or not opening.record_clue("lyra_observation") or not opening.form_working_fuel_theory():
        _fail("working fuel theory gate failed")
        return
    if not _expect_presence(gate, opening, ENDER_LYRA, "working_theory"):
        return

    # Source state tampering fails closed; the gate itself must not repair it.
    opening.active_party_ids.erase("ionia")
    if not _expect_denial(gate, opening, ENDER_LYRA, "story_roster_mismatch"):
        return
    opening.active_party_ids.append("ionia")
    if not _expect_denial(gate, opening, ENDER_LYRA, "story_roster_mismatch"):
        return
    opening.active_party_ids = ["ender", "ionia", "lyra"]
    opening.safe_reunion_confirmed = false
    if not _expect_denial(gate, opening, ENDER_LYRA, "reunion_evidence_mismatch"):
        return

    print("TSTSS_RESONANCE_CHRONOLOGY_GATE_PASS: Ionia first, Lyra post-splashdown only, no automatic Art or turn authority")
    quit(0)

func _expect_denial(gate: Variant, opening: Variant, participants: Variant, reason: String) -> bool:
    var before: Dictionary = {}
    if opening is RefCounted and opening.get_script() == Opening:
        before = opening.snapshot()
    var result: Dictionary = gate.evaluate(opening, participants)
    if result.get("reason", "") != reason or result.get("rosterEligible", true) or result.get("canExecute", true) or result.get("canUnlockArt", true):
        _fail("unexpected admission: expected " + reason + ", got " + str(result))
        return false
    if not before.is_empty() and opening.snapshot() != before:
        _fail("denied roster check mutated revised-opening state")
        return false
    return true

func _expect_presence(gate: Variant, opening: Variant, participants: Array, phase: String) -> bool:
    var before: Dictionary = opening.snapshot()
    var result: Dictionary = gate.evaluate(opening, participants)
    if not result.get("rosterEligible", false) or result.get("canExecute", true) or result.get("canUnlockArt", true):
        _fail("roster-ready accidentally became a combat unlock at " + phase)
        return false
    if result.get("storyStep", "") != phase or result.get("reason", "") != "story_presence_only":
        _fail("incorrect story milestone for roster readiness")
        return false
    if opening.snapshot() != before:
        _fail("roster-readiness query mutated story progression")
        return false
    return true

func _fail(reason: String) -> void:
    push_error("TSTSS_RESONANCE_CHRONOLOGY_GATE_FAIL: " + reason)
    quit(1)
