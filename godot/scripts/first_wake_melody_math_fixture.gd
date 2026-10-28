extends RefCounted
## Noncanonical ORIGINAL numeric fixture for a future composed sea-work melody.
## Relative pitch-step offsets and beat holds, not audio recognition or lore.
## The phase vector here is a deterministic QA mapping, NOT a real engine spec.
const RELATIVE_STEPS: Array[int] = [0, 2, 5, 3]
const HOLD_TICKS: Array[int] = [1, 1, 2, 1]
const REVIEW_PHASE_VECTOR: Array[int] = [0, 2, 6, -2]

static func sample_phrase(transposition: int = 0) -> Array:
    var result: Array = []
    for i in range(RELATIVE_STEPS.size()):
        result.append({
            "tone_step": transposition + RELATIVE_STEPS[i],
            "hold_ticks": HOLD_TICKS[i],
        })
    return result

static func sample_sensor_vector() -> Array:
    return REVIEW_PHASE_VECTOR.duplicate()

static func verify(heard: Variant, instrument: Variant) -> Dictionary:
    if not (heard is Array) or not (instrument is Array):
        return _no("invalid_input_type")
    if heard.size() != RELATIVE_STEPS.size() or instrument.size() != REVIEW_PHASE_VECTOR.size():
        return _no("incomplete_phrase_or_chart")
    var first_step: int = 0
    var last_relative: int = 0
    for i in range(heard.size()):
        var entry: Variant = heard[i]
        if not (entry is Dictionary) or entry.size() != 2:
            return _no("malformed_note")
        if not entry.has("tone_step") or not entry.has("hold_ticks"):
            return _no("missing_note_fields")
        if typeof(entry["tone_step"]) != TYPE_INT or typeof(entry["hold_ticks"]) != TYPE_INT:
            return _no("unmeasured_note")
        var tone: int = entry["tone_step"]
        var hold: int = entry["hold_ticks"]
        if hold <= 0:
            return _no("nonpositive_note_hold")
        if i == 0:
            first_step = tone
        var relative: int = tone - first_step
        if relative != RELATIVE_STEPS[i] or hold != HOLD_TICKS[i]:
            return _no("interval_or_dwell_mismatch")
        var jump: int = relative - last_relative if i > 0 else 0
        var derived: int = jump * hold
        if typeof(instrument[i]) != TYPE_INT or instrument[i] != derived:
            return _no("phase_chart_mismatch")
        last_relative = relative
    return {
        "ok": true,
        "reason": "original_review_fixture_correspondence",
        "relative_intervals": RELATIVE_STEPS.duplicate(),
        "hold_ticks": HOLD_TICKS.duplicate(),
        "derived_chart": REVIEW_PHASE_VECTOR.duplicate(),
        "live_engine_verified": false,
        "audio_captured": false,
        "flight_authorized": false,
    }

static func _no(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason, "flight_authorized": false}
