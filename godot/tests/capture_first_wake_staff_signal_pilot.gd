extends SceneTree
## Three genuine 960x640 First Wake scene captures. NOT a standalone
## side-by-side composition: the overlay is actually a child of Chapter I.
const OUT := "res://review-evidence"
const NAMES: Array[String] = [
    "before-authorized-action","staff-action-visual-contact","staff-action-reduced-motion"
]
var wrapper: Node2D
var world: Node2D
var presenter: Node2D
var hashes: Array[String] = []
var images: Array[Image] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    wrapper=load("res://scenes/first_wake_staff_signal_pilot_review.tscn").instantiate()
    get_root().add_child(wrapper)
    await process_frame
    world=wrapper.chapter_scene
    presenter=wrapper.presenter
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    if not world.start_formula_review() or not await _save(NAMES[0]):
        return
    if not world.take_formula_review_action("staffStrike") \
        or presenter.accepted_visual_count!=1 or not presenter.visible:
        _fail("accepted Chapter I staff action did not trigger opt-in overlay")
        return
    var after: Dictionary = world.formula_encounter.snapshot()
    var duration: float = presenter.observer.bridge.timeline.duration(
        "full_length_staff","attack")
    if not presenter.seek_review_seconds(duration*0.695) \
        or not await _save(NAMES[1]):
        return
    presenter.set_reduced_motion(true)
    if not presenter.seek_review_seconds(duration*0.695) \
        or not await _save(NAMES[2]):
        return
    if hashes.size()!=3 or hashes[0]==hashes[1] or hashes[1]==hashes[2] \
        or world.formula_encounter.snapshot()!=after:
        _fail("native visual frames not different or presenter changed formula state")
        return
    if not _emit_sheet():
        _fail("native montage encoding failed")
        return
    print("FIRST_WAKE_STAFF_SIGNAL_RENDER_PASS: real First Wake scene with optional signal-driven overlay in 3 native frames; same accepted turn")
    wrapper.queue_free()
    quit(0)

func _save(name: String) -> bool:
    await process_frame
    await process_frame
    var img: Image=get_root().get_texture().get_image()
    if img==null or img.get_width()!=960 or img.get_height()!=640:
        _fail("incorrect native source viewport dimensions: "+name)
        return false
    var path:=OUT+"/first-wake-event-"+name+"-960x640.png"
    if img.save_png(path)!=OK:
        _fail("cannot save native frame "+name)
        return false
    var digest:=FileAccess.get_sha256(path)
    if digest.is_empty():
        _fail("missing real image hash "+name)
        return false
    hashes.append(digest)
    print("FIRST_WAKE_STAFF_SIGNAL_FRAME_SHA256 "+name+" "+digest)
    img.convert(Image.FORMAT_RGB8)
    img.resize(720,480,Image.INTERPOLATE_BILINEAR)
    images.append(img)
    return true

func _emit_sheet() -> bool:
    var montage:=Image.create_empty(1440,960,false,Image.FORMAT_RGB8)
    montage.blit_rect(images[0],Rect2i(0,0,720,480),Vector2i.ZERO)
    montage.blit_rect(images[1],Rect2i(0,0,720,480),Vector2i(720,0))
    montage.blit_rect(images[2],Rect2i(0,0,720,480),Vector2i(0,480))
    var jpg: PackedByteArray=montage.save_jpg_to_buffer(0.68)
    if jpg.is_empty():
        return false
    var encoded:=Marshalls.raw_to_base64(jpg)
    print("FIRST_WAKE_SIGNAL_CONTACT_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("FIRST_WAKE_SIGNAL_CONTACT_CHUNK "+encoded.substr(offset,760))
    print("FIRST_WAKE_SIGNAL_CONTACT_END")
    return true

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_STAFF_SIGNAL_RENDER_FAIL: "+reason)
    quit(1)
