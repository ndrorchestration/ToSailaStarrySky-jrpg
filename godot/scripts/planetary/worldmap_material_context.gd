extends RefCounted
## MATERIAL-P0 / S1: read-only globe-cartography -> candidate material hint.
## No shader ownership, scene changes, climate simulation or hidden progression.
## Exact authored coast/alpine and weather/lighting choices are NOT canonical.
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const WEATHER = ["clear", "mist", "rain", "storm"]
const SAND = ["arid", "shore"]
const GROUND = ["woodland", "rainforest", "grassland", "alpine"]
const OCEAN = ["deep_ocean", "open_ocean", "coastal_shelf", "sea_ice"]

static func resolve(lat_deg: float, lon_deg: float, weather: String,
        rain_strength: float, wind_world: Vector3,
        sun_world: Vector3, low_quality: bool = false,
        reduced_motion: bool = false) -> Dictionary:
    # Fail closed to no material assignment for bad runtime input.
    if not is_finite(lat_deg) or not is_finite(lon_deg) \
            or absf(lat_deg) > 90.0 or not is_finite(rain_strength) \
            or rain_strength < 0.0 or rain_strength > 1.0 \
            or not wind_world.is_finite() or wind_world.length_squared() < 1.0e-10 \
            or not sun_world.is_finite() or sun_world.length_squared() < 1.0e-10 \
            or not WEATHER.has(weather):
        return {}
    var normalized_lon: float = Geo.normalize_longitude(lon_deg)
    var item: Dictionary = Cart.sample(lat_deg, normalized_lon)
    var biome: String = str(item["biome"])
    var land: bool = bool(item["land"])
    var snow: bool = land and biome == "snow"
    var sand: bool = land and SAND.has(biome)
    var rain_active: bool = weather == "rain" or weather == "storm"
    var wet_ground: bool = land and GROUND.has(biome) and rain_active \
        and rain_strength > 0.0
    var material: String = "base"
    if snow:
        material = "snow"
    elif sand:
        material = "sand"
    elif wet_ground:
        material = "wet_ground"
    # The global wind is projected onto the local east/north tangent frame,
    # independent of the cube face, so longitude seams cannot flip ripples.
    var latitude: float = deg_to_rad(lat_deg)
    var longitude: float = deg_to_rad(normalized_lon)
    if absf(lat_deg) >= 90.0:
        longitude = 0.0 # Same deterministic pole convention as Cart.sample.
    var east := Vector3(-sin(longitude), 0.0, cos(longitude))
    var north := Vector3(-sin(latitude)*cos(longitude),
        cos(latitude), -sin(latitude)*sin(longitude))
    var wind := wind_world.normalized()
    var projected := Vector2(wind.dot(east), wind.dot(north))
    if projected.length_squared() <= 1.0e-10:
        projected = Vector2.RIGHT # stable nonzero fallback at radial winds
    else:
        projected = projected.normalized()
    return {
        "biome": biome,
        "material": material,
        "land": land,
        "wind_tangent": projected, # x=east; y=north; tile-local only
        "sun_world": sun_world.normalized(),
        "optics_strength": 0.0 if low_quality else 1.0,
        "wetness_request": rain_strength if wet_ground else 0.0,
        "fog_requested": weather != "clear",
        "weather": weather, # sourced explicitly; moisture != precipitation
        "reduced_motion": reduced_motion, # pass to existing environment clock
        "climate_temperature": float(item["temperature"]),
        "climate_moisture": float(item["moisture"])
    }
