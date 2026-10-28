extends Node3D
## REVIEW-ONLY maritime deck architecture: real physical railing stays in parent.
## New curves are original art meshes, intentionally not physics or canon.
const ART_VERSION := "aureate-wake-deck-trim-study.v1"
const SOURCE_COLLISION_STUDY_PR: int = 549
const DECK_SIDE_X: float = 1.11
const TOP_M: float = 1.05
const INFILL_HEIGHTS := [0.18, 0.36, 0.54, 0.72, 0.90]
const POST_Z := [-5.39, -4.53, -3.67, -2.81]
const THIN_WIRE_RADIUS: float = 0.010
var physical_rail_visuals_hidden: int = 0
var visual_strands: int = 0
var accent_members: int = 0
var _brass: StandardMaterial3D
var _wood: StandardMaterial3D
var _patina: StandardMaterial3D
var _ivory: StandardMaterial3D

func _ready() -> void:
    _brass = _surface(Color(0.72, 0.52, 0.24), 0.35, 0.65)
    _wood = _surface(Color(0.35, 0.23, 0.14), 0.68, 0.09)
    _patina = _surface(Color(0.17, 0.45, 0.46), 0.48, 0.22)
    _ivory = _surface(Color(0.79, 0.70, 0.49), 0.61, 0.10)
    _hide_original_bar_renderers()
    _build_deck_sweep()
    _build_hatch_trim()

func _surface(tint: Color, rough: float, metallic: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = rough
    material.metallic = metallic
    return material

func _hide(name: String) -> void:
    var visual := get_parent().get_node_or_null(name) as MeshInstance3D
    if visual != null:
        visual.visible = false
        physical_rail_visuals_hidden += 1

func _hide_original_bar_renderers() -> void:
    # Hide visual BOXES only; never change StaticBody3D collision layers/shapes.
    for side in ["Port", "Starboard"]:
        _hide(side + "SafetyRail")
        for rung in range(5):
            _hide(side + "RailInfill" + str(rung))
        for post in range(4):
            _hide(side + "Post" + str(post))
    _hide("ForedeckNoseRail")
    for rung in range(5):
        _hide("ForedeckNoseInfill" + str(rung))

func _beam(name: String, a: Vector3, b: Vector3,
        radius: float, material: Material) -> void:
    var length: float = a.distance_to(b)
    if length < 0.0001:
        return
    var item := MeshInstance3D.new()
    item.name = name
    var tube := CylinderMesh.new()
    tube.top_radius = radius
    tube.bottom_radius = radius
    tube.height = length
    tube.radial_segments = 8
    item.mesh = tube
    item.material_override = material
    item.position = (a + b) * 0.5
    item.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
    add_child(item)
    visual_strands += 1

func _sweep_x(side: float, t: float) -> float:
    # A perceptual sweep inside 2 cm of original rigid collision envelope.
    # It is NOT a new physical deck curvature.
    return side * (DECK_SIDE_X - 0.015 * sin(t * PI))

func _build_deck_sweep() -> void:
    for side in [-1.0, 1.0]:
        var side_name: String = "Port" if side < 0.0 else "Starboard"
        var material: Material = _patina if side < 0.0 else _brass
        for height_m in INFILL_HEIGHTS:
            for segment in range(12):
                var a: float = float(segment) / 12.0
                var b: float = float(segment + 1) / 12.0
                _beam(side_name + "AureateCable" + str(roundi(height_m * 100.0)) +
                        "S" + str(segment),
                    Vector3(_sweep_x(side, a), height_m, lerpf(-2.81, -5.39, a)),
                    Vector3(_sweep_x(side, b), height_m, lerpf(-2.81, -5.39, b)),
                    THIN_WIRE_RADIUS, material)
        for i in range(12):
            var t0: float = float(i) / 12.0
            var t1: float = float(i + 1) / 12.0
            _beam(side_name + "TimberCap" + str(i),
                Vector3(_sweep_x(side, t0), TOP_M, lerpf(-2.81, -5.39, t0)),
                Vector3(_sweep_x(side, t1), TOP_M, lerpf(-2.81, -5.39, t1)),
                0.043, _wood)
        for post_i in range(POST_Z.size()):
            var z: float = POST_Z[post_i]
            _beam(side_name + "BronzeStanchion" + str(post_i),
                Vector3(side * DECK_SIDE_X, 0.04, z),
                Vector3(side * DECK_SIDE_X, TOP_M, z),
                0.028, _brass)
            accent_members += 1
        for bay in range(POST_Z.size() - 1):
            # Sailmaker diagonal tension members; decorative, not rigging physics.
            _beam(side_name + "TensionBrace" + str(bay),
                Vector3(side * DECK_SIDE_X, 0.08, POST_Z[bay]),
                Vector3(side * DECK_SIDE_X, 0.82, POST_Z[bay + 1]),
                0.012, _ivory)
            accent_members += 1
    # Bow ornaments are attached over unchanged physical 5-level nose barrier.
    for height_m in INFILL_HEIGHTS:
        for segment in range(12):
            var a: float = float(segment) / 12.0
            var b: float = float(segment + 1) / 12.0
            _beam("BowAureateCable" + str(roundi(height_m * 100.0)) +
                    "S" + str(segment),
                Vector3(lerpf(-1.10, 1.10, a), height_m, -5.53),
                Vector3(lerpf(-1.10, 1.10, b), height_m, -5.53),
                THIN_WIRE_RADIUS, _brass)
    for segment in range(12):
        var a: float = float(segment) / 12.0
        var b: float = float(segment + 1) / 12.0
        _beam("BowTimberCap" + str(segment),
            Vector3(lerpf(-1.12, 1.12, a), TOP_M, -5.53),
            Vector3(lerpf(-1.12, 1.12, b), TOP_M, -5.53),
            0.044, _wood)
    _beam("BowOrnamentalKeel", Vector3(0, 0.03, -5.51),
        Vector3(0, 0.99, -5.51), 0.035, _patina)
    accent_members += 1

func _build_hatch_trim() -> void:
    for side in [-1.0, 1.0]:
        var label_name: String = "Port" if side < 0.0 else "Starboard"
        # Trim mounts outside existing 1.24m hatch capsule clearance.
        _beam(label_name + "HatchBrassReveal",
            Vector3(side * 0.85, 0.10, -2.605),
            Vector3(side * 0.85, 2.32, -2.605),
            0.026, _brass)
        accent_members += 1
    _beam("HatchCrownTrim", Vector3(-0.85, 2.32, -2.605),
        Vector3(0.85, 2.32, -2.605), 0.030, _brass)
    accent_members += 1
