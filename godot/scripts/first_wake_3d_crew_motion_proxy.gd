extends Node3D
## Explicit noncanonical walk-cycle mannequin, NOT Ender character asset.
## Art-only child of the original real 1.74m CharacterBody3D capsule collider.
const VISUAL_VERSION := "crew-readable-motion-proxy.v1"
const MAX_SWING_RAD: float = 0.46
const STRIDE_HZ: float = 2.45
var _phase: float = 0.0
var walk_cycles: int = 0
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var head: MeshInstance3D
var torso: MeshInstance3D
var current_speed: float = 0.0

func _paint(tint: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.metallic = metallic
    m.roughness = 0.76
    return m

func _part(label_name: String, shape: Mesh, at: Vector3, tint: Color,
        metallic: float = 0.0) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = label_name
    piece.mesh = shape
    piece.position = at
    piece.material_override = _paint(tint, metallic)
    add_child(piece)
    return piece

func _capsule(radius: float, height: float) -> CapsuleMesh:
    var m := CapsuleMesh.new()
    m.radius = radius
    m.height = height
    return m

func _ready() -> void:
    name = "ReadableCrewWalkArtProxy"
    torso = _part("PrototypeTunicTorso",
        _capsule(0.215, 0.88), Vector3(0, 0.08, 0),
        Color(0.32, 0.48, 0.51))
    head = _part("PrototypeUnidentifiedCrewHead",
        SphereMesh.new(), Vector3(0, 0.65, -0.005),
        Color(0.87, 0.73, 0.56))
    head.scale = Vector3(0.19, 0.22, 0.18)
    left_arm = _part("LeftReviewArm",
        _capsule(0.075, 0.66), Vector3(-0.29, -0.08, 0),
        Color(0.66, 0.48, 0.32))
    right_arm = _part("RightReviewArm",
        _capsule(0.075, 0.66), Vector3(0.29, -0.08, 0),
        Color(0.66, 0.48, 0.32))
    left_leg = _part("LeftReviewLeg",
        _capsule(0.085, 0.74), Vector3(-0.12, -0.52, 0),
        Color(0.26, 0.31, 0.33))
    right_leg = _part("RightReviewLeg",
        _capsule(0.085, 0.74), Vector3(0.12, -0.52, 0),
        Color(0.26, 0.31, 0.33))
    var crest := _part("NeutralChestTrim",
        BoxMesh.new(), Vector3(0, 0.19, -0.20),
        Color(0.82, 0.65, 0.37), 0.15)
    crest.scale = Vector3(0.22, 0.05, 0.022)

func _process(delta: float) -> void:
    var actor := get_parent() as CharacterBody3D
    if actor == null:
        return
    current_speed = Vector2(actor.velocity.x, actor.velocity.z).length()
    var moving: bool = current_speed > 0.22 and actor.is_on_floor()
    if moving:
        _phase += delta * TAU * STRIDE_HZ
        if _phase >= TAU:
            _phase = fmod(_phase, TAU)
            walk_cycles += 1
    var swing: float = sin(_phase) * MAX_SWING_RAD if moving else 0.0
    var settle: float = minf(delta * 11.0, 1.0)
    left_leg.rotation.x = lerpf(left_leg.rotation.x, swing, settle)
    right_leg.rotation.x = lerpf(right_leg.rotation.x, -swing, settle)
    left_arm.rotation.x = lerpf(left_arm.rotation.x, -swing * 0.75, settle)
    right_arm.rotation.x = lerpf(right_arm.rotation.x, swing * 0.75, settle)
    torso.position.y = 0.08 + (absf(sin(_phase)) * 0.025 if moving else 0.0)
