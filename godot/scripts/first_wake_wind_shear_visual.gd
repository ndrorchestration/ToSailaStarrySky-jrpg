extends Node2D
## Original, provisional 2D combat silhouette for the current-story Wind Shear.
## Presentation only: no collision, randomness, damage, encounter authority, or
## progression writes. All geometry is bounded to the right-hand battle stage.
##
## Visual grammar: broken-pressure halo, wind-cut crystal, asymmetric trailing
## ribbons, and a split harmonic core. EMP exposure reveals the core; the
## existing Gale Force enemy turn causes a brief warm-edged pressure accent.
## This is NOT an admitted production sprite or a new enemy design canon.

const ART_ID := "windShear"
const ART_BOUNDS := Rect2(-91.0, -92.0, 182.0, 184.0)
const ATLAS_PATH := "res://art-review/wind_shear_elemental_v1_atlas.png"
const IDLE_ATLAS_PATH := "res://art-review/wind_shear_elemental_idle_v2_atlas.png"
const FRAME_SIZE := Vector2i(80, 92)
const FRAME_COUNT := 4
const IDLE_FRAME_COUNT := 4
const DISPLAY_SCALE := 2.0
const IDLE_POSE_STEP_SECONDS := 0.24
# The v2 still frame must be byte-identical in pixel content to v1 idle.
# Frames 1-3 have individually authored facets rather than split-image shifts.
const MAX_EFFECT_SECONDS := 0.34
const HIT_FEEDBACK_SECONDS := 0.24

var analyzed: bool = false
var dissipated: bool = false
var reduced_motion: bool = false
var last_enemy_turn: int = 0
var gale_accent_seconds: float = 0.0
# A retaliatory Gale Force *already resolved* in combat may be shown after
# the true post-hit visual accent, not at the same instant.
var queued_gale_seconds: float = 0.0
# Brief *post-resolution* confirmation that the existing formula caused damage.
# Does not delay the turn or invent anticipation/counterplay.
var hit_feedback_seconds: float = 0.0
var visual_clock: float = 0.0
var _frame_accumulator: float = 0.0
var atlas_texture: Texture2D = null
var idle_atlas_texture: Texture2D = null

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    # A deliberate provisional pixel-art import, not final sprite admission.
    # The procedural silhouette remains a fallback if import is unavailable.
    if ResourceLoader.exists(ATLAS_PATH, "Texture2D"):
        var candidate: Resource = load(ATLAS_PATH)
        if candidate is Texture2D:
            var imported: Texture2D = candidate as Texture2D
            if imported.get_size() == Vector2(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y):
                atlas_texture = imported
    # This is an optional visual refinement, not new encounter authority.
    # Missing or invalid art leaves the existing original static atlas intact.
    if ResourceLoader.exists(IDLE_ATLAS_PATH, "Texture2D"):
        var idle_candidate: Resource = load(IDLE_ATLAS_PATH)
        if idle_candidate is Texture2D:
            var idle_import: Texture2D = idle_candidate as Texture2D
            if idle_import.get_size() == Vector2(FRAME_SIZE.x * IDLE_FRAME_COUNT, FRAME_SIZE.y):
                idle_atlas_texture = idle_import
    visible = false

func begin_encounter() -> void:
    analyzed = false
    dissipated = false
    last_enemy_turn = 0
    gale_accent_seconds = 0.0
    queued_gale_seconds = 0.0
    hit_feedback_seconds = 0.0
    visual_clock = 0.0
    _frame_accumulator = 0.0
    queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    if enabled:
        visual_clock = 0.0
        gale_accent_seconds = 0.0
        queued_gale_seconds = 0.0
        hit_feedback_seconds = 0.0
    queue_redraw()

func set_encounter_state(is_analyzed: bool, is_dissipated: bool, enemy_turn: int) -> void:
    analyzed = is_analyzed
    dissipated = is_dissipated
    if enemy_turn > last_enemy_turn and not reduced_motion and not dissipated:
        if hit_feedback_seconds > 0.0:
            queued_gale_seconds = MAX_EFFECT_SECONDS
        else:
            gale_accent_seconds = MAX_EFFECT_SECONDS
    last_enemy_turn = maxi(0, enemy_turn)
    if dissipated:
        gale_accent_seconds = 0.0
        queued_gale_seconds = 0.0
        hit_feedback_seconds = 0.0
    queue_redraw()

