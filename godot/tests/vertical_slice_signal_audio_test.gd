extends SceneTree
## Asset-independent contract for the original procedural signal motif.

const SignalAudio = preload("res://scripts/vertical_slice_signal_audio.gd")

func _initialize() -> void:
    var question := SignalAudio.make_question()
    var answer := SignalAudio.make_answer()
    if question == null or answer == null:
        _fail("stream construction failed")
        return
    if question.format != AudioStreamWAV.FORMAT_16_BITS or answer.format != AudioStreamWAV.FORMAT_16_BITS:
        _fail("unexpected PCM format")
        return
    if question.mix_rate != SignalAudio.SAMPLE_RATE or answer.mix_rate != SignalAudio.SAMPLE_RATE:
        _fail("sample rate mismatch")
        return
    if question.stereo or answer.stereo:
        _fail("review motif should remain mono")
        return
    if question.data.is_empty() or answer.data.is_empty() or question.data == answer.data:
        _fail("question/answer streams missing or identical")
        return
    if question.data.size() < 15000 or answer.data.size() < 18000:
        _fail("motif unexpectedly truncated")
        return
    print("AETHERWAKE_SIGNAL_AUDIO_PASS: original question/answer PCM generated with visual-equivalent gameplay cues")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_SIGNAL_AUDIO_FAIL: " + reason)
    quit(1)
