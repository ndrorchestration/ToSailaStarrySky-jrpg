extends Control
## Overlay drawn only by the opt-in pilot scene. It covers THREE existing HUD
## text rows temporarily; the underlying encounter remains authoritative.
## It never captures input and never writes to scene/encounter/save data.
const SOURCE := "FIRST_WAKE_POST_RESOLUTION_HUD_PROJECTION_REVIEW"
const PANEL_COLOR := Color(0.025,0.055,0.10,1.0)
const BODY := Color("#d7eaf0")
const WARM := Color("#f0a072")
const GOLD := Color("#fff1ce")
const BLUE := Color("#9dd9ee")

var presenter: Node2D
var last_projection: Dictionary = {}

func _ready() -> void:
    position=Vector2.ZERO
    size=Vector2(960,640)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    visible=false
    set_process(true)

func bind_presenter(ref: Node2D) -> bool:
    if ref == null or presenter != null \
        or not ref.has_method("presentation_projection"):
        return false
    presenter=ref
    return true

func _process(_delta: float) -> void:
    if not is_instance_valid(presenter):
        if visible:
            visible=false
            last_projection={}
        return
    var projected: Dictionary = presenter.presentation_projection()
    if projected != last_projection:
        last_projection=projected.duplicate(true)
        visible=not projected.is_empty()
        queue_redraw()

func _draw() -> void:
    if last_projection.is_empty() or not visible:
        return
    var p: Dictionary = last_projection
    if str(p.get("source","")) != "FIRST_WAKE_POST_RESOLUTION_PRESENTATION_QUEUE_REVIEW":
        return
    # These three masks match the existing review HUD's exact line bounds.
    # They are not changing the HP text in the authoritative world node.
    draw_rect(Rect2(171,211,618,27),PANEL_COLOR)
    draw_rect(Rect2(171,249,618,29),PANEL_COLOR)
    draw_rect(Rect2(171,427,620,30),PANEL_COLOR)
    var line_player: String = "ENDER  VIT %d/%d   STAFF %d/%d   HEAT %d/%d" % [
        int(p["playerVit"]),int(p["playerMaxVit"]),
        int(p["staffCharges"]),int(p["maxStaffCharges"]),
        int(p["heat"]),int(p["maxHeat"])
    ]
    var line_target: String = "%s  HP %d/%d" % [
        str(p["targetName"]),int(p["targetHp"]),int(p["targetMaxHp"])
    ]
    draw_string(ThemeDB.fallback_font,Vector2(176,232),line_player,
        HORIZONTAL_ALIGNMENT_LEFT,610,18,BODY)
    draw_string(ThemeDB.fallback_font,Vector2(176,270),line_target,
        HORIZONTAL_ALIGNMENT_LEFT,610,19,WARM)
    draw_string(ThemeDB.fallback_font,Vector2(176,448),str(p["statusText"]),
        HORIZONTAL_ALIGNMENT_LEFT,610,15,BODY)
    if bool(p["damageNumberVisible"]):
        var delta_text: String = "-%d" % maxi(0,int(p["formulaDamage"]))
        draw_string(ThemeDB.fallback_font,Vector2(681,270),delta_text,
            HORIZONTAL_ALIGNMENT_LEFT,-1,22,GOLD)
        draw_string(ThemeDB.fallback_font,Vector2(497,214),
            "DISPLAYED AT CONTACT",HORIZONTAL_ALIGNMENT_LEFT,-1,11,BLUE)
    else:
        draw_string(ThemeDB.fallback_font,Vector2(505,214),
            "ANTICIPATION • VISUAL ONLY",HORIZONTAL_ALIGNMENT_LEFT,-1,11,BLUE)

func visual_contract() -> Dictionary:
    return {
        "source":SOURCE,"active":visible,
        "phase":str(last_projection.get("phase","inactive")),
        "targetHpDisplayed":int(last_projection.get("targetHp",-1)),
        "staffChargesDisplayed":int(last_projection.get("staffCharges",-1)),
        "damageNumberVisible":bool(last_projection.get("damageNumberVisible",false)),
        "noninteractive":mouse_filter==Control.MOUSE_FILTER_IGNORE,
        "actualResultAlreadyCommitted":bool(last_projection.get("actualResultAlreadyCommitted",false)),
        "combatCommandIssued":false,"saveWritten":false
    }
