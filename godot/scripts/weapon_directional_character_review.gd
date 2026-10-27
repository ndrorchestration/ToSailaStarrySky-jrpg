extends Node2D
## Review-only presentation of pre-existing, UNAPPROVED four-direction Ender
## six-frame *walking* sprite candidates. Frame 0 is deliberately held:
## these are not authored combat poses. Staff is BAKED into sprite artwork;
## the geometric weapon child of the practice stage must stay hidden.
const EAST = preload("res://art-review/ender-walk-candidate.png")
const WEST = preload("res://art-review/ender-west-visible-staff-v2-candidate.svg")
const SOUTH = preload("res://art-review/ender-south-detailed-staff-v2-candidate.svg")
const NORTH = preload("res://art-review/ender-north-detailed-staff-v2-candidate.svg")

const FACINGS: Array[String] = ["east","west","south","north"]
const ART_STATUS := "EXISTING_DIRECTIONAL_CANDIDATE_UNAPPROVED"
const BASE_POSITIONS := {
    "east": Vector2(-45.0,64.0),
    "west": Vector2(-45.0,80.0),
    "south": Vector2(-45.0,64.0),
    "north": Vector2(-45.0,64.0)
}
var facing: String = "east"
var current_pose: Dictionary = {}
var display_sprite: Sprite2D

func _ready() -> void:
    display_sprite = Sprite2D.new()
    display_sprite.name = "UnapprovedDirectionalEnder"
    display_sprite.hframes = 6
    display_sprite.frame = 0
    display_sprite.centered = true
    display_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(display_sprite)
    _apply()

func set_facing(value: String) -> bool:
    if value not in FACINGS:
        return false
    facing = value
    _apply()
    return true

func apply_battle_pose(value: Dictionary) -> bool:
    if str(value.get("actorId","")) != "ender" \
        or str(value.get("weaponId","")) != "full_length_staff" \
        or str(value.get("formulaActionId","")) != "staffStrike" \
        or str(value.get("mode","")) != "AUTHORIZED_ACTION_VISUAL_ONLY" \
        or bool(value.get("combatCommandIssued",true)) \
        or bool(value.get("canExecute",true)):
        return false
    current_pose = value.duplicate(true)
    _apply()
    return true

func _apply() -> void:
    if display_sprite == null:
        return
    match facing:
        "east": display_sprite.texture = EAST
        "west": display_sprite.texture = WEST
        "south": display_sprite.texture = SOUTH
        "north": display_sprite.texture = NORTH
        _: return
    display_sprite.hframes = 6
    # Walking candidate frame 0 is not misrepresented as an attack animation.
    display_sprite.frame = 0
    display_sprite.flip_h = false
    display_sprite.scale = Vector2(0.83,0.82) if facing == "west" else Vector2.ONE
    var x_offset := 0.0
    var y_offset := 0.0
    if not bool(current_pose.get("motionReduced",false)):
        x_offset = float(current_pose.get("advance",0.0))*0.32
        y_offset = float(current_pose.get("bob",0.0))*0.20
    display_sprite.position = Vector2(BASE_POSITIONS[facing]) + Vector2(x_offset,y_offset)
    display_sprite.rotation_degrees = 0.0
    queue_redraw()

func visual_contract() -> Dictionary:
    if display_sprite == null:
        return {}
    return {
        "actorId":"ender","weaponId":"full_length_staff","facing":facing,
        "spriteFrame":display_sprite.frame,"candidateStatus":ART_STATUS,
        "texturePath":display_sprite.texture.resource_path,
        "staffAlreadyInSprite":true,"geometricWeaponOverlayAuthorized":false,
        "combatActionExecuted":false,
        "motionReduced":bool(current_pose.get("motionReduced",false))
    }

func _draw() -> void:
    # Ground contact remains visible in the absence of placeholder mannequin.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-75,112),Vector2(-16,112),Vector2(-10,116),Vector2(-82,116)
    ]),Color("#0b1d29",0.35))
