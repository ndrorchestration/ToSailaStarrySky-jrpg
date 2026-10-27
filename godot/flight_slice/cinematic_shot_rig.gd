extends RefCounted
## Public-safe, noncanonical shot composition for the local Godot art study.
## This class never drives ship movement, collision, lore, moon gates, or saves.
## Camera pose is a pure function of the authored 37 s flight clock.
const LOOP_SECONDS: float = 37.0
const COAST_FOREST_CROSSFADE: Vector2 = Vector2(10.5, 13.5)
const FOREST_HIGHLAND_CROSSFADE: Vector2 = Vector2(24.5, 27.5)

# Relative camera/focus offsets preserve the real ship in the scene. A deliberately
# uncentered gaze makes the geography and horizon part of each composition.
const COAST_CAMERA := Vector3(-25.0, 14.5, 23.0)
const FOREST_CAMERA := Vector3(-13.0, 8.6, 18.0)
const HIGHLAND_CAMERA := Vector3(-25.0, 17.0, -13.0)
const COAST_FOCUS := Vector3(9.0, 0.9, -2.5)
const FOREST_FOCUS := Vector3(7.0, 1.2, -1.0)
const HIGHLAND_FOCUS := Vector3(10.0, 1.6, 1.0)
const COAST_FOV: float = 57.0
const FOREST_FOV: float = 50.0
const HIGHLAND_FOV: float = 55.0

static func sample(clock: float, ship_position: Vector3,
        reduced_motion: bool = false) -> Dictionary:
    # Caller provides the bounded scene clock; invalid inputs fail to a
    # stable wide shot instead of propagating NaN into the active camera.
    if not is_finite(clock) or not ship_position.is_finite():
        return {"position": Vector3(-25.0, 20.0, 23.0),
            "focus": Vector3.ZERO, "fov": COAST_FOV, "shot": "fallback"}
    var time: float = fposmod(clock, LOOP_SECONDS)
    var into_forest: float = smoothstep(
        COAST_FOREST_CROSSFADE.x, COAST_FOREST_CROSSFADE.y, time)
    var into_highland: float = smoothstep(
        FOREST_HIGHLAND_CROSSFADE.x, FOREST_HIGHLAND_CROSSFADE.y, time)
    var offset: Vector3 = COAST_CAMERA.lerp(FOREST_CAMERA, into_forest).lerp(
        HIGHLAND_CAMERA, into_highland)
    var focus_offset: Vector3 = COAST_FOCUS.lerp(FOREST_FOCUS, into_forest).lerp(
        HIGHLAND_FOCUS, into_highland)
    var field_of_view: float = lerpf(
        lerpf(COAST_FOV, FOREST_FOV, into_forest),
        HIGHLAND_FOV, into_highland)

    # One slow, low-amplitude lateral drift; motion-reduction removes it.
    # No shake, roll, snap cuts, synthetic zoom bursts or camera-only HUD cues.
    if not reduced_motion:
        offset += Vector3(
            sin(time * 0.12) * 0.60,
            sin(time * 0.10 + 0.7) * 0.28,
            cos(time * 0.09) * 0.33)

    var shot_name: String = "coastal_departure"
    if time >= COAST_FOREST_CROSSFADE.y:
        shot_name = "forest_passage"
    if time >= FOREST_HIGHLAND_CROSSFADE.y:
        shot_name = "highland_reveal"
    if (time > COAST_FOREST_CROSSFADE.x and
            time < COAST_FOREST_CROSSFADE.y) or (
            time > FOREST_HIGHLAND_CROSSFADE.x and
            time < FOREST_HIGHLAND_CROSSFADE.y):
        shot_name = "dissolve"
    return {"position": ship_position + offset,
        "focus": ship_position + focus_offset,
        "fov": field_of_view, "shot": shot_name}
