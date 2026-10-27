extends Node2D
## Deterministic, reusable five-phase cinematic spell *visual*.
## Presentation only: no hitboxes, targets, MP, timers affecting battle, or unlocks.
signal phase_changed(next_phase: String)

const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const SIGIL_DIR = "res://art-review/magic_vfx/"
const AURA_SHADER = preload("res://shaders/magic_vfx_aura.gdshader")
const Particles = preload("res://scripts/magic_vfx_particles.gd")
const Ground = preload("res://scripts/magic_vfx_ground.gd")
const DEFAULT_STILL_PROGRESS = 0.29
const SHADER_RESOLUTION = Vector2(380.0, 380.0)

var character_id: String = "ender"
var reduced_motion: bool = true
var elapsed: float = 0.0
var phase: String = "formation"
var finished: bool = false
var _sigil: Sprite2D
var _aura: ColorRect
var _aura_material: ShaderMaterial
var _particles: Node2D
var _ground: Node2D
var quality_level: int = 1

func _ready() -> void:
    _aura = ColorRect.new()
    _aura.name = "AtmosphericLens"
    _aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _aura.position = -SHADER_RESOLUTION * 0.5
    _aura.size = SHADER_RESOLUTION
    _aura.color = Color.WHITE
    _aura.show_behind_parent = true
    _aura_material = ShaderMaterial.new()
    _aura_material.shader = AURA_SHADER
    _aura.material = _aura_material
    add_child(_aura)
    _ground = Ground.new()
    _ground.name = "GroundContact"
    _ground.position = Vector2(0.0, 138.0)
    _ground.show_behind_parent = true
    add_child(_ground)
    _sigil = Sprite2D.new()
    _sigil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _sigil.show_behind_parent = true
    add_child(_sigil)
    _particles = Particles.new()
    _particles.name = "CinematicMicroParticles"
    add_child(_particles)
    play_affinity(character_id, reduced_motion)

func play_affinity(next_id: String, use_reduced_motion: bool = true) -> bool:
    if not Catalog.has_character(next_id):
        return false
    character_id = next_id
    reduced_motion = use_reduced_motion
    elapsed = Catalog.DURATION_SECONDS * DEFAULT_STILL_PROGRESS if reduced_motion else 0.0
    finished = reduced_motion
    phase = "formation" if reduced_motion else "anticipation"
    if _sigil != null:
        var path := SIGIL_DIR + str(Catalog.profile(next_id)["glyph"]) + ".svg"
        _sigil.texture = load(path) if ResourceLoader.exists(path) else null
        _sigil.scale = Vector2.ONE * 0.72
        _sigil.rotation = 0.0
        _sigil.modulate = Color(1.0, 1.0, 1.0, 0.57)
    set_process(not reduced_motion)
    _sync_layers()
    phase_changed.emit(phase)
    return true

func set_reduced_motion(enabled: bool) -> void:
    play_affinity(character_id, enabled)

func set_quality(level: int) -> void:
    quality_level = clampi(level, 0, 2)
    _sync_layers()

func seek_visual_phase(progress: float) -> bool:
    # Manual phase stepping is possible even in reduced-motion mode: no autoplay.
    if is_nan(progress) or is_inf(progress):
        return false
    elapsed = clampf(progress, 0.0, 1.0) * Catalog.DURATION_SECONDS
    var next_phase: String = Catalog.phase_at(elapsed / Catalog.DURATION_SECONDS)
    if next_phase != phase:
        phase = next_phase
        phase_changed.emit(phase)
    finished = true
    set_process(false)
    _sync_layers()
    return true

