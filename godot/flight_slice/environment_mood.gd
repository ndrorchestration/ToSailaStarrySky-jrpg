extends RefCounted
## Original, noncanonical environmental look presets. Pure and deterministic.
## These are cinematic grades, NOT a simulated planetary day/night or climate.
const TIMES = ["GOLDEN", "MIDDAY", "BLUE_HOUR", "NIGHT"]
const WEATHER = ["CLEAR", "MIST", "RAIN", "STORM"]

static func sample(time_index: int, weather_index: int, magic_enabled: bool) -> Dictionary:
    var t: int = posmod(time_index, TIMES.size())
    var w: int = posmod(weather_index, WEATHER.size())
    var key_color := Color(1.0, 0.83, 0.62)
    var key_energy: float = 1.15
    var fill_color := Color(0.62, 0.76, 0.88)
    var fill_energy: float = 0.55
    var ambient_color := Color(0.35, 0.46, 0.61)
    var ambient_energy: float = 0.85
    var fog_color := Color(0.39, 0.49, 0.58)
    var fog_density: float = 0.0035
    var sun_visibility: float = 1.0
    match t:
        1: # clear midday
            key_color = Color(0.94, 0.97, 1.0)
            key_energy = 1.38
            fill_energy = 0.64
            ambient_color = Color(0.45, 0.55, 0.68)
            ambient_energy = 1.0
            fog_color = Color(0.56, 0.67, 0.75)
            fog_density = 0.0028
        2: # blue hour: a restrained transition, not an eclipse
            key_color = Color(0.60, 0.66, 0.94)
            key_energy = 0.55
            fill_color = Color(0.53, 0.67, 0.88)
            fill_energy = 0.44
            ambient_color = Color(0.24, 0.34, 0.56)
            ambient_energy = 0.70
            fog_color = Color(0.31, 0.41, 0.59)
            fog_density = 0.0045
            sun_visibility = 0.35
        3: # moonlit color study; no astronomical or route authority
            key_color = Color(0.55, 0.69, 0.98)
            key_energy = 0.24
            fill_color = Color(0.39, 0.52, 0.77)
            fill_energy = 0.28
            ambient_color = Color(0.11, 0.18, 0.36)
            ambient_energy = 0.64
            fog_color = Color(0.14, 0.23, 0.40)
            fog_density = 0.0048
            sun_visibility = 0.0
    var weather_strength: float = [0.0, 0.22, 0.65, 1.0][w]
    var dim: float = [1.0, 0.87, 0.75, 0.57][w]
    key_energy *= dim
    fill_energy *= lerpf(1.0, 0.81, weather_strength)
    ambient_energy *= lerpf(1.0, 0.89, weather_strength)
    fog_density += [0.0, 0.0035, 0.0025, 0.0070][w]
    fog_color = fog_color.lerp(Color(0.29, 0.36, 0.46), weather_strength * 0.36)
    return {
        "time_name": TIMES[t], "weather_name": WEATHER[w],
        "time_palette": float(t), "weather_strength": weather_strength,
        "magic_veil_strength": 0.70 if magic_enabled else 0.0,
        "sun_visibility": sun_visibility, "key_color": key_color,
        "key_energy": key_energy, "fill_color": fill_color,
        "fill_energy": fill_energy, "ambient_color": ambient_color,
        "ambient_energy": ambient_energy, "fog_color": fog_color,
        "fog_density": fog_density, "precipitation": w >= 2
    }
