extends RefCounted
## Visual-only, manual-preview admission: NEVER ability/quest/story authority.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const VERSION := "0.1.0"
const CHANNEL := "manual_visual_review"
const REQUEST_KEYS = ["channel", "identity", "phaseIndex", "quality", "reducedMotion"]
const PHASE_POSITIONS = [0.08, 0.29, 0.49, 0.67, 0.89]

func render_plan(request: Dictionary) -> Dictionary:
    if request.size() != REQUEST_KEYS.size():
        return {}
    for key in REQUEST_KEYS:
        if not request.has(key):
            return {}
    if typeof(request["channel"]) != TYPE_STRING or request["channel"] != CHANNEL:
        return {}
    if typeof(request["identity"]) != TYPE_STRING:
        return {}
    var identity: String = request["identity"]
    if not Catalog.has_character(identity):
        return {}
    if typeof(request["phaseIndex"]) != TYPE_INT or typeof(request["quality"]) != TYPE_INT:
        return {}
    if typeof(request["reducedMotion"]) != TYPE_BOOL:
        return {}
    var phase_index: int = request["phaseIndex"]
    var quality: int = request["quality"]
    if phase_index < 0 or phase_index >= PHASE_POSITIONS.size() or quality < 0 or quality > 2:
        return {}
    return {
        "protocol": VERSION, "channel": CHANNEL, "identity": identity,
        "phaseIndex": phase_index, "phaseProgress": float(PHASE_POSITIONS[phase_index]),
        "quality": quality, "reducedMotion": bool(request["reducedMotion"]),
        "renderOnly": true, "canExecute": false, "canGrantMagic": false,
        "canMutateStory": false, "canMutateSave": false,
    }