func register_resolved_damage(before_hp: int, after_hp: int) -> bool:
    # Only the live Chapter I scene calls this after a *successful* action.
    # Require an actual fall in current enemy HP, never a projected hit.
    if not visible or dissipated or reduced_motion:
        return false
    if before_hp <= 0 or after_hp < 0 or after_hp >= before_hp:
        return false
    # The synchronous combat controller has already applied both the player
    # strike and any Gale Force retaliation. Only their presentation is
    # serialized. Never create a future attack/counterplay window here.
    if gale_accent_seconds > 0.0:
        queued_gale_seconds = MAX_EFFECT_SECONDS
        gale_accent_seconds = 0.0
    hit_feedback_seconds = HIT_FEEDBACK_SECONDS
    queue_redraw()
    return true

func reaction_phase() -> String:
    if reduced_motion or dissipated:
        return "still"
    if hit_feedback_seconds > 0.0:
        return "hit"
    if gale_accent_seconds > 0.0:
        return "gale"
    return "idle"

func _process(delta: float) -> void:
    if not visible or reduced_motion or dissipated:
        return
    var dt := clampf(delta, 0.0, 0.05)
    visual_clock += dt
    var was_showing_hit := hit_feedback_seconds > 0.0
    hit_feedback_seconds = maxf(0.0, hit_feedback_seconds - dt)
    if was_showing_hit and hit_feedback_seconds <= 0.0 and queued_gale_seconds > 0.0:
        # True post-resolution choreography: observe the impact first, then
        # show the retaliation that has already occurred mechanically.
        gale_accent_seconds = queued_gale_seconds
        queued_gale_seconds = 0.0
    else:
        gale_accent_seconds = maxf(0.0, gale_accent_seconds - dt)
    _frame_accumulator += dt
    # The limited redraw cadence keeps the ambient pulse quieter than actions.
    if _frame_accumulator >= 1.0 / 20.0:
        _frame_accumulator = 0.0
        queue_redraw()

