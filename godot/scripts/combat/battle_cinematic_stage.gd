extends Node3D
## Isolated native 3D battle camera/staging prototype. Never runs combat.
## Geometry is temporary blocking for renderer validation, not approved art.
const CREW_SIDE := -1.0
const FOE_SIDE := 1.0
var actors: Dictionary = {}
var stage_camera: Camera3D
var stage_light: DirectionalLight3D
var active_actor_id: String = ""
var last_event: Dictionary = {}

func _ready() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#182a45")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#9cb9cd")
    environment.ambient_light_energy = 0.6
    world.environment = environment
    add_child(world)
    stage_light = DirectionalLight3D.new()
    stage_light.rotation_degrees = Vector3(-47, 22, 0)
    stage_light.light_color = Color("#f6d5a7")
    stage_light.light_energy = 1.4
    stage_light.shadow_enabled = true
    add_child(stage_light)
    var floor_mesh := MeshInstance3D.new()
    floor_mesh.name = "TemporaryBattleFloor_NotApprovedArt"
    var plane := PlaneMesh.new()
    plane.size = Vector2(24, 18)
    floor_mesh.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#344d58")
    material.roughness = 0.82
    floor_mesh.material_override = material
    add_child(floor_mesh)
    stage_camera = Camera3D.new()
    stage_camera.name = "BattleCamera"
    stage_camera.position = Vector3(0, 8, 15)
    stage_camera.fov = 45.0
    stage_camera.current = true
    add_child(stage_camera)
    stage_camera.look_at(Vector3(0, 1, 0), Vector3.UP)

func present_snapshot(turn_state: Dictionary, factions: Dictionary) -> bool:
    if not turn_state.has_all(["order", "roster", "cursor"]):
        return false
    if typeof(turn_state["order"]) != TYPE_ARRAY or typeof(turn_state["roster"]) != TYPE_DICTIONARY:
        return false
    var order: Array = turn_state["order"]
    if order.is_empty() or order.size() > 8:
        return false
    var counts := {"crew": 0, "opponent": 0}
    var seen := {}
    for id in order:
        if typeof(id) != TYPE_STRING or id.is_empty() or seen.has(id):
            return false
        if not turn_state["roster"].has(id) or not factions.has(id):
            return false
        if factions[id] not in ["crew", "opponent"]:
            return false
        var unit: Variant = turn_state["roster"][id]
        if typeof(unit) != TYPE_DICTIONARY or not unit.has("hp") or typeof(unit["hp"]) != TYPE_INT:
            return false
        seen[id] = true
        counts[factions[id]] += 1
    if counts["crew"] < 1 or counts["crew"] > 3 or counts["opponent"] < 1:
        return false
    if typeof(turn_state["cursor"]) != TYPE_INT:
        return false
    var cursor: int = turn_state["cursor"]
    if cursor < 0 or cursor >= order.size():
        return false
    for child in actors.values():
        child.queue_free()
    actors.clear()
    counts = {"crew": 0, "opponent": 0}
    for id in order:
        var side: String = factions[id]
        var offset: int = counts[side]
        counts[side] += 1
        var node := MeshInstance3D.new()
        node.name = "ReviewMarker_" + id
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.42
        capsule.height = 1.7
        node.mesh = capsule
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("#c9aa77") if side == "crew" else Color("#75899e")
        mat.roughness = 0.6
        node.material_override = mat
        node.position = Vector3((-3.0 if side == "crew" else 3.0), 0.92, float(offset) * 2.0 - 1.5)
        add_child(node)
        actors[id] = node
    active_actor_id = order[cursor]
    last_event = {}
    return true

func present_event(event: Dictionary) -> bool:
    if not event.has_all(["actor_id", "target_id", "kind", "amount_applied"]):
        return false
    if not actors.has(event["actor_id"]) or not actors.has(event["target_id"]):
        return false
    if typeof(event["amount_applied"]) != TYPE_INT or event["amount_applied"] < 0:
        return false
    if event["kind"] not in ["damage", "heal"]:
        return false
    last_event = event.duplicate(true)
    return true

func review_snapshot() -> Dictionary:
    return {
        "actor_count": actors.size(),
        "active_actor_id": active_actor_id,
        "last_event": last_event.duplicate(true),
        "visual_only": true,
        "authoritative_combat": false,
        "uses_temporary_markers": true,
        "creator_art_approved": false
    }
