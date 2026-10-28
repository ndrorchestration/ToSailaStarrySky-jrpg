extends SceneTree
## Genuine Godot Compatibility GL snapshots after the authentic Ionia-first
## game, original 2D ocean splashdown and second physical local berth sensor.
## Test runner-local PNG custody; small JPEGs appear only in private job logs.
const Game = preload("res://scenes/first_wake_game.tscn")
const OUT := "res://review-evidence/first-wake-playable-berth/"
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _advance(job) -> bool:
    for i in range(18):
        if not job.dialogue_open:
            return true
        if not job.interact():
            return false
    return not job.dialogue_open

func _image(label: String) -> Image:
    for i in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img == null or img.get_size() != Vector2i(960, 640):
        problems.append("Godot framebuffer unavailable/incorrect size: " + label)
        return null
    var path = OUT + label + ".png"
    if img.save_png(path) != OK:
        problems.append("source PNG not saved: " + label)
        return null
    print("TSTSS_BERTH_NATIVE_FRAME:", label, ":", FileAccess.get_sha256(path))
    var preview: Image = img.duplicate()
    preview.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var compressed: PackedByteArray = preview.save_jpg_to_buffer(0.69)
    if compressed.is_empty() or compressed.size() > 180000:
        problems.append("private JPEG bounds violated: " + label)
    else:
        var encoded: String = Marshalls.raw_to_base64(compressed)
        print("TSTSS_BERTH_JPEG_BEGIN:", label, ":480x320")
        for p in range(0, encoded.length(), 3500):
            print("TSTSS_BERTH_JPEG_DATA:", encoded.substr(p, 3500))
        print("TSTSS_BERTH_JPEG_END:", label)
    return img.duplicate()

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("TSTSS_BERTH_GL_FAIL: cannot create source frame directory")
        quit(1)
        return
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    var job = game.job
    if job == null:
        problems.append("no actual player-controlled First Wake entry")
    else:
        job.ender.position = job.FLYER_POSITION
        if not job.interact() or not _advance(job):
            problems.append("authored flyer interaction failed")
        job.ender.position = job.IONIA_DOCK_POSITION
        if not job.interact() or not _advance(job):
            problems.append("Ionia hiring invalid")
        job.ender.position = job.GANGWAY_POSITION
        if not job.interact():
            problems.append("gangway invalid")
        for item in ["reference", "containment", "fuel"]:
            job.ender.position = job.ROOM_POSITIONS[item]
            if not job.interact() or not _advance(job):
                problems.append("engineering gate missing " + item)
        job.ender.position = job.ROOM_POSITIONS["checklist"]
        if not job.interact() or not _advance(job) or not job.launch_flight_review():
            problems.append("native real flight invalid")
        if problems.is_empty():
            var flight = job.flight_review
            if not flight.begin_short_test_flight():
                problems.append("first lift refused")
            for tick in range(200):
                await process_frame
                if flight.phase == "warning":
                    break
            if flight.phase != "warning" or not flight.stabilize_for_water_descent():
                problems.append("genuine phase-warning/abort missing")
            for tick in range(560):
                await process_frame
                if flight.phase == "waterborne":
                    break
            if not flight.contact_observed or not flight.stable_float_verified:
                problems.append("real 2D ocean contact missing")
            for tick in range(130):
                await process_frame
                if game.game_stage == "postflight":
                    break
    if game.game_stage != "postflight" or game.postflight == null:
        problems.append("did not reach physical postflight game")
    if not problems.is_empty():
        for err in problems:
            push_error("TSTSS_BERTH_GL_FAIL: " + err)
        quit(1)
        return
    var deck = game.postflight
    deck.ender.position = deck.RESERVE_STATION
    if not deck.interact_reserve():
        problems.append("reserve interaction not playable")
    for line in range(deck.messages.size()):
        if not deck.interact_reserve():
            problems.append("reserve dialogue stopped early")
            break
    deck.ender.position = deck.ionia.position
    if not deck.request_local_berth_review():
        problems.append("real captain's berth request refused")
    for i in range(6):
        await process_frame
    if game.game_stage != "local_berth" or game.berth_review == null:
        problems.append("new actual local berth stage not entered")
    if not problems.is_empty():
        for err in problems:
            push_error("TSTSS_BERTH_GL_FAIL: " + err)
        quit(1)
        return
    var pilot = game.berth_review
    var initial: Image = await _image("01-player-command-before-approach")
    if not pilot.set_native_3d_review_enabled(true):
        problems.append("optional authentic 3D berth viewport failed to enable")
    var inset_on: Image = await _image("01b-original-source-3d-wake-enabled")
    if pilot.native_3d_review == null or pilot.native_3d_review.viewport == null:
        problems.append("real SubViewport unavailable")
    elif not pilot.native_3d_review.review_snapshot().get("ship_mesh_present", false):
        problems.append("original source 3D ship not present")
    if initial != null and inset_on != null and initial.get_data() == inset_on.get_data():
        problems.append("3D source render did not change genuine game framebuffer")
    if not pilot.set_native_3d_review_enabled(false):
        problems.append("3D view could not be disabled")
    var inset_off: Image = await _image("01c-original-source-3d-wake-disabled")
    if inset_off != null and inset_on != null and inset_off.get_data() == inset_on.get_data():
        problems.append("3D off state did not change genuine game framebuffer")
    if pilot.contact_observed or pilot.lines_secured or game.session.safe_local_berth_recorded:
        problems.append("3D visual toggle forged physics or story authorization")
    if not pilot.start_local_approach():
        problems.append("real 2D approach start invalid")
    # The GL runner may render many frames per fixed physics tick. Wait on
    # real SceneTree.physics_frame, never confuse video FPS with contact.
    for tick in range(800):
        await physics_frame
        if pilot.contact_observed:
            break
    if not pilot.contact_observed or not pilot.berth_area.overlaps_body(pilot.hull):
        problems.append("true berth Area2D contact not recorded")
    var contact: Image = await _image("02-independent-physical-berth-contact")
    for tick in range(160):
        await physics_frame
        if pilot.phase == "berth_ready":
            break
    if pilot.phase != "berth_ready" or not pilot.secure_lines():
        problems.append("real low-speed dwell/explicit line securing missing")
    for i in range(3):
        await process_frame
    if not game.session.safe_local_berth_recorded:
        problems.append("real sensor-guarded session did not receive berth")
    var secured: Image = await _image("03-player-secured-safe-local-berth")
    if initial == null or contact == null or secured == null:
        problems.append("missing actual source frame")
    elif initial.get_data() == contact.get_data():
        problems.append("physics displacement did not change source pixels")
    elif contact.get_data() == secured.get_data():
        problems.append("actual manual securing did not change visible gameplay")
    if not pilot.request_return():
        problems.append("player return action missing")
    for i in range(3):
        await process_frame
    if game.game_stage != "postflight" or game.postflight == null or not game.postflight.ender.player_controlled:
        problems.append("genuine player control not restored")
    game.queue_free()
    await process_frame
    if problems.is_empty():
        print("TSTSS_BERTH_GL_CAPTURE_PASS frames=5 genuine_gl=true",
            " independent_2d_area_contact=true original_splashdown=true",
            " player_lines=true no_story_reunion=true")
        quit(0)
    else:
        for err in problems:
            push_error("TSTSS_BERTH_GL_FAIL: " + err)
        quit(1)
