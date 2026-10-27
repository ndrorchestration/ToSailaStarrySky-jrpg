extends Node2D
## Socket-based character/equipment review rig for native Chapter I battles.
## Draws a deliberately neutral actor mannequin with real, independent
## weapon, armor, accessory and hand CanvasItem children. No accepted sprites
## are repainted, and the model grants no skills, turns, stats or save data.

const Attachment = preload("res://scripts/battle_equipment_attachment.gd")
const VALID_POSES := ["idle", "strike", "guard", "analyze", "rest"]
const HAND_SOCKETS := {
    "idle": Vector2(16, 14),
    "strike": Vector2(20, -4),
    "guard": Vector2(9, 10),
    "analyze": Vector2(23, 1),
    "rest": Vector2(12, 19),
}
const WEAPON_ROTATIONS := {
    "idle": 0.0,
    "strike": -0.83,
    "guard": 0.46,
    "analyze": -0.30,
    "rest": 0.10,
}

var appearance: Dictionary = {}
var pose_id: String = "idle"
var armor_attachment: Node2D
var accessory_attachment: Node2D
var weapon_attachment: Node2D
var hand_attachment: Node2D

func _ready() -> void:
    armor_attachment = _make_attachment("ArmorAttachment", "armor")
    accessory_attachment = _make_attachment("AccessoryAttachment", "accessory")
    weapon_attachment = _make_attachment("WeaponAttachment", "weapon")
    hand_attachment = _make_attachment("GripHandAttachment", "hand")
    _sync_attachments()

func _make_attachment(node_name: String, layer: String) -> Node2D:
    var part = Attachment.new()
    part.name = node_name
    part.layer_key = layer
    add_child(part)
    return part

func set_appearance(next_appearance: Dictionary) -> void:
    appearance = next_appearance.duplicate(true)
    visible = not appearance.is_empty()
    _sync_attachments()
    queue_redraw()

func set_pose(next_pose: String) -> bool:
    if next_pose not in VALID_POSES:
        return false
    pose_id = next_pose
    _sync_attachments()
    queue_redraw()
    return true

func socket_position() -> Vector2:
    return HAND_SOCKETS[pose_id]

func visual_key() -> String:
    return str(appearance.get("weaponVisual", "")) + "|" + str(appearance.get("armorVisual", "")) + "|" + str(appearance.get("accessoryVisual", ""))

func _sync_attachments() -> void:
    if not is_instance_valid(weapon_attachment):
        return
    armor_attachment.configure("armor", appearance)
    accessory_attachment.configure("accessory", appearance)
    weapon_attachment.configure("weapon", appearance)
    hand_attachment.configure("hand", appearance)
    weapon_attachment.position = socket_position()
    hand_attachment.position = socket_position()
    weapon_attachment.rotation = float(WEAPON_ROTATIONS[pose_id])
    hand_attachment.rotation = 0.0

func _draw() -> void:
    if appearance.is_empty():
        return
    var pale := Color("#eff0da")
    var coat := Color("#687c63")
    var skin := Color("#d0ba9e")
    var actor_id := str(appearance.get("actorId", ""))
    var half_width := 18.0 if actor_id == "reson" else (12.0 if actor_id == "aepex" else 15.0)
    draw_rect(Rect2(-56, -68, 112, 141), Color("#132536"))
    draw_rect(Rect2(-56, -68, 112, 141), Color("#47657a"), false, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-46, -51), "GEAR RIG / REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 99, 10, Color("#add5dc"))

    # Provisional neutral body under the attached gear. Never substitute this
    # for Ender's locked source likeness or assert final cast portrait quality.
    draw_circle(Vector2(-23, -19), 11, skin)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-23 - half_width, -7), Vector2(-23 + half_width, -7),
        Vector2(-23 + half_width - 1, 37), Vector2(-23 - half_width, 37)
    ]), coat)
    draw_line(Vector2(-22, 37), Vector2(-30, 47), Color("#303b3a"), 5.0)
    draw_line(Vector2(-18, 37), Vector2(-8, 47), Color("#303b3a"), 5.0)
    draw_line(Vector2(-11, 0), socket_position(), skin, 7.0)
    draw_line(Vector2(-36, -1), Vector2(-40, 18), skin, 6.0)

    var label := str(appearance.get("weaponName", "NO EQUIPMENT")).to_upper()
    draw_string(ThemeDB.fallback_font, Vector2(-51, 62), label, HORIZONTAL_ALIGNMENT_LEFT, 102, 10, pale)
    draw_string(ThemeDB.fallback_font, Vector2(-49, -34), pose_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 90, 9, Color("#a9ccd0"))