func _draw() -> void:
    var sway := 0.0 if reduced_motion else sin(visual_clock * 1.35) * 2.0
    var breath := 0.0 if reduced_motion else sin(visual_clock * 2.2) * 0.09
    var aura_alpha := 0.23 + breath
    if dissipated:
        if atlas_texture != null:
            _draw_pixel_atlas(0.0)
        else:
            _draw_disperse()
        return

    # Narrow elliptical ground-shadow line anchors the air creature in the
    # combat composition without implying a collider or physical feet.
    var shadow := PackedVector2Array()
    for i in range(25):
        var a := TAU * float(i) / 24.0
        shadow.append(Vector2(cos(a) * 57.0, 72.0 + sin(a) * 8.0))
    draw_colored_polygon(shadow, Color(0.06, 0.14, 0.22, 0.52))

    # Pressure streamers are intentionally asymmetrical and pointed, never
    # a featureless circular blob. Their offsets remain inside ART_BOUNDS.
    for i in range(5):
        var y := -46.0 + float(i) * 23.0
        var flutter := 0.0 if reduced_motion else sin(visual_clock * 1.75 + float(i) * 1.4) * 3.0
        draw_colored_polygon(PackedVector2Array([
            Vector2(-78.0, y - 2.0 + flutter),
            Vector2(-33.0, y - 12.0),
            Vector2(19.0, y - 19.0 + sway),
            Vector2(-29.0, y + 4.0),
            Vector2(-86.0, y + 8.0 + flutter),
        ]), Color(0.19, 0.49, 0.66, aura_alpha * (0.86 if i % 2 == 0 else 0.55)))

    # Interrupted concentric shear-wave arcs: the missing sectors explain the
    # foe's instability and distinguish it from a normal elemental sphere.
    var orbit := 0.0 if reduced_motion else sin(visual_clock * 0.7) * 0.09
    draw_arc(Vector2(1.0, -6.0), 69.0, -2.4 + orbit, -0.35 + orbit, 28, Color(0.50, 0.82, 0.91, 0.50), 2.0)
    draw_arc(Vector2(1.0, -6.0), 69.0, 0.30 + orbit, 2.28 + orbit, 28, Color(0.30, 0.69, 0.83, 0.40), 2.0)
    draw_arc(Vector2(2.0, -6.0), 56.0, -0.86 - orbit, 0.68 - orbit, 24, Color(0.86, 0.92, 0.83, 0.28), 2.0)

    # The authored 80x92 pixel atlas is the default provisional silhouette
    # in this draft. Nearest-neighbor source rectangles cannot bleed frames.
    if atlas_texture != null:
        _draw_pixel_atlas(sway)
        return

    # Silhouette: broad rear wind-fin + rising fractured fin + spined nose.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-52.0, -28.0 + sway), Vector2(-21.0, -49.0),
        Vector2(-5.0, -80.0), Vector2(14.0, -39.0),
        Vector2(47.0, -54.0), Vector2(32.0, -13.0),
        Vector2(58.0, 13.0), Vector2(21.0, 35.0),
        Vector2(6.0, 59.0), Vector2(-21.0, 26.0),
        Vector2(-45.0, 31.0), Vector2(-29.0, -2.0)
    ]), Color(0.12, 0.27, 0.43, 0.95))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-42.0, -22.0 + sway), Vector2(-12.0, -49.0),
        Vector2(-5.0, -70.0), Vector2(9.0, -30.0),
        Vector2(40.0, -42.0), Vector2(23.0, -8.0),
        Vector2(45.0, 12.0), Vector2(14.0, 23.0),
        Vector2(4.0, 45.0), Vector2(-16.0, 17.0)
    ]), Color(0.22, 0.57, 0.70, 0.80))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-27.0, -19.0), Vector2(-5.0, -59.0),
        Vector2(3.0, -24.0), Vector2(-9.0, -4.0)
    ]), Color(0.60, 0.84, 0.88, 0.72))
    draw_colored_polygon(PackedVector2Array([
        Vector2(13.0, -22.0), Vector2(39.0, -38.0),
        Vector2(22.0, -4.0), Vector2(3.0, 11.0)
    ]), Color(0.40, 0.71, 0.82, 0.88))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-29.0, 7.0), Vector2(-12.0, 18.0),
        Vector2(5.0, 46.0), Vector2(11.0, 19.0)
    ]), Color(0.14, 0.34, 0.54, 0.92))

    # Paired offset cores are a harmonic pressure fracture, not eyes. Exposing
    # the established EMP weakness brightens the breach without changing stats.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-14.0, -18.0), Vector2(1.0, -29.0),
        Vector2(17.0, -12.0), Vector2(8.0, 10.0),
        Vector2(-7.0, 5.0)
    ]), Color(0.035, 0.12, 0.22, 0.92))
    var exposed := Color(1.0, 0.84, 0.54, 0.94) if analyzed else Color(0.72, 0.90, 0.91, 0.77)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-8.0, -16.0), Vector2(-1.0, -23.0),
        Vector2(1.0, -4.0), Vector2(-5.0, 4.0)
    ]), exposed)
    draw_colored_polygon(PackedVector2Array([
        Vector2(6.0, -19.0), Vector2(12.0, -12.0),
        Vector2(5.0, 2.0), Vector2(3.0, -5.0)
    ]), Color(0.85, 0.97, 0.94, 0.84))
    if analyzed:
        _draw_exposed_core()
    if gale_accent_seconds > 0.0 and not reduced_motion:
        _draw_gale_accent()
    if hit_feedback_seconds > 0.0 and not reduced_motion:
        _draw_hit_confirmation()

func authored_idle_frame() -> int:
    # The combat controller already owns turns and outcomes. This function
    # only selects one of four drawn idle animation images.
    if idle_atlas_texture == null or reduced_motion or analyzed or dissipated:
        return 0
    if gale_accent_seconds > 0.0 or hit_feedback_seconds > 0.0:
        return 0
    return int(floor(visual_clock / IDLE_POSE_STEP_SECONDS)) % IDLE_FRAME_COUNT

