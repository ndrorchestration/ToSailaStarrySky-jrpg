extends CharacterBody2D
## Early Godot input/grounding proof; NOT approved character art or equipment canon.

@export var character_name: String = "Ender"
@export var player_controlled: bool = false
@export var walk_speed: float = 148.0
## Optional unapproved artwork preview; no production FIELD_PACK admission.
@export var review_source_texture: Texture2D
@export var review_aligned_texture: Texture2D

var walking_bounds: Rect2 = Rect2(Vector2(145, 410), Vector2(670, 112))
var review_sprite: Sprite2D
var aligned_sprite: Sprite2D
var walk_review_sprite: Sprite2D
var travel_distance: float = 0.0
var gait_step: float = 0.0

func _ready() -> void:
    var shape_node := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 10.0
    shape_node.shape = shape
    add_child(shape_node)
    if review_source_texture != null and character_name == "Ionia":
        review_sprite = Sprite2D.new()
        review_sprite.name = "IoniaArtReviewUnapproved"
        review_sprite.texture = review_source_texture
        review_sprite.centered = true
        review_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        # Review-only 512×768 source at approximately 67×100 on the 960×640 dock.
        # Offset places the drawn boots near the existing actor ground anchor.
        review_sprite.scale = Vector2(0.13, 0.13)
        review_sprite.position = Vector2(0, -42)
        review_sprite.visible = false
        add_child(review_sprite)
    if review_aligned_texture != null and character_name == "Ionia":
        aligned_sprite = Sprite2D.new()
        aligned_sprite.name = "IoniaAlignmentReviewUnapproved"
        aligned_sprite.texture = review_aligned_texture
        aligned_sprite.centered = true
        aligned_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        aligned_sprite.scale = Vector2(0.13, 0.13)
        aligned_sprite.position = Vector2(0, -42)
        aligned_sprite.visible = false
        add_child(aligned_sprite)
    if character_name == "Ender":
        walk_review_sprite = Sprite2D.new()
        walk_review_sprite.name = "EnderWalkReviewUnapproved"
        walk_review_sprite.texture = preload("res://art-review/ender-walk-candidate.png")
        walk_review_sprite.hframes = 6
        walk_review_sprite.position = Vector2(0, -46)
        walk_review_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        walk_review_sprite.visible = false
        add_child(walk_review_sprite)
    queue_redraw()

func set_walk_review_enabled(enabled: bool) -> void:
    if walk_review_sprite != null:
        walk_review_sprite.visible = enabled
        queue_redraw()

func set_review_art_enabled(enabled: bool) -> void:
    if review_sprite != null:
        review_sprite.visible = enabled
    if aligned_sprite != null:
        aligned_sprite.visible = false
    queue_redraw()

func set_aligned_review_enabled(enabled: bool) -> void:
    if aligned_sprite != null:
        aligned_sprite.visible = enabled
    if review_sprite != null:
        review_sprite.visible = false
    queue_redraw()

func is_aligned_review_enabled() -> bool:
    return aligned_sprite != null and aligned_sprite.visible

func is_review_art_enabled() -> bool:
    return (review_sprite != null and review_sprite.visible) or (aligned_sprite != null and aligned_sprite.visible)

func _physics_process(_delta: float) -> void:
    if not player_controlled:
        return
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * walk_speed
    var before := global_position
    move_and_slide()
    global_position = global_position.clamp(walking_bounds.position, walking_bounds.end)
    var traveled := global_position.distance_to(before)
    if traveled > 0.001:
        travel_distance += traveled
        gait_step = sin(travel_distance * TAU / 88.8) * 3.0
    else:
        travel_distance = 0.0
        gait_step = 0.0
    if walk_review_sprite != null:
        walk_review_sprite.frame = int(travel_distance / 14.8) % 6
        # Original source is side-facing only. No invented front/back poses.
        if abs(direction.x) > 0.01:
            walk_review_sprite.flip_h = direction.x < 0.0
    queue_redraw()

func _draw() -> void:
    # Intentionally rudimentary silhouettes; DO NOT confuse with field-pack admission.
    var is_ionia := character_name == "Ionia"
    var coat := Color("#203d68") if is_ionia else Color("#47634c")
    var highlight := Color("#d7b56a") if is_ionia else Color("#dccbaa")
    var hair := Color("#e4b65f") if is_ionia else Color("#965936")
    draw_circle(Vector2(0, -3), 14.0, Color(0.05, 0.11, 0.19, 0.45))
    if is_review_art_enabled() or (walk_review_sprite != null and walk_review_sprite.visible):
        # Suppress placeholder body only, retain shared foot-ground cue.
        return
    var step := gait_step if player_controlled else 0.0
    draw_line(Vector2(-5, -19), Vector2(-7-step, -2), Color("#253344"), 6.0)
    draw_line(Vector2(5, -19), Vector2(6+step, -2), Color("#253344"), 6.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-13, -43), Vector2(12, -43), Vector2(15, -15), Vector2(0, -21), Vector2(-17, -15)
    ]), coat)
    draw_line(Vector2(-12, -41), Vector2(6, -21), highlight, 2.0)
    draw_line(Vector2(12, -39), Vector2(-1, -24), highlight, 2.0)
    draw_circle(Vector2(0, -54), 11.0, Color("#efc1a0"))
    draw_arc(Vector2(0, -58), 12.0, 3.1, 6.3, 12, hair, 7.0)
    if is_ionia:
        # Shoulder-length curls; reference identity only, not a finished sprite.
        for i in range(4):
            draw_circle(Vector2(-11 + i * 7, -47), 4.0, hair)
    else:
        draw_line(Vector2(16, -87), Vector2(16, -2), Color("#806341"), 3.0)
        draw_line(Vector2(16, -83), Vector2(16, -66), Color("#cbb37b"), 4.0)
    draw_line(Vector2(-4, -55), Vector2(-2, -55), Color("#4d9f79"), 2.0)
    draw_line(Vector2(3, -55), Vector2(5, -55), Color("#4d9f79"), 2.0)

