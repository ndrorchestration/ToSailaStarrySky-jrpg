extends CharacterBody2D
## REVIEW ONLY: real Godot 2D physics translation through source-bound character atlases.
## This does not establish pixel-foot planting, job, recruitment, final animation or gameplay.
const FootPixelProbe = preload("res://scripts/character_foot_pixel_probe.gd")
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const ROUTE_OFFSETS: Array[Vector2] = [
    Vector2(0.0, 100.0), Vector2(-100.0, 100.0),
    Vector2(-100.0, 0.0), Vector2.ZERO
]
const PIXELS_PER_PHASE := 12.5
const SOURCE_SCALE := 1.0
const LOGICAL_BOOT_OFFSET := 60.0
const ALLOWED: Array[String] = ["Lyra", "Aepex", "Reson"]

@export var character_id: String = "Lyra"
@export var review_speed: float = 90.0

var source_sprites: Dictionary = {}
var source_foot_samples: Dictionary = {}
var foot_pixel_align_enabled: bool = true
var origin: Vector2
var review_enabled: bool = false
var completed: bool = false
var segment: int = 0
var facing: String = "south"
var current_phase: int = 0
var travel_distance: float = 0.0
var moving_ticks: int = 0
var collision_ticks: int = 0

func _ready() -> void:
    if not ALLOWED.has(character_id):
        push_error("THREE_ACTOR_WALK_FAIL: unsupported review character")
        set_physics_process(false)
        return
    origin = global_position
    collision_layer = 2
    collision_mask = 1
    var collision := CollisionShape2D.new()
    collision.name = "FootContactCollision"
    var body := CircleShape2D.new()
    body.radius = 6.0
    collision.shape = body
    add_child(collision)
    for direction in FACINGS:
        var atlas_path: String = "res://art-review/%s-%s-sixphase-v1-unapproved.svg" % [character_id.to_lower(), direction]
        var atlas: Texture2D = load(atlas_path) as Texture2D
        if atlas == null:
            push_error("THREE_ACTOR_WALK_FAIL: missing native atlas " + atlas_path)
            set_physics_process(false)
            return
        var sprite := Sprite2D.new()
        sprite.name = direction.capitalize() + "NativeReviewUnapproved"
        sprite.texture = atlas
        sprite.hframes = 6
        sprite.position = Vector2(0.0, -LOGICAL_BOOT_OFFSET)
        sprite.scale = Vector2(SOURCE_SCALE, SOURCE_SCALE)
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.visible = direction == "south"
        add_child(sprite)
        source_sprites[direction] = sprite
        source_foot_samples[direction] = FootPixelProbe.inspect_atlas(atlas)
    _apply_pixel_baselines()
    set_physics_process(true)
    queue_redraw()

func start_route_review() -> void:
    if source_sprites.size() != FACINGS.size():
        return
    global_position = origin
    segment = 0
    facing = "south"
    travel_distance = 0.0
    moving_ticks = 0
    collision_ticks = 0
    current_phase = 0
    completed = false
    review_enabled = true
    _apply_pixel_baselines()
    _sync_direction()

func stop_route_review() -> void:
    review_enabled = false
    velocity = Vector2.ZERO
    current_phase = 0
    for direction in FACINGS:
        (source_sprites[direction] as Sprite2D).frame = 0
    _apply_pixel_baselines()
    _sync_direction()

func set_pixel_baseline_enabled(enabled: bool) -> void:
    foot_pixel_align_enabled = enabled
    _apply_pixel_baselines()

func get_source_boot_sample(direction: String, phase: int) -> Dictionary:
    if not source_foot_samples.has(direction) or phase < 0 or phase >= 6:
        return {"valid": false, "reason": "unknown_direction_or_phase"}
    var entries: Array = source_foot_samples[direction]
    return entries[phase]

func _apply_pixel_baselines() -> void:
    for direction in FACINGS:
        var sprite: Sprite2D = source_sprites.get(direction) as Sprite2D
        if sprite == null:
            continue
        var position_y := -LOGICAL_BOOT_OFFSET
        if foot_pixel_align_enabled:
            var measured: Dictionary = get_source_boot_sample(direction, current_phase)
            if measured.get("valid", false):
                position_y = float(measured["baseline_correction_y"])
        sprite.position = Vector2(0.0, position_y)

func _sync_direction() -> void:
    for direction in FACINGS:
        var sprite: Sprite2D = source_sprites.get(direction) as Sprite2D
        if sprite != null:
            sprite.visible = direction == facing
            sprite.flip_h = false

func _physics_process(delta: float) -> void:
    if not review_enabled or completed or segment >= ROUTE_OFFSETS.size():
        velocity = Vector2.ZERO
        return
    var target: Vector2 = origin + ROUTE_OFFSETS[segment]
    var remaining: Vector2 = target - global_position
    if remaining.length() <= 0.01:
        _arrive_at_target(target)
        return
    var direction: Vector2 = remaining.normalized()
    if absf(direction.y) > absf(direction.x):
        facing = "south" if direction.y > 0.0 else "north"
    else:
        facing = "east" if direction.x > 0.0 else "west"
    velocity = direction * minf(review_speed, remaining.length() / maxf(delta, 0.0001))
    var before: Vector2 = global_position
    move_and_slide() # Godot physics collision resolution, not a position animation.
    if get_slide_collision_count() > 0:
        collision_ticks += 1
    var traveled: float = before.distance_to(global_position)
    if traveled > 0.0001:
        moving_ticks += 1
        travel_distance += traveled
        current_phase = int(travel_distance / PIXELS_PER_PHASE) % 6
    for source in source_sprites.values():
        (source as Sprite2D).frame = current_phase
    _apply_pixel_baselines()
    _sync_direction()
    if global_position.distance_to(target) < 0.5:
        _arrive_at_target(target)

func _arrive_at_target(target: Vector2) -> void:
    # Subpixel arrival snapping only; never pass through a colliding boundary.
    global_position = target
    segment += 1
    if segment >= ROUTE_OFFSETS.size():
        completed = true
        stop_route_review()
    else:
        velocity = Vector2.ZERO

func _draw() -> void:
    if origin == Vector2.ZERO:
        return
    # Non-collision visual grounding. A real foot-plant study remains outstanding.
    draw_line(Vector2(-23.0, 2.0), Vector2(23.0, 2.0), Color(0.36, 0.48, 0.54, 0.55), 2.0)
