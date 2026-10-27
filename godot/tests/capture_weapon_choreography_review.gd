extends SceneTree
## Native rendered, fixed-frame evidence only. These original geometry frames
## must not be mistaken for approved character or weapon production art.
const OUTPUT := "res://review-evidence"
var review: Control
var hashes: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/weapon_choreography_review.tscn")
    if packed == null:
        _fail("missing scene")
        return
    review = packed.instantiate()
    get_root().add_child(review)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    if not await _save("staff-idle"):
        return
    review._cycle_action()
    review._scrub(70.0)
    if not await _save("staff-impact"):
        return
    review._cycle_weapon()
    review._scrub(70.0)
    if not await _save("sword-impact"):
        return
    review._set_motion(true)
    if not await _save("sword-reduced"):
        return
    if hashes.size() != 4 or hashes[0] == hashes[1] or hashes[1] == hashes[2] \
        or hashes[2] == hashes[3]:
        _fail("authentic frame variation not established")
        return
    print("WEAPON_NATIVE_RENDER_PASS: four distinct 960x640 real Godot frames")
    review.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var image: Image = get_root().get_texture().get_image()
    if image == null or image.get_width() != 960 or image.get_height() != 640:
        _fail("capture size mismatch: "+label)
        return false
    var path := OUTPUT+"/"+label+"-native-960x640.png"
    if image.save_png(path) != OK:
        _fail("PNG write failed: "+label)
        return false
    var digest := FileAccess.get_sha256(path)
    if digest.is_empty():
        _fail("missing hash: "+label)
        return false
    hashes.append(digest)
    print("WEAPON_FRAME_SHA256 "+label+" "+digest)
    return true

func _fail(reason: String) -> void:
    push_error("WEAPON_NATIVE_RENDER_FAIL: "+reason)
    quit(1)
