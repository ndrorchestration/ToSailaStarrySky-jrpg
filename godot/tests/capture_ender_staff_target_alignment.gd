extends SceneTree
## 4-direction × 3-beat real Godot study plus one reduced-motion proof.
## Full 960x640 PNG frames remain on CI runner; logged montage is lossy.
const OUT := "res://review-evidence"
const FACINGS: Array[String] = ["east","west","south","north"]
const BEATS: Array[String] = ["approach","contact","recovery"]
const PCTS: Array[float] = [0.10,0.695,0.90]
var review: Control
var hashes: Dictionary = {}
var thumbnails: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if scene == null:
        _fail("missing review scene")
        return
    review = scene.instantiate()
    get_root().add_child(review)
    review._toggle_combat_pose()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for face_index in range(FACINGS.size()):
        review.facing_index = face_index
        for beat_index in range(BEATS.size()):
            review._scrub(PCTS[beat_index]*100.0)
            var label: String = FACINGS[face_index]+"-"+BEATS[beat_index]
            if not await _save(label):
                return
    review.facing_index = 0
    review._set_motion(true)
    review._scrub(69.5)
    if not await _save("east-reduced-contact"):
        return
    if hashes.size() != 13 or not _emit_contact_sheet():
        _fail("loss of native capture or contact montage")
        return
    print("ENDER_STAFF_TARGET_RENDER_PASS: 13 distinct 960x640 frame captures, optical alignment and reduced-motion state")
    review.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var image: Image = get_root().get_texture().get_image()
    if image == null or image.get_width()!=960 or image.get_height()!=640:
        _fail("wrong actual renderer size: "+label)
        return false
    var path := OUT+"/staff-target-"+label+"-960x640.png"
    if image.save_png(path) != OK:
        _fail("failed PNG write: "+label)
        return false
    var digest := FileAccess.get_sha256(path)
    if digest.is_empty() or hashes.values().has(digest):
        _fail("duplicate or missing native image hash: "+label)
        return false
    hashes[label]=digest
    var crop: Image = image.get_region(Rect2i(492,130,450,399))
    crop.convert(Image.FORMAT_RGB8)
    crop.resize(300,220,Image.INTERPOLATE_BILINEAR)
    thumbnails[label]=crop
    print("ENDER_STAFF_TARGET_FRAME_SHA256 "+label+" "+digest)
    return true

func _emit_contact_sheet() -> bool:
    var sheet: Image = Image.create_empty(900,1100,false,Image.FORMAT_RGB8)
    for f in range(FACINGS.size()):
        for b in range(BEATS.size()):
            var label: String = FACINGS[f]+"-"+BEATS[b]
            sheet.blit_rect(thumbnails[label],Rect2i(0,0,300,220),
                Vector2i(b*300,f*220))
    sheet.blit_rect(thumbnails["east-reduced-contact"],Rect2i(0,0,300,220),
        Vector2i(0,880))
    var buffer: PackedByteArray = sheet.save_jpg_to_buffer(0.76)
    if buffer.is_empty():
        return false
    var encoded: String = Marshalls.raw_to_base64(buffer)
    print("ENDER_STAFF_TARGET_CONTACT_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("ENDER_STAFF_TARGET_CONTACT_CHUNK "+encoded.substr(offset,760))
    print("ENDER_STAFF_TARGET_CONTACT_END")
    return true

func _fail(reason: String) -> void:
    push_error("ENDER_STAFF_TARGET_RENDER_FAIL: "+reason)
    quit(1)
