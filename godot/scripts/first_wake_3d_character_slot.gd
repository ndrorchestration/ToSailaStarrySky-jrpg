extends Node3D
## Private-production-art slot: loads a creator-reviewed GLB only when it contains
## real 3D skeletal and authored animation content. Never builds fake humanoids.
##
## Asset target: res://art-review/private-3d/characters/<id>.glb
## Source model must be original/authorized and carry named animations.
@export_enum("ionia", "ender", "aepex", "lyra", "reson") var character_id := "ender"
@export var require_animation := true
@export var model_root := "res://art-review/private-3d/characters/"

var loaded_model: Node3D
var ready_for_art_review := false
var failure_reason := ""
var skeleton_bones := 0
var animation_count := 0

func _ready() -> void:
    try_load_private_art()

func _scan(node: Node) -> void:
    if node is Skeleton3D:
        skeleton_bones += (node as Skeleton3D).get_bone_count()
    if node is AnimationPlayer:
        var player := node as AnimationPlayer
        animation_count += player.get_animation_list().size()
    for child in node.get_children():
        _scan(child)

func try_load_private_art() -> bool:
    ready_for_art_review = false
    failure_reason = ""
    skeleton_bones = 0
    animation_count = 0
    if loaded_model != null:
        loaded_model.queue_free()
        loaded_model = null
    var expected := model_root.path_join(character_id + ".glb")
    if not ResourceLoader.exists(expected):
        failure_reason = "Real creator-approved 3D asset missing: " + expected
        return false
    var resource := load(expected)
    if not resource is PackedScene:
        failure_reason = "GLB import must produce a PackedScene"
        return false
    var instance := (resource as PackedScene).instantiate()
    if not instance is Node3D:
        instance.free()
        failure_reason = "GLB must instantiate a Node3D root"
        return false
    loaded_model = instance
    add_child(loaded_model)
    _scan(loaded_model)
    if skeleton_bones < 8:
        failure_reason = "A valid skeletal character needs at least eight bones"
        loaded_model.visible = false
        return false
    if require_animation and animation_count < 1:
        failure_reason = "No authored AnimationPlayer tracks found"
        loaded_model.visible = false
        return false
    ready_for_art_review = true
    return true

func audit_snapshot() -> Dictionary:
    return {
        "character": character_id,
        "real_model_loaded": ready_for_art_review,
        "bones": skeleton_bones,
        "animations": animation_count,
        "visual_approval": false,
        "release_approval": false,
        "error": failure_reason
    }
