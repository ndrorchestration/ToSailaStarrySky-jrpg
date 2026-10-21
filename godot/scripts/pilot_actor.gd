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
var walk_west_sprite: Sprite2D
var walk_front_sprite: Sprite2D
var walk_back_sprite: Sprite2D
var ionia_front_walk_sprite: Sprite2D
var ionia_north_walk_sprite: Sprite2D
var ionia_east_walk_sprite: Sprite2D
var ionia_west_walk_sprite: Sprite2D
var ionia_route_review_enabled: bool = false
var ionia_route_segment: int = 0
var ionia_facing: String = "south"
var walk_review_enabled: bool = false
var ionia_walk_review_enabled: bool = false
var walk_facing: String = "east"
var travel_distance: float = 0.0
var gait_step: float = 0.0
const PIXELS_PER_STEP := 14.8
const IONIA_REVIEW_WALK_SPEED := 55.0
const IONIA_REVIEW_START := Vector2(570, 419)
const IONIA_REVIEW_STOP_Y := 510.0
const IONIA_ROUTE_SPEED := 68.0
const IONIA_ROUTE_POINTS := [Vector2(570, 510), Vector2(470, 510), Vector2(470, 419), Vector2(570, 419)]

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
        # SVG boot soles are near source y=738: -46px aligns them to ground.
        review_sprite.scale = Vector2(0.13, 0.13)
        review_sprite.position = Vector2(0, -46)
        review_sprite.visible = false
        add_child(review_sprite)
    if review_aligned_texture != null and character_name == "Ionia":
        aligned_sprite = Sprite2D.new()
        aligned_sprite.name = "IoniaAlignmentReviewUnapproved"
        aligned_sprite.texture = review_aligned_texture
        aligned_sprite.centered = true
        aligned_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        aligned_sprite.scale = Vector2(0.13, 0.13)
        aligned_sprite.position = Vector2(0, -46)
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
        walk_west_sprite = Sprite2D.new()
        walk_west_sprite.name = "EnderWestWalkReviewUnapproved"
        walk_west_sprite.texture = preload("res://art-review/ender-west-ferruled-sixframe-candidate.svg")
        walk_west_sprite.hframes = 6
        # Independent full-size vector art reads wider/taller than the original
        # 64x96 pixel-source silhouette. Scale the review candidate only.
        # Source boots end near local +44: -37 + 44*0.82 ~= -1 ground anchor.
        walk_west_sprite.scale = Vector2(0.83, 0.82)
        walk_west_sprite.position = Vector2(0, -37)
        walk_west_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        walk_west_sprite.visible = false
        add_child(walk_west_sprite)
        walk_front_sprite = Sprite2D.new()
        walk_front_sprite.name = "EnderFrontWalkReviewUnapproved"
        walk_front_sprite.texture = preload("res://art-review/ender-south-sixframe-candidate.svg")
        walk_front_sprite.hframes = 6
        walk_front_sprite.position = Vector2(0, -46)
        walk_front_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        walk_front_sprite.visible = false
        add_child(walk_front_sprite)
        walk_back_sprite = Sprite2D.new()
        walk_back_sprite.name = "EnderBackWalkReviewUnapproved"
        walk_back_sprite.texture = preload("res://art-review/ender-north-sixframe-candidate.svg")
        walk_back_sprite.hframes = 6
        walk_back_sprite.position = Vector2(0, -46)
        walk_back_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        walk_back_sprite.visible = false
        add_child(walk_back_sprite)
    if character_name == "Ionia":
        ionia_front_walk_sprite = Sprite2D.new()
        ionia_front_walk_sprite.name = "IoniaFrontWalkReviewUnapproved"
        ionia_front_walk_sprite.texture = preload("res://art-review/ionia-front-sixframe-candidate.svg")
        ionia_front_walk_sprite.hframes = 6
        ionia_front_walk_sprite.scale = Vector2(0.13, 0.13)
        ionia_front_walk_sprite.position = Vector2(0, -46)
        ionia_front_walk_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        ionia_front_walk_sprite.visible = false
        add_child(ionia_front_walk_sprite)
        ionia_north_walk_sprite = _new_ionia_walk_view("IoniaRearWalkReviewUnapproved", preload("res://art-review/ionia-north-sixframe-candidate.svg"))
        ionia_east_walk_sprite = _new_ionia_walk_view("IoniaEastWalkReviewUnapproved", preload("res://art-review/ionia-east-sixframe-candidate.svg"))
        ionia_west_walk_sprite = _new_ionia_walk_view("IoniaWestWalkReviewUnapproved", preload("res://art-review/ionia-west-sixframe-candidate.svg"))
    queue_redraw()

