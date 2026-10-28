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
var frame_border: ColorRect
var frame_rule: ColorRect
var frame_accent: ColorRect
const SKY_ANCHOR := Vector2(704.0, 122.0)
const CARD_SIZE := Vector2(236.0, 258.0)
const IONIA_ACCENT := Color("#d7aa70")
const ENDER_ACCENT := Color("#68b7b5")
var _test_textures: Dictionary = {}

func _ready() -> void:
    name = "CreatorHighFidelityPortraitPreview"
    # 432x432 source is deliberately kept square, never portrait-cropped.
    # Place the portrait entirely above the physical dock walking band (y>=405).
    # This avoids covering either field actor or the y=535 dialogue ribbon.
    position = SKY_ANCHOR
    size = CARD_SIZE
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shadow := ColorRect.new()
    shadow.name = "SoftPlanimetricShadow"
    shadow.position = Vector2(-7.0, 6.0)
    shadow.size = size + Vector2(7.0, 3.0)
    shadow.color = Color(0.012, 0.025, 0.043, 0.55)
    shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shadow)
    frame_border = ColorRect.new()
    frame_border.name = "BrassFrame"
    frame_border.color = IONIA_ACCENT
    frame_border.size = size
    frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(frame_border)
    var inner := ColorRect.new()
    inner.position = Vector2(2.0, 2.0)
    inner.size = size - Vector2(4, 4)
    inner.color = Color("#0c1927")
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(inner)
    frame_accent = ColorRect.new()
    frame_accent.name = "SpeakerAccentTop"
    frame_accent.position = Vector2(10.0, 5.0)
    frame_accent.size = Vector2(216.0, 2.0)
    frame_accent.color = IONIA_ACCENT
    frame_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(frame_accent)
    visual = TextureRect.new()
    visual.name = "CreatorReferenceStillImage"
    visual.position = Vector2(10.0, 9.0)
    visual.size = Vector2(216.0, 216.0)
    visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(visual)
    speaker_label = Label.new()
    frame_rule = ColorRect.new()
    frame_rule.name = "BrassPortraitRule"
    frame_rule.position = Vector2(10.0, 228.0)
    frame_rule.size = Vector2(216.0, 1.0)
    frame_rule.color = IONIA_ACCENT
    frame_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(frame_rule)
    speaker_label.position = Vector2(15.0, 231.0)
    speaker_label.add_theme_font_size_override("font_size", 16)
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
    var accent: Color = IONIA_ACCENT if speaker == "IONIA" else ENDER_ACCENT
    frame_border.color = accent
    frame_rule.color = accent
    frame_accent.color = accent
    speaker_label.text = "IONIA  /  CAPTAIN" if speaker == "IONIA" else "ENDER  /  RIFT SCHOLAR"
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
        "viewport_rect": Rect2(position, size),
        "world_actor_occlusion": false
    }
