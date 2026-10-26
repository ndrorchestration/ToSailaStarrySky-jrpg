extends StaticBody3D
## Noncanonical bounded PhysicsServer fixture for the local landing-study pad.
## Physics queries prove a native shape exists; they do not establish full
## obstacle avoidance, rigidbody dynamics or global terrain collision.
const TerrainStudy = preload("res://terrain.gd")
const LandingStudy = preload("res://landing_study.gd")
const PATCH_STEP: float = 0.5
const CONTACT_LAYER: int = 2
const HEIGHT_TOLERANCE: float = 0.12

var triangle_count: int = 0

func _ready() -> void:
    name = "TemporaryPhysicsGround"
    collision_layer = CONTACT_LAYER
    collision_mask = 0
    var faces := PackedVector3Array()
    var nx: int = roundi((LandingStudy.FIELD_X.y - LandingStudy.FIELD_X.x) / PATCH_STEP)
    var nz: int = roundi((LandingStudy.FIELD_Z.y - LandingStudy.FIELD_Z.x) / PATCH_STEP)
    for ix in range(nx):
        for iz in range(nz):
            var x: float = LandingStudy.FIELD_X.x + float(ix) * PATCH_STEP
            var z: float = LandingStudy.FIELD_Z.x + float(iz) * PATCH_STEP
            var a := Vector3(x, TerrainStudy.sample_height(x, z), z)
            var b := Vector3(x + PATCH_STEP, TerrainStudy.sample_height(x + PATCH_STEP, z), z)
            var c := Vector3(x, TerrainStudy.sample_height(x, z + PATCH_STEP), z + PATCH_STEP)
            var d := Vector3(x + PATCH_STEP,
                TerrainStudy.sample_height(x + PATCH_STEP, z + PATCH_STEP), z + PATCH_STEP)
            # Upward face winding on the x/z plane.
            faces.append_array(PackedVector3Array([a, c, b, b, c, d]))
    triangle_count = faces.size() / 3
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(faces)
    # A concave mesh has orientation-sensitive ray contact; the temporary
    # physics pad is deliberately double-sided for diagnostic safety.
    shape.backface_collision = true
    var collider := CollisionShape3D.new()
    collider.name = "VerifiedTerrainTrimesh"
    collider.shape = shape
    add_child(collider)

func probe(at: Vector3, space: PhysicsDirectSpaceState3D) -> Dictionary:
    # Call ONLY in _physics_process or a controlled native physics test.
    var query := PhysicsRayQueryParameters3D.create(
        Vector3(at.x, at.y + 6.0, at.z), Vector3(at.x, at.y - 32.0, at.z))
    query.collision_mask = CONTACT_LAYER
    query.collide_with_areas = false
    var result: Dictionary = space.intersect_ray(query)
    if result.is_empty() or result.get("collider") != self:
        print("GODOT_CONTACT_RAY_MISS origin=", query.from, " to=", query.to,
            " hit=", result, " layer=", collision_layer,
            " faces=", triangle_count)
        return {"valid": false, "reason": "NO_NATIVE_TERRAIN_CONTACT"}
    var point: Vector3 = result["position"]
    var normal: Vector3 = result["normal"]
    var expected_height: float = TerrainStudy.sample_height(at.x, at.z)
    if absf(point.y - expected_height) > HEIGHT_TOLERANCE:
        return {"valid": false, "reason": "COLLIDER_TERRAIN_HEIGHT_MISMATCH"}
    if normal.y <= 0.0:
        return {"valid": false, "reason": "UNSAFE_SURFACE_NORMAL"}
    return {"valid": true, "position": point, "normal": normal,
        "height_error": absf(point.y - expected_height)}
