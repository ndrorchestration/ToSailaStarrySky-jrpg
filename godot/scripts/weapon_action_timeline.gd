extends RefCounted
## Review-only, deterministic physical combat choreography. Never resolves damage,
## spends resources, executes learned skills, or grants combat authority.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const VERSION := "0.1.0"
const AUTHORITY := "NON_CANONICAL_VISUAL_STUDY"
const ACTIONS: Array[String] = ["idle", "attack", "guard", "victory"]
const STAGES: Array[String] = [
    "anticipation", "formation", "release", "impact", "aftermath"
]
const CUTS: Array[float] = [0.0, 0.20, 0.40, 0.62, 0.77, 1.0]
const DURATIONS := {
    "staff": {"idle":2.0, "attack":1.10, "guard":0.90, "victory":1.25},
    "sword": {"idle":2.0, "attack":0.85, "guard":0.84, "victory":1.15},
    "pike": {"idle":2.0, "attack":1.20, "guard":1.00, "victory":1.25},
    "rifle": {"idle":2.0, "attack":1.05, "guard":0.95, "victory":1.20},
}
const ATTACK_ANGLES := {
    "staff": [-3.0, -37.0, -54.0, 50.0, 12.0, -3.0],
    "sword": [-15.0, -50.0, -70.0, 55.0, -8.0, -15.0],
    "pike": [0.0, -12.0, -17.0, 5.0, 1.0, 0.0],
    "rifle": [0.0, 9.0, 0.0, -11.0, -3.0, 0.0],
}
const GUARD_ANGLES := {
    "staff": [0.0, 19.0, 31.0, 31.0, 18.0, 16.0],
    "sword": [-15.0, 1.0, 25.0, 30.0, 20.0, 18.0],
    "pike": [0.0, -10.0, -21.0, -20.0, -18.0, -17.0],
    "rifle": [0.0, 5.0, 13.0, 11.0, 8.0, 8.0],
}
const VICTORY_ANGLES := {
    "staff": [0.0, 5.0, 18.0, 30.0, 33.0, 30.0],
    "sword": [-15.0, -4.0, -28.0, -52.0, -53.0, -52.0],
    "pike": [0.0, 7.0, 14.0, 19.0, 20.0, 20.0],
    "rifle": [0.0, 10.0, 12.0, 10.0, 9.0, 9.0],
}
const CUES := {
    "staff": "full-shaft leverage; twin brass ferrules remain visible",
    "sword": "blade weight and clean follow-through",
    "pike": "long reach, bracing and linear commitment",
    "rifle": "steady aim, bounded recoil and restrained muzzle pulse",
}

var catalog = Catalog.new()

func duration(weapon_id: String, action_id: String) -> float:
    var weapon := catalog.weapon(weapon_id)
    var family: String = str(weapon.get("family", ""))
    if not DURATIONS.has(family) or action_id not in ACTIONS:
        return 0.0
    return float(DURATIONS[family][action_id])

func phase_at(progress: float) -> int:
    var p := clampf(progress, 0.0, 1.0)
    if p >= 1.0:
        return 4
    for i in range(5):
        if p < CUTS[i + 1]:
            return i
    return 4

func _keyframed(poses: Array, progress: float) -> float:
    var p := clampf(progress, 0.0, 1.0)
    if p >= 1.0:
        return float(poses[5])
    var index := phase_at(p)
    var fraction := (p - CUTS[index]) / (CUTS[index + 1] - CUTS[index])
    var eased := fraction * fraction * (3.0 - 2.0 * fraction)
    return lerpf(float(poses[index]), float(poses[index + 1]), eased)

func sample(weapon_id: String, action_id: String, seconds: float, reduced_motion: bool = false) -> Dictionary:
    var run_time := duration(weapon_id, action_id)
    if run_time <= 0.0 or is_nan(seconds) or is_inf(seconds):
        return {}
    var item := catalog.weapon(weapon_id)
    var family: String = str(item["family"])
    var elapsed := clampf(seconds, 0.0, run_time)
    var progress := elapsed / run_time
    var phase_index := phase_at(progress)
    var angle := 0.0
    var lean := 0.0
    var advance := 0.0
    var bob := 0.0
    var effect := 0.0
    var recoil := 0.0
    match action_id:
        "idle":
            angle = -3.0 if family == "sword" else 0.0
            bob = sin(progress * TAU) * 1.8
        "attack":
            angle = _keyframed(ATTACK_ANGLES[family], progress)
            lean = _keyframed([0.0, -4.0, -10.0, 15.0, 6.0, 0.0], progress)
            advance = _keyframed([0.0, -3.0, -6.0, 14.0, 10.0, 0.0], progress)
            if phase_index == 3:
                effect = 1.0 - abs(progress - 0.695) / 0.075
                if family == "rifle":
                    recoil = 9.0 * maxf(effect, 0.0)
        "guard":
            angle = _keyframed(GUARD_ANGLES[family], progress)
            lean = _keyframed([0.0, -2.0, -7.0, -8.0, -7.0, -6.0], progress)
            if phase_index >= 2:
                effect = 0.35
        "victory":
            angle = _keyframed(VICTORY_ANGLES[family], progress)
            lean = _keyframed([0.0, 2.0, 4.0, 8.0, 9.0, 7.0], progress)
            bob = _keyframed([0.0, -1.0, -8.0, -5.0, -3.0, 0.0], progress)
    if reduced_motion:
        angle = 0.0
        lean = 0.0
        advance = 0.0
        bob = 0.0
        effect = 0.0
        recoil = 0.0
    return {
        "weaponId": weapon_id, "family": family, "action": action_id,
        "authority": AUTHORITY, "duration": run_time, "elapsed": elapsed,
        "progress": progress, "phase": STAGES[phase_index], "phaseIndex": phase_index,
        "weaponAngle": angle, "lean": lean, "advance": advance, "bob": bob,
        "effect": maxf(effect, 0.0), "recoil": recoil,
        "motionReduced": reduced_motion, "damage": 0, "canExecute": false,
        "cue": CUES[family]
    }

func validate() -> bool:
    if ACTIONS.size() != 4 or STAGES.size() != 5:
        return false
    for weapon_id in Catalog.WEAPONS:
        for action in ACTIONS:
            var first := sample(weapon_id, action, 0.0)
            var last := sample(weapon_id, action, 999.0)
            if first.is_empty() or last.is_empty():
                return false
            if float(first["progress"]) != 0.0 or float(last["progress"]) != 1.0:
                return false
            if bool(first["canExecute"]) or int(last["damage"]) != 0:
                return false
            var muted := sample(weapon_id, action, 0.55, true)
            if float(muted["effect"]) != 0.0 or float(muted["advance"]) != 0.0:
                return false
    return true
