extends RefCounted
## Bounded, readable choice experiment; not audio transcription, canon tune,
## microphone calibration, or physical ship engine authority.
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const Melody = preload("res://scripts/first_wake_melody_math_fixture.gd")

const TITLES: Array[String] = [
    "A  |  0, +2, +5, +3   holds 1 / 1 / 1 / 1",
    "B  |  0, +2, +5, +3   holds 1 / 1 / 2 / 1",
    "C  |  0, +2, +4, +3   holds 1 / 1 / 2 / 1",
]
var open: bool = false
var selected: int = -1
var attempts: int = 0
var feedback: String = ""
var _candidates: Array = []

func _init() -> void:
    var short_hold: Array = Melody.sample_phrase()
    short_hold[2]["hold_ticks"] = 1
    var wrong_interval: Array = Melody.sample_phrase()
    wrong_interval[2]["tone_step"] = 4
    _candidates = [short_hold, Melody.sample_phrase(), wrong_interval]

func show_for(core: Variant) -> bool:
    if open or not (core is RefCounted) or core.get_script() != Core:
        return false
    if core.snapshot().get("phase", "") != "analyze":
        return false
    selected = -1
    attempts = 0
    feedback = "Compare note steps, held beats and measured phase response."
    open = true
    return true

func choose(index: int) -> bool:
    if not open or index < 0 or index >= _candidates.size():
        return false
    selected = index
    feedback = "Hypothesis %s selected. Press Interact to compare with the chart." % ["A", "B", "C"][index]
    return true

func submit(core: Variant) -> Dictionary:
    if not open or not (core is RefCounted) or core.get_script() != Core:
        return {"ok": false, "reason": "not_active"}
    if selected < 0:
        feedback = "Choose A, B or C first. None has been tested."
        return {"ok": false, "reason": "no_selection"}
    if core.snapshot().get("phase", "") != "analyze":
        return {"ok": false, "reason": "core_stage_changed"}
    attempts += 1
    var result: Dictionary = Melody.verify(_candidates[selected], Melody.sample_sensor_vector())
    if not bool(result.get("ok", false)):
        feedback = (
            "The third note's hold ends too soon; the chart needs two beats."
            if selected == 0
            else "The third interval disagrees with the phase shift. Recheck its height."
        )
        return {"ok": false, "reason": str(result.get("reason", "mismatch"))}
    if not core.ender_matches_review_phrase(_candidates[selected], Melody.sample_sensor_vector()):
        feedback = "The engine evidence rejected that interpretation."
        return {"ok": false, "reason": "story_contract_refused"}
    open = false
    feedback = "Ender connects Ionia's remembered intervals and held note to the instrument readings."
    return {"ok": true, "reason": "review_phrase_correspondence", "attempts": attempts}

func dismiss() -> bool:
    if not open:
        return false
    open = false
    selected = -1
    feedback = "Chart closed. Core remains out of phase."
    return true

func option_lines() -> String:
    var lines: Array[String] = []
    for i in range(TITLES.size()):
        lines.append(("%s  " % ("[SELECTED]" if selected == i else "[        ]")) + TITLES[i])
    return "\n".join(lines)

func snapshot() -> Dictionary:
    return {
        "open": open,
        "selected": selected,
        "attempts": attempts,
        "feedback": feedback,
        "can_launch": false,
        "can_execute_art": false,
        "audio_verified": false,
        "review_only": true,
    }
