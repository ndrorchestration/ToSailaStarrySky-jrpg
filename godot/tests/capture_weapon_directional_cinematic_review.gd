extends SceneTree
## Native renderer contact sheet is ONLY existing review-only Ender art.
## Full frames stay on runner; log-only contact sheet is a downsample.
const OUT := "res://review-evidence"
var review: Control
var fingerprints: Array[String] = []
const SHOTS: Array[String] = [
    "ender-east-impact", "ender-west-impact", "ender-south-impact",
    "ender-north-impact", "ender-east-reduced", "geometric-mannequin"
]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if packed == null:
        _fail("review scene not found")
        return
    review = packed.instantiate()
    get_root().add_child(review)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    review._scrub(69.5)
    for i in range(4):
        if not await _save(SHOTS[i]):
            return
        review._cycle_facing()
    review._set_motion(true)
    if not await _save(SHOTS[4]):
        return
    review._toggle_candidate()
    if not await _save(SHOTS[5]):
        return
    if fingerprints.size() != SHOTS.size():
        _fail("lost native frame in capture")
        return
    for i in range(1,fingerprints.size()):
        for j in range(i):
            if fingerprints[i] == fingerprints[j]:
                _fail("duplicate rendered image: "+SHOTS[i])
                return
    if not _emit_log_contact_sheet():
        return
    print("WEAPON_DIRECTIONAL_NATIVE_RENDER_PASS: 4 direction candidates, reduced-motion and mannequin baseline")
    review.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var captured: Image = get_root().get_texture().get_image()
    if captured == null or captured.get_width() != 960 or captured.get_height() != 640:
        _fail("native screenshot incorrect size: "+label)
        return false
    var output := OUT+"/"+label+"-native-960x640.png"
    if captured.save_png(output) != OK:
        _fail("PNG write failed: "+label)
        return false
    var digest := FileAccess.get_sha256(output)
    if digest.is_empty():
        _fail("PNG hash missing: "+label)
        return false
    fingerprints.append(digest)
    print("WEAPON_DIRECTIONAL_FRAME_SHA256 "+label+" "+digest)
    return true

func _emit_log_contact_sheet() -> bool:
    var sheet := Image.create_empty(1440,640,false,Image.FORMAT_RGB8)
    for i in range(SHOTS.size()):
        var frame := Image.load_from_file(
            ProjectSettings.globalize_path(OUT+"/"+SHOTS[i]+"-native-960x640.png"))
        if frame == null or frame.is_empty():
            _fail("cannot reload native frame")
            return false
        frame.convert(Image.FORMAT_RGB8)
        frame.resize(480,320,Image.INTERPOLATE_BILINEAR)
        sheet.blit_rect(frame,Rect2i(0,0,480,320),
            Vector2i((i%3)*480,(i/3)*320))
    var bytes := sheet.save_jpg_to_buffer(0.68)
    if bytes.is_empty():
        _fail("contact JPEG invalid")
        return false
    var encoded := Marshalls.raw_to_base64(bytes)
    print("WEAPON_DIRECTIONAL_CONTACT_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("WEAPON_DIRECTIONAL_CONTACT_CHUNK "+encoded.substr(offset,760))
    print("WEAPON_DIRECTIONAL_CONTACT_END")
    return true

func _fail(reason: String) -> void:
    push_error("WEAPON_DIRECTIONAL_NATIVE_RENDER_FAIL: "+reason)
    quit(1)