func _draw_pixel_atlas(sway: float) -> void:
    if atlas_texture == null:
        return
    var frame_index: int = 0
    if dissipated:
        frame_index = 3
    elif gale_accent_seconds > 0.0 and not reduced_motion:
        frame_index = 2
    elif analyzed:
        frame_index = 1

    # Idle sprites are hand-pixel-authored whole frames, not procedural
    # horizontal raster strips. In reduced motion or any action reaction,
    # render the original authoritative static/gale/analyzed atlas instead.
    var selected_atlas: Texture2D = atlas_texture
    if idle_atlas_texture != null and not analyzed and not dissipated and not reduced_motion:
        if gale_accent_seconds <= 0.0 and hit_feedback_seconds <= 0.0:
            selected_atlas = idle_atlas_texture
            frame_index = authored_idle_frame()

    var recoil: int = 0
    if hit_feedback_seconds > 0.0 and not reduced_motion:
        recoil = roundi(4.0 * clampf(hit_feedback_seconds / HIT_FEEDBACK_SECONDS, 0.0, 1.0))
    var image_size := Vector2(FRAME_SIZE) * DISPLAY_SCALE
    var source := Rect2(
        Vector2(FRAME_SIZE.x * frame_index, 0),
        Vector2(FRAME_SIZE)
    )
    var destination := Rect2(
        Vector2(-image_size.x * 0.5 + recoil, -92.0 + float(roundi(sway))),
        image_size
    )
    draw_texture_rect_region(selected_atlas, destination, source)
    if gale_accent_seconds > 0.0 and not reduced_motion and not dissipated:
        _draw_gale_accent()
    if hit_feedback_seconds > 0.0 and not reduced_motion and not dissipated:
        _draw_hit_confirmation()

func _draw_hit_confirmation() -> void:
    # Pixel-scale spark fragments only; no screen flash, camera motion or
    # speculative damage amount. Kept inside the 182x184 local bounds.
    var remaining := clampf(hit_feedback_seconds / HIT_FEEDBACK_SECONDS, 0.0, 1.0)
    var tint := Color(0.99, 0.80, 0.51, remaining * 0.76)
    draw_rect(Rect2(-44.0, -29.0, 11.0, 3.0), tint)
    draw_rect(Rect2(35.0, -17.0, 12.0, 3.0), tint)
    draw_rect(Rect2(-27.0, 34.0, 3.0, 10.0), tint)
    draw_rect(Rect2(29.0, 33.0, 3.0, 10.0), tint)
    draw_arc(Vector2(1.0, -8.0), 37.0 + (1.0 - remaining) * 11.0,
        -0.92, 0.73, 16, Color(0.97, 0.73, 0.41, remaining * 0.32), 2.0)

func _draw_exposed_core() -> void:
    # Thin angular brackets read as analyzed weak-point UI, not a spell cast.
    var bracket := Color(1.0, 0.75, 0.43, 0.92)
    draw_polyline(PackedVector2Array([
        Vector2(-28.0, -16.0), Vector2(-33.0, -16.0),
        Vector2(-33.0, 5.0), Vector2(-27.0, 5.0)
    ]), bracket, 2.0)
    draw_polyline(PackedVector2Array([
        Vector2(27.0, -16.0), Vector2(33.0, -16.0),
        Vector2(33.0, 5.0), Vector2(27.0, 5.0)
    ]), bracket, 2.0)
    draw_line(Vector2(-1.0, 11.0), Vector2(8.0, 27.0), bracket, 2.0)

func _draw_gale_accent() -> void:
    var strength := clampf(gale_accent_seconds / MAX_EFFECT_SECONDS, 0.0, 1.0)
    var hot := Color(0.99, 0.58, 0.31, strength * 0.68)
    for i in range(3):
        var y := -31.0 + 31.0 * float(i)
        draw_polyline(PackedVector2Array([
            Vector2(-85.0, y + 16.0), Vector2(-51.0, y - 5.0),
            Vector2(31.0, y - 20.0), Vector2(80.0, y - 29.0)
        ]), hot, 2.0)

func _draw_disperse() -> void:
    # Cleared foes have no readable solid core; no victory animation is
    # implied here and the existing confirmation gate still owns progression.
    var fragments := [
        PackedVector2Array([Vector2(-54, -51), Vector2(-38, -67), Vector2(-35, -39)]),
        PackedVector2Array([Vector2(36, -62), Vector2(54, -47), Vector2(28, -40)]),
        PackedVector2Array([Vector2(-56, 36), Vector2(-38, 20), Vector2(-30, 48)]),
        PackedVector2Array([Vector2(31, 37), Vector2(52, 25), Vector2(43, 55)]),
    ]
    for fragment in fragments:
        draw_colored_polygon(fragment, Color(0.37, 0.77, 0.86, 0.40))
    draw_arc(Vector2.ZERO, 46.0, 0.18, 2.35, 20, Color(0.46, 0.79, 0.89, 0.23), 2.0)
