extends SceneTree
## Portable enemy-presentation contract, independent of the superseded
## Lyra-first Chapter I Crossing scene, party, quest, save and formulas.
## Verifies the existing provisional Wind Shear view as an isolated Godot
## CanvasItem. It does NOT authorize new enemy species or story placement.

const EnemyView = preload("res://scripts/first_wake_wind_shear_visual.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var art = EnemyView.new()
    root.add_child(art)
    await process_frame

    if art.visible or art.name == "CombatAuthority":
        _fail("standalone art must start hidden and remain presentation-only")
        return
    if art.atlas_texture == null or art.idle_atlas_texture == null:
        _fail("original combat and animated idle texture imports are required")
        return
    if art.atlas_texture.get_size() != Vector2(320, 92):
        _fail("combat sprite atlas dimensions changed")
        return
    if art.idle_atlas_texture.get_size() != Vector2(320, 92):
        _fail("idle sprite atlas dimensions changed")
        return
    if art.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
        _fail("enemy sprite scaling no longer uses nearest-neighbor")
        return

    # A future encounter adapter may decide *whether* this art is visible.
    # This test owns only an isolated visual, not party/combat authority.
    art.visible = true
    art.begin_encounter()
    art.set_process(false)
    if art.reaction_phase() != "idle" or art.analyzed or art.dissipated:
        _fail("new visual instantiation did not reset transient state")
        return
    for pose in range(4):
        art.visual_clock = float(pose) * EnemyView.IDLE_POSE_STEP_SECONDS + 0.01
        if art.authored_idle_frame() != pose:
            _fail("authored independent idle phase mismatch %d" % pose)
            return

    # No damage is inferred from selecting an action or observing a status.
    if art.register_resolved_damage(14, 14) or art.register_resolved_damage(0, -1):
        _fail("non-damage/invalid health falsely reported an impact")
        return
    if art.reaction_phase() != "idle":
        _fail("non-damaging observation generated an effect")
        return

    # Retaliation and actual HP loss have already been resolved by the
    # external controller. This script simply orders *visual* display.
    art.set_encounter_state(true, false, 1)
    if not art.analyzed or art.reaction_phase() != "gale":
        _fail("authorized analyzed/retaliation metadata not reflected")
        return
    if not art.register_resolved_damage(14, 5):
        _fail("actual observed health loss did not register hit feedback")
        return
    if art.reaction_phase() != "hit" or art.queued_gale_seconds <= 0.0:
        _fail("resolved hit did not precede already-resolved Gale effect")
        return
    for _step in range(6):
        art._process(0.05)
    if art.reaction_phase() != "gale":
        _fail("queued Gale presentation was not shown after hit effect")
        return
    for _step in range(8):
        art._process(0.05)
    if art.reaction_phase() != "idle":
        _fail("bounded visual aftereffects did not expire")
        return

    # Accessibility must restore an exact static pose, even if a future
    # integration remembers a nonzero interpolation clock.
    art.set_reduced_motion(true)
    art.visual_clock = 0.63
    art.set_encounter_state(false, false, 2)
    if art.reaction_phase() != "still" or art.authored_idle_frame() != 0:
        _fail("reduced-motion/static visual contract not enforced")
        return
    if art.gale_accent_seconds > 0.0 or art.queued_gale_seconds > 0.0:
        _fail("reduced-motion mode left a queued combat visual")
        return

    art.set_reduced_motion(false)
    art.set_encounter_state(true, true, 2)
    if art.reaction_phase() != "still" or not art.dissipated:
        _fail("cleared visual must not restart its idle/attack cycle")
        return
    art.begin_encounter()
    art.visible = false
    if art.analyzed or art.dissipated or art.last_enemy_turn != 0:
        _fail("visual reused stale encounter state")
        return

    art.queue_free()
    await process_frame
    print("TSTSS_ENEMY_VISUAL_PORTABILITY_PASS: atlas, idle, analyzed, actual hit, resolved Gale, reduced motion, reset; no Chapter I scene dependency")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_ENEMY_VISUAL_PORTABILITY_FAIL: " + reason)
    quit(1)
