extends SceneTree
## Native admission contract. Does not assert artistic approval or combat readiness.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const MagicVFX = preload("res://scripts/magic_vfx.gd")
const Review = preload("res://scenes/magic_vfx_showcase.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if Catalog.CHARACTER_ORDER != ["ender", "lyra", "ionia", "reson", "aepex"]:
        _fail("creator-approved protagonist affinity order drift")
        return
    var affinities := ["Spirit", "Water", "Earth", "Fire", "Air"]
    for i in range(5):
        var identity: String = Catalog.CHARACTER_ORDER[i]
        if str(Catalog.profile(identity).get("affinity", "")) != affinities[i]:
            _fail("affinity drift " + identity)
            return
        var texture_path := "res://art-review/magic_vfx/" + str(Catalog.profile(identity)["glyph"]) + ".svg"
        if not ResourceLoader.exists(texture_path):
            _fail("missing imported sigil: " + texture_path)
            return
    if Catalog.has_character("dreaming") or not Catalog.profile("unknown").is_empty():
        _fail("unauthorized affinity admitted")
        return
    if Catalog.phase_at(0.0) != "anticipation" or Catalog.phase_at(0.2) != "formation" or Catalog.phase_at(0.5) != "release" or Catalog.phase_at(0.6) != "impact" or Catalog.phase_at(1.0) != "aftermath":
        _fail("cinematic phase timing drift")
        return
    var node := MagicVFX.new()
    root.add_child(node)
    await process_frame
    if node.character_id != "ender" or not node.reduced_motion or not node.finished:
        _fail("motion-sensitive default not static")
        return
    if node.play_affinity("unsupported", false) or node.character_id != "ender":
        _fail("unknown character changed active visual")
        return
    for identity in Catalog.CHARACTER_ORDER:
        if not node.play_affinity(identity, false) or node.reduced_motion or node.finished:
            _fail("active review effect missing " + identity)
            return
        node._process(0.55)
        if node.elapsed <= 0.0:
            _fail("timeline did not advance " + identity)
            return
        node.set_reduced_motion(true)
        if not node.reduced_motion or not node.finished or node.phase != "formation":
            _fail("motion reduction did not freeze meaningful static frame")
            return
    node.queue_free()
    var review = Review.instantiate()
    root.add_child(review)
    await process_frame
    if review.active_index != 0 or not review.reduced_motion:
        _fail("showcase defaults drift")
        return
    if not review.choose(4) or review.effect.character_id != "aepex":
        _fail("gallery selection failed")
        return
    if review.choose(-1) or review.choose(5):
        _fail("out-of-range gallery selection accepted")
        return
    review.toggle_reduced_motion()
    if review.reduced_motion or review.effect.reduced_motion:
        _fail("animation opt-in toggle failed")
        return
    review.queue_free()
    await process_frame
    print("STARRY_SKY_MAGIC_VFX_PASS: five creator affinities, five cinematic phases, imported sigils, visual-only controls, motion-safe default")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_MAGIC_VFX_FAIL: " + reason)
    quit(1)
