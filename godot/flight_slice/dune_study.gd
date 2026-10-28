extends Node3D
## Detached NONCANON desert art fixture: procedural smooth dune geometry and a
## single material reference to the existing native sand-optics terrain shader.
## This scene does not enter main.tscn, world progression or landing physics.
const SEGMENTS: int = 96
const HALF_EXTENT: float = 34.0
const WIND_AXIS := Vector2(0.93, 0.37)
const SUN_DIRECTION := Vector3(0.65, 0.43, -0.70)
const SandShader = preload("res://shaders/terrain.gdshader")

var dune_mesh: MeshInstance3D
var dune_material: ShaderMaterial

static func sample_height(x: float, z: float) -> float:
    var wind: Vector2 = WIND_AXIS.normalized()
    var across: Vector2 = Vector2(-wind.y, wind.x)
    var point := Vector2(x, z)
    var downwind: float = point.dot(wind)
    var transverse: float = point.dot(across)
    # Broad asymmetrical crescent ridges, smooth enough that material normals,
    # not sand-sized triangles, carry the micro-scale shading.
    var crest_offset: float = 2.1 * sin(transverse * 0.076)
    var near_crest: float = exp(-pow((downwind + 6.0 + crest_offset) / 9.2, 2.0))
    var farther_crest: float = exp(-pow((downwind - 19.0
        - 1.8 * sin(transverse * 0.052)) / 12.0, 2.0))
    var broad_variation: float = 0.84 + 0.16 * cos(transverse * 0.067)
    return 0.50 + 4.60 * near_crest * broad_variation \
        + 1.95 * farther_crest * (0.77 + 0.23 * sin(transverse * 0.082)) \
        + 0.15 * sin(downwind * 0.15 + transverse * 0.085)

static func sample_normal(x: float, z: float) -> Vector3:
    const SAMPLE_STEP: float = 0.12
    var dx: float = (sample_height(x + SAMPLE_STEP, z)
        - sample_height(x - SAMPLE_STEP, z)) / (2.0 * SAMPLE_STEP)
    var dz: float = (sample_height(x, z + SAMPLE_STEP)
        - sample_height(x, z - SAMPLE_STEP)) / (2.0 * SAMPLE_STEP)
    return Vector3(-dx, 1.0, -dz).normalized()

func _ready() -> void:
    dune_material = ShaderMaterial.new()
    dune_material.shader = SandShader
    dune_material.set_shader_parameter("dune_study_override", true)
    dune_material.set_shader_parameter("shoreline_wetness", 0.0)
    dune_material.set_shader_parameter("sand_optics_strength", 1.0)
    dune_material.set_shader_parameter("sand_wind_axis", WIND_AXIS)
    dune_material.set_shader_parameter("sun_direction", SUN_DIRECTION)
    dune_material.set_shader_parameter("low_quality", false)
    dune_material.set_shader_parameter("study_time", 9.0)
    dune_mesh = MeshInstance3D.new()
    dune_mesh.name = "UncollidableDuneMaterialStudy"
    dune_mesh.mesh = _build_mesh()
    dune_mesh.material_override = dune_material
    add_child(dune_mesh)

func set_optics_strength(value: float) -> void:
    dune_material.set_shader_parameter("sand_optics_strength", clampf(value, 0.0, 1.0))

func set_low_quality(enabled: bool) -> void:
    dune_material.set_shader_parameter("low_quality", enabled)

func _build_mesh() -> ArrayMesh:
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var indices := PackedInt32Array()
    var vertex_count: int = (SEGMENTS + 1) * (SEGMENTS + 1)
    vertices.resize(vertex_count)
    normals.resize(vertex_count)
    for iz in range(SEGMENTS + 1):
        for ix in range(SEGMENTS + 1):
            var x: float = lerpf(-HALF_EXTENT, HALF_EXTENT,
                float(ix) / float(SEGMENTS))
            var z: float = lerpf(-HALF_EXTENT, HALF_EXTENT,
                float(iz) / float(SEGMENTS))
            var i: int = iz * (SEGMENTS + 1) + ix
            vertices[i] = Vector3(x, sample_height(x, z), z)
            normals[i] = sample_normal(x, z)
    for iz in range(SEGMENTS):
        for ix in range(SEGMENTS):
            var a: int = iz * (SEGMENTS + 1) + ix
            var b: int = a + 1
            var c: int = a + SEGMENTS + 1
            var d: int = c + 1
            # XZ-space triangles must face upward for the Godot 3D convention.
            indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_INDEX] = indices
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh
