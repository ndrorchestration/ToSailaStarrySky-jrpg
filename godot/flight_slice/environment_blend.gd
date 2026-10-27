extends RefCounted
## Deterministic, presentation-only interpolation between authored environmental
## palettes. No saved world time, weather simulation, triggers or route changes.
const COLOR_FIELDS = [
    "key_color", "fill_color", "ambient_color", "fog_color"
]
const SCALAR_FIELDS = [
    "time_palette", "weather_strength", "magic_veil_strength",
    "sun_visibility", "key_energy", "fill_energy", "ambient_energy",
    "fog_density", "rain_strength"
]

static func sample(start: Dictionary, destination: Dictionary,
        progress: float) -> Dictionary:
    if not is_finite(progress) or progress <= 0.0:
        return start.duplicate(true)
    if progress >= 1.0:
        return destination.duplicate(true)
    # Smoothstep has zero velocity at each endpoint and cannot overshoot.
    var t: float = progress * progress * (3.0 - 2.0 * progress)
    var result: Dictionary = destination.duplicate(true)
    for field in COLOR_FIELDS:
        result[field] = (start[field] as Color).lerp(destination[field], t)
    for field in SCALAR_FIELDS:
        result[field] = lerpf(float(start[field]), float(destination[field]), t)
    result["precipitation"] = float(result["rain_strength"]) > 0.035
    return result
