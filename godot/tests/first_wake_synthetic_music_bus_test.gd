extends SceneTree
## Real native AudioStreamPlayer mechanics proof. Uses ORIGINAL GENERATED
## sine loop test signals, never the historical soundtrack files.
const Bus = preload("res://scripts/first_wake_synthetic_music_bus_review.gd")
const StoryProjection = preload("res://scripts/first_wake_pipeline_projection.gd")
const JobScene = preload("res://scenes/first_wake_job_preview.tscn")

const PROOF := {"source": "isolated_godot_synthetic_music_fixture", "synthetic_only": true, "explicit_start": true}

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var scene = JobScene.instantiate()
    root.add_child(scene)
    var bus = Bus.new()
    bus.name = "IsolatedFirstWakeMusicBusReview"
    root.add_child(bus)
    await process_frame
    var first: Dictionary = StoryProjection.project(scene.opening)
    if not first.get("ok", false):
        _fail("forward Ionia-first source unavailable")
        return
    if bus.start_synthetic_preview(PROOF):
        _fail("no soundtrack cue was selected but preview started")
        return
    if not bus.select_candidate(first, "title_menu"):
        _fail("title music identity could not be proposed")
        return
    if bus.deck_a.stream != null or bus.deck_b.stream != null or bus.current_track != "":
        _fail("selecting an archived track alone created music playback")
        return
    if bus.start_synthetic_preview({"source":"isolated_godot_synthetic_music_fixture", "synthetic_only":true}):
        _fail("malformed audio fixture started playback")
        return
    if bus.start_synthetic_preview({"source":"isolated_godot_synthetic_music_fixture", "synthetic_only":true, "explicit_start":true, "license_granted":true}):
        _fail("music fixture accepted invented license field")
        return
    if not bus.start_synthetic_preview(PROOF):
        _fail("explicit synthetic-only Godot AudioStreamPlayer rehearsal failed")
        return
    var before: Dictionary = bus.review_snapshot()
    if before.get("mode", "") != "synthetic" or before.get("requested_historical_track", "") != "skyward_arpeggio":
        _fail("title label wasn't bound to archived cue identity")
        return
    if not bus.deck_a.playing or not bus.deck_a.stream is AudioStreamWAV or bus.deck_b.stream != null:
        _fail("real Godot audio deck did not use isolated synthetic WAV")
        return
    if not bool(before.get("stream_a_is_synthetic", false)) or bool(before.get("historical_mp3_loaded", true)):
        _fail("synthetic playback misreported as original audio")
        return
    if not bus.set_volume_percent(40.0) or bus.set_volume_percent(-1.0) or bus.set_volume_percent(101.0):
        _fail("out-of-bounds volume accepted")
        return
    var audible_db: float = bus.deck_a.volume_db
    bus.set_muted(true)
    if bus.deck_a.volume_db > -79.0 or bus.volume_percent != 40.0:
        _fail("mute broke volume preference or failed to suppress channel")
        return
    bus.set_muted(false)
    if not is_equal_approx(bus.deck_a.volume_db, audible_db):
        _fail("unmute failed to restore chosen volume")
        return
    bus.set_preview_paused(true)
    if not bus.deck_a.stream_paused or not bus.review_snapshot()["paused"]:
        _fail("pause didn't propagate to real AudioStreamPlayer")
        return
    bus.set_preview_paused(false)

    var stranger: Dictionary = first.duplicate(true)
    stranger["story_party"] = ["ender", "lyra"]
    if bus.transition_synthetic(stranger, "opening_cinematic", PROOF):
        _fail("an illicit Lyra-first cue triggered music transition")
        return
    if bus.transition_synthetic(first, "combat_danger", PROOF):
        _fail("combat music bypassed combat authority")
        return
    if bus.transition_synthetic(first, "denith_shanty", PROOF):
        _fail("Ionia/Denith unrevealed shanty was invented")
        return
    if bus.review_snapshot()["mode"] != "synthetic" or bus.current_track != "skyward_arpeggio":
        _fail("invalid music request changed playback state")
        return

    if not scene.opening.accept_ionia_job():
        _fail("Ionia-first scene transition failed")
        return
    var engineering: Dictionary = StoryProjection.project(scene.opening)
    if not engineering.get("ok", false):
        _fail("forward engineering cue missing")
        return
    if bus.transition_synthetic(engineering, "title_menu", PROOF):
        _fail("title music in engine room was allowed")
        return
    if not bus.transition_synthetic(engineering, "opening_cinematic", PROOF, 2.0):
        _fail("title-to-opening music transition did not start")
        return
    if bus.mode != "synthetic_crossfade" or bus.current_track != "amonigio_umulula":
        _fail("crossfade controller did not update candidate identifier")
        return
    if not bus.deck_b.playing or not bus.deck_b.stream is AudioStreamWAV:
        _fail("second real Godot audio channel did not start its own synthetic stream")
        return
    if bus.transition_synthetic(engineering, "opening_cinematic", PROOF):
        _fail("an in-progress crossfade admitted a duplicate transition")
        return
    if not bus.advance_fade(1.0):
        _fail("deterministic midpoint advance failed")
        return
    if absf(bus.deck_a.volume_db - bus.deck_b.volume_db) > 0.1:
        _fail("two active AudioStreamPlayers did not share equal linear gain at midpoint")
        return
    bus.set_muted(true)
    if bus.deck_a.volume_db > -79.0 or bus.deck_b.volume_db > -79.0:
        _fail("muting a crossfade left an active audible channel")
        return
    bus.set_muted(false)
    if not bus.advance_fade(1.0):
        _fail("deterministic fade completion failed")
        return
    if bus.deck_a.playing or bus.deck_a.stream != null or not bus.deck_b.playing or bus.deck_b.stream == null or bus.mode != "synthetic":
        _fail("fade did not cleanly stop/clear outgoing real player")
        return
    var end: Dictionary = bus.review_snapshot()
    for flag in ["historical_mp3_loaded","real_recording_playback_verified","public_streaming_authorized","music_placement_approved","denith_shanty_verified","may_write_save","may_modify_story_or_combat"]:
        if end.get(flag, true):
            _fail("synthetic fixture leaked forbidden production authority: " + flag)
            return
    if not bus.select_candidate(engineering, "opening_cinematic"):
        _fail("same cue selection should be non-destructive")
        return
    bus.stop_preview()
    if bus.mode != "idle" or bus.deck_a.stream != null or bus.deck_b.stream != null or not bus.current_track.is_empty():
        _fail("audio bus shutdown retained streams or story track")
        return
    bus.queue_free()
    scene.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_SYNTH_MUSIC_BUS_PASS: two actual AudioStreamPlayers, opt-in original test WAV, real story title-to-opening cue, mute/volume/pause/crossfade, no historical MP3 import or gameplay/publication authority")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_SYNTH_MUSIC_BUS_FAIL: " + reason)
    quit(1)
