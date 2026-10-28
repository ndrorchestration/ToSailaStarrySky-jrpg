extends SceneTree
## G2 review-only visual deck trim, crew fit, hull ray and unchanged physics.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const Ship = preload("res://scripts/aureate_wake_metric_bridge_study.gd")
const Trim = preload("res://scripts/aureate_wake_deck_trim_review.gd")
const FirstWake = preload("res://scenes/first_wake_job_preview.tscn")
var count: int = 0
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    count += 1
    if not ok:
        problems.append(reason)

func _fit(ship: Node3D, point: Vector3) -> bool:
    var body := CapsuleShape3D.new()
    body.height = 1.74
    body.radius = 0.26
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = body
    query.transform = Transform3D(Basis(), point)
    query.collision_mask = Ship.COLLISION_LAYER
    query.margin = 0.001
    return ship.get_world_3d().direct_space_state.intersect_shape(query, 8).is_empty()

func _sightline(ship: Node3D, from: Vector3, toward: Vector3) -> Dictionary:
    var q := PhysicsRayQueryParameters3D.create(
        from, toward, Ship.COLLISION_LAYER)
    return ship.get_world_3d().direct_space_state.intersect_ray(q)

func _run() -> void:
    var ship = StudyScene.instantiate()
    root.add_child(ship)
    await process_frame
    await physics_frame
    await physics_frame
    var art = ship.get_node_or_null("AureateMaritimeRailArtReview") as Trim
    check(art != null and art.visible and
        Trim.ART_VERSION == "aureate-wake-deck-trim-study.v1",
        "review overlay must be real Node3D on isolated Godot ship")
    check(Trim.SOURCE_COLLISION_STUDY_PR == 549
        and Trim.DECK_SIDE_X == 1.11,
        "decorative art cannot assert different guard scale or source")
    check(art.physical_rail_visuals_hidden == 26,
        "replace only 26 visual mesh boxes, not physical guard bodies")
    check(art.visual_strands >= 220 and art.accent_members >= 15,
        "curved bronze cable, wooden rail cap and decorative hatch trim actually exist")

    for side in ["Port", "Starboard"]:
        check(not ship.get_node(side + "SafetyRail").visible,
            "old fence top-rail mesh is hidden, physical rail persists: " + side)
        check(ship.get_node(side + "SafetyRailBody") is StaticBody3D
            and ship.get_node(side + "RailInfill0Body") is StaticBody3D
            and ship.get_node(side + "RailInfill4Body") is StaticBody3D,
            "top and bottom hull guard colliders retained: " + side)
    check(not ship.get_node("ForedeckNoseRail").visible
        and ship.get_node("ForedeckNoseInfill0Body") is StaticBody3D,
        "bow visual fence replaced without removing physical bow guard")
    var previously_visible: int = art.visual_strands
    art.set_design_review_enabled(false)
    check(not art.visible
        and ship.get_node("PortRailInfill0").visible
        and ship.get_node("ForedeckNoseRail").visible,
        "legacy reference design can be restored visually for same-pose A/B")
    art.set_design_review_enabled(true)
    check(art.visible and not ship.get_node("PortRailInfill0").visible
        and art.visual_strands == previously_visible,
        "new maritime art returns with no generated-node or collision drift")

    for station in [
        ["port_cabin_crew", Vector3(-0.55, 1.05, 2.10)],
        ["starboard_cabin_crew", Vector3(0.55, 1.05, 2.10)],
        ["helm_centre", Vector3(0.0, 1.05, -1.45)],
        ["open_deck_centre", Vector3(0.0, 1.05, -4.10)]
    ]:
        check(_fit(ship, station[1]),
            "adult capsule test occupies designated isolated station: " + station[0])
    check(Vector3(-0.55, 0, 2.10).distance_to(
        Vector3(0.55, 0, 2.10)) > 0.52,
        "two separate cabin stations have adult capsule centre clearance")
    for height_m in Trim.INFILL_HEIGHTS:
        var side_hit: Dictionary = _sightline(ship,
            Vector3(0.72, height_m, -4.25),
            Vector3(1.48, height_m, -4.25))
        check(not side_hit.is_empty() and
            str(side_hit["collider"].name).contains("StarboardRailInfill"),
            "physical guard remains collidable after all art changes at " + str(height_m))

    ship.set_hatch_open(true)
    await physics_frame
    for x in [-0.38, 0.0, 0.38]:
        check(_sightline(ship, Vector3(x, 1.56, -1.48),
            Vector3(x, 1.56, -4.84)).is_empty(),
            "open helm sightline toward exposed bow remains clear x=" + str(x))
    ship.set_hatch_open(false)
    await physics_frame
    check(not _sightline(ship, Vector3(0.0, 1.56, -1.48),
        Vector3(0.0, 1.56, -4.84)).is_empty(),
        "closed hatch physically interrupts clear forward view")
    ship.set_hatch_open(true)
    await physics_frame
    check(_sightline(ship, Vector3(0.0, 1.56, -1.48),
        Vector3(0.0, 1.56, -4.84)).is_empty(),
        "normal foredeck view restored by reopening actual hatch")

    var chapter = FirstWake.instantiate()
    root.add_child(chapter)
    await process_frame
    var saved: Dictionary = chapter.export_revised_checkpoint()
    var before: Dictionary = chapter.opening.snapshot()
    check(chapter.opening.active_party_ids == ["ender"]
        and not chapter.ship_spaces_handoff.visible,
        "decorative 3D ship is not present in the playable Chapter I first scene")
    check(chapter.opening.snapshot() == before
        and chapter.export_revised_checkpoint() == saved
        and chapter.resonance_status_label.text.contains("LOCKED"),
        "new visual art cannot alter recruitment, save or magic authority")
    chapter.queue_free()
    ship.queue_free()
    await process_frame
    if problems.is_empty():
        print("AUREATE_WAKE_ARCHITECTURE_PASS checks=", count,
            " guard_collision=UNCHANGED",
            " walk_stations=REVIEW_ONLY",
            " art=TIMBER_BRASS",
            " production=BLOCKED")
        quit(0)
    else:
        for problem in problems:
            push_error("AUREATE_WAKE_ARCHITECTURE_FAIL: " + problem)
        quit(1)
