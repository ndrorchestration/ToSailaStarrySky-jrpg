extends Node
## Isolated sound-system *mechanics* proof for the forward First Wake project.
## Generates its own short, low-level sine-loop WAV. NEVER loads, emits, streams
## or grants publication rights to the five historical soundtrack recordings.
## The external story/music candidate is data only until separately authorized.

const ExistingMusic = preload("res://scripts/first_wake_existing_music_cue_contract.gd")
const QA_PROOF := "isolated_godot_synthetic_music_fixture"
const BUS_SCHEMA := "tstss.review.music_bus.synthetic.v1"

var deck_a: AudioStreamPlayer
var deck_b: AudioStreamPlayer
var active_deck: AudioStreamPlayer
var outgoing_deck: AudioStreamPlayer
var candidate: Dictionary = {}
var current_track: String = ""
var mode: String = "idle"
var muted: bool = false
var volume_percent: float = 65.0
var paused: bool = false
var fade_elapsed: float = 0.0
var fade_length: float = 0.0

func _ready() -> void:
    deck_a = AudioStreamPlayer.new()
    deck_a.name = "SyntheticReviewDeckA"
    add_child(deck_a)
    deck_b = AudioStreamPlayer.new()
    deck_b.name = "SyntheticReviewDeckB"
    add_child(deck_b)
    deck_a.volume_db = -80.0
    deck_b.volume_db = -80.0
    set_process(false)

func select_candidate(source: Dictionary, role: String) -> bool:
    var incoming: Dictionary = ExistingMusic.candidate(source, role)
    if not bool(incoming.get("ok", false)):
        return false
    if incoming.get("native_audio_playback_proven", true) != false:
        return false
    if incoming.get("may_autoplay", true) != false or incoming.get("scene_placement_approved", true) != false:
        return false
    if current_track == str(incoming["track_id"]) and mode in ["synthetic", "synthetic_crossfade"]:
        candidate = incoming.duplicate(true)
        return true
    # Merely selecting an archived track NEVER creates an AudioStreamPlayer stream.
    candidate = incoming.duplicate(true)
    return true

func start_synthetic_preview(proof: Dictionary) -> bool:
    if not _valid_fixture(proof) or not is_inside_tree():
        return false
    if not bool(candidate.get("ok", false)) or candidate.get("status", "") != "historical_source_candidate_only":
        return false
    if bool(ExistingMusic.verify_local_audio(candidate).get("ok", false)):
        # If archival bytes appear, do not treat them as synthetic fixture material.
        return false
    if mode != "idle":
        return false
    active_deck = deck_a
    active_deck.stream = _generate_test_stream(125.0)
    active_deck.play()
    active_deck.stream_paused = paused
    current_track = str(candidate["track_id"])
    mode = "synthetic"
    _update_levels()
    return true

func transition_synthetic(source: Dictionary, role: String, proof: Dictionary, seconds: float = 1.0) -> bool:
    if not _valid_fixture(proof) or mode != "synthetic" or active_deck == null:
        return false
    if seconds <= 0.0 or seconds > 10.0:
        return false
    var incoming: Dictionary = ExistingMusic.candidate(source, role)
    if not bool(incoming.get("ok", false)):
        return false
    if str(incoming["track_id"]) == current_track:
        return false
    if bool(ExistingMusic.verify_local_audio(incoming).get("ok", false)):
        return false
    outgoing_deck = active_deck
    active_deck = deck_b if active_deck == deck_a else deck_a
    active_deck.stream = _generate_test_stream(175.0)
    active_deck.play()
    active_deck.stream_paused = paused
    candidate = incoming.duplicate(true)
    current_track = str(incoming["track_id"])
    fade_elapsed = 0.0
    fade_length = seconds
    mode = "synthetic_crossfade"
    set_process(true)
    _update_levels()
    return true