func _new_ionia_walk_view(view_name: String, atlas: Texture2D) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.name = view_name
    sprite.texture = atlas
    sprite.hframes = 6
    sprite.scale = Vector2(0.13, 0.13)
    sprite.position = Vector2(0, -46)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    sprite.visible = false
    add_child(sprite)
    return sprite

func _sync_ionia_direction() -> void:
    if ionia_front_walk_sprite == null:
        return
    var visible: bool = ionia_walk_review_enabled or ionia_route_review_enabled
    ionia_front_walk_sprite.visible = visible and ionia_facing == "south"
    ionia_north_walk_sprite.visible = visible and ionia_facing == "north"
    ionia_east_walk_sprite.visible = visible and ionia_facing == "east"
    ionia_west_walk_sprite.visible = visible and ionia_facing == "west"

func set_walk_review_enabled(enabled: bool) -> void:
    walk_review_enabled = enabled
    _sync_ender_direction()
    queue_redraw()

func _sync_ender_direction() -> void:
    if walk_review_sprite == null:
        return
    # East preserves the unmodified original six-frame pixel source from #308.
    # West has its OWN unmirrored source. No staff-side reversal of the east PNG.
    walk_review_sprite.visible = walk_review_enabled and walk_facing == "east"
    walk_west_sprite.visible = walk_review_enabled and walk_facing == "west"
    walk_front_sprite.visible = walk_review_enabled and walk_facing == "south"
    walk_back_sprite.visible = walk_review_enabled and walk_facing == "north"
    walk_review_sprite.flip_h = false
    walk_west_sprite.flip_h = false

func set_ionia_walk_review_enabled(enabled: bool) -> void:
    if ionia_front_walk_sprite == null:
        return
    ionia_route_review_enabled = false
    ionia_walk_review_enabled = enabled
    ionia_facing = "south"
    if enabled:
        # Preserve the original PR #310 front-only diagnostic unchanged.
        global_position = IONIA_REVIEW_START
        travel_distance = 0.0
        ionia_front_walk_sprite.frame = 0
        if review_sprite != null:
            review_sprite.visible = false
        if aligned_sprite != null:
            aligned_sprite.visible = false
    _sync_ionia_direction()
    queue_redraw()

func set_ionia_route_review_enabled(enabled: bool) -> void:
    if ionia_north_walk_sprite == null:
        return
    ionia_walk_review_enabled = false
    ionia_route_review_enabled = enabled
    ionia_route_segment = 0
    ionia_facing = "south"
    travel_distance = 0.0
    if enabled:
        # Noncanonical four-leg route entirely within the existing pilot bounds.
        global_position = IONIA_REVIEW_START
        if review_sprite != null:
            review_sprite.visible = false
        if aligned_sprite != null:
            aligned_sprite.visible = false
    _sync_ionia_direction()
    queue_redraw()

func is_ionia_route_review_enabled() -> bool:
    return ionia_route_review_enabled

func is_ionia_walk_review_enabled() -> bool:
    return ionia_front_walk_sprite != null and (ionia_walk_review_enabled or ionia_route_review_enabled)

func set_review_art_enabled(enabled: bool) -> void:
    if review_sprite != null:
        review_sprite.visible = enabled
    if aligned_sprite != null:
        aligned_sprite.visible = false
    if ionia_front_walk_sprite != null:
        ionia_walk_review_enabled = false
        ionia_route_review_enabled = false
        _sync_ionia_direction()
    queue_redraw()

func set_aligned_review_enabled(enabled: bool) -> void:
    if aligned_sprite != null:
        aligned_sprite.visible = enabled
    if review_sprite != null:
        review_sprite.visible = false
    if ionia_front_walk_sprite != null:
        ionia_walk_review_enabled = false
        ionia_route_review_enabled = false
        _sync_ionia_direction()
    queue_redraw()

func is_aligned_review_enabled() -> bool:
    return aligned_sprite != null and aligned_sprite.visible

