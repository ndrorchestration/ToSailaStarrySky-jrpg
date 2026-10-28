extends SceneTree
const Music = preload("res://scripts/first_wake_existing_music_cue_contract.gd")
const StoryProjection = preload("res://scripts/first_wake_pipeline_projection.gd")
const JobScene = preload("res://scenes/first_wake_job_preview.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var index: Dictionary = Music.inventory()
    if not index.get("ok", false) or index["tracks"].size() != 5:
        _fail("archived five-track source manifest was not readable")
        return
    var expected_sha := {
        "skyward_arpeggio": "7ac5fe9c2ee0bc8d0cbfa36441dbb7783dbe2ef0cc5e2ee665086a527a7bc350",
        "amonigio_umulula": "bce86fc575323b99573e420dcb6c0d19bfe1eb8e6ba637edc2b72c1edf20cd98",
        "nocturnal_resolve": "c8a35d42762705011f8a9eeefebea91736b333677a9b1117087490bbf0dbc65c",
        "solar_punk_airship": "d5d1561c1ef056978342732e363df5411860611739fb485bb707c6e98800335c",
        "open_sky_signal": "831a195d060e22107c9b38ac1655b0ae879485e87eba601d41d3af46d8518484",
    }
    for item in index["tracks"]:
        if not expected_sha.has(item["id"]) or item["sha256"] != expected_sha[item["id"]]:
            _fail("historic music SHA identity drift: " + str(item.get("id", "")))
            return
    var job = JobScene.instantiate()
    root.add_child(job)
    await process_frame
    var cue: Dictionary = StoryProjection.project(job.opening)
    if not cue.get("ok", false):
        _fail("native story producer not available")
        return
    var title: Dictionary = Music.candidate(cue, "title_menu")
    var opening: Dictionary = Music.candidate(cue, "opening_cinematic")
    if not title.get("ok", false) or title.get("track_id", "") != "skyward_arpeggio":
        _fail("archival title track identity not preserved")
        return
    if not opening.get("ok", false) or opening.get("track_id", "") != "amonigio_umulula":
        _fail("opening music archival identity not preserved")
        return
    for item in [title, opening]:
        if item["may_autoplay"] or item["native_audio_playback_proven"] or item["public_streaming_authorized"] or item["scene_placement_approved"] or item["story_shanty_composition_verified"]:
            _fail("archival soundtrack was silently approved for new scene, playback, redistribution or Denith melody")
            return
        var live: Dictionary = Music.verify_local_audio(item)
        if live.get("ok", true) or live.get("status", "") != "missing_in_forward_godot" or live.get("may_play", true):
            _fail("missing native audio binary was incorrectly counted as playable")
            return
    for invalid_role in ["combat_danger", "ender_first_note_leitmotif", "world_airship_exploration", "denith_shanty"]:
        if Music.candidate(cue, invalid_role).get("ok", true):
            _fail("unearned or unapproved music role accepted: " + invalid_role)
            return
    if not job.opening.accept_ionia_job():
        _fail("native recruitment source failed")
        return
    var engineering: Dictionary = StoryProjection.project(job.opening)
    if not engineering.get("ok", false):
        _fail("Ionia-first story producer failed to yield engineering stage")
        return
    if Music.candidate(engineering, "title_menu").get("ok", true):
        _fail("title/menu track would continue automatically into engineering")
        return
    if not Music.candidate(engineering, "opening_cinematic").get("ok", false):
        _fail("existing opening music cannot be selected as candidate for engineering")
        return
    for bad in [
        _mutate(engineering, "authority", "production"),
        _mutate(engineering, "world_navigation_authorized", true),
        _mutate(engineering, "story_party", ["ender", "lyra"]),
        _mutate(engineering, "gameplay_combat_grants", ["invented_power"]),
    ]:
        if Music.candidate(bad, "opening_cinematic").get("ok", true):
            _fail("malformed producer record authorized a soundtrack candidate")
            return
    # A random non-audio temporary file must never pass archived MP3 identity.
    var bogus_path := "user://tstss_music_collision_preflight.bin"
    var test_file := FileAccess.open(bogus_path, FileAccess.WRITE)
    if test_file == null:
        _fail("cannot create isolated fake-media rejection fixture")
        return
    test_file.store_string("not an approved source recording")
    test_file.close()
    var corrupt := opening.duplicate(true)
    corrupt["expected_future_godot_path"] = bogus_path
    if Music.verify_local_audio(corrupt).get("ok", true):
        _fail("a forged resource location bypassed source-admission rule")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(bogus_path))
    job.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_FIVE_TRACK_AUDIO_PREFLIGHT_PASS: five historical original SHA identities, real story-cue producer, nonplaying title/opening candidates, missing Godot binaries denied, no combat/Ender/shanty privilege")
    quit(0)

func _mutate(source: Dictionary, field: String, value: Variant) -> Dictionary:
    var out: Dictionary = source.duplicate(true)
    out[field] = value
    return out

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_FIVE_TRACK_AUDIO_PREFLIGHT_FAIL: " + reason)
    quit(1)
