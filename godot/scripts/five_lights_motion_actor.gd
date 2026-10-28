extends CharacterBody2D
## Four-direction six-phase source-custody review only; no story or save effects.
const DIRECTIONS: Array[String] = ["south", "west", "north", "east"]
const PHASE_COUNT := 6
@export var character_id: String = "Ender"
var sprites: Dictionary = {}
var facing: String = "south"
var phase: int = 0
var distance_travelled: float = 0.0
var motion: Vector2 = Vector2.ZERO
var ready_to_review: bool = false
var selected: bool = false
var pose_preview_enabled: bool = false

## Scene-only inspection scale, not a resampling or approved source-art rewrite.
const REVIEW_SCALE: Dictionary = {"Ender": 1.62, "Ionia": 0.22, "Lyra": 1.54, "Aepex": 1.54, "Reson": 1.54}

func atlas_paths() -> Dictionary:
    match character_id:
        "Ender":
            return {"south": "res://art-review/ender-south-detailed-staff-v2-candidate.svg",
                "west": "res://art-review/ender-west-visible-staff-v2-candidate.svg",
                "north": "res://art-review/ender-north-detailed-staff-v2-candidate.svg",
                "east": "res://art-review/ender-walk-candidate.png"}
        "Ionia":
            return {"south": "res://art-review/ionia-front-cohesion-v5-candidate.svg",
                "west": "res://art-review/ionia-west-sidebody-v4-candidate.svg",
                "north": "res://art-review/ionia-north-cohesion-v5-candidate.svg",
                "east": "res://art-review/ionia-east-sidebody-v4-candidate.svg"}
        "Lyra", "Aepex", "Reson":
            var paths: Dictionary = {}
            for d in DIRECTIONS:
                paths[d] = "res://art-review/%s-%s-sixphase-v1-unapproved.svg" % [character_id.to_lower(), d]
            return paths
    return {}

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    var col := CollisionShape2D.new()
    col.name = "RealFootCollision"
    var circle := CircleShape2D.new()
    circle.radius = 7.0
    col.shape = circle
    add_child(col)
    var paths: Dictionary = atlas_paths()
    if paths.size() != 4:
        push_error("FIVE_CAST_ATLAS_INVALID: unknown character " + character_id)
        return
    for d in DIRECTIONS:
        var tex: Texture2D = load(String(paths[d])) as Texture2D
        if tex == null or tex.get_width() % PHASE_COUNT != 0:
            push_error("FIVE_CAST_ATLAS_INVALID: " + String(paths[d]))
            return
        var sprite := Sprite2D.new()
        sprite.name = d.capitalize() + "SourceAtlas"
        sprite.texture = tex
        sprite.hframes = PHASE_COUNT
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.flip_h = false
        sprite.visible = d == facing
        var scale_value: float = float(REVIEW_SCALE.get(character_id, 1.0))
        if character_id == "Ender" and d == "west":
            # Retain the distinct source's proven silhouette-size ratio.
            sprite.scale = Vector2(scale_value * 0.83, scale_value * 0.82)
        else:
            sprite.scale = Vector2(scale_value, scale_value)
        # Foot-anchor from native atlas frame height. This is a visual baseline
        # hypothesis, NOT artist-marked toe/heel planting or physics grounding.
        var frame_height: float = float(tex.get_height())
        var nominal_sole_y: float = frame_height * 0.47
        sprite.position = Vector2(0.0, -roundf(nominal_sole_y * sprite.scale.y))
        add_child(sprite)
        sprites[d] = sprite
    ready_to_review = true
    _sync()

func set_motion(vector: Vector2) -> void:
    motion = vector.limit_length(1.0)

func set_facing(direction: String) -> bool:
    if not ready_to_review or not DIRECTIONS.has(direction):
        return false
    facing = direction
    _sync()
    return true

func set_pose_preview(enabled: bool, requested_phase: int = 0) -> bool:
    if not ready_to_review or requested_phase < 0 or requested_phase >= PHASE_COUNT:
        return false
    pose_preview_enabled = enabled
    motion = Vector2.ZERO
    velocity = Vector2.ZERO
    phase = requested_phase if enabled else 0
    _sync()
    return true

func reset_at(point: Vector2) -> void:
    position = point
    motion = Vector2.ZERO
    velocity = Vector2.ZERO
    phase = 0
    distance_travelled = 0.0
    pose_preview_enabled = false
    set_facing("south")

func _physics_process(_delta: float) -> void:
    if not ready_to_review:
        return
    if pose_preview_enabled:
        velocity = Vector2.ZERO
        return
    velocity = motion * 105.0
    var previous: Vector2 = global_position
    move_and_slide()
    var advanced: float = global_position.distance_to(previous)
    if advanced > 0.001:
        distance_travelled += advanced
        phase = int(distance_travelled / 12.5) % PHASE_COUNT
        if absf(motion.x) > absf(motion.y):
            facing = "east" if motion.x > 0.0 else "west"
        else:
            facing = "south" if motion.y > 0.0 else "north"
    else:
        phase = 0
    _sync()

func _sync() -> void:
    for d in DIRECTIONS:
        var sprite: Sprite2D = sprites.get(d) as Sprite2D
        if sprite != null:
            sprite.visible = d == facing
            sprite.frame = phase
            sprite.flip_h = false

func mark_selected(value: bool) -> void:
    selected = value
    queue_redraw()

func _draw() -> void:
    # Fixed world-root review cue: selection is not a hitbox or gameplay buff.
    draw_ellipse_shadow()
    if selected:
        draw_arc(Vector2(0, -2), 29.0, 0.0, TAU, 48, Color(0.94, 0.70, 0.37, 0.94), 1.6, true)

func draw_ellipse_shadow() -> void:
    for i in range(3):
        draw_arc(Vector2(0.0, 1.5), 19.0 + float(i) * 6.0, 0.0, TAU, 36,
            Color(0.02, 0.03, 0.06, 0.25 - float(i) * 0.06), 2.0, true)

