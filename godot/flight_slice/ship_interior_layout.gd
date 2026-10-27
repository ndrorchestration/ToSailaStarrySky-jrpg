extends RefCounted
## NONCANON planning envelope for a separate ship-as-home cutaway study.
## Proportions are design feasibility hypotheses, not the flight mesh's metres.
const LENGTH_M: float = 10.4
const BEAM_M: float = 3.8
const HEIGHT_M: float = 2.6
const AISLE_HALF_WIDTH_M: float = 0.66
const AISLE_FRONT_Z: float = -4.05
const AISLE_BACK_Z: float = 4.04

static func gross_envelope_m3() -> float:
    return LENGTH_M * BEAM_M * HEIGHT_M

static func zones() -> Array[Dictionary]:
    return [
        {"id": "bridge", "title": "NAVIGATION", "from_z": -5.05, "to_z": -2.04},
        {"id": "commons", "title": "COMMON ROOM", "from_z": -2.04, "to_z": 1.64},
        {"id": "engineering", "title": "ENGINEERING", "from_z": 1.64, "to_z": 5.05}
    ]

static func fixtures() -> Array[Dictionary]:
    # Center and half_footprint use X/Z metres. All maintain a clear continuous
    # central aisle; bunks are provisional fold-down sleeping surfaces.
    return [
        {"id": "helm_console", "zone": "bridge", "kind": "console",
            "center": Vector2(-1.22, -3.61), "half_footprint": Vector2(0.48, 0.60)},
        {"id": "chart_shelf", "zone": "bridge", "kind": "chart",
            "center": Vector2(1.24, -3.52), "half_footprint": Vector2(0.40, 0.66)},
        {"id": "shared_table", "zone": "commons", "kind": "table",
            "center": Vector2(-1.20, -1.10), "half_footprint": Vector2(0.46, 0.60)},
        {"id": "galley_storage", "zone": "commons", "kind": "galley",
            "center": Vector2(1.23, -1.11), "half_footprint": Vector2(0.44, 0.65)},
        {"id": "foldaway_berth_port", "zone": "commons", "kind": "berth",
            "center": Vector2(-1.20, 0.66), "half_footprint": Vector2(0.42, 0.76)},
        {"id": "foldaway_berth_starboard", "zone": "commons", "kind": "berth",
            "center": Vector2(1.20, 0.66), "half_footprint": Vector2(0.42, 0.76)},
        {"id": "phase_repair_bench", "zone": "engineering", "kind": "repair",
            "center": Vector2(-1.23, 2.90), "half_footprint": Vector2(0.43, 0.76)},
        {"id": "tool_lockers", "zone": "engineering", "kind": "storage",
            "center": Vector2(1.23, 3.01), "half_footprint": Vector2(0.43, 0.76)}
    ]

static func fixture_inside_envelope(fixture: Dictionary) -> bool:
    var c: Vector2 = fixture["center"]
    var h: Vector2 = fixture["half_footprint"]
    return h.x > 0.0 and h.y > 0.0 \
        and absf(c.x) + h.x <= BEAM_M * 0.5 - 0.08 \
        and absf(c.y) + h.y <= LENGTH_M * 0.5 - 0.08

static func aisle_is_clear(fixture: Dictionary) -> bool:
    var c: Vector2 = fixture["center"]
    var h: Vector2 = fixture["half_footprint"]
    var z_intersects: bool = c.y + h.y > AISLE_FRONT_Z \
        and c.y - h.y < AISLE_BACK_Z
    return not z_intersects or absf(c.x) - h.x >= AISLE_HALF_WIDTH_M

static func zones_cover_station(z: float) -> bool:
    for zone in zones():
        if z >= float(zone["from_z"]) and z <= float(zone["to_z"]):
            return true
    return false
