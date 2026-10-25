extends RefCounted
## Deterministic globe coloration and biome classification. Every sampled feature is
## NON-CANON placeholder geography; no city, shore or planet size is approved.
## Longitude is cyclic, and the exact poles are independent of longitude.
const COAST_THRESHOLD := 0.025
const FIXTURE_SEED := 17

static func sample(lat_deg: float, lon_deg: float, seed: int = FIXTURE_SEED) -> Dictionary:
    assert(is_finite(lat_deg) and is_finite(lon_deg), "WORLDMAP_COORD_NONFINITE")
    assert(lat_deg >= -90.0 and lat_deg <= 90.0, "WORLDMAP_LATITUDE_RANGE")
    var phi := deg_to_rad(lat_deg)
    var theta := deg_to_rad(fposmod(lon_deg + 180.0, 360.0) - 180.0)
    if absf(lat_deg) >= 90.0:
        theta = 0.0
    var x := cos(phi) * cos(theta)
    var y := sin(phi)
    var z := cos(phi) * sin(theta)
    var phase := float(seed % 101) * 0.019
    # All frequencies live in xyz on the unit sphere: no equirectangular seam.
    var low := 0.36 * sin(3.1*x + 2.2*z + phase)
    low += 0.29 * cos(3.7*z - 1.9*y - phase)
    low += 0.16 * sin(6.9*x + 3.2*y - 2.8*z)
    low += 0.11 * cos(10.2*y + 4.3*z + phase)
    var detail := 0.047 * sin(17.0*x + 13.0*z + 3.0*y)
    detail += 0.025 * cos(23.0*z - 9.0*x + 2.0*y)
    var elevation: float = low + detail - 0.18
    var temperature := clampf(1.04 - absf(lat_deg)/87.0 - maxf(elevation,0.0)*0.43, 0.0, 1.0)
    var moisture := clampf(0.50 + 0.26*sin(5.1*z+2.7*y+phase) + 0.19*cos(6.3*x-4.1*y),0.0,1.0)
    var biome := "deep_ocean"
    var color := Color("#062743")
    if elevation < -0.25:
        biome = "deep_ocean"
        color = Color("#073756").lerp(Color("#092843"), clampf((-elevation-0.25)*1.3, 0.0, 1.0))
    elif elevation <= 0.0:
        biome = "coastal_shelf" if elevation > -0.09 else "open_ocean"
        color = Color("#0e496a").lerp(Color("#2d8e96"), clampf((elevation+0.25)/0.25,0.0,1.0))
    elif elevation < COAST_THRESHOLD:
        biome = "shore"
        color = Color("#d7bb86")
    elif temperature < 0.16:
        biome = "snow"
        color = Color("#e2eae4")
    elif elevation > 0.49:
        biome = "alpine"
        color = Color("#c6c2aa") if temperature > 0.26 else Color("#d8e4df")
    elif moisture < 0.31 and temperature > 0.44:
        biome = "arid"
        color = Color("#bca373").lerp(Color("#dfbe83"), clampf(temperature, 0.0, 1.0))
    elif moisture > 0.68 and temperature > 0.67:
        biome = "rainforest"
        color = Color("#215f58")
    elif moisture > 0.47:
        biome = "woodland"
        color = Color("#426f5c").lerp(Color("#73906b"), clampf((elevation-0.04)*0.7,0.0,1.0))
    else:
        biome = "grassland"
        color = Color("#89966c")
    if elevation <= 0.0 and temperature < 0.09:
        biome = "sea_ice"
        color = Color("#aeced1").lerp(Color("#e5ede9"), clampf((0.09-temperature)*8.0,0.0,1.0))
    var shade := clampf(0.94 + detail * 0.85, 0.88, 1.04)
    color = Color(clampf(color.r * shade,0.0,1.0),
            clampf(color.g * shade,0.0,1.0),
            clampf(color.b * shade,0.0,1.0), 1.0)
    return {"elevation": elevation, "temperature": temperature, "moisture": moisture,
            "biome": biome, "color": color, "land": elevation > 0.0}

static func render_equirect(width: int = 640, height: int = 320, seed: int = FIXTURE_SEED) -> Image:
    assert(width >= 16 and width <= 2048 and height >= 8 and height <= 1024, "WORLDMAP_RASTER_BOUNDS")
    var img := Image.create(width,height,false,Image.FORMAT_RGBA8)
    for j in range(height):
        var lat := 90.0 - 180.0 * float(j) / float(height-1)
        for i in range(width):
            var lon := -180.0 + 360.0 * float(i) / float(width-1)
            var record := sample(lat,lon,seed)
            img.set_pixel(i,j,record["color"])
    return img

static func render_local(center: Dictionary, radius_km: float, planet_radius_km: float, size: int = 160) -> Image:
    const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")
    assert(size >= 32 and size <= 512, "WORLDMAP_LOCAL_RASTER_BOUNDS")
    assert(radius_km > 0.0 and radius_km < planet_radius_km, "WORLDMAP_LOCAL_RADIUS")
    var img := Image.create(size,size,false,Image.FORMAT_RGBA8)
    for y in range(size):
        for x in range(size):
            var east_km := (float(x) / float(size-1)*2.0-1.0)*radius_km
            var north_km := (1.0-float(y)/float(size-1)*2.0)*radius_km
            if east_km*east_km+north_km*north_km > radius_km*radius_km:
                img.set_pixel(x,y,Color("#061321"))
                continue
            var p := Geometry.from_local_km(center,east_km,north_km,planet_radius_km)
            var record := sample(float(p["latDeg"]),float(p["lonDeg"]))
            img.set_pixel(x,y,record["color"])
    return img
