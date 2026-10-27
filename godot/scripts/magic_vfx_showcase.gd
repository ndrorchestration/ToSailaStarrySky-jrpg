extends Node2D
## Standalone authored VFX look-development gallery; not wired to spell casting.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const MagicVFX = preload("res://scripts/magic_vfx.gd")
var active_index: int = 0
var reduced_motion: bool = true
var effect: Node2D

func _ready() -> void:
    effect = MagicVFX.new()
    effect.position = Vector2(480.0, 310.0)
    add_child(effect)
    effect.play_affinity(Catalog.CHARACTER_ORDER[active_index], reduced_motion)
    queue_redraw()

func choose(index: int) -> bool:
    if index < 0 or index >= Catalog.CHARACTER_ORDER.size():
        return false
    active_index = index
    effect.play_affinity(Catalog.CHARACTER_ORDER[active_index], reduced_motion)
    queue_redraw()
    return true

func toggle_reduced_motion() -> void:
    reduced_motion = not reduced_motion
    effect.set_reduced_motion(reduced_motion)
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_5:
        choose(event.keycode - KEY_1)
    elif event.keycode == KEY_M:
        toggle_reduced_motion()
    elif event.keycode == KEY_SPACE:
        effect.play_affinity(Catalog.CHARACTER_ORDER[active_index], reduced_motion)
    elif event.keycode == KEY_ESCAPE:
        get_tree().quit()

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 960.0, 640.0), Color("#0c1726"))
    # Grounded stage silhouette and calm atmospheric parallax bands.
    draw_rect(Rect2(0.0, 465.0, 960.0, 175.0), Color("#102431"))
    draw_colored_polygon(PackedVector2Array([Vector2(0, 495), Vector2(240, 473), Vector2(480, 504), Vector2(720, 475), Vector2(960, 500), Vector2(960, 640), Vector2(0, 640)]), Color("#19313a"))
    for i in range(6):
        draw_arc(Vector2(480, 448), 160.0 + i * 29.0, 0.07, PI - 0.07, 36, Color(0.26, 0.45, 0.54, 0.12 - i * 0.013), 1.0, true)
    var profile: Dictionary = Catalog.profile(Catalog.CHARACTER_ORDER[active_index])
    var primary := Color(str(profile["color"]))
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(40, 53), "TO SAIL THE STARRY SKY  /  MAGIC VFX STUDY", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#e6e7d9"))
    draw_string(font, Vector2(40, 93), str(profile["character"]).to_upper() + "  -  " + str(profile["affinity"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 29, primary)
    draw_string(font, Vector2(40, 125), str(profile["signature"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ccd7db"))
    draw_string(font, Vector2(40, 574), "1 Ender    2 Lyra    3 Ionia    4 Reson    5 Aepex", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d3d8dc"))
    draw_string(font, Vector2(40, 605), "M Reduce motion: " + ("ON" if reduced_motion else "OFF") + "     SPACE Replay     ESC Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b6cad1"))
    draw_string(font, Vector2(730, 93), "VISUAL STUDY / NOT GAMEPLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b6cad1"))