func is_review_art_enabled() -> bool:
    return (review_sprite != null and review_sprite.visible) or (aligned_sprite != null and aligned_sprite.visible) or is_ionia_walk_review_enabled()

func _physics_process(_delta: float) -> void:
    if not player_controlled and not (ionia_walk_review_enabled or ionia_route_review_enabled):
        return
    var direction := Vector2.ZERO
    if player_controlled:
        direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        velocity = direction * walk_speed
    elif ionia_route_review_enabled:
        if ionia_route_segment < IONIA_ROUTE_POINTS.size():
            var target: Vector2 = IONIA_ROUTE_POINTS[ionia_route_segment]
            var remaining := target - global_position
            if remaining.length() > 0.001:
                direction = remaining.normalized()
                velocity = direction * minf(IONIA_ROUTE_SPEED, remaining.length() / maxf(_delta, 0.0001))
            else:
                velocity = Vector2.ZERO
        else:
            velocity = Vector2.ZERO
    elif global_position.y < IONIA_REVIEW_STOP_Y:
        # Preserve the old T-only linear traversal.
        direction = Vector2.DOWN
        velocity = direction * IONIA_REVIEW_WALK_SPEED
    else:
        velocity = Vector2.ZERO
    var before := global_position
    move_and_slide()
    global_position = global_position.clamp(walking_bounds.position, walking_bounds.end)
    if not player_controlled and ionia_walk_review_enabled and global_position.y >= IONIA_REVIEW_STOP_Y:
        global_position.y = min(global_position.y, IONIA_REVIEW_STOP_Y)
    if ionia_route_review_enabled and ionia_route_segment < IONIA_ROUTE_POINTS.size():
        if global_position.distance_to(IONIA_ROUTE_POINTS[ionia_route_segment]) < 0.5:
            global_position = IONIA_ROUTE_POINTS[ionia_route_segment]
            ionia_route_segment += 1
    var traveled := global_position.distance_to(before)
    if player_controlled and direction.length_squared() > 0.001:
        if abs(direction.y) > abs(direction.x):
            walk_facing = "south" if direction.y > 0.0 else "north"
        else:
            walk_facing = "east" if direction.x > 0.0 else "west"
    if ionia_route_review_enabled and traveled > 0.001:
        if abs(direction.y) > abs(direction.x):
            ionia_facing = "south" if direction.y > 0.0 else "north"
        else:
            ionia_facing = "east" if direction.x > 0.0 else "west"
    if traveled > 0.001:
        travel_distance += traveled
        gait_step = sin(travel_distance * TAU / 88.8) * 3.0
    else:
        travel_distance = 0.0
        gait_step = 0.0
    var current_frame := int(travel_distance / PIXELS_PER_STEP) % 6
    if walk_review_sprite != null:
        walk_review_sprite.frame = current_frame
        walk_west_sprite.frame = current_frame
        walk_front_sprite.frame = current_frame
        walk_back_sprite.frame = current_frame
        _sync_ender_direction()
    if ionia_front_walk_sprite != null:
        for ionia_frame in [ionia_front_walk_sprite, ionia_north_walk_sprite, ionia_east_walk_sprite, ionia_west_walk_sprite]:
            ionia_frame.frame = current_frame
        _sync_ionia_direction()
    queue_redraw()

func _draw() -> void:
    # Intentionally rudimentary silhouettes; DO NOT confuse with field-pack admission.
    var is_ionia := character_name == "Ionia"
    var coat := Color("#203d68") if is_ionia else Color("#47634c")
    var highlight := Color("#d7b56a") if is_ionia else Color("#dccbaa")
    var hair := Color("#e4b65f") if is_ionia else Color("#965936")
    # Flattened foot-contact ambient shadow, drawn behind the actual sprite.
    var outer_contact := PackedVector2Array()
    var inner_contact := PackedVector2Array()
    for i in range(17):
        var angle := float(i) * TAU / 16.0
        outer_contact.append(Vector2(cos(angle) * 19.0, -2.0 + sin(angle) * 5.0))
        inner_contact.append(Vector2(cos(angle) * 12.0, -1.0 + sin(angle) * 2.7))
    draw_colored_polygon(outer_contact, Color(0.09, 0.13, 0.17, 0.19))
    draw_colored_polygon(inner_contact, Color(0.05, 0.09, 0.13, 0.31))
    if is_review_art_enabled() or walk_review_enabled:
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

