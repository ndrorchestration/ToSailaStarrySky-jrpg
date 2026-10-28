extends RefCounted
## Review-only story mechanics: physical recovery AND tested harmonic alignment.
## No actual inventory assets, audio DSP, engine physics or flight authorization.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Melody = preload("res://scripts/first_wake_melody_math_fixture.gd")
const ITEM_IDS: Array[String] = ["recovered_supply", "recovered_part"]
const PHASES: Array[String] = ["closed", "recover", "install", "retest", "listen", "repeat", "analyze", "observe", "authorize", "verify", "candidate"]
var phase: int = 0
var recovered: Array[String] = []
var installed: Array[String] = []
var failed_retest: bool = false
var melody_recognized: bool = false
# Exact in-memory origin of this review core; no serialized item/plot authority.
var authorized_story: Variant

func begin(story: Variant) -> bool:
    if phase != 0 or not (story is RefCounted) or story.get_script() != Opening:
        return false
    var state: Dictionary = story.snapshot()
    if state.get("step", "") != "working_theory":
        return false
    if not state.get("safe_reunion_confirmed", false):
        return false
    if state.get("active_party_ids", []) != ["ender", "ionia", "lyra"]:
        return false
    if int(state.get("evidence_count", 0)) < 2:
        return false
    authorized_story = story
    phase = 1
    return true

func take_world_item(item_id: String, source: String) -> bool:
    if phase != 1 or source != "world_pickup" or item_id not in ITEM_IDS or item_id in recovered:
        return false
    recovered.append(item_id)
    if recovered.size() == ITEM_IDS.size():
        phase = 2
    return true

func install_part(item_id: String, physical_installation_checked: bool) -> bool:
    if phase != 2 or not physical_installation_checked or item_id not in recovered or item_id in installed:
        return false
    installed.append(item_id)
    if installed.size() == ITEM_IDS.size():
        phase = 3
    return true

func retest_with_supplies(supplies_present: bool, phase_still_unstable: bool, containment_safe: bool) -> bool:
    if phase != 3 or not supplies_present or not phase_still_unstable or not containment_safe:
        return false
    failed_retest = true
    phase = 4
    return true

func ionia_hums_unprompted(unprompted: bool) -> bool:
    return _advance(4, unprompted and failed_retest)

func ionia_repeats_denith_song(ionia_agrees: bool, former_captain_memory: bool) -> bool:
    return _advance(5, ionia_agrees and former_captain_memory)

func ender_matches_review_phrase(heard: Variant, instrument: Variant) -> bool:
    if phase != 6 or not bool(Melody.verify(heard, instrument).get("ok", false)):
        return false
    phase = 7
    melody_recognized = true
    return true

func lyra_confirms_response(independent_observation: bool) -> bool:
    return _advance(7, independent_observation and melody_recognized)

func ionia_approves_bench_test(authorization: bool, containment_checked: bool) -> bool:
    return _advance(8, authorization and containment_checked)

func verify_stable_core(phase_stable: bool, containment_stable: bool) -> bool:
    return _advance(9, phase_stable and containment_stable)

func snapshot() -> Dictionary:
    return {
        "phase": PHASES[phase],
        "recovered": recovered.duplicate(),
        "installed": installed.duplicate(),
        "failed_retest": failed_retest,
        "melody_recognized": melody_recognized,
        "materialReady": phase >= 3,
        "alignment_candidate": phase == 10,
        "can_launch": false,
        "can_execute_art": false,
        "save_migrated": false,
        "native_audio_verified": false,
        "native_physics_verified": false,
        "review_only": true,
    }

func _advance(expected: int, evidence: bool) -> bool:
    if phase != expected or not evidence:
        return false
    phase += 1
    return true
