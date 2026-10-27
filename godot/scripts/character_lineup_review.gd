extends Control
## REVIEW ONLY: no final field sprites/portraits or newly approved costume designs.
## The first two textures are existing UNAPPROVED Godot candidate atlases.
## The other three figures are deliberately faceless proportion blockouts.
## Innate resonance is plot identity, independent of job and learned magic.

const ENDER_ATLAS: Texture2D = preload("res://art-review/ender-south-detailed-staff-v2-candidate.svg")
const IONIA_ATLAS: Texture2D = preload("res://art-review/ionia-front-sixframe-candidate.svg")
const DISPLAY_ORDER = ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]
const INNATE_ENERGIES = ["Earth", "Spirit", "Air", "Water", "Fire"]
const COLORS = [
    Color("#baae78"), Color("#c2edcf"), Color("#a6dbe2"),
    Color("#e8a9d7"), Color("#f2ae7c")
]
const CARD_X = [107.0, 293.0, 479.0, 665.0, 851.0]
const GROUND_Y := 422.0

var walk_phase: int = 0
var _ender_sprite: Sprite2D
var _ionia_sprite: Sprite2D

func _ready() -> void:
    name = "FiveProtagonistVisualReviewUnapproved"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _ionia_sprite = _candidate("IoniaCandidateFront", IONIA_ATLAS, CARD_X[0], Vector2(0.13, 0.13))
    _ender_sprite = _candidate("EnderCandidateFront", ENDER_ATLAS, CARD_X[1], Vector2.ONE)
    set_walk_phase(0)

func _candidate(source_name: String, source: Texture2D, x: float, size: Vector2) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.name = source_name
    sprite.texture = source
    sprite.hframes = 6
    sprite.scale = size
    sprite.position = Vector2(x, GROUND_Y - 46.0)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.centered = true
    sprite.z_index = 1
    add_child(sprite)
    return sprite

func get_character_id_order() -> Array:
    return DISPLAY_ORDER.duplicate()

func get_innate_energy_names() -> Array:
    return INNATE_ENERGIES.duplicate()

func set_walk_phase(phase: int) -> void:
    walk_phase = posmod(phase, 6)
    if _ionia_sprite != null:
        _ionia_sprite.frame = walk_phase
    if _ender_sprite != null:
        _ender_sprite.frame = walk_phase
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#091829"))
    draw_rect(Rect2(0, 0, 960, 132), Color("#11293c"))
    draw_string(ThemeDB.fallback_font, Vector2(34, 50), "FIVE LIGHTS / PROTAGONIST ART REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("#f4e9d5"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 82), "Two existing Godot sprite candidates + three silhouette blockouts. No art acceptance.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c1d0d6"))
    for i in range(DISPLAY_ORDER.size()):
        var x: float = CARD_X[i]
        var color: Color = COLORS[i]
        draw_rect(Rect2(x - 86.0, 146.0, 172.0, 319.0), Color("#172d3b"))
        draw_rect(Rect2(x - 86.0, 146.0, 172.0, 3.0), color)
        draw_line(Vector2(x - 68.0, GROUND_Y), Vector2(x + 68.0, GROUND_Y), Color("#81928c"), 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 183.0), DISPLAY_ORDER[i].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160, 20, Color("#ffefda"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 212.0), INNATE_ENERGIES[i].to_upper() + " / INNATE", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, color)
        var art_state := "CANDIDATE SPRITE" if i < 2 else "BLOCKOUT ONLY"
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 449.0), art_state, HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color("#c4ced0"))
        if i >= 2:
            _draw_noncanon_blockout(i, x, color)
    draw_rect(Rect2(0, 484, 960, 156), Color("#102333"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 518), "[ / ]  SCRUB CONTACT PHASE    L or ESC  CLOSE REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f1dec0"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 547), "PHASE %d / 5     Existing sprite studies are not accepted production atlases." % walk_phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c6d7d9"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 576), "Relative silhouettes are illustrative, not a centimeter height chart. Magic use remains job-optional.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c6d7d9"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 604), "Source: creator character/art authority; visual design and animation remain review-gated.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#94aeb7"))

func _draw_noncanon_blockout(index: int, x: float, tint: Color) -> void:
    # No invented uniform, insignia, weapons, powers or default jobs.
    var height := 111.0
    var shoulder := 22.0
    if index == 2: # Aepex: second-tallest and lean.
        height = 122.0
        shoulder = 18.0
    elif index == 3: # Lyra: adult; unapproved final costume.
        height = 100.0
        shoulder = 19.0
    elif index == 4: # Reson: tallest and broadest.
        height = 137.0
        shoulder = 30.0
    var head_y := GROUND_Y - height + 12.0
    draw_circle(Vector2(x, head_y), 10.0, Color("#425463"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(x - shoulder, head_y + 13.0), Vector2(x + shoulder, head_y + 13.0),
        Vector2(x + shoulder * 0.72, GROUND_Y - 44.0), Vector2(x - shoulder * 0.72, GROUND_Y - 44.0)
    ]), Color("#425463"))
    draw_line(Vector2(x - 9.0, GROUND_Y - 44.0), Vector2(x - 13.0, GROUND_Y - 2.0), Color("#425463"), 8.0)
    draw_line(Vector2(x + 9.0, GROUND_Y - 44.0), Vector2(x + 13.0, GROUND_Y - 2.0), Color("#425463"), 8.0)
    draw_arc(Vector2(x, GROUND_Y - 72.0), 43.0, -PI * 0.81, -PI * 0.19, 20, Color(tint.r, tint.g, tint.b, 0.48), 2.0)
