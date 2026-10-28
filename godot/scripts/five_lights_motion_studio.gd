extends Node2D
## Five distinct four-direction original-source studies, isolated from Chapter I.
const Actor = preload("res://scripts/five_lights_motion_actor.gd")
const Atmosphere = preload("res://shaders/five_lights_motion_studio.gdshader")
const Scenography = preload("res://scripts/five_lights_stage_scenography.gd")
const CAST: Array[String] = ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]
const START_X: Array[float] = [134.0, 307.0, 480.0, 653.0, 826.0]
const START_Y := 441.0
var cast_actors: Dictionary = {}
var selected_index: int = 1
var keyboard_enabled: bool = true
var reduced_motion: bool = false
var ambience: ShaderMaterial
var status: Label
var controls: Label
var note: Label

func _ready() -> void:
    var background := ColorRect.new()
    background.name = "OriginalNightHarborAtmosphere"
    background.size = Vector2(960.0, 640.0)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ambience = ShaderMaterial.new()
    ambience.shader = Atmosphere
    background.material = ambience
    add_child(background)
    var scenery := Scenography.new()
    scenery.name = "OriginalReviewScenographyNonColliding"
    add_child(scenery)
    var cast_root := Node2D.new()
    cast_root.name = "NonCanonicalFiveLightsSourceReview"
    cast_root.y_sort_enabled = true
    add_child(cast_root)
    for i in range(CAST.size()):
        var actor = Actor.new()
        actor.name = CAST[i] + "Candidate"
        actor.character_id = CAST[i]
        actor.position = Vector2(START_X[i], START_Y)
        cast_root.add_child(actor)
        cast_actors[CAST[i]] = actor
    _barrier(Vector2(480, 344), Vector2(898, 18))
    _barrier(Vector2(480, 524), Vector2(898, 18))
    _barrier(Vector2(51, 435), Vector2(18, 176))
    _barrier(Vector2(909, 435), Vector2(18, 176))
    var ui := CanvasLayer.new()
    ui.name = "ReviewInstructions"
    add_child(ui)
    _label(ui, Vector2(38, 24), "TO SAIL THE STARRY SKY     |     FIVE LIGHTS", 24)
    _label(ui, Vector2(42, 61), "IN-ENGINE CHARACTER MOTION  /  Source-original art  /  Night harbor review", 14)
    for i in range(CAST.size()):
        var tag := _label(ui, Vector2(START_X[i] - 60, 485), CAST[i].to_upper(), 16)
        tag.custom_minimum_size = Vector2(120, 26)
        tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status = _label(ui, Vector2(40, 541), "", 19)
    controls = _label(ui, Vector2(40, 578), "WASD / arrows: move     TAB: select     F: facing     R: reset     M: reduced motion", 15)
    note = _label(ui, Vector2(40, 603), "ART & STANCE UNAPPROVED  /  Gameplay, canon and saves unchanged", 13)
    _choose(1)

func _label(parent: Node, at: Vector2, words: String, font_size: int) -> Label:
    var out := Label.new()
    out.position = at
    out.text = words
    out.add_theme_font_size_override("font_size", font_size)
    out.add_theme_color_override("font_color", Color("#f6e5c7"))
    out.add_theme_color_override("font_shadow_color", Color("#11192b"))
    parent.add_child(out)
    return out

func _barrier(point: Vector2, dimensions: Vector2) -> void:
    var solid := StaticBody2D.new()
    solid.collision_layer = 1
    solid.collision_mask = 0
    solid.position = point
    var hit := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = dimensions
    hit.shape = rect
    solid.add_child(hit)
    add_child(solid)

func _choose(index: int) -> void:
    selected_index = posmod(index, CAST.size())
    for i in range(CAST.size()):
        cast_actors[CAST[i]].mark_selected(i == selected_index)
    _update_hud()

func _update_hud() -> void:
    if status == null:
        return
    var actor = cast_actors[CAST[selected_index]]
    status.text = "SELECTED %s  /  %s  /  frame %d of 6" % [
        CAST[selected_index].to_upper(), actor.facing.to_upper(), actor.phase + 1]
    # A clean status row keeps source truth visible without covering actors.

func _physics_process(_delta: float) -> void:
    if not keyboard_enabled or cast_actors.size() != CAST.size():
        return
    var vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        vector.x -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        vector.x += 1.0
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        vector.y -= 1.0
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        vector.y += 1.0
    for i in range(CAST.size()):
        cast_actors[CAST[i]].set_motion(vector.limit_length() if i == selected_index else Vector2.ZERO)
    _update_hud()

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_TAB:
            _choose(selected_index + 1)
        KEY_F:
            var actor = cast_actors[CAST[selected_index]]
            var facings: Array[String] = ["south", "west", "north", "east"]
            actor.set_facing(facings[(facings.find(actor.facing) + 1) % 4])
        KEY_M:
            reduced_motion = not reduced_motion
            ambience.set_shader_parameter("reduced_motion", reduced_motion)
        KEY_R:
            for i in range(CAST.size()):
                cast_actors[CAST[i]].reset_at(Vector2(START_X[i], START_Y))
    _update_hud()