func _sync_layers() -> void:
    var profile: Dictionary = Catalog.profile(character_id)
    if profile.is_empty():
        return
    var p := clampf(elapsed / Catalog.DURATION_SECONDS, 0.0, 1.0)
    if _aura_material != null:
        _aura_material.set_shader_parameter("core_tint", Color(str(profile["color"])))
        _aura_material.set_shader_parameter("accent_tint", Color(str(profile["accent"])))
        _aura_material.set_shader_parameter("motif", Catalog.CHARACTER_ORDER.find(character_id))
        _aura_material.set_shader_parameter("phase_progress", p)
        _aura_material.set_shader_parameter("energy", 0.82 if reduced_motion else clampf(sin(p * PI), 0.0, 1.0))
    if _particles != null:
        _particles.set_visual(character_id, p, reduced_motion, quality_level)
    if _ground != null:
        _ground.set_visual(character_id, p, reduced_motion)
    queue_redraw()

func _process(delta: float) -> void:
    if finished or reduced_motion:
        return
    elapsed = minf(Catalog.DURATION_SECONDS, elapsed + maxf(delta, 0.0))
    var next_phase: String = Catalog.phase_at(elapsed / Catalog.DURATION_SECONDS)
    if next_phase != phase:
        phase = next_phase
        phase_changed.emit(phase)
    if _sigil != null:
        _sigil.rotation = elapsed * 0.23
        _sigil.modulate = Color(1.0, 1.0, 1.0, 0.34 + 0.24 * sin(elapsed * 3.5) * sin(elapsed * 3.5))
    if elapsed >= Catalog.DURATION_SECONDS:
        finished = true
        set_process(false)
    _sync_layers()

func _rgba(source: Color, alpha: float) -> Color:
    return Color(source.r, source.g, source.b, clampf(alpha, 0.0, 1.0))

func _draw() -> void:
    var profile: Dictionary = Catalog.profile(character_id)
    if profile.is_empty():
        return
    var core := Color(str(profile["color"]))
    var accent := Color(str(profile["accent"]))
    # Static representative composition for motion-sensitive players.
    var p := clampf(elapsed / Catalog.DURATION_SECONDS, 0.0, 1.0)
    var envelope := 0.86 if reduced_motion else clampf(sin(PI * p), 0.0, 1.0)
    var breadth := 12.0 if reduced_motion else p * 32.0
    for i in range(5, 0, -1):
        draw_circle(Vector2.ZERO, float(i) * 23.0 + breadth, _rgba(core, 0.009 * envelope))
    draw_arc(Vector2.ZERO, 78.0 + breadth * 0.5, -PI * 0.88, PI * 0.88, 80, _rgba(core, 0.58 * envelope), 2.0, true)
    draw_arc(Vector2.ZERO, 113.0 + breadth, 0.18, TAU - 0.30, 96, _rgba(accent, 0.33 * envelope), 1.4, true)
    match character_id:
        "ender":
            _draw_spirit(core, accent, p, envelope)
        "lyra":
            _draw_water(core, accent, p, envelope)
        "ionia":
            _draw_earth(core, accent, p, envelope)
        "reson":
            _draw_fire(core, accent, p, envelope)
        "aepex":
            _draw_air(core, accent, p, envelope)
    draw_circle(Vector2.ZERO, 9.0, _rgba(accent, 0.65 * envelope))
    draw_circle(Vector2.ZERO, 3.0, _rgba(Color.WHITE, 0.78 * envelope))

func _draw_spirit(core: Color, accent: Color, p: float, energy: float) -> void:
    # The luminous fivefold constellation communicates a narrative connection,
    # not a fifth mastery rank or an unlocked spell.
    for i in range(5):
        var angle := -PI * 0.5 + float(i) * TAU / 5.0
        var direction := Vector2.from_angle(angle)
        var radius := 95.0 + sin(p * TAU + float(i)) * 6.0
        var point := direction * radius
        draw_line(Vector2.ZERO, point, _rgba(core, 0.42 * energy), 1.6, true)
        draw_circle(point, 4.5, _rgba(accent, 0.9 * energy))
        draw_circle(point * 1.20, 1.8, _rgba(core, 0.75 * energy))
    for i in range(3):
        draw_arc(Vector2.ZERO, 32.0 + float(i) * 20.0, p * 0.7 + i * 0.35, p * 0.7 + PI + i * 0.35, 32, _rgba(accent, 0.55 * energy), 2.1, true)

