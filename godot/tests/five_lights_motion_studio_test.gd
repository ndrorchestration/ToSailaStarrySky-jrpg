extends SceneTree
const Studio = preload("res://scenes/five_lights_motion_studio.tscn")
const CAST: Array[String] = ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]
const FACINGS: Array[String] = ["south", "west", "north", "east"]
var failures: int = 0
func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        push_error("TSTSS_FIVE_LIGHTS_STUDIO_FAIL: " + description)

func _run() -> void:
    check(String(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/first_wake_game.tscn", "main scene changed")
    var stage = Studio.instantiate()
    root.add_child(stage)
    await process_frame
    stage.keyboard_enabled = false
    check(stage.cast_actors.size() == 5, "five required")
    check(stage.selected_index == 1, "Ender selected")
    var scenery: Node = stage.get_node_or_null("OriginalReviewScenographyNonColliding")
    check(scenery != null and not (scenery is CollisionObject2D), "decorative stage cannot acquire collision authority")
    check(stage.get_node_or_null("NonCanonicalFiveLightsSourceReview") != null, "visual actors must remain in isolated stage")
    for id in CAST:
        var actor = stage.cast_actors.get(id)
        check(actor != null, "missing " + id)
        if actor == null:
            continue
        check(actor is CharacterBody2D and actor.ready_to_review, "native actor not imported " + id)
        check(actor.sprites.size() == 4, "four independent facings required " + id)
        for direction in FACINGS:
            var sprite: Sprite2D = actor.sprites.get(direction) as Sprite2D
            check(sprite != null, "missing " + id + "/" + direction)
            if sprite == null:
                continue
            check(sprite.texture != null and sprite.hframes == 6 and not sprite.flip_h, "six-phase original source " + id + "/" + direction)
            check(sprite.texture.get_height() * sprite.scale.y >= 115.0, "sprite collapsed below useful stage-review height " + id + "/" + direction)
            check(actor.set_facing(direction), "facing rejected " + id + "/" + direction)
            check(sprite.visible, "facing hidden " + id + "/" + direction)
        check(not actor.set_facing("invalid"), "invalid facing accepted " + id)
        check(actor.get_node_or_null("RealFootCollision") != null, "real collision absent " + id)
    var ender = stage.cast_actors["Ender"]
    ender.reset_at(Vector2(307, 441))
    var initial: Vector2 = ender.global_position
    ender.set_motion(Vector2.RIGHT)
    for step in range(30):
        await physics_frame
    ender.set_motion(Vector2.ZERO)
    await physics_frame
    check(ender.global_position.x > initial.x + 15.0, "no actual physics travel")
    check(ender.distance_travelled > 15.0 and ender.facing == "east", "travel was not converted to east-facing animation")
    check(ender.phase == 0, "idle animation did not settle")
    check(stage.cast_actors["Ionia"].global_position == Vector2(134, 441), "unselected Ionia translated")
    check(not stage.reduced_motion, "ambient reduced-motion default changed")
    var frozen_position: Vector2 = ender.global_position
    stage.toggle_pose_inspector()
    check(stage.pose_inspector_enabled, "pose mode not enabled")
    check(ender.pose_preview_enabled, "chosen actor was not frozen for pose inspection")
    check(stage.scrub_pose(4), "manual source frame 5 rejected")
    check(ender.phase == 4 and ender.sprites[ender.facing].frame == 4, "source atlas not showing frame 5")
    ender.set_motion(Vector2.RIGHT)
    for tick in range(12):
        await physics_frame
    check(ender.global_position == frozen_position, "pose inspector illegally translated native body")
    stage.toggle_pose_inspector()
    check(not stage.pose_inspector_enabled and not ender.pose_preview_enabled and ender.phase == 0,
        "pose mode was not reversibly cleared")
    check(stage.ambience != null and stage.ambience.shader != null, "review shader is missing")
    check(stage.cast_actors["Lyra"].motion == Vector2.ZERO, "unselected character has movement intent")
    stage.queue_free()
    await process_frame
    if failures == 0:
        print("TSTSS_FIVE_LIGHTS_STUDIO_PASS: five=5 directions=4 phases=6 native_motion=true story_untouched=true")
    quit(0 if failures == 0 else 1)
