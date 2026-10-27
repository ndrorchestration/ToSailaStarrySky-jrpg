extends Node2D
## Original procedural 2D battle EQUIPMENT preview, not accepted portrait art.
## The hand anchor and held equipment are drawn together on every loadout
## change. No shader/magic, attack formula or approved sprite is replaced.

var appearance: Dictionary = {}

func set_appearance(next_appearance: Dictionary) -> void:
    appearance = next_appearance.duplicate(true)
    visible = not appearance.is_empty()
    queue_redraw()

func visual_key() -> String:
    return str(appearance.get("weaponVisual", "")) + "|" + str(appearance.get("armorVisual", "")) + "|" + str(appearance.get("accessoryVisual", ""))

func _draw() -> void:
    if appearance.is_empty():
        return
    var edge := Color("#47657a")
    var brass := Color("#d6ac6a")
    var pale := Color("#eff0da")
    var coat := Color("#687c63")
    draw_rect(Rect2(-56, -68, 112, 141), Color("#132536"))
    draw_rect(Rect2(-56, -68, 112, 141), edge, false, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-46, -51), "EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, 98, 11, Color("#add5dc"))

    # Neutral pose dummy: a silhouette for equipment alignment, never a
    # replacement for Ender's locked likeness or final cast sprite sheets.
    draw_circle(Vector2(-21, -19), 11, Color("#d0ba9e"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-39, -6), Vector2(-8, -6), Vector2(-9, 38), Vector2(-39, 38)
    ]), coat)
    draw_line(Vector2(-12, 0), Vector2(13, 14), Color("#d0ba9e"), 7.0)
    draw_circle(Vector2(13, 14), 4.5, Color("#d0ba9e"))

    if str(appearance.get("armorVisual", "")) == "brass-plate":
        draw_colored_polygon(PackedVector2Array([
            Vector2(-35, -3), Vector2(-13, -3), Vector2(-12, 23),
            Vector2(-24, 30), Vector2(-37, 20)
        ]), Color("#b6a17c"))
        draw_line(Vector2(-34, 5), Vector2(-13, 5), brass, 2.0)

    var family := str(appearance.get("weaponFamily", ""))
    var variant := str(appearance.get("weaponVisual", ""))
    match family:
        "staff":
            # Full shaft with brass ferrules and centered longitudinal grip.
            var shaft_color := Color("#b0bdc9") if variant == "staff-silver-inlay" else Color("#916745")
            draw_line(Vector2(19, -45), Vector2(19, 49), shaft_color, 5.0)
            draw_line(Vector2(19, -45), Vector2(19, -36), brass, 6.0)
            draw_line(Vector2(19, 40), Vector2(19, 49), brass, 6.0)
            draw_line(Vector2(19, 6), Vector2(19, 21), Color("#44332f"), 7.0)
            if variant == "staff-silver-inlay":
                draw_line(Vector2(19, -33), Vector2(19, 3), pale, 2.0)
                draw_circle(Vector2(19, -43), 3.5, pale)
        "sword":
            draw_line(Vector2(19, 14), Vector2(19, -44), Color("#e1e7e8"), 7.0)
            draw_line(Vector2(5, 7), Vector2(33, 7), brass, 4.0)
            draw_line(Vector2(19, 8), Vector2(19, 23), Color("#795746"), 5.0)
            draw_colored_polygon(PackedVector2Array([Vector2(16, -44), Vector2(22, -44), Vector2(19, -57)]), pale)
        "mace":
            draw_line(Vector2(19, 20), Vector2(19, -31), Color("#95724b"), 6.0)
            draw_circle(Vector2(19, -40), 14.0, Color("#abb9b8"))
            for offset in [-10.0, 0.0, 10.0]:
                draw_line(Vector2(6, -40 + offset), Vector2(32, -40 + offset), brass, 2.0)
        "rifle":
            draw_line(Vector2(12, 6), Vector2(46, -12), Color("#aabac1"), 8.0)
            draw_line(Vector2(24, 0), Vector2(51, 0), Color("#3a494e"), 5.0)
            draw_line(Vector2(27, 0), Vector2(31, 17), brass, 5.0)
            draw_line(Vector2(7, 7), Vector2(18, 15), Color("#8d644a"), 6.0)
        "chakram":
            draw_arc(Vector2(31, -1), 20.0, 0.0, TAU, 44, Color("#d1c8dc"), 7.0)
            draw_arc(Vector2(31, -1), 15.0, 0.0, TAU, 44, brass, 2.0)
        "unarmed":
            draw_circle(Vector2(13, 14), 7.5, Color("#7a674e"))
            draw_line(Vector2(10, 11), Vector2(17, 18), pale, 2.0)

    if str(appearance.get("accessoryVisual", "")) == "small-charm":
        draw_line(Vector2(-24, -4), Vector2(-24, 10), brass, 1.5)
        draw_circle(Vector2(-24, 12), 3.5, Color("#91d0ce"))

    var label := str(appearance.get("weaponName", "NO EQUIPMENT")).to_upper()
    draw_string(ThemeDB.fallback_font, Vector2(-51, 62), label, HORIZONTAL_ALIGNMENT_LEFT, 101, 10, pale)
