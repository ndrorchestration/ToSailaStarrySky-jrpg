extends SceneTree
## Cross-branch native contract proof. A readable preview is NOT a playable Art.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const OldCrossing = preload("res://scripts/first_wake_chapter1_state.gd")
const Battle = preload("res://scripts/tidebound_promise_review.gd")
const Composite = preload("res://scripts/first_wake_resonance_composite_preflight.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")
const Catalog = preload("res://scripts/party_resonance_catalog.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var checker = Composite.new()
    var story = Opening.new()
    var trial = Battle.new()

    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if not trial.grant_training_access(Battle.ART_ID).get("ok", false):
        _fail("explicit early lab grant rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    var illegal: Dictionary = checker.try_execute(story, trial)
    if illegal.get("canExecute", true) or illegal.get("reason", "") != "production_art_authority_not_implemented":
        _fail("executing composite adapter unexpectedly authorized")
        return
    if not _deny(checker, OldCrossing.new(), trial, "unrecognized_story_contract"):
        return
    if not _deny(checker, {"step": "family_reunion", "active_party_ids": ["ender", "ionia", "lyra"]}, trial, "unrecognized_story_contract"):
        return
    if not _deny(checker, story, {"reviewOnly": true, "phase": "player"}, "unrecognized_training_fixture"):
        return

    if not story.accept_ionia_job():
        _fail("creator-directed Ionia recruitment rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if not story.complete_engineering_checks():
        _fail("engineering transition rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if not story.begin_test_flight():
        _fail("test flight transition rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if not story.record_engine_failure(true, true, true):
        _fail("engineering fault evidence rejected")
        return
    if not story.complete_ocean_splashdown(true, true):
        _fail("seaworthy ocean-contact evidence rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if not story.inspect_postflight_reserve(true):
        _fail("postflight fuel evidence rejected")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return
    if story.introduce_lyra_and_talen(false):
        _fail("unsafe reunion accepted")
        return
    if not _deny(checker, story, trial, "story:lyra_not_joined"):
        return

    if not story.introduce_lyra_and_talen(true):
        _fail("safe Lyra/Talen introduction rejected")
        return
    var no_grant = Battle.new()
    if not _deny(checker, story, no_grant, "training:art_not_granted_for_review"):
        return
    if not no_grant.grant_training_access(Battle.ART_ID).get("ok", false):
        _fail("post-reunion training grant rejected")
        return

    var story_before: Dictionary = story.snapshot()
    var trial_before: Dictionary = no_grant.snapshot()
    var preflight: Dictionary = checker.inspect(story, no_grant)
    if not bool(preflight.get("canPreview", false)):
        _fail("post-reunion + explicit-grant review preflight denied: " + str(preflight.get("reason", "")))
        return
    if preflight.get("canExecute", true) or preflight.get("canUnlockArt", true):
        _fail("review preflight laundered roster/grant into execution rights")
        return
    if preflight.get("storyStep", "") != "family_reunion" or preflight.get("artId", "") != Battle.ART_ID:
        _fail("cross-system provenance was not bound")
        return
    var receipts = preflight.get("reservationPreview", [])
    if not (receipts is Array) or receipts.size() != 2:
        _fail("missing both atomic preview reservation receipts")
        return
    if receipts[0].get("actorId", "") != "ender" or receipts[1].get("actorId", "") != "lyra":
        _fail("reservation not bound to expected participants")
        return
    if story.snapshot() != story_before or no_grant.snapshot() != trial_before:
        _fail("composite preflight mutated story or trial")
        return
    if checker.try_execute(story, no_grant).get("canExecute", true):
        _fail("story presence plus grant was enough to execute")
        return
    if not Authority.new().validate() or Authority.new().can_take_formula_turn("lyra"):
        _fail("original native party authority drifted")
        return
    if Catalog.new().try_execute(Battle.ART_ID, {}).get("canExecute", true):
        _fail("design-only catalog unexpectedly executed")
        return

    # Tampered roster cannot be laundered through an otherwise valid grant.
    story.active_party_ids.erase("ionia")
    if not _deny(checker, story, no_grant, "story:story_roster_mismatch"):
        return
    story.active_party_ids.insert(1, "ionia")
    story.safe_reunion_confirmed = false
    if not _deny(checker, story, no_grant, "story:reunion_evidence_mismatch"):
        return
    story.safe_reunion_confirmed = true
    if story.snapshot() != story_before:
        _fail("story-model repair after negative tests changed its state")
        return

    # Review-only balance/cost gates remain independently necessary after join.
    no_grant.reset()
    if not _deny(checker, story, no_grant, "training:art_not_granted_for_review"):
        return
    if not no_grant.grant_training_access(Battle.ART_ID).get("ok", false):
        _fail("reset regrant failed")
        return
    if not no_grant.configure_fixture("lyra", {"focus": 0}):
        _fail("zero-focus fixture setup failed")
        return
    if not _deny(checker, story, no_grant, "training:insufficient_review_focus:lyra"):
        return
    no_grant.reset()
    if not no_grant.grant_training_access(Battle.ART_ID).get("ok", false):
        _fail("new reservation fixture setup failed")
        return
    if not no_grant.activate().get("ok", false):
        _fail("isolated lab cast unavailable")
        return
    if not _deny(checker, story, no_grant, "training:wrong_phase"):
        return
    if checker.try_execute(story, no_grant).get("canExecute", true):
        _fail("spent lab state granted production execution")
        return
    print("TSTSS_RESONANCE_COMPOSITE_PREFLIGHT_PASS: revised chronology, explicit lab grant, two-party cost preview, zero execution authority")
    quit(0)

func _deny(checker: Variant, story: Variant, trial: Variant, expected: String) -> bool:
    var result: Dictionary = checker.inspect(story, trial)
    if result.get("canPreview", true) or result.get("canExecute", true) or result.get("canUnlockArt", true):
        _fail("denied preflight unexpectedly enabled Art for " + expected)
        return false
    if result.get("reason", "") != expected:
        _fail("expected " + expected + "; got " + str(result.get("reason", "")))
        return false
    return true

func _fail(reason: String) -> void:
    push_error("TSTSS_RESONANCE_COMPOSITE_PREFLIGHT_FAIL: " + reason)
    quit(1)
