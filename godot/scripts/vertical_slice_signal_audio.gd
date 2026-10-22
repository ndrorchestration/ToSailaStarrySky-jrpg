extends RefCounted
## Procedural, original two-note review motif. No external audio assets or borrowed melody.
## Essential gameplay information is also represented visually/textually.

const SAMPLE_RATE := 22050
const AMPLITUDE := 0.24

static func make_question() -> AudioStreamWAV:
    return _make_sequence([392.0, 493.88], [0.16, 0.22], 0.07)

static func make_answer() -> AudioStreamWAV:
    return _make_sequence([493.88, 659.25], [0.16, 0.30], 0.05)

static func _make_sequence(frequencies: Array[float], durations: Array[float], gap: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    for i in range(frequencies.size()):
        _append_tone(bytes, frequencies[i], durations[i])
        if i < frequencies.size() - 1:
            _append_silence(bytes, gap)
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    stream.data = bytes
    return stream

static func _append_tone(bytes: PackedByteArray, frequency: float, seconds: float) -> void:
    var count := int(round(seconds * SAMPLE_RATE))
    for i in range(count):
        var t := float(i) / float(SAMPLE_RATE)
        var phase := TAU * frequency * t
        var progress := float(i) / maxf(1.0, float(count - 1))
        var envelope := minf(1.0, progress / 0.08) * minf(1.0, (1.0 - progress) / 0.12)
        var wave := sin(phase) + 0.23 * sin(phase * 2.0)
        var value := int(clampf(wave * AMPLITUDE * envelope, -1.0, 1.0) * 32767.0)
        var packed := value & 0xffff
        bytes.append(packed & 0xff)
        bytes.append((packed >> 8) & 0xff)

static func _append_silence(bytes: PackedByteArray, seconds: float) -> void:
    var count := int(round(seconds * SAMPLE_RATE))
    for i in range(count):
        bytes.append(0)
        bytes.append(0)
