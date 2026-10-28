extends SceneTree
## First production-source identity admission gate: STATIC source only, never animated field-pack.
const Game = preload("res://scenes/first_wake_game.tscn")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, what: String) -> void:
    checks += 1
    if not ok:
        failures.append(what)
        push_error("TSTSS_CREATOR_STANDEE_FAIL: " + what)

func _run() -> void:
    check(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "playable entry changed")
    var scene = Game.instantiate()
    root.add_child(scene)
    await process_frame
    var dock = scene.job
    check(dock != null and scene.postflight == null, "authentic dock starts")
    if dock != null:
        var e = dock.ender
        var i = dock.ionia
        check(e is CharacterBody2D and i is CharacterBody2D, "real physics actors retained")
        check(not e.creator_standee_enabled and not i.creator_standee_enabled, "must opt in")
        check(not e.enable_creator_standee(true) or e.has_creator_standee(),
            "Ender cannot claim absent art was enabled")
        check(not i.enable_creator_standee(true) or i.has_creator_standee(),
            "Ionia cannot claim absent art was enabled")
        if e.has_creator_standee() and i.has_creator_standee():
            check(e.creator_standee_enabled and i.creator_standee_enabled,
                "actual source previews enabled")
            check(e.creator_standee.texture.get_size().y == 535 and
                i.creator_standee.texture.get_size().y == 535,
                "correct full-body source proportions")
            check(e.creator_standee.hframes == 1 and i.creator_standee.hframes == 1,
                "must not pretend static art is six-frame animation")
            check(not e.walk_review_sprite.visible and not i.ionia_front_walk_sprite.visible,
                "rejected provisional sprites must be hidden during source view")
        check(e.enable_creator_standee(false) and i.enable_creator_standee(false),
            "P must always restore previous art")
        check(not e.creator_standee_enabled and not i.creator_standee_enabled,
            "disabled source art still visible")
        check(scene.session.opening.active_party_ids == ["ender"],
            "preview must not recruit Ionia or later protagonists")
        check(not scene.session.can_checkpoint(), "preview must not earn checkpoint")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("TSTSS_CREATOR_STANDEE_PASS checks=", checks,
            " native_actor=true opt_in=true static_only=true absent_asset_safe=true story_unchanged=true")
        quit(0)
    else:
        quit(1)
