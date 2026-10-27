extends RefCounted
## NONCANON local bathymetry contract for the Coast-to-Highland art study.
## Uses the SAME height source and sea-level datum as rendered terrain.
## This does not implement planetary seabed geography or underwater gameplay.
const TerrainStudy = preload("res://terrain.gd")

static func bed_elevation(x: float, z: float) -> float:
    return TerrainStudy.sample_height(x, z)

static func water_depth(x: float, z: float) -> float:
    return maxf(TerrainStudy.SEA_LEVEL - bed_elevation(x, z), 0.0)

static func is_submerged(x: float, z: float) -> bool:
    return bed_elevation(x, z) < TerrainStudy.SEA_LEVEL

static func sample(x: float, z: float) -> Dictionary:
    var bed: float = bed_elevation(x, z)
    return {
        "bed_elevation": bed,
        "sea_surface_elevation": TerrainStudy.SEA_LEVEL,
        "water_depth": maxf(TerrainStudy.SEA_LEVEL - bed, 0.0),
        "submerged": bed < TerrainStudy.SEA_LEVEL,
    }
