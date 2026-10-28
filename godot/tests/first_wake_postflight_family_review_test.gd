extends SceneTree
## Physically walkable safe-family and investigation scene after existing revised
## story chronology. Safe berth itself is a staged review, not real geography.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Family = preload("res://scenes/first_wake_postflight_family_review.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _postflight_story():
    var story = Opening.new()
    story.accept_ionia_job()
    story.complete_engineering_checks()
    story.begin_test_flight()
    story.record_engine_failure(true, true, true)
    story.complete_ocean_splashdown(true, true)
    story.inspect_postflight_reserve(true)
    return story

func _verify() -> void:
    var scene = Family.instantiate()
    var early = Opening.new()
    if scene.configure_after_safe_review(early, true, true, true, true):
        _fail("hiring-stage story admitted to postflight family meetup")
        return
    var story = _postflight_story()
    if scene.configure_after_safe_review(story, false, true, true, true) or scene.configure_after_safe_review(story, true, false, true, true):
        _fail("reunion before verified water contact or settled flotation")
        return
    if scene.configure_after_safe_review(story, true, true, false, true) or scene.configure_after_safe_review(story, true, true, true, false):
        _fail("reunion before reserve diagnosis and explicit safe-berth gate")
        return
    if scene.configure_after_safe_review({"step": "postflight_diagnosis"}, true, true, true, true):
        _fail("forged story contract admitted")
        return
    if not scene.configure_after_safe_review(story, true, true, true, true):
        _fail("valid reviewed postflight handoff refused")
        return
    if scene.configure_after_safe_review(story, true, true, true, true):
        _fail("duplicate family handoff accepted")
        return

    root.add_child(scene)
    await process_frame
    if scene.ender == null or not scene.ender.walk_review_enabled:
        _fail("postflight Ender is not walkable")
        return
    if scene.review_snapshot()["lyra_joined"] or story.active_party_ids != ["ender", "ionia"]:
        _fail("Lyra prematurely recruited when scene was opened")
        return
    if scene.interact():
        _fail("family dialogue activated remotely")
        return
    if story.form_working_fuel_theory() or story.record_clue("phase_readings"):
        _fail("analysis was allowed before the family introduction")
        return
    scene.ender.position = scene.TALEN_POSITION
    if not scene.interact() or not scene.dialogue_open:
        _fail("Talen's optional block-built ship not interactable")
        return
    if not _finish(scene) or not scene.child_block_ship_viewed:
        _fail("Talen's optional everyday conversation did not complete")
        return
    if "talen" in story.active_party_ids or "lyra" in story.active_party_ids:
        _fail("Talen or Lyra recruited prematurely through optional block scene")
        return
    scene.ender.position = scene.LYRA_POSITION
    if not scene.interact() or not scene.dialogue_open:
        _fail("safe Lyra/Ionia/Ender reunion dialogue unavailable")
        return
    if scene.ender.player_controlled or "lyra" in story.active_party_ids:
        _fail("Lyra joined early, or Ender moved during mandatory family dialogue")
        return
    if not _finish(scene):
        _fail("safe family introduction did not finish")
        return
    if story.active_party_ids != ["ender", "ionia", "lyra"] or scene.scene_phase != "investigation":
        _fail("Lyra did not join second after completed family dialogue")
        return
    if story.active_party_ids.has("talen") or not scene.review_snapshot()["child_noncombat"]:
        _fail("child entered combat/story party")
        return
    if scene.interact() != true:
        _fail("Lyra's independent listening observation was not accessible")
        return
    if not _finish(scene) or "lyra_observation" not in story.clues:
        _fail("Lyra's post-reunion sensory clue not recorded")
        return
    scene.ender.position = scene.THEORY_TABLE
    if scene.interact() or story.step_key() != "family_reunion":
        _fail("single clue unlocked fuel theory")
        return
    scene.ender.position = scene.PHASE_CHART
    if not scene.interact() or not _finish(scene) or "phase_readings" not in story.clues:
        _fail("Ender's phase clue missing")
        return
    if story.clues.size() != 2:
        _fail("two independently collected clues not recognized")
        return
    scene.ender.position = scene.THEORY_TABLE
    if not scene.interact() or not scene.dialogue_open:
        _fail("two-clue shared theory conversation missing")
        return
    if story.step_key() != "family_reunion":
        _fail("working theory granted before the crew finished dialogue")
        return
    if not _finish(scene) or story.step_key() != "working_theory":
        _fail("three-adult collaborative theory did not complete")
        return
    if story.snapshot()["fuel_explanation_status"] != "hypothesis_only" or scene.review_snapshot()["real_return_route_verified"]:
        _fail("theory incorrectly claimed fuel formula or physical recovery route")
        return
    if scene.interact() or scene.review_snapshot()["combat_art_granted"] or scene.review_snapshot()["canonical_geography_assigned"]:
        _fail("working theory repeated or fabricated combat/geography authority")
        return
    scene.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_POSTFLIGHT_FAMILY_PASS: safe-mooring gate, Talen blocks and noncombat, Lyra second only after dialogue, independent clues, two-of-three shared hypothesis")
    quit(0)

func _finish(scene: Node) -> bool:
    var budget := 18
    while scene.dialogue_open and budget > 0:
        if not scene.interact():
            return false
        budget -= 1
    return not scene.dialogue_open and budget > 0

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_POSTFLIGHT_FAMILY_FAIL: " + reason)
    quit(1)
