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
            check(e.creator_standee_variant in ["matte_v3", "source_v1"] and
                i.creator_standee_variant in ["matte_v3", "source_v1"],
                "source-custody revision must be named")
            check(e.creator_standee_source_path() != "" and i.creator_standee_source_path() != "",
                "source revision path must exist")
            check(e.creator_standee.texture.get_size().y == 535 and
                i.creator_standee.texture.get_size().y == 535,
                "correct full-body source proportions")
            check(e.creator_standee.hframes == 1 and i.creator_standee.hframes == 1,
                "must not pretend static art is six-frame animation")
            for actor in [e, i]:
                check(actor.creator_standee.scale.is_equal_approx(Vector2.ONE * 0.21),
                    "source-actor silhouette must render at intended scale")
                check(absf(actor.creator_standee.position.y +
                    actor.creator_standee.texture.get_height() * actor.creator_standee.scale.y * 0.5) < 0.01,
                    "boots must remain grounded at actor foot origin")
                check(actor.creator_standee.material is ShaderMaterial and
                    actor.creator_standee.material.shader != null,
                    "source figure must use bounded cinematic-coastal lighting")
                # The existing actor creates an unnamed CollisionShape2D at runtime.
                # Check its TYPE, rather than inventing a new canonical node name.
                var original_collider: CollisionShape2D = null
                for child in actor.get_children():
                    if child is CollisionShape2D:
                        original_collider = child
                        break
                check(original_collider != null and original_collider.shape is CircleShape2D and
                    absf(original_collider.shape.radius - 10.0) < 0.01,
                    "source visuals must not change existing physics footprint")
            check(not e.walk_review_sprite.visible and not i.ionia_front_walk_sprite.visible,
                "rejected provisional sprites must be hidden during source view")
        if e.has_creator_standee() and i.has_creator_standee():
            var light_key := InputEventKey.new()
            light_key.keycode = KEY_L
            light_key.pressed = true
            dock._unhandled_input(light_key)
            check(not e.creator_field_lighting_enabled and not i.creator_field_lighting_enabled,
                "actual L-key must disable both visual-only lighting materials")
            check(e.creator_standee.material == null and i.creator_standee.material == null,
                "lighting A/B OFF must preserve unmodified original texture")
            dock._unhandled_input(light_key)
            check(e.creator_field_lighting_enabled and i.creator_field_lighting_enabled,
                "actual L-key must restore both cinematic light previews")
            check(e.creator_standee.material is ShaderMaterial and
                i.creator_standee.material is ShaderMaterial,
                "lighting A/B ON must rebind cinematic source material")
        # Exercise the actual player's P-key hook, not only low-level actor API.
        e.enable_creator_standee(false)
        i.enable_creator_standee(false)
        var p_key := InputEventKey.new()
        p_key.keycode = KEY_P
        p_key.pressed = true
        dock._unhandled_input(p_key)
        if e.has_creator_standee() and i.has_creator_standee():
            check(e.creator_standee_enabled and i.creator_standee_enabled,
                "real input P did not turn on both source art candidates")
            check("STATIC" in dock.party_label.text,
                "HUD misrepresented source as completed walk animation")
        else:
            check(not e.creator_standee_enabled and not i.creator_standee_enabled,
                "missing private art caused partial swap")
        dock._unhandled_input(p_key)
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
