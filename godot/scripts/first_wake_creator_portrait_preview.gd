extends Control
## Read-only high-fidelity portrait display, never story/party/save authority.
## Source images are creator-provided local review assets, deliberately not copied
## into public GitHub. Missing files leave original First Wake presentation intact.
const SOURCES: Dictionary = {
    "ENDER": "res://art-review/creator-portrait-preview/ender_hifi_review_crop.jpg",
    "IONIA": "res://art-review/creator-portrait-preview/ionia_hifi_review_crop.jpg",
}
const ALLOWED: Array[String] = ["ENDER", "IONIA"]

var portraits_enabled: bool = true
var current_speaker: String = ""
var visual: TextureRect
var speaker_label: Label
var _test_textures: Dictionary = {}

func _ready() -> void:
    name = "CreatorHighFidelityPortraitPreview"
    # 432x432 source is deliberately kept square, never portrait-cropped.
    # The plaque ends at y=527, above the game's dialogue area at y=535.
    position = Vector2(704.0, 269.0)
    size = Vector2(236.0, 258.0)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var outer := ColorRect.new()
    outer.color = Color("#c7a46a")
    outer.size = size
    outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(outer)
    var inner := ColorRect.new()
    inner.position = Vector2(2.0, 2.0)
    inner.size = size - Vector2(4, 4)
    inner.color = Color("#0c1927")
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(inner)
    visual = TextureRect.new()
    visual.name = "CreatorReferenceStillImage"
    visual.position = Vector2(10.0, 9.0)
    visual.size = Vector2(216.0, 216.0)
    visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(visual)
    speaker_label = Label.new()
    var rule := ColorRect.new()
    rule.name = "BrassPortraitRule"
    rule.position = Vector2(10.0, 228.0)
    rule.size = Vector2(216.0, 1.0)
    rule.color = Color("#8e7148")
    rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(rule)
    speaker_label.position = Vector2(15.0, 231.0)
    speaker_label.add_theme_font_size_override("font_size", 17)
    speaker_label.add_theme_color_override("font_color", Color("#f8e7ca"))
    speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(speaker_label)
    visible = false

func set_portraits_enabled(value: bool) -> void:
    portraits_enabled = value
    if not value:
        hide_portrait()

func set_test_texture(speaker: String, tex: Texture2D) -> void:
    # Isolated SceneTree test injection, not a source-art promotion API.
    if ALLOWED.has(speaker) and tex != null:
        _test_textures[speaker] = tex

func display_dialogue_line(line: String, speaker_fallback: String = "") -> bool:
    if not portraits_enabled or visual == null:
        hide_portrait()
        return false
    var speaker: String = line.get_slice(":", 0).strip_edges().to_upper() if ":" in line else ""
    if not ALLOWED.has(speaker):
        speaker = speaker_fallback.strip_edges().to_upper()
    # Mixed or unidentified speaker tags deliberately fail closed.
    if not ALLOWED.has(speaker):
        hide_portrait()
        return false
    var texture: Texture2D = _test_textures.get(speaker) as Texture2D
    if texture == null:
        var source_path: String = String(SOURCES.get(speaker, ""))
        if source_path.is_empty() or not ResourceLoader.exists(source_path):
            hide_portrait()
            return false
        texture = load(source_path) as Texture2D
    if texture == null:
        hide_portrait()
        return false
    visual.texture = texture
    speaker_label.text = speaker
    current_speaker = speaker
    visible = true
    return true

func hide_portrait() -> void:
    current_speaker = ""
    visible = false
    if visual != null:
        visual.texture = null

func snapshot() -> Dictionary:
    return {
        "speaker": current_speaker, "visible": visible,
        "enabled": portraits_enabled,
        "story_mutation": false, "party_mutation": false,
        "save_mutation": false, "field_animation": false,
        "source_aspect_preserved": true, "review_only": true,
        "viewport_rect": Rect2(position, size)
    }
