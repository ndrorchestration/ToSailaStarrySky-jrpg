extends SceneTree
## Actual Godot OpenGL Compatibility framebuffer evidence, not composited art.
## Runs a neutral review fixture. No Chapter I scene or plot labels are loaded.
const SCENE = preload("res://scenes/neutral_battle_visual_lab.tscn")
const OUT := "res://review-evidence/neutral-battle-lab"
const LOGICAL := Vector2i(960, 640)

var lab
var frames: Array[Image] = []

func _initialize() -> void:
    call_deferred("_capture")

func _picture(label: String) -> bool:
    lab.queue_redraw()
    lab.enemy_view.queue_redraw()
    lab.staff_view.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    var shot: Image = root.get_texture().get_image()
    if shot.get_size() != LOGICAL:
        push_error("NEUTRAL_BATTLE_VISUAL_FRAME_FAIL: not a native 960x640 render")
        return false
    var path: String = OUT.path_join(label + "-native-960x640.png")
    if shot.save_png(path) != OK:
        push_error("NEUTRAL_BATTLE_VISUAL_FRAME_FAIL: PNG write failed")
        return false
    frames.append(shot)
    var sha: String = FileAccess.get_sha256(path)
    print("NEUTRAL_BATTLE_VISUAL_FRAME:" + label + ":" + sha)
    # The public-safe fixture contains no spoiler, new monster or actor lore.
    # Quota-independent preview is for *human* native layout inspection.
    var small: Image = shot.duplicate()
    small.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var jpeg: PackedByteArray = small.save_jpg_to_buffer(0.72)
    if jpeg.is_empty() or jpeg.size() > 100000:
        push_error("NEUTRAL_BATTLE_VISUAL_FRAME_FAIL: bounded preview missing")
        return false
    var encoded: String = Marshalls.raw_to_base64(jpeg)
    print("NEUTRAL_BATTLE_VISUAL_PREVIEW_BEGIN:" + label + ":" + sha + ":" + str(jpeg.size()))
    for i in range(0, encoded.length(), 3200):
        print("NEUTRAL_BATTLE_VISUAL_PREVIEW_DATA:" + label + ":" +
            str(i / 3200) + ":" + encoded.substr(i, 3200))
    print("NEUTRAL_BATTLE_VISUAL_PREVIEW_END:" + label)
    return true

func _capture() -> void:
    root.size = LOGICAL
    if DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT)) != OK:
        _fail("could not create native evidence directory")
        return
    lab = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    if not lab.start_lab():
        _fail("isolated existing enemy review failed to start")
        return
    lab.enemy_view.set_process(false)
    if not (await _picture("idle")):
        _fail("idle capture")
        return
    if not lab.resolve_one_staff_strike():
        _fail("one real staff strike failed")
        return
    var resolved: Dictionary = lab.encounter.snapshot()
    if not (await _picture("hit")):
        _fail("hit and staff visual capture")
        return
    for _tick in range(6):
        lab.enemy_view._process(0.05)
    if lab.enemy_view.reaction_phase() != "gale":
        _fail("real Gale response did not appear after hit phase")
        return
    if not (await _picture("gale")):
        _fail("resolved Gale capture")
        return
    if lab.encounter.snapshot() != resolved:
        _fail("rendered battle states changed mechanics")
        return

    if not lab.close_lab() or not lab.start_lab(true):
        _fail("reduced-motion fixture failed")
        return
    lab.enemy_view.set_process(false)
    if not lab.resolve_one_staff_strike():
        _fail("reduced-motion authorized strike failed")
        return
    if not (await _picture("reduced")):
        _fail("reduced-motion capture")
        return

    if frames.size() != 4:
        _fail("four native lab frames missing")
        return
    var region := Rect2i(160, 183, 675, 290)
    var idle_pixels: PackedByteArray = frames[0].get_region(region).get_data()
    var hit_pixels: PackedByteArray = frames[1].get_region(region).get_data()
    var gale_pixels: PackedByteArray = frames[2].get_region(region).get_data()
    if idle_pixels == hit_pixels or hit_pixels == gale_pixels:
        _fail("actual staff/elemental presentation states did not differ")
        return
    var reduced_pixels: PackedByteArray = frames[3].get_region(region).get_data()
    if reduced_pixels == hit_pixels:
        _fail("reduced-motion render identical to active hit animation")
        return
    lab.queue_free()
    await process_frame
    print("TSTSS_NEUTRAL_BATTLE_VISUAL_RENDER_PASS: four real 960x640 frames; one real turn per independent fixture; no Chapter I route")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_NEUTRAL_BATTLE_VISUAL_RENDER_FAIL: " + reason)
    quit(1)
