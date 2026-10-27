extends RefCounted
## Noncanonical visual-only signed shoreline proximity. Source is exactly the
## existing sampled terrain height Image; no second coast or gameplay collider.
## Positive = inland, negative = water. Distances are approximated in meters
## with a deterministic eight-neighbor chamfer distance transform.
const MAX_DISTANCE_METERS: float = 24.0
const DIAGONAL_COST: float = 1.41421356237

static func bake(height_field: Image, sea_level: float, span_meters: float) -> Image:
    if height_field == null or height_field.is_empty() or not is_finite(span_meters) or span_meters <= 0.0:
        return null
    var width: int = height_field.get_width()
    var height: int = height_field.get_height()
    if width < 3 or height < 3 or width != height:
        return null
    var length: int = width * height
    var land := PackedByteArray()
    land.resize(length)
    var distance := PackedFloat32Array()
    distance.resize(length)
    distance.fill(1.0e6)
    for y in range(height):
        for x in range(width):
            land[y * width + x] = 1 if height_field.get_pixel(x, y).r >= sea_level else 0
    # Boundary seeds are derived from opposing wet/dry height samples only.
    for y in range(height):
        for x in range(width):
            var i: int = y * width + x
            var dry: int = land[i]
            if (x > 0 and land[i - 1] != dry) or (x < width - 1 and land[i + 1] != dry) or (y > 0 and land[i - width] != dry) or (y < height - 1 and land[i + width] != dry):
                distance[i] = 0.0
    # Two forward/backward raster sweeps admit horizontal/vertical and
    # diagonal shortest-neighbor paths. Fixed work: O(width * height).
    for y in range(height):
        for x in range(width):
            var i: int = y * width + x
            var d: float = distance[i]
            if x > 0: d = minf(d, distance[i - 1] + 1.0)
            if y > 0:
                d = minf(d, distance[i - width] + 1.0)
                if x > 0: d = minf(d, distance[i - width - 1] + DIAGONAL_COST)
                if x < width - 1: d = minf(d, distance[i - width + 1] + DIAGONAL_COST)
            distance[i] = d
    for y in range(height - 1, -1, -1):
        for x in range(width - 1, -1, -1):
            var i: int = y * width + x
            var d: float = distance[i]
            if x < width - 1: d = minf(d, distance[i + 1] + 1.0)
            if y < height - 1:
                d = minf(d, distance[i + width] + 1.0)
                if x > 0: d = minf(d, distance[i + width - 1] + DIAGONAL_COST)
                if x < width - 1: d = minf(d, distance[i + width + 1] + DIAGONAL_COST)
            distance[i] = d
    var meters_per_pixel: float = span_meters / float(width)
    var output := Image.create(width, height, false, Image.FORMAT_RF)
    for y in range(height):
        for x in range(width):
            var i: int = y * width + x
            var meters: float = minf(distance[i] * meters_per_pixel, MAX_DISTANCE_METERS)
            if land[i] == 0: meters = -meters
            output.set_pixel(x, y, Color(meters, 0.0, 0.0))
    return output
