extends SceneTree
## Authentic Godot 960×640 comparison sheet for all five original starter
## combat equipment identities. Unapproved neutral mannequins; not party turns.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Rig = preload("res://scripts/battle_equipment_visual.gd")
const OUTPUT := "res://review-evidence/battle-equipment/"
const CAST := ["ender", "lyra", "ionia", "reson", "aepex"]
const RESON_REGION := Rect2i(590, 205, 112, 172)

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        return null
    var filename := OUTPUT.path_join(name + ".png")
    if img.save_png(filename) != OK:
        return null
    print("AETHERWAKE_EQUIPMENT_CAST_NATIVE_FRAME:" + name + ":" + FileAccess.get_sha256(ProjectSettings.globalize_path(filename)))
    return img

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot create equipment gallery")
        return
    var backdrop := ColorRect.new()
    backdrop.size = Vector2(960, 640)
    backdrop.color = Color("#0b1725")
    root.add_child(backdrop)

    var headline := Label.new()
    headline.text = "TO SAIL THE STARRY SKY / DETACHABLE BATTLE GEAR STUDY"
    headline.position = Vector2(120, 99)
    headline.add_theme_font_size_override("font_size", 22)
    backdrop.add_child(headline)

    var rigs: Dictionary = {}
    var loadouts: Dictionary = {}
    for i in range(CAST.size()):
        var actor_id: String = CAST[i]
        var loadout = Loadout.new(actor_id)
        if not loadout.validate():
            _fail("invalid gallery starter: " + actor_id)
            return
        var rig = Rig.new()
        rig.position = Vector2(145 + i * 167, 285)
        rig.set_appearance(loadout.appearance())
        root.add_child(rig)
        var caption := Label.new()
        caption.text = actor_id.to_upper()
        caption.position = Vector2(105 + i * 167, 385)
        caption.add_theme_color_override("font_color", Color("#a8d1d5"))
        root.add_child(caption)
        rigs[actor_id] = rig
        loadouts[actor_id] = loadout
    await process_frame
    var original: Image = await _snapshot("starter-cast-native-960x640")
    if original == null:
        _fail("starter cast native capture missing")
        return

    var reson = loadouts["reson"]
    if not reson.hold_weapon_slot("secondaryWeapon"):
        _fail("Reson secondary rifle is unavailable")
        return
    rigs["reson"].set_appearance(reson.appearance())
    await process_frame
    var switched: Image = await _snapshot("reson-rifle-native-960x640")
    if switched == null or switched.get_region(RESON_REGION).get_data() == original.get_region(RESON_REGION).get_data():
        _fail("Reson changing sword to rifle had no rendered region difference")
        return
    print("AETHERWAKE_BATTLE_EQUIPMENT_CAST_GALLERY_PASS: five cast families and independently equipped Reson rifle rendered in native Godot")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_CAST_GALLERY_FAIL: " + reason)
    quit(1)
