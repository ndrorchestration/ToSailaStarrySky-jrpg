extends Node2D
## PW-01 prototype-only, neutral engine resonance *visual*; not Ender's Spirit
## spell, Lyra's Water spell, or a reveal of specialized fuel mathematics.
const Envelope = preload("res://scripts/cinematic_vfx_envelope.gd")
const MATERIAL = preload("res://shaders/first_wake_engine_phase_warning.gdshader")
const SIZE = Vector2(248.0, 180.0)
const MAX_STATIC_MARKERS = 8

var active: bool = false
var reduced_motion: bool = true
var detail_level: int = 0
var progress: float = 0.0
var phase: String = "anticipation"
var activation_count: int = 0
var shader_rect: ColorRect
var shader_material: ShaderMaterial

func _ready() -> void:
    name = "EnginePhaseDriftVisualReviewOnly"
    shader_rect = ColorRect.new()
    shader_rect.name = "BoundedEngineHarmonicLens"
    shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shader_rect.position = -SIZE * 0.5
    shader_rect.size = SIZE
    shader_rect.color = Color.WHITE
    shader_material = ShaderMaterial.new()
    shader_material.shader = MATERIAL
    shader_rect.material = shader_material
    add_child(shader_rect)
    visible = false
    set_process(false)
    _sync()

func begin_warning() -> bool:
    if active:
        return false
    active = true
    visible = true
    activation_count += 1
    progress = 0.49 if reduced_motion else 0.0
    phase = Envelope.phase_at(progress)
    set_process(not reduced_motion)
    _sync()
    return true

func stop_warning() -> void:
    active = false
    visible = false
    set_process(false)

func configure(motion_safe: bool, quality: int) -> bool:
    if not Envelope.valid_quality(quality):
        return false
    reduced_motion = motion_safe
    detail_level = quality
    if active:
        progress = 0.49 if reduced_motion else progress
        phase = Envelope.phase_at(progress)
        set_process(not reduced_motion and progress < 1.0)
        _sync()
    return true

func seek(progress_fraction: float) -> bool:
    if is_nan(progress_fraction) or is_inf(progress_fraction):
        return false
    progress = clampf(progress_fraction, 0.0, 1.0)
    phase = Envelope.phase_at(progress)
    set_process(false)
    _sync()
    return true

func _process(delta: float) -> void:
    if not active or reduced_motion:
        return
    progress = minf(1.0, progress + maxf(delta, 0.0) / Envelope.DURATION_SECONDS)
    phase = Envelope.phase_at(progress)
    _sync()
    if progress >= 1.0:
        set_process(false)

func _sync() -> void:
    if shader_material != null:
        shader_material.set_shader_parameter("phase_progress", progress)
        shader_material.set_shader_parameter("opacity_budget", 0.53 if reduced_motion else 0.76)
    queue_redraw()

func _draw() -> void:
    if not active:
        return
    # Smaller marker count in reduced-motion / low-quality settings.
    var count: int = 4 if reduced_motion or detail_level == 0 else (6 if detail_level == 1 else MAX_STATIC_MARKERS)
    var copper: Color = Color("#f3b76a", 0.77 if reduced_motion else 0.61)
    var teal: Color = Color("#a9e5d8", 0.60 if reduced_motion else 0.52)
    var vertical: float = 25.0 + progress * 7.0
    draw_arc(Vector2.ZERO, 54.0, -PI * 0.93, PI * 0.88, 66, copper, 2.6, true)
    draw_arc(Vector2(5, 0), 69.0, 0.29, TAU - 0.25, 72, teal, 1.7, true)
    for i in range(count):
        var angle: float = float(i) * TAU / float(count) + 0.15
        var near_point: Vector2 = Vector2(cos(angle) * 43.0, sin(angle) * vertical)
        var far_point: Vector2 = near_point + Vector2.from_angle(angle) * (11.0 + progress * 7.0)
        draw_line(near_point, far_point, copper if i % 2 == 0 else teal, 2.2, true)
        draw_circle(far_point, 2.4, teal if i % 2 == 0 else copper)
