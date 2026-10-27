extends Node2D
## Small overlay placed inside the EXISTING Chapter I battle UI.
## Visual-only: no collision, hitbox, stat, target or turn API.
const Silhouette = preload("res://scripts/weapon_silhouette_review.gd")
const Projection = preload("res://scripts/weapon_battle_visual_projection.gd")

const PANEL := Color("#152e3e")
const BORDER := Color("#7eada9")
const PAPER := Color("#e8dfc5")

var model = Projection.new()
var equipment: Node2D
var current: Dictionary = {}

func _ready() -> void:
    visible = false
    equipment = Silhouette.new()
    equipment.name = "EquippedWeaponVisual"
    equipment.show_backplate = false
    equipment.scale = Vector2(0.43,0.43)
    equipment.position = Vector2(0,5)
    add_child(equipment)
    queue_redraw()

func show_frame(frame: Dictionary) -> bool:
    # Never render arbitrary ability/weapon data as trusted combat animation.
    if str(frame.get("actorId","")) != "ender" \
        or str(frame.get("weaponId","")) != Projection.ENDER_STAFF_ID \
        or str(frame.get("renderAuthority","")) != Projection.RENDER_AUTHORITY \
        or bool(frame.get("canAuthorizeActions",true)):
        return false
    var action := str(frame.get("action",""))
    if action != "idle" and action != "attack":
        return false
    if action == "attack" and str(frame.get("formulaActionId","")) != Projection.STRIKE_ACTION_ID:
        return false
    if action == "idle" and str(frame.get("formulaActionId","")) not in ["","uncoverTruth","hold","rest"]:
        return false
    current = frame.duplicate(true)
    visible = true
    if equipment != null:
        equipment.select_weapon(str(current["weaponId"]))
        equipment.rotation_degrees = float(current.get("weaponAngle",0.0))
        equipment.position = Vector2(
            float(current.get("advance",0.0))*0.35,5.0+float(current.get("bob",0.0))*0.35
        )
    queue_redraw()
    return true

func clear_frame() -> void:
    current = {}
    visible = false
    if equipment != null:
        equipment.rotation_degrees = 0.0
        equipment.position = Vector2(0,5)
    queue_redraw()

func visual_contract() -> Dictionary:
    if not visible or current.is_empty():
        return {}
    return {
        "actorId":str(current["actorId"]), "weaponId":str(current["weaponId"]),
        "action":str(current["action"]), "phase":str(current["phase"]),
        "renderAuthority":str(current["renderAuthority"]),
        "canAuthorizeActions":false,
        "motionReduced":bool(current.get("motionReduced",false))
    }

func _draw() -> void:
    if current.is_empty() or not visible:
        return
    draw_rect(Rect2(-77,-69,154,141),Color("#0a1b28",0.97))
    draw_rect(Rect2(-74,-66,148,135),PANEL)
    draw_rect(Rect2(-74,-66,148,135),BORDER,false,1.5)
    draw_string(ThemeDB.fallback_font,Vector2(-67,-45),
        "EQUIPPED / ENDER",HORIZONTAL_ALIGNMENT_LEFT,138,12,PAPER)
    draw_line(Vector2(-66,-37),Vector2(66,-37),Color(BORDER,0.32),1.0)
    draw_circle(Vector2(0,5),46.0,Color("#213d4d"))
    draw_arc(Vector2(0,5),45.0,0.0,TAU,48,Color(BORDER,0.55),1.0)
    # A read-only phase cue, not a physical collision indicator.
    var text := str(current.get("phase","")).to_upper()
    if str(current.get("action","")) == "attack":
        text = "STRIKE / "+text
    else:
        text = "STAFF / READY"
    draw_string(ThemeDB.fallback_font,Vector2(-66,58),text,
        HORIZONTAL_ALIGNMENT_LEFT,140,11,PAPER)
