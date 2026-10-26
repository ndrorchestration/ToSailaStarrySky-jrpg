extends Node
## Diagnostic MAIN-LOOP frame interval sample, not a GPU timestamp or FPS certification.
## Trigger: godot --path godot/flight_slice -- --benchmark
const WARMUP: int = 120
const SAMPLE_COUNT: int = 1000
var _previous: int = 0
var _frame_number: int = 0
var _samples_ms: Array[float] = []

func _process(_delta: float) -> void:
    var now: int = Time.get_ticks_usec()
    if _previous > 0 and _frame_number > WARMUP:
        _samples_ms.append(float(now - _previous) / 1000.0)
    _previous = now
    _frame_number += 1
    if _samples_ms.size() >= SAMPLE_COUNT:
        _write_report()
        set_process(false)
        get_tree().quit()

func _write_report() -> void:
    _samples_ms.sort()
    var n: int = _samples_ms.size()
    var result: Dictionary = {
        "method": "main_loop_intervals_only_not_gpu_completion",
        "engine_version": Engine.get_version_info().get("string", "unknown"),
        "operating_system": OS.get_name(),
        "configured_renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
        "warmup_frames": WARMUP,
        "recorded_intervals": n,
        "median_ms": _samples_ms[int(floor((n - 1) * 0.50))],
        "p95_ms": _samples_ms[int(floor((n - 1) * 0.95))],
        "worst_ms": _samples_ms[n - 1],
        "all_intervals_ms": _samples_ms,
        "limitations": "CPU-loop timestamps only; no GPU timestamps, VRAM, power, realtime output or creator acceptance."
    }
    var file := FileAccess.open("user://flight_slice_intervals.json", FileAccess.WRITE)
    if file == null:
        push_error("Could not write benchmark diagnostics")
        return
    file.store_string(JSON.stringify(result, "  "))
    file.close()
    print("FLIGHT_SLICE_DIAGNOSTICS_SAVED:", ProjectSettings.globalize_path("user://flight_slice_intervals.json"))
