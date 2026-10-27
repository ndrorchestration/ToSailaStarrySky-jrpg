extends SceneTree
## Real-engine rendered 4x5 new staff strike storyboard, plus reduced-motion.
## Full-resolution native 960x640 PNGs are runner-only. Logged contact sheet is
## a lossy downsized inspection artifact, not delivery or art acceptance.
const OUT := "res://review-evidence"
const FACES: Array[String] = ["east","west","south","north"]
const BEATS: Array[String] = ["anticipation","formation","release","impact","recovery"]
const PCTS: Array[float] = [0.10,0.30,0.51,0.695,0.90]
var review: Control
var hashes: Dictionary = {}
var thumbs: Dictionary = {}

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if packed == null:
        _fail("weapon review scene not available")
        return
    review = packed.instantiate()
    get_root().add_child(review)
    review._toggle_combat_pose()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for f in range(FACES.size()):
        review.facing_index = f
        for b in range(BEATS.size()):
            review._scrub(PCTS[b]*100.0)
            var identity: String = FACES[f]+"-"+BEATS[b]
            if not await _save(identity):
                return
    review.facing_index = 0
    review._set_motion(true)
    review._scrub(69.5)
    if not await _save("east-reduced"):
        return
    if hashes.size()!=21 or not _emit_sheet():
        _fail("incomplete contact frames, or contact-sheet encoding failed")
        return
    print("ENDER_COMBAT_STORYBOARD_RENDER_PASS: 20 distinct authored pose frames plus reduced-motion")
    review.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var picture: Image = get_root().get_texture().get_image()
    if picture == null or picture.get_width()!=960 or picture.get_height()!=640:
        _fail("incorrect actual rendered dimensions: "+label)
        return false
    var path := OUT+"/staff-combat-"+label+"-960x640.png"
    if picture.save_png(path)!=OK:
        _fail("native PNG cannot be saved: "+label)
        return false
    var digest := FileAccess.get_sha256(path)
    if digest.is_empty() or hashes.values().has(digest):
        _fail("empty/repeated actual pixels: "+label)
        return false
    hashes[label]=digest
    # Stage-only crop enables anatomy and grip inspection at log payload limits.
    var crop: Image = picture.get_region(Rect2i(490,130,460,400))
    crop.convert(Image.FORMAT_RGB8)
    crop.resize(230,200,Image.INTERPOLATE_BILINEAR)
    thumbs[label]=crop
    print("ENDER_STAFF_COMBAT_FRAME_SHA256 "+label+" "+digest)
    return true

func _emit_sheet() -> bool:
    var sheet := Image.create_empty(1150,1000,false,Image.FORMAT_RGB8)
    for row in range(FACES.size()):
        for column in range(BEATS.size()):
            var key: String = FACES[row]+"-"+BEATS[column]
            sheet.blit_rect(thumbs[key],Rect2i(0,0,230,200),
                Vector2i(column*230,row*200))
    sheet.blit_rect(thumbs["east-reduced"],Rect2i(0,0,230,200),Vector2i(0,800))
    var bytes: PackedByteArray = sheet.save_jpg_to_buffer(0.78)
    if bytes.is_empty():
        return false
    var encoded: String = Marshalls.raw_to_base64(bytes)
    print("ENDER_STAFF_COMBAT_SHEET_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("ENDER_STAFF_COMBAT_SHEET_CHUNK "+encoded.substr(offset,760))
    print("ENDER_STAFF_COMBAT_SHEET_END")
    return true

func _fail(reason: String) -> void:
    push_error("ENDER_STAFF_COMBAT_STORYBOARD_RENDER_FAIL: "+reason)
    quit(1)
