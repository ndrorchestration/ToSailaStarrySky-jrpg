extends RefCounted
## Bounded five-phase *presentation* envelope derived from the VFX lookdev
## timing contract (#411/#496). Independent of any five-character magic school.
const PHASES = ["anticipation", "formation", "release", "impact", "aftermath"]
const DURATION_SECONDS = 2.4
const REVIEW_POSITIONS = [0.08, 0.29, 0.49, 0.67, 0.89]

static func phase_at(progress: float) -> String:
    if is_nan(progress) or is_inf(progress):
        return ""
    var p: float = clampf(progress, 0.0, 1.0)
    if p < 0.18:
        return "anticipation"
    if p < 0.40:
        return "formation"
    if p < 0.58:
        return "release"
    if p < 0.77:
        return "impact"
    return "aftermath"

static func valid_quality(level: int) -> bool:
    return level >= 0 and level <= 2
