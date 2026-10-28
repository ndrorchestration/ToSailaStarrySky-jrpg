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
        sprite.position = Vector2(0.0, -48.0)
        if character_id == "Ionia":
            sprite.scale = Vector2(0.13, 0.13)
            sprite.position = Vector2(0.0, -46.0)
        elif character_id == "Ender" and d == "west":
            sprite.scale = Vector2(0.83, 0.82)
            sprite.position = Vector2(0.0, -37.0)
        elif character_id in ["Lyra", "Aepex", "Reson"]:
            sprite.scale = Vector2(0.8, 0.8)
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

func reset_at(point: Vector2) -> void:
    position = point
    motion = Vector2.ZERO
    velocity = Vector2.ZERO
    phase = 0
    distance_travelled = 0.0
    set_facing("south")

func _physics_process(_delta: float) -> void:
    if not ready_to_review:
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
    if selected:
        draw_arc(Vector2(0, -3), 18.0, 0.0, TAU, 36, Color(0.95, 0.75, 0.37), 2.0, true)
