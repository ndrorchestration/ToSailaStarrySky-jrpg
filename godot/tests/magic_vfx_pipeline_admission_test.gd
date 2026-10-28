extends SceneTree
## Verifies that preview visuals can flow into the real Godot Chapter I dock,
## yet cannot add formula actions, combat, story triggers, or save mutations.
const Contract = preload("res://scripts/magic_vfx_preview_contract.gd")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")
const Review = preload("res://scenes/magic_vfx_chapter1_camera_review.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("STARRY_SKY_VFX_ADMISSION_FAIL: " + message)
    quit(1)

func _request(identity: String, phase_index: int = 1, quality: int = 0) -> Dictionary:
    return {"channel":Contract.CHANNEL, "identity":identity, "phaseIndex":phase_index, "quality":quality, "reducedMotion":true}

func _run() -> void:
    var contract = Contract.new()
    if not Authority.new().validate():
        _fail("battle authorization regression")
        return
    for identity in Catalog.CHARACTER_ORDER:
        for phase_index in range(5):
            var plan: Dictionary = contract.render_plan(_request(identity, phase_index))
            if plan.is_empty() or plan["identity"] != identity or plan["phaseIndex"] != phase_index:
                _fail("visual catalog not admitted: " + identity)
                return
            if not plan["renderOnly"] or plan["canExecute"] or plan["canGrantMagic"] or plan["canMutateStory"] or plan["canMutateSave"]:
                _fail("non-authority invariant broken")
                return
    for quality in range(3):
        var q: Dictionary = contract.render_plan(_request("ender", 1, quality))
        if q.is_empty() or q["quality"] != quality:
            _fail("visual quality pipeline broken")
            return
    var denied: Array[Dictionary] = [
        _request("unregistered"), _request("lyra", -1), _request("lyra", 5),
        _request("ender", 1, -1), _request("ender", 1, 3),
        {"channel":"combat", "identity":"ender", "phaseIndex":1, "quality":0, "reducedMotion":true},
        {"channel":"story_energy_auto", "identity":"lyra", "phaseIndex":1, "quality":0, "reducedMotion":true},
        {"channel":"resonance", "identity":"lyra", "phaseIndex":1, "quality":0, "reducedMotion":true},
        {"channel":"manual_visual_review", "identity":"ender", "phaseIndex":1, "quality":0, "reducedMotion":true, "spellId":"sharedDream"},
        {"channel":"manual_visual_review", "identity":"ender", "phaseIndex":1, "quality":0, "reducedMotion":true, "execute":true},
        {"channel":"manual_visual_review", "identity":"ender", "phaseIndex":1, "quality":0},
    ]
    for item in denied:
        if not contract.render_plan(item).is_empty():
            _fail("invalid or unauthorized request admitted: " + str(item))
            return
    var wrong: Dictionary = _request("ender")
    wrong["phaseIndex"] = 2.4
    if not contract.render_plan(wrong).is_empty():
        _fail("noninteger timing accepted")
        return
    wrong = _request("ender")
    wrong["reducedMotion"] = "false"
    if not contract.render_plan(wrong).is_empty():
        _fail("unsafe motion input accepted")
        return
    if Authority.new().can_use_formula_action("lyra", "staffStrike") or Authority.new().can_use_formula_action("ender", "sharedDream"):
        _fail("visual preview granted combat powers")
        return
    var scene = Review.instantiate()
    root.add_child(scene)
    await process_frame
    var state: Dictionary = scene.world.chapter.snapshot()
    var save: Dictionary = scene.world.export_save_snapshot()
    var pos: Vector2 = scene.world.ender.global_position
    for identity in Catalog.CHARACTER_ORDER:
        var index: int = Catalog.CHARACTER_ORDER.find(identity)
        if not scene.choose_affinity(index) or scene.last_visual_plan.get("identity", "") != identity:
            _fail("native scene did not consume the validation plan")
            return
        for phase_index in range(5):
            if not scene.seek_phase(phase_index) or scene.last_visual_plan.get("phaseIndex", -1) != phase_index:
                _fail("native phase transition failed")
                return
            if scene.effect.phase != Catalog.PHASES[phase_index]:
                _fail("renderer and planner phase mismatch")
                return
    if scene.world.chapter.snapshot() != state or scene.world.export_save_snapshot() != save:
        _fail("visual admission modified Chapter I progress or save")
        return
    if scene.world.ender.global_position != pos or scene.world.contacts["elder_farmer"].visible:
        _fail("visual admission moved Ender or revealed Ionia")
        return
    scene.queue_free()
    await process_frame
    print("STARRY_SKY_VFX_ADMISSION_PASS: 25 visual configurations, strict denial, native Chapter I consumer and preserved battle/quest/save")
    print("STARRY_SKY_VFX_ADMISSION_MAIN_MERGE=NOT_PERFORMED")
    quit(0)
