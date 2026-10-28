extends SceneTree
## Checks visible portrait provenance and authentic dialog speaker changes, not fake story progress.
const Game = preload("res://scenes/first_wake_game.tscn")
const Deck = preload("res://scenes/first_wake_postflight_game.tscn")
var failures: Array[String] = []
var checks: int = 0

func verify(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)

func _initialize() -> void:
    call_deferred("_run")

func _inject(actor) -> void:
    var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
    image.fill(Color("#cba982"))
    var texture := ImageTexture.create_from_image(image)
    actor.set_test_texture("ENDER", texture)
    actor.set_test_texture("IONIA", texture)

func _run() -> void:
    verify(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "normal First Wake entry not preserved")
    var game = Game.instantiate()
    root.add_child(game)
    await process_frame
    verify(game.job != null and game.postflight == null, "game must begin at job/flyer")
    var job = game.job
    var a = job.portrait_preview
    verify(a != null and not a.visible, "new portrait overlay must begin hidden")
    verify(a.snapshot().get("save_mutation") == false, "portrait has no save authority")
    verify(a.snapshot().get("party_mutation") == false, "portrait has no party authority")
    verify(a.mouse_filter == Control.MOUSE_FILTER_IGNORE, "cannot intercept input")
    verify(a.position == Vector2(704, 269) and a.size == Vector2(236, 258),
        "portrait card does not intrude on dialogue footer")
    verify(a.visual.size == Vector2(216, 216) and
        a.visual.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
        "source portrait must remain square and uncropped")
    verify(a.snapshot().get("source_aspect_preserved") == true,
        "source aspect provenance contract not set")
    verify(not a.display_dialogue_line("LYRA: testing") and not a.visible,
        "later protagonist reveal must fail closed")
    verify(not a.display_dialogue_line("IONIA / ENDER: mixed"),
        "unknown mixed speakers must fail closed")
    _inject(a)
    job.ender.position = job.FLYER_POSITION
    verify(job.interact(), "actual job flyer should open")
    verify(job.dialogue_open and a.visible and a.current_speaker == "ENDER",
        "Ender face follows authentic flyer dialogue")
    while job.dialogue_open:
        verify(job.interact(), "actual flyer dialogue should continue")
    verify(job.flyer_read and not a.visible, "portrait hides after actual flyer close")
    job.ender.position = job.IONIA_DOCK_POSITION
    verify(job.interact(), "actual Ionia job interview should open")
    verify(a.visible and a.current_speaker == "IONIA", "Ionia face follows first actual interview line")
    verify(job.interact(), "actual interview advances to Ender")
    verify(a.visible and a.current_speaker == "ENDER", "portrait switches by dialogue speaker")
    a.set_portraits_enabled(false)
    job._sync_presentation()
    verify(not a.visible, "V toggle can disable portrait independent of story")
    a.set_portraits_enabled(true)
    job._sync_presentation()
    verify(a.visible and a.current_speaker == "ENDER", "portrait toggle restores current line")
    verify(game.session.opening.active_party_ids == ["ender"], "visuals did not recruit Ionia")
    # The deck is a review-only isolated presentation fixture; no fake landing or game transition.
    var deck = Deck.instantiate()
    root.add_child(deck)
    await process_frame
    verify(deck.portrait_preview != null and not deck.portrait_preview.visible,
        "postflight portrait begins hidden")
    _inject(deck.portrait_preview)
    deck.reserve_dialogue_open = true
    deck.dialogue_index = 0
    deck._sync_ui()
    verify(deck.portrait_preview.current_speaker == "ENDER", "postflight line 1 is Ender")
    deck.dialogue_index = 1
    deck._sync_ui()
    verify(deck.portrait_preview.current_speaker == "IONIA", "postflight line 2 is Ionia")
    deck.reserve_dialogue_open = false
    deck._sync_ui()
    verify(not deck.portrait_preview.visible, "postflight portrait hides outside dialogue")
    verify(not deck.inspected_station, "portrait test never inspects reserve")
    verify(game.session.opening.active_party_ids == ["ender"], "visuals did not change party")
    deck.queue_free()
    game.queue_free()
    await process_frame
    if failures.is_empty():
        print("TSTSS_FIRST_WAKE_CREATOR_PORTRAIT_PASS checks=", checks,
            " authentic_dialogue=true intro_order=true assets_optional=true no_story_write=true")
        quit(0)
    else:
        for error in failures:
            push_error("TSTSS_FIRST_WAKE_CREATOR_PORTRAIT_FAIL: " + error)
        quit(1)