func advance_fade(seconds: float) -> bool:
    if mode != "synthetic_crossfade" or seconds < 0.0 or seconds > 10.0:
        return false
    fade_elapsed = minf(fade_length, fade_elapsed + seconds)
    _update_levels()
    if fade_elapsed >= fade_length:
        outgoing_deck.stop()
        outgoing_deck.stream = null
        outgoing_deck = null
        mode = "synthetic"
        set_process(false)
        _update_levels()
    return true

func _process(delta: float) -> void:
    if mode == "synthetic_crossfade" and not paused:
        advance_fade(delta)

func set_volume_percent(value: float) -> bool:
    if not is_finite(value) or value < 0.0 or value > 100.0:
        return false
    volume_percent = value
    _update_levels()
    return true

func set_muted(value: bool) -> void:
    muted = value
    _update_levels()

func set_preview_paused(value: bool) -> void:
    paused = value
    if deck_a != null:
        deck_a.stream_paused = value
    if deck_b != null:
        deck_b.stream_paused = value
    _update_levels()

func stop_preview() -> void:
    if deck_a != null:
        deck_a.stop()
        deck_a.stream = null
    if deck_b != null:
        deck_b.stop()
        deck_b.stream = null
    active_deck = null
    outgoing_deck = null
    current_track = ""
    candidate.clear()
    fade_elapsed = 0.0
    fade_length = 0.0
    mode = "idle"
    set_process(false)

func _exit_tree() -> void:
    stop_preview()

func review_snapshot() -> Dictionary:
    return {
        "schema": BUS_SCHEMA,
        "mode": mode,
        "requested_historical_track": current_track,
        "test_signal_only": true,
        "muted": muted,
        "volume_percent": volume_percent,
        "paused": paused,
        "fade_progress": clampf(fade_elapsed / fade_length, 0.0, 1.0) if fade_length > 0.0 else 0.0,
        "stream_a_is_synthetic": deck_a == null or deck_a.stream == null or deck_a.stream is AudioStreamWAV,
        "stream_b_is_synthetic": deck_b == null or deck_b.stream == null or deck_b.stream is AudioStreamWAV,
        "historical_mp3_loaded": false,
        "real_recording_playback_verified": false,
        "public_streaming_authorized": false,
        "music_placement_approved": false,
        "denith_shanty_verified": false,
        "may_write_save": false,
        "may_modify_story_or_combat": false,
    }

func _update_levels() -> void:
    if deck_a == null or deck_b == null:
        return
    var gain: float = 0.0 if muted else volume_percent / 100.0
    if mode == "synthetic_crossfade" and outgoing_deck != null:
        var t: float = clampf(fade_elapsed / fade_length, 0.0, 1.0)
        _set_gain(outgoing_deck, gain * (1.0 - t))
        _set_gain(active_deck, gain * t)
    else:
        _set_gain(deck_a, gain if active_deck == deck_a else 0.0)
        _set_gain(deck_b, gain if active_deck == deck_b else 0.0)

func _set_gain(player: AudioStreamPlayer, amount: float) -> void:
    player.volume_db = -80.0 if amount <= 0.0001 else linear_to_db(amount)

func _valid_fixture(proof: Dictionary) -> bool:
    return proof.size() == 3 and proof.get("source", "") == QA_PROOF and proof.get("synthetic_only", false) == true and proof.get("explicit_start", false) == true

func _generate_test_stream(hertz: float) -> AudioStreamWAV:
    # Original synthetic 1-second sine test tone, low amplitude. No sample of any
    # game soundtrack, melody, song, lyrics or third-party recording is present.
    const SAMPLE_RATE := 8000
    var samples := PackedByteArray()
    samples.resize(SAMPLE_RATE * 2)
    for i in range(SAMPLE_RATE):
        var wave: float = sin(TAU * hertz * float(i) / float(SAMPLE_RATE))
        var pcm: int = int(round(wave * 1100.0)) & 0xffff
        samples[i * 2] = pcm & 0xff
        samples[i * 2 + 1] = (pcm >> 8) & 0xff
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.data = samples
    return stream
