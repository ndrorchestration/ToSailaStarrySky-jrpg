extends Node2D
## Opaque native practice-only equipment overlay. Drawn on top of the
## review battle without accepting mouse input or modifying game state.
## Keyboard/controller handling is delegated to the Chapter I scene.

const ROW_LABELS := ["WEAPON", "ARMOR", "CHARM"]

var inspection: Dictionary = {}

func set_inspection(data: Dictionary) -> void:
    inspection = data.duplicate(true)
    queue_redraw()

func _line(y: float, text: String, color: Color, size: int = 15, x: float = 195.0, width: int = 570) -> void:
    draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)

func _draw() -> void:
    if inspection.is_empty():
        return
    var warm := Color("#ffe7ad")
    var pale := Color("#deedf3")
    var mint := Color("#8cdbc8")
    var muted := Color("#a9c2d0")
    draw_rect(Rect2(157, 105, 646, 407), Color("#061321"))
    draw_rect(Rect2(160, 108, 640, 401), Color("#87b3c4"), false, 2.0)
    _line(146, "EQUIPMENT  /  PRACTICE INVENTORY", warm, 22)
    _line(168, "NONCANONICAL STUDY  •  UP/DOWN slot  •  LEFT/RIGHT item  •  ENTER equip", muted, 12)

    var slot_idx := int(inspection.get("slotIndex", 0))
    for idx in ROW_LABELS.size():
        var y := 192.0 + float(idx) * 44.0
        var selected := idx == slot_idx
        draw_rect(Rect2(186, y, 235, 36), Color("#234a59") if selected else Color("#142a3b"))
        if selected:
            draw_rect(Rect2(186, y, 235, 36), mint, false, 2.0)
        _line(y + 24.0, ("> " if selected else "  ") + str(ROW_LABELS[idx]), warm if selected else pale, 18, 198.0, 207)

    draw_rect(Rect2(434, 192, 354, 124), Color("#142a3b"))
    draw_rect(Rect2(434, 192, 354, 124), Color("#365b6e"), false, 1.0)
    _line(214, "SELECTED  •  " + str(inspection.get("slotLabel", "")), mint, 12, 446.0, 331)
    _line(243, str(inspection.get("itemName", "")), warm, 20, 446.0, 333)
    _line(262, "Bag available: %d   %s" % [
        int(inspection.get("ownedInBag", 0)),
        "EQUIPPED" if bool(inspection.get("alreadyEquipped", false)) else "PREVIEW"
    ], muted, 12, 446.0, 331)
    var description := str(inspection.get("description", ""))
    # Static test-only summaries are intentionally short. Two-line display
    # avoids hiding the combat comparison at 960x640 native resolution.
    _line(285, description.substr(0, 47), pale, 12, 446.0, 328)
    if description.length() > 47:
        _line(301, description.substr(47, 47), pale, 12, 446.0, 328)

    _line(336, "CURRENT EQUIPMENT  →  SELECTED TRIAL", mint, 13)
    draw_rect(Rect2(185, 346, 602, 118), Color("#102a3a"))
    draw_rect(Rect2(185, 346, 602, 118), Color("#385568"), false, 1.0)

    _line(365, "Strike dmg       %d  ->  %d" % [
        int(inspection.get("beforeStrike", 0)), int(inspection.get("afterStrike", 0))
    ], pale, 15, 198.0, 572)
    _line(389, "Physical DEF     %d  ->  %d     practice hit %d  ->  %d" % [
        int(inspection.get("beforePhysicalDefense", 0)), int(inspection.get("afterPhysicalDefense", 0)),
        int(inspection.get("beforePhysicalHit", 0)), int(inspection.get("afterPhysicalHit", 0))
    ], pale, 15, 198.0, 572)
    _line(413, "Aether DEF       %d  ->  %d     practice hit %d  ->  %d" % [
        int(inspection.get("beforeAetherDefense", 0)), int(inspection.get("afterAetherDefense", 0)),
        int(inspection.get("beforeAetherHit", 0)), int(inspection.get("afterAetherHit", 0))
    ], pale, 15, 198.0, 572)
    _line(447, "Practice formulas only. Story combat, inventory and plot are unchanged.", muted, 12, 198.0, 574)
    _line(491, "9 / ESC Close     ENTER Confirm     No turns spent while inspecting", mint, 13)
