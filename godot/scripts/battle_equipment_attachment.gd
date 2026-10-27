extends Node2D
## Removable procedural equipment layer for the native battle review rig.
## One node = one visible slot/hand. Never applies stats, owns inventory,
## changes skill authority or replaces creator-approved character art.

var layer_key: String = "weapon"
var appearance: Dictionary = {}

func configure(next_layer: String, next_appearance: Dictionary) -> void:
    layer_key = next_layer
    set_appearance(next_appearance)

func set_appearance(next_appearance: Dictionary) -> void:
    appearance = next_appearance.duplicate(true)
    match layer_key:
        "armor":
            visible = not str(appearance.get("armorVisual", "")).is_empty()
        "accessory":
            visible = not str(appearance.get("accessoryVisual", "")).is_empty()
        "weapon", "hand":
            visible = not str(appearance.get("weaponVisual", "")).is_empty()
        _:
            visible = false
    queue_redraw()

func _draw() -> void:
    if appearance.is_empty():
        return
    match layer_key:
        "armor":
            _draw_armor()
        "accessory":
            _draw_accessory()
        "weapon":
            _draw_weapon()
        "hand":
            _draw_hand()

func _draw_armor() -> void:
    if str(appearance.get("armorVisual", "")) != "brass-plate":
        return
    var brass := Color("#dfba79")
    draw_colored_polygon(PackedVector2Array([
        Vector2(-35, -3), Vector2(-13, -3), Vector2(-12, 23),
        Vector2(-24, 30), Vector2(-37, 20)
    ]), Color("#a99b82"))
    draw_line(Vector2(-34, 6), Vector2(-13, 6), brass, 2.0)
    draw_line(Vector2(-24, 5), Vector2(-24, 24), Color("#e9dcc3"), 1.0)
    draw_circle(Vector2(-25, 5), 2.5, brass)

func _draw_accessory() -> void:
    if str(appearance.get("accessoryVisual", "")) != "small-charm":
        return
    draw_line(Vector2(-24, -4), Vector2(-24, 11), Color("#d6ac6a"), 1.5)
    draw_circle(Vector2(-24, 13), 4.5, Color("#a6d6cf"))
    draw_circle(Vector2(-25.2, 11.5), 1.4, Color("#f6fff3"))

func _draw_weapon() -> void:
    # Weapon origin is the right-hand grip socket. Every family is authored
    # independently here; changing item data reselects the attached silhouette.
    var family := str(appearance.get("weaponFamily", ""))
    var variant := str(appearance.get("weaponVisual", ""))
    var brass := Color("#d6ac6a")
    var pale := Color("#edf2e8")
    match family:
        "staff":
            # Exactly one continuous full-length shaft; longitudinal grip
            # lives around y=0, between two brass ferrules.
            var shaft := Color("#b0bec9") if variant == "staff-silver-inlay" else Color("#916745")
            draw_line(Vector2(0, -54), Vector2(0, 40), shaft, 5.0)
            draw_line(Vector2(0, -54), Vector2(0, -46), brass, 6.0)
            draw_line(Vector2(0, 32), Vector2(0, 40), brass, 6.0)
            draw_line(Vector2(0, -9), Vector2(0, 10), Color("#45332c"), 7.0)
            for y in [-7.0, -2.0, 3.0, 8.0]:
                draw_line(Vector2(-3.0, y), Vector2(3.0, y + 2.0), Color("#ad8870"), 1.0)
            if variant == "staff-silver-inlay":
                draw_line(Vector2(0, -43), Vector2(0, -13), pale, 2.0)
                draw_circle(Vector2(0, -51), 2.6, pale)
        "sword":
            draw_line(Vector2(0, -9), Vector2(0, -47), Color("#b7cbd1"), 7.0)
            draw_line(Vector2(-1, -44), Vector2(-1, -13), pale, 2.0)
            draw_colored_polygon(PackedVector2Array([
                Vector2(-4, -44), Vector2(4, -44), Vector2(0, -58)
            ]), pale)
            draw_line(Vector2(-14, -9), Vector2(14, -9), brass, 4.0)
            draw_line(Vector2(0, -7), Vector2(0, 15), Color("#76553e"), 5.0)
            draw_circle(Vector2(0, 17), 3.0, brass)
        "mace":
            draw_line(Vector2(0, 12), Vector2(0, -31), Color("#9b7550"), 6.0)
            draw_circle(Vector2(0, -41), 13.0, Color("#aeb9b6"))
            for offset in [-8.0, 0.0, 8.0]:
                draw_line(Vector2(-10, -41 + offset), Vector2(10, -41 + offset), brass, 2.0)
            draw_circle(Vector2(-4, -45), 4.0, Color("#dde2d4"))
        "rifle":
            draw_line(Vector2(-17, 9), Vector2(43, -13), Color("#8c9ca5"), 7.0)
            draw_line(Vector2(5, 1), Vector2(40, -11), Color("#d3dce0"), 2.0)
            draw_line(Vector2(20, -5), Vector2(46, -14), Color("#343e47"), 4.0)
            draw_line(Vector2(-5, 6), Vector2(2, 23), Color("#7c563b"), 6.0)
            draw_line(Vector2(-20, 8), Vector2(-12, 17), Color("#a37550"), 6.0)
        "chakram":
            draw_line(Vector2(0, 0), Vector2(10, -6), Color("#ab97b5"), 3.0)
            draw_arc(Vector2(21, -9), 19.0, 0.0, TAU, 48, Color("#d5c8e2"), 7.0)
            draw_arc(Vector2(21, -9), 14.0, 0.0, TAU, 48, brass, 2.0)
            draw_circle(Vector2(21, -28), 3.0, pale)
        "unarmed":
            # Gloves and knuckles, not an invented signature armament.
            draw_circle(Vector2(0, 0), 6.0, Color("#857254"))
            draw_line(Vector2(-4, -4), Vector2(3, 3), pale, 1.7)

func _draw_hand() -> void:
    # Renders over the separate weapon attachment, preserving grip contact.
    draw_circle(Vector2.ZERO, 4.2, Color("#cfb9a0"))
    draw_arc(Vector2(0, 0), 4.2, -PI * 0.1, PI * 0.8, 8, Color("#8c735d"), 1.2)
