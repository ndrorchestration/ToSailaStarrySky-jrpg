extends SceneTree
## Four actual native 960x640 frames of Chapter I's opt-in HUD projection.
## The single formula turn is executed ONCE; all frames are presentation only.
const OUT := "res://review-evidence"
const SHOTS: Array[String] = ["pre-action","anticipation-displayed-pre-result",
    "contact-displayed-committed-result","reduced-motion-reveal"]
var world: Node2D
var wrapper: Node2D
var presenter: Node2D
var hashes: Array[String] = []
var images: Array[Image] = []

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene: PackedScene=load("res://scenes/first_wake_staff_signal_pilot_review.tscn")
    wrapper=scene.instantiate()
    get_root().add_child(wrapper)
    await process_frame
    world=wrapper.chapter_scene
    presenter=wrapper.presenter
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    if not world.start_formula_review() or not await _save(SHOTS[0]):
        return
    var before: Dictionary=world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("real staffStrike refused")
        return
    var resolved: Dictionary=world.formula_encounter.snapshot()
    var duration: float=presenter.observer.bridge.timeline.duration(
        "full_length_staff","attack")
    if not presenter.seek_review_seconds(duration*0.50) \
        or str(presenter.presentation_projection().get("phase","")) != "pending" \
        or not await _save(SHOTS[1]):
        return
    if int(presenter.presentation_projection()["targetHp"]) != int(before["target"]["hp"]) \
        or int(world.formula_encounter.target["hp"]) != int(resolved["target"]["hp"]):
        _fail("anticipation projection altered authoritative formula")
        return
    if not presenter.seek_review_seconds(duration*0.695) \
        or str(presenter.presentation_projection().get("phase","")) != "revealed" \
        or not await _save(SHOTS[2]):
        return
    presenter.set_reduced_motion(true)
    if not presenter.seek_review_seconds(duration*0.695) \
        or not await _save(SHOTS[3]):
        return
    if hashes.size()!=4 or hashes.duplicate().size()!=4 \
        or hashes[0]==hashes[1] or hashes[1]==hashes[2] \
        or hashes[2]==hashes[3] \
        or world.formula_encounter.snapshot()!=resolved \
        or int(world.formula_encounter.turns)!=1:
        _fail("rendered frames repeated or visual replayed a real turn")
        return
    if not _emit_sheet():
        _fail("native screenshot contact montage missing")
        return
    print("FIRST_WAKE_TIMED_HUD_RENDER_PASS: four genuine Chapter I frames, pre/reveal/reduced, exactly one real combat turn")
    wrapper.queue_free()
    quit(0)

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var pic: Image=get_root().get_texture().get_image()
    if pic==null or pic.get_width()!=960 or pic.get_height()!=640:
        _fail("Godot viewport size not 960x640: "+label)
        return false
    var filename:=OUT+"/first-wake-timed-"+label+"-960x640.png"
    if pic.save_png(filename)!=OK:
        _fail("PNG cannot be written: "+label)
        return false
    var digest:=FileAccess.get_sha256(filename)
    if digest.is_empty() or hashes.has(digest):
        _fail("missing or repeated native frame hash: "+label)
        return false
    hashes.append(digest)
    print("FIRST_WAKE_TIMED_HUD_FRAME_SHA256 "+label+" "+digest)
    pic.convert(Image.FORMAT_RGB8)
    pic.resize(720,480,Image.INTERPOLATE_BILINEAR)
    images.append(pic)
    return true

func _emit_sheet() -> bool:
    var sheet: Image=Image.create_empty(1440,960,false,Image.FORMAT_RGB8)
    for i in range(images.size()):
        sheet.blit_rect(images[i],Rect2i(0,0,720,480),
            Vector2i((i%2)*720,(i/2)*480))
    var bytes: PackedByteArray=sheet.save_jpg_to_buffer(0.70)
    if bytes.is_empty():
        return false
    var encoded: String=Marshalls.raw_to_base64(bytes)
    print("FIRST_WAKE_TIMED_HUD_CONTACT_BEGIN "+str(encoded.length()))
    for offset in range(0,encoded.length(),760):
        print("FIRST_WAKE_TIMED_HUD_CONTACT_CHUNK "+encoded.substr(offset,760))
    print("FIRST_WAKE_TIMED_HUD_CONTACT_END")
    return true

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_TIMED_HUD_RENDER_FAIL: "+reason)
    quit(1)
