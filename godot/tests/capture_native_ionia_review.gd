extends SceneTree
## Real Godot renderer capture for the opt-in SVG review; NOT acceptance proof.
## Must run under a functioning display/renderer (e.g. xvfb-run), not dummy headless.

const SCENE = preload("res://scenes/first_wake.tscn")
const OUTPUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world := SCENE.instantiate()
    root.add_child(world)
    await process_frame
    await process_frame
    var baseline: Image = await _snapshot()
    if not _valid_screen(baseline):
        push_error("GODOT_CAPTURE_FAIL: baseline not a rendered 960x640 scene")
        quit(2)
        return

    var ionia = world.get_node_or_null("YSortedActors/IoniaPilot")
    if ionia == null or not ionia.has_method("set_review_art_enabled"):
        push_error("GODOT_CAPTURE_FAIL: review actor missing")
        quit(3)
        return
    ionia.call("set_review_art_enabled", true)
    await process_frame
    var art_review: Image = await _snapshot()
    if not _valid_screen(art_review):
        push_error("GODOT_CAPTURE_FAIL: art state is not a rendered 960x640 scene")
        quit(4)
        return

    # This ROI contains Ionia at dock position 570,458. A source import that
    # never becomes visible must fail rather than creating two identical PNGs.
    var roi := Rect2i(510, 340, 140, 135)
    if baseline.get_region(roi).get_data() == art_review.get_region(roi).get_data():
        push_error("GODOT_CAPTURE_FAIL: preview did not alter native actor pixels")
        quit(5)
        return
    var absolute_dir := ProjectSettings.globalize_path(OUTPUT)
    if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
        push_error("GODOT_CAPTURE_FAIL: output directory not available")
        quit(6)
        return
    if baseline.save_png(OUTPUT + "ionia-baseline-native-960x640.png") != OK:
        push_error("GODOT_CAPTURE_FAIL: failed to store baseline")
        quit(7)
        return
    if art_review.save_png(OUTPUT + "ionia-svg-review-native-960x640.png") != OK:
        push_error("GODOT_CAPTURE_FAIL: failed to store candidate")
        quit(8)
        return
    print("GODOT_CAPTURE_PASS: two 960x640 native rendered states differ at Ionia ROI")
    print("GODOT_CAPTURE_REVIEW_ONLY: art, map geometry and player acceptance not admitted")
    quit(0)

func _snapshot() -> Image:
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _valid_screen(image: Image) -> bool:
    return (not image.is_empty()
        and image.get_width() == 960
        and image.get_height() == 640
        and image.get_pixel(10, 10) != image.get_pixel(480, 460))
