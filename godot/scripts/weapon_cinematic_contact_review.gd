extends RefCounted
## Deterministic bounded, non-executable contact framing. No Camera2D
## or encounter state is changed. Drives a standalone practice-stage transform.
const VERSION := "0.1.0"
const SOURCE := "REVIEW_ONLY_DIRECTIONAL_CINEMATIC"
const END = 1.0
const HIT_START = 0.62
const HIT_PEAK = 0.695
const HIT_END = 0.77

func sample(pose: Dictionary, facing: String) -> Dictionary:
    if str(pose.get("actorId","")) != "ender" \
        or str(pose.get("weaponId","")) != "full_length_staff" \
        or str(pose.get("formulaActionId","")) != "staffStrike" \
        or str(pose.get("action","")) != "attack" \
        or bool(pose.get("canExecute",true)) \
        or bool(pose.get("combatCommandIssued",true)) \
        or facing not in ["east","west","south","north"]:
        return {}
    var p := float(pose.get("progress",-1.0))
    if is_nan(p) or is_inf(p) or p < 0.0 or p > END:
        return {}
    var reduced := bool(pose.get("motionReduced",false))
    var intensity := 0.0
    if p >= HIT_START and p <= HIT_PEAK:
        intensity = (p - HIT_START) / (HIT_PEAK-HIT_START)
    elif p > HIT_PEAK and p < HIT_END:
        intensity = (HIT_END - p) / (HIT_END-HIT_PEAK)
    intensity = clampf(intensity,0.0,1.0)
    var directional := -1.0 if facing == "west" else 1.0
    var zoom := 1.0
    var stage_shift := Vector2.ZERO
    var contact_strength := 0.0
    if not reduced:
        zoom = 1.0 + intensity*0.022
        stage_shift = Vector2(-directional*2.5*intensity,-1.7*intensity)
        contact_strength = intensity*0.55
    return {
        "source":SOURCE,"actorId":"ender","weaponId":"full_length_staff",
        "facing":facing,"progress":p,"phase":str(pose["phase"]),
        "zoom":zoom,"stageShift":stage_shift,"contactStrength":contact_strength,
        "targetReaction":"VISUAL_MARKER_ONLY","hitAuthorized":false,
        "cameraStateOnly":true,"motionReduced":reduced,
        "damage":0,"combatCommandIssued":false
    }

func validate() -> bool:
    var authorized := {
        "actorId":"ender","weaponId":"full_length_staff",
        "formulaActionId":"staffStrike","action":"attack","phase":"impact",
        "progress":HIT_PEAK,"canExecute":false,"combatCommandIssued":false
    }
    for face in ["east","west","south","north"]:
        var peak := sample(authorized,face)
        if peak.is_empty() or float(peak["zoom"]) > 1.03 \
            or float(peak["contactStrength"]) > 0.56 \
            or bool(peak["hitAuthorized"]) or int(peak["damage"]) != 0:
            return false
        var muted := authorized.duplicate()
        muted["motionReduced"] = true
        var quiet := sample(muted,face)
        if float(quiet["zoom"]) != 1.0 or float(quiet["contactStrength"]) != 0.0 \
            or Vector2(quiet["stageShift"]) != Vector2.ZERO:
            return false
    return sample(authorized,"invalid").is_empty()
