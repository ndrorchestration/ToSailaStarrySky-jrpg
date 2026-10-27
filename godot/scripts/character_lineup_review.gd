extends Control
## REVIEW ONLY: no final field sprites/portraits or newly approved costume designs.
## The first two textures are existing UNAPPROVED Godot candidate atlases.
## Three original front-facing six-phase SVG art STUDIES now replace anonymous blockouts.
## Innate resonance is plot identity, independent of job and learned magic.

const ENDER_ATLAS: Texture2D = preload("res://art-review/ender-south-detailed-staff-v2-candidate.svg")
const IONIA_ATLAS: Texture2D = preload("res://art-review/ionia-front-sixframe-candidate.svg")
const AEPEX_ATLAS: Texture2D = preload("res://art-review/aepex-south-sixphase-v1-unapproved.svg")
const LYRA_ATLAS: Texture2D = preload("res://art-review/lyra-south-sixphase-v1-unapproved.svg")
const RESON_ATLAS: Texture2D = preload("res://art-review/reson-south-sixphase-v1-unapproved.svg")
const DISPLAY_ORDER = ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]
const INNATE_ENERGIES = ["Earth", "Spirit", "Air", "Water", "Fire"]
const COLORS = [
    Color("#baae78"), Color("#c2edcf"), Color("#a6dbe2"),
    Color("#e8a9d7"), Color("#f2ae7c")
]
const CARD_X = [107.0, 293.0, 479.0, 665.0, 851.0]
const GROUND_Y := 422.0

var walk_phase: int = 0
var magnified: bool = true
var _ender_sprite: Sprite2D
var _ionia_sprite: Sprite2D
var _aepex_sprite: Sprite2D
var _lyra_sprite: Sprite2D
var _reson_sprite: Sprite2D

func _ready() -> void:
    name = "FiveProtagonistVisualReviewUnapproved"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _ionia_sprite = _candidate("IoniaCandidateFront", IONIA_ATLAS, CARD_X[0], Vector2(0.13, 0.13))
    _ender_sprite = _candidate("EnderCandidateFront", ENDER_ATLAS, CARD_X[1], Vector2.ONE)
    _aepex_sprite = _candidate("AepexSouthV1Unapproved", AEPEX_ATLAS, CARD_X[2], Vector2.ONE)
    _lyra_sprite = _candidate("LyraSouthV1Unapproved", LYRA_ATLAS, CARD_X[3], Vector2.ONE)
    _reson_sprite = _candidate("ResonSouthV1Unapproved", RESON_ATLAS, CARD_X[4], Vector2.ONE)
    set_walk_phase(0)
    set_magnified(true)

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

func set_magnified(enabled: bool) -> void:
    # Default: comparable review zoom. Toggle down to exact dock-preview sizes.
    magnified = enabled
    if _ionia_sprite != null:
        var scale_value := 0.192 if enabled else 0.13
        _ionia_sprite.scale = Vector2(scale_value, scale_value)
        _ionia_sprite.position.y = GROUND_Y - 46.0 * scale_value / 0.13
    if _ender_sprite != null:
        var scale_value := 1.65 if enabled else 1.0
        _ender_sprite.scale = Vector2(scale_value, scale_value)
        _ender_sprite.position.y = GROUND_Y - 46.0 * scale_value
    for study in [_aepex_sprite, _lyra_sprite, _reson_sprite]:
        if study != null:
            var size := 1.55 if enabled else 1.0
            study.scale = Vector2(size, size)
            # New SVGs are authored with boots near local source y=124 in 128px cells.
            study.position.y = GROUND_Y - 60.0 * size
    queue_redraw()

func set_walk_phase(phase: int) -> void:
    walk_phase = posmod(phase, 6)
    if _ionia_sprite != null:
        _ionia_sprite.frame = walk_phase
    if _ender_sprite != null:
        _ender_sprite.frame = walk_phase
    for study in [_aepex_sprite, _lyra_sprite, _reson_sprite]:
        if study != null:
            study.frame = walk_phase
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#091829"))
    draw_rect(Rect2(0, 0, 960, 132), Color("#11293c"))
    draw_string(ThemeDB.fallback_font, Vector2(34, 50), "FIVE LIGHTS / PROTAGONIST ART REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("#f4e9d5"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 82), "Five original-source studies; three new front-only art candidates. M toggles native size.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c1d0d6"))
    for i in range(DISPLAY_ORDER.size()):
        var x: float = CARD_X[i]
        var color: Color = COLORS[i]
        draw_rect(Rect2(x - 86.0, 146.0, 172.0, 319.0), Color("#172d3b"))
        draw_rect(Rect2(x - 86.0, 146.0, 172.0, 3.0), color)
        draw_line(Vector2(x - 68.0, GROUND_Y), Vector2(x + 68.0, GROUND_Y), Color("#81928c"), 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 183.0), DISPLAY_ORDER[i].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160, 20, Color("#ffefda"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 212.0), INNATE_ENERGIES[i].to_upper() + " / INNATE", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, color)
        var art_state := "EARLIER CANDIDATE" if i < 2 else "NEW FRONT STUDY"
        draw_string(ThemeDB.fallback_font, Vector2(x - 80.0, 449.0), art_state, HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color("#c4ced0"))
    draw_rect(Rect2(0, 484, 960, 156), Color("#102333"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 518), "[ / ]  SCRUB PHASE    M  SCALE    L / ESC  CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f1dec0"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 547), "PHASE %d / 5  •  %s     Unapproved source atlases." % [walk_phase, "REVIEW ZOOM" if magnified else "NATIVE SIZE"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c6d7d9"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 576), "New art is south-facing only; silhouettes and costumes remain creator-review candidates.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c6d7d9"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 604), "Innate plot resonance exists independently of learned magic or selected jobs.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#94aeb7"))

