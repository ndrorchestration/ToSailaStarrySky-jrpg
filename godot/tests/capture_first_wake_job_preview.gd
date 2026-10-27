extends SceneTree
## Real native 960x640 visual receipt for the isolated Ionia-first hiring preview.
## Captures are reviewer evidence only: not approved art, integrated Chapter I,
## flight or water-physics evidence, and not a release package.

const SCENE = preload("res://scenes/first_wake_job_preview.tscn")
const OUT := "res://review-evidence/first-wake-hiring/"
const FILES := [
    "01-unemployed-dock-native-960x640.png",
    "02-flyer-dialogue-native-960x640.png",
    "03-ionia-hired-native-960x640.png",
    "04-engineering-room-native-960x640.png",
    "05-fuel-inspection-native-960x640.png",
    "06-preflight-handoff-native-960x640.png",
]

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(filename: String) -> Image:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("FIRST_WAKE_HIRING_RENDER_FAIL: screenshot was not real 960x640 framebuffer")
        return null
    var path: String = OUT.path_join(filename)
    if image.save_png(path) != OK:
        push_error("FIRST_WAKE_HIRING_RENDER_FAIL: unable to save " + filename)
        return null
    print("FIRST_WAKE_HIRING_RENDER_PNG:" + filename + ":960x640:" + FileAccess.get_sha256(path))
    return image

func _finish_dialogue(world: Node) -> bool:
    var budget: int = 20
    while world.dialogue_open and budget > 0:
        if not world.interact():
            return false
        budget -= 1
    return not world.dialogue_open and budget > 0

func _stop(message: String) -> void:
    push_error("FIRST_WAKE_HIRING_RENDER_FAIL: " + message)
    quit(1)

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = SCENE.instantiate()
    root.add_child(world)
    await process_frame
    if world.ender == null or world.ionia == null:
        _stop("missing cast")
        return
    # Physically static fixed camera/state study, not simulated walking evidence.
    world.ender.set_physics_process(false)
    world.ionia.set_physics_process(false)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        _stop("review-only output unavailable")
        return
    if world.opening.active_party_ids != ["ender"] or world.opening.step_key() != "job_search":
        _stop("opening starts with incorrect party or phase")
        return

    var frames: Array[Image] = []
    var frame: Image = await _snapshot(FILES[0])
    if frame == null:
        quit(2)
        return
    frames.append(frame)

    world.ender.position = world.FLYER_POSITION
    if not world.interact() or not world.dialogue_open or world.flyer_read:
        _stop("notice dialogue is not gated")
        return
    frame = await _snapshot(FILES[1])
    if frame == null:
        quit(3)
        return
    frames.append(frame)
    if not _finish_dialogue(world) or not world.flyer_read:
        _stop("flyer did not finish")
        return

    world.ender.position = world.IONIA_DOCK_POSITION
    if not world.interact() or not world.dialogue_open or not _finish_dialogue(world):
        _stop("Ionia employment interview did not finish")
        return
    if world.opening.active_party_ids != ["ender", "ionia"] or world.opening.step_key() != "engineering":
        _stop("Ionia did not join first")
        return
    frame = await _snapshot(FILES[2])
    if frame == null:
        quit(4)
        return
    frames.append(frame)

    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        _stop("no boardable engineering layout")
        return
    frame = await _snapshot(FILES[3])
    if frame == null:
        quit(5)
        return
    frames.append(frame)

    world.ender.position = world.ROOM_POSITIONS["fuel"]
    if not world.interact() or not world.dialogue_open or "fuel" in world.inspected_items:
        _stop("fuel observation dialogue gate failed")
        return
    frame = await _snapshot(FILES[4])
    if frame == null:
        quit(6)
        return
    frames.append(frame)
    if not _finish_dialogue(world):
        _stop("fuel dialogue did not finish")
        return
    for key in ["reference", "containment"]:
        world.ender.position = world.ROOM_POSITIONS[key]
        if not world.interact() or not _finish_dialogue(world):
            _stop("inspection incomplete: " + key)
            return
    world.ender.position = world.ROOM_POSITIONS["checklist"]
    if not world.interact() or not _finish_dialogue(world):
        _stop("preflight dialogue incomplete")
        return
    if world.opening.step_key() != "preflight" or world.ender.player_controlled:
        _stop("preflight advanced beyond isolated review boundary")
        return
    if world.opening.active_party_ids != ["ender", "ionia"]:
        _stop("premature Lyra recruitment")
        return
    frame = await _snapshot(FILES[5])
    if frame == null:
        quit(7)
        return
    frames.append(frame)

    # This proves stage-specific framebuffer changes, not visual quality.
    # Full frames include stage UI by design; art acceptance requires inspection.
    for i in range(frames.size() - 1):
        if frames[i].get_data() == frames[i + 1].get_data():
            _stop("duplicate native framebuffer stages " + str(i) + " and " + str(i + 1))
            return
    world.queue_free()
    await process_frame
    print("FIRST_WAKE_HIRING_NATIVE_RENDER_PASS: six distinct real 960x640 review frames")
    print("FIRST_WAKE_HIRING_INTEGRATED_CHAPTER1=false")
    print("FIRST_WAKE_HIRING_WATER_PHYSICS=false")
    print("FIRST_WAKE_HIRING_ART_ACCEPTANCE=PENDING")
    quit(0)
