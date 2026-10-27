extends Node2D
## Opt-in, standalone Resonance playability study. Placeholder silhouettes only.
## No Chapter I transitions, save writes, main combat permissions or final art.
const Battle = preload("res://scripts/tidebound_promise_review.gd")
const ENDER_POS := Vector2(254.0, 318.0)
const LYRA_POS := Vector2(708.0, 318.0)
const WARD_CENTER := Vector2(481.0, 305.0)

var battle = Battle.new()
var reduced_motion: bool = true
var elapsed: float = 0.0
var visual_step: int = 3  # 0 Spirit, 1 Water, 2 confluence, 3 stable ward
var last_action_result: Dictionary = {}
var heading: Label
var battle_status: Label
var detail: Label
var notice: Label
var motion_button: Button

func _ready() -> void:
    var ui := CanvasLayer.new()
    ui.name = "ResonanceReviewHUD"
    add_child(ui)
    heading = _label(ui, Vector2(28, 20), Vector2(900, 34), 27)
    heading.text = "TO SAIL THE STARRY SKY  /  RESONANCE LAB"
    battle_status = _label(ui, Vector2(38, 72), Vector2(882, 55), 20)
    detail = _label(ui, Vector2(50, 452), Vector2(862, 58), 19)
    notice = _label(ui, Vector2(50, 562), Vector2(860, 66), 17)
    _button(ui, Vector2(48, 516), Vector2(226, 38), "1  Raise shared ward", _cast)
    _button(ui, Vector2(286, 516), Vector2(196, 38), "2  Enemy strike", _strike)
    _button(ui, Vector2(494, 516), Vector2(184, 38), "B  No-ward test", _baseline)
    _button(ui, Vector2(692, 516), Vector2(107, 38), "R  Reset", _restart)
    motion_button = _button(ui, Vector2(812, 516), Vector2(112, 38), "M  Motion: OFF", _toggle_motion)
    _refresh_hud()
    queue_redraw()

func _label(parent: Node, point: Vector2, dims: Vector2, text_size: int) -> Label:
    var l := Label.new()
    l.position = point
    l.size = dims
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", text_size)
    l.add_theme_color_override("font_color", Color("#f5f4e9"))
    l.add_theme_color_override("font_shadow_color", Color("#0b1429"))
    l.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(l)
    return l

func _button(parent: Node, point: Vector2, dims: Vector2, caption: String, callback: Callable) -> Button:
    var b := Button.new()
    b.position = point
    b.size = dims
    b.text = caption
    b.focus_mode = Control.FOCUS_ALL
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_1:
            _cast()
        KEY_2:
            _strike()
        KEY_B:
            _baseline()
        KEY_R:
            _restart()
        KEY_M:
            _toggle_motion()
        _:
            return
    get_viewport().set_input_as_handled()

func _cast() -> void:
    last_action_result = battle.activate()
    visual_step = 0 if bool(last_action_result.get("ok", false)) and not reduced_motion else 3
    elapsed = 0.0
    _refresh_hud()
    queue_redraw()

func _strike() -> void:
    last_action_result = battle.resolve_enemy_strike("ender", Battle.DEFAULT_STRIKE)
    visual_step = 3
    elapsed = 0.0
    _refresh_hud()
    queue_redraw()

func _baseline() -> void:
    last_action_result = battle.pass_without_art()
    visual_step = 3
    elapsed = 0.0
    _refresh_hud()
    queue_redraw()

func _restart() -> void:
    battle.reset()
    last_action_result = {}
    visual_step = 3
    elapsed = 0.0
    _refresh_hud()
    queue_redraw()

func _toggle_motion() -> void:
    reduced_motion = not reduced_motion
    visual_step = 3 if reduced_motion else visual_step
    elapsed = 0.0
    _refresh_hud()
    queue_redraw()

func _process(delta: float) -> void:
    if reduced_motion or battle.phase != "enemy" or visual_step >= 3:
        return
    elapsed += minf(delta, 0.06)
    var next_step: int = 0
    if elapsed >= 0.9:
        next_step = 3
    elif elapsed >= 0.6:
        next_step = 2
    elif elapsed >= 0.3:
        next_step = 1
    if next_step != visual_step:
        visual_step = next_step
        _refresh_hud()
    queue_redraw()