func _draw_water(core: Color, accent: Color, p: float, energy: float) -> void:
    # Curling tide lines plus Lyra's independently identified pink spirit-light.
    for band in range(3):
        var points := PackedVector2Array()
        for step in range(34):
            var t := float(step) / 33.0
            var angle := TAU * (t * 1.45 + float(band) / 3.0) + p * 1.5
            var radius := 18.0 + t * 93.0
            points.append(Vector2.from_angle(angle) * radius * Vector2(1.0, 0.65))
        draw_polyline(points, _rgba(core, (0.85 - band * 0.15) * energy), 3.4, true)
    for i in range(8):
        var a := float(i) * TAU / 8.0 + p * 0.6
        var pos := Vector2(cos(a) * 125.0, sin(a) * 69.0)
        draw_circle(pos, 2.8 if i % 2 == 0 else 4.0, _rgba(accent if i % 2 == 0 else core, 0.82 * energy))

func _draw_earth(core: Color, accent: Color, p: float, energy: float) -> void:
    for i in range(8):
        var angle := TAU * float(i) / 8.0
        var pivot := Vector2.from_angle(angle)
        var normal := Vector2(-pivot.y, pivot.x)
        var r := 67.0 + 6.0 * sin(float(i) * 2.0 + p * TAU)
        var shard := PackedVector2Array([
            pivot * (r - 17.0) + normal * 9.0,
            pivot * (r + 36.0),
            pivot * (r + 12.0) - normal * 10.0,
            pivot * (r - 14.0) - normal * 4.0
        ])
        draw_colored_polygon(shard, _rgba(core if i % 2 == 0 else accent, 0.55 * energy))
        draw_line(shard[0], shard[1], _rgba(Color.WHITE, 0.43 * energy), 1.4, true)
    for i in range(12):
        var a := float(i) * 2.399963
        draw_circle(Vector2.from_angle(a) * (119.0 + float(i % 3) * 5.0), 1.9, _rgba(core, 0.56 * energy))

func _draw_fire(core: Color, accent: Color, p: float, energy: float) -> void:
    for i in range(14):
        var a := TAU * float(i) / 14.0
        var travel := Vector2.from_angle(a)
        var tangent := Vector2(-travel.y, travel.x)
        var base := travel * 52.0
        var flicker := 13.0 * sin(5.0 * p + float(i))
        var flame := PackedVector2Array([
            base - tangent * 11.0,
            base + travel * (53.0 + flicker) + tangent * 6.0,
            base + tangent * 12.0,
            base + travel * 14.0
        ])
        draw_colored_polygon(flame, _rgba(core if i % 2 == 0 else accent, 0.58 * energy))
    for i in range(16):
        var a := float(i) * 2.399963 + p
        var radius := 97.0 + float(i % 5) * 11.0
        draw_circle(Vector2.from_angle(a) * radius, 1.7 + float(i % 3), _rgba(accent, 0.72 * energy))

func _draw_air(core: Color, accent: Color, p: float, energy: float) -> void:
    # Displaced pressure rings and nonuniform streamlines—not icy shards.
    for i in range(4):
        var offset := Vector2(float(i - 2) * 10.0, float(i % 2) * 9.0)
        var r := 47.0 + float(i) * 20.0
        draw_arc(offset, r, -PI * 0.73 + p * 0.6, PI * 0.41 + p * 0.6, 48, _rgba(core, (0.82 - i * 0.14) * energy), 2.8, true)
        draw_arc(offset, r, PI * 0.58 + p * 0.6, PI * 1.12 + p * 0.6, 28, _rgba(accent, 0.53 * energy), 1.6, true)
    for i in range(9):
        var y := float(i - 4) * 19.0
        var x := sin(float(i) + p * TAU) * 12.0
        draw_line(Vector2(-126 + x, y), Vector2(-61 + x, y - 11.0), _rgba(core, 0.41 * energy), 1.8, true)
