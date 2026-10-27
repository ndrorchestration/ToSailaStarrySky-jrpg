extends SceneTree
## Rendered comparison evidence from the isolated battle-equipment preview.
const DIR := "res://review-evidence"
var screen: Control
var fingerprints: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/weapon_battle_equipment_review.tscn")
    if packed == null:
        _fail("review scene missing")
        return
    screen = packed.instantiate()
    get_root().add_child(screen)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    screen._scrub(70.0)
    if not await _save("ender-staff-authorized-intent"):
        return
    screen._toggle_mode()
    screen._cycle_weapon()
    screen._scrub(70.0)
    if not await _save("sandbox-sword-equipment"):
        return
    screen._cycle_weapon()
    screen._scrub(70.0)
    if not await _save("sandbox-pike-equipment"):
        return
    screen._set_reduced_motion(true)
    if not await _save("sandbox-pike-reduced"):
        return
    if fingerprints.size() != 4 or fingerprints[0] == fingerprints[1] \
        or fingerprints[1] == fingerprints[2] or fingerprints[2] == fingerprints[3]:
        _fail("weapon state frames were not distinct")
        return
    if not _emit_preview_contact_sheet():
        return
    print("WEAPON_BATTLE_NATIVE_FRAMES_PASS: four rendered 960x640 variations, no battle commands")
    screen.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var frame: Image = get_root().get_texture().get_image()
    if frame == null or frame.get_width() != 960 or frame.get_height() != 640:
        _fail("invalid native renderer frame dimensions: "+label)
        return false
    var file_path := DIR+"/"+label+"-native-960x640.png"
    if frame.save_png(file_path) != OK:
        _fail("PNG write failed: "+label)
        return false
    var digest := FileAccess.get_sha256(file_path)
    if digest.is_empty():
        _fail("missing PNG sha256: "+label)
        return false
    fingerprints.append(digest)
    print("WEAPON_BATTLE_FRAME_SHA256 "+label+" "+digest)
    return true

func _fail(reason: String) -> void:
    push_error("WEAPON_BATTLE_NATIVE_FRAMES_FAIL: "+reason)
    quit(1)

## Compact private-ish CI-log review of original geometric placeholders only.
## Full-size PNG authority stays runner-local. This contact sheet is NOT canon art.
func _emit_preview_contact_sheet() -> bool:
    var montage: Image = Image.create_empty(960,640,false,Image.FORMAT_RGB8)
    var labels: Array[String] = [
        "ender-staff-authorized-intent", "sandbox-sword-equipment",
        "sandbox-pike-equipment", "sandbox-pike-reduced"
    ]
    for i in range(labels.size()):
        var path := ProjectSettings.globalize_path(
            DIR+"/"+labels[i]+"-native-960x640.png")
        var snapshot: Image = Image.load_from_file(path)
        if snapshot == null or snapshot.is_empty():
            _fail("could not reopen native capture for visual review")
            return false
        snapshot.convert(Image.FORMAT_RGB8)
        snapshot.resize(480,320,Image.INTERPOLATE_BILINEAR)
        montage.blit_rect(snapshot,Rect2i(0,0,480,320),
            Vector2i((i % 2)*480,(i / 2)*320))
    var jpeg: PackedByteArray = montage.save_jpg_to_buffer(0.72)
    if jpeg.is_empty():
        _fail("native montage JPG encoding failed")
        return false
    var encoded: String = Marshalls.raw_to_base64(jpeg)
    print("WEAPON_BATTLE_CONTACT_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("WEAPON_BATTLE_CONTACT_CHUNK "+encoded.substr(offset,760))
    print("WEAPON_BATTLE_CONTACT_END")
    return true