func _refresh_hud() -> void:
    var snap: Dictionary = battle.snapshot()
    var ender: Dictionary = snap["party"]["ender"]
    var lyra: Dictionary = snap["party"]["lyra"]
    battle_status.text = "ENDER  %d/%d HP  |  Focus %d      LYRA  %d/%d HP  |  Focus %d" % [
        ender["hp"], ender["maxHp"], ender["focus"],
        lyra["hp"], lyra["maxHp"], lyra["focus"],
    ]
    var phase_name := str(snap["phase"]).to_upper()
    if str(snap["phase"]) == "player":
        detail.text = "READY: Spirit steadies Water. One Art consumes both actions and 1 review Focus each."
    elif str(snap["phase"]) == "enemy":
        detail.text = "WARD ACTIVE (%d capacity). Press 2 for an eight-point incoming strike." % int(snap["wardCapacity"]) if int(snap["wardCapacity"]) > 0 else "NO WARD. Press 2 to compare the incoming strike."
        if int(snap["wardCapacity"]) > 0 and not reduced_motion and visual_step < 3:
            detail.text += "   |   " + ["SPIRIT: anchor", "WATER: shape", "CONFLUENCE: stabilize"][mini(visual_step, 2)]
    else:
        var result: Dictionary = snap["lastOutcome"]
        detail.text = "RESULT: %d absorbed  |  Ender took %d  |  Lyra took %d" % [
            int(result.get("absorbed", 0)), int(result.get("targetDamage", 0)), int(result.get("partnerDamage", 0))
        ]
    var last_line := str(snap["log"].back())
    if not last_action_result.is_empty() and not bool(last_action_result.get("ok", false)):
        last_line = "Not available: " + str(last_action_result.get("reason", "unknown"))
    notice.text = phase_name + "  /  " + last_line + "\nStandalone mechanics review. Keys 1, 2, B, R, M; no story progress, saves or spell unlocks."
    if motion_button != null:
        motion_button.text = "M Motion: " + ("OFF" if reduced_motion else "ON")

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#0b1630"))
    draw_rect(Rect2(0, 142, 960, 285), Color("#162c4b"))
    draw_rect(Rect2(0, 410, 960, 90), Color("#10213a"))
    for i in range(8):
        var height: float = 155.0 + float(i) * 22.0
        draw_line(Vector2(0, height), Vector2(960, height), Color(0.50, 0.73, 0.88, 0.06), 1.0)
    draw_line(Vector2(24, 428), Vector2(936, 428), Color("#6689a0"), 2.0)
    draw_rect(Rect2(18, 10, 924, 122), Color(0.025, 0.05, 0.12, 0.83))
    draw_rect(Rect2(18, 444, 924, 189), Color(0.025, 0.05, 0.12, 0.88))

    # Abstract review sigils, not approved likenesses or character sprites.
    _draw_actor(ENDER_POS, Color("#ead9ff"), false)
    _draw_actor(LYRA_POS, Color("#8ad7ed"), true)
    draw_string(ThemeDB.fallback_font, ENDER_POS + Vector2(-42, 128), "ENDER / SPIRIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#eee0ff"))
    draw_string(ThemeDB.fallback_font, LYRA_POS + Vector2(-40, 128), "LYRA / WATER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#acf0f2"))
    var snap: Dictionary = battle.snapshot()
    var result: Dictionary = snap["lastOutcome"]
    var warded: bool = int(snap["wardCapacity"]) > 0 or bool(result.get("wardApplied", false))
    if warded:
        # Readable three-part composition: Spirit anchor, Water ribbon, shared ward.
        var glow: float = 1.0
        if not reduced_motion and elapsed < 1.8:
            glow = 0.88 + 0.12 * sin(elapsed * 3.1)
        if visual_step >= 0:
            draw_line(ENDER_POS + Vector2(38, -32), WARD_CENTER, Color(0.82, 0.70, 1.0, 0.78 * glow), 4.0)
        if visual_step >= 1:
            draw_line(LYRA_POS + Vector2(-38, -32), WARD_CENTER, Color(0.48, 0.88, 0.95, 0.84 * glow), 4.0)
        if visual_step >= 2:
            draw_arc(WARD_CENTER, 86.0, -PI * 0.85, PI * 0.85, 52, Color("#a7e6ef"), 6.0)
            draw_arc(WARD_CENTER, 72.0, PI * 0.15, PI * 1.85, 52, Color("#e5aed7"), 5.0)
            draw_circle(WARD_CENTER, 20.0, Color("#b0dfdc"))
            draw_circle(WARD_CENTER, 9.0, Color("#faf1fe"))
            draw_string(ThemeDB.fallback_font, WARD_CENTER + Vector2(-73, 118), "SHARED WARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f5f1d6"))
    else:
        draw_arc(WARD_CENTER, 60, PI * 0.1, PI * 0.90, 30, Color("#667c9d"), 2)
        draw_string(ThemeDB.fallback_font, WARD_CENTER + Vector2(-63, 98), "WARD INACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfd0e1"))
    if str(snap["phase"]) == "complete":
        draw_string(ThemeDB.fallback_font, Vector2(375, 166), "STRIKE RESOLVED", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#eacb9b"))

func _draw_actor(origin: Vector2, tone: Color, is_lyra: bool) -> void:
    draw_circle(origin + Vector2(0, 83), 44, Color(0.04, 0.08, 0.17, 0.6))
    draw_rect(Rect2(origin.x - 29, origin.y + 14, 58, 74), Color("#314463"))
    draw_circle(origin + Vector2(0, -16), 35, tone)
    draw_arc(origin + Vector2(0, -16), 46, 0, TAU, 40, Color("#f6f1df"), 3.0)
    if is_lyra:
        draw_arc(origin + Vector2(0, -16), 55, PI * 0.16, PI * 1.84, 32, Color("#eaa4ce"), 4.0)
        draw_line(origin + Vector2(-18, -38), origin + Vector2(18, -38), Color("#174e70"), 3)
    else:
        draw_line(origin + Vector2(0, -40), origin + Vector2(0, 8), Color("#6f4a96"), 4)
        draw_line(origin + Vector2(-22, -16), origin + Vector2(22, -16), Color("#6f4a96"), 4)
