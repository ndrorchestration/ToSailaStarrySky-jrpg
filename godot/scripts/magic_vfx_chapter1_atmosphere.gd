extends Node2D
## Deterministic cosmetic mist/rain test plate for the Chapter I VFX study.
## No atmospheric simulation, audio, collision, game weather, or randomness.
const WEATHER = ["clear", "mist", "rain"]
const RAIN_STREAKS = 42

var weather: String = "clear"
var reduced_motion: bool = true

func set_weather(next_weather: String) -> bool:
    if not next_weather in WEATHER:
        return false
    weather = next_weather
    queue_redraw()
    return true

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    queue_redraw()

func _draw() -> void:
    match weather:
        "mist":
            for i in range(7):
                var band_y: float = 186.0 + float(i) * 43.0
                var transparency: float = 0.035 if reduced_motion else 0.048
                draw_rect(Rect2(0.0, band_y, 960.0, 30.0), Color(0.78, 0.88, 0.91, transparency))
            # Even reduced-motion mist has distinct texture with no animated shimmer.
            for i in range(9):
                var y: float = 224.0 + float(i) * 29.0
                draw_line(Vector2(128.0 + float(i % 2) * 24.0, y), Vector2(815.0, y), Color(0.82, 0.89, 0.88, 0.075), 1.0, true)
        "rain":
            for i in range(RAIN_STREAKS):
                var x: float = 90.0 + float((i * 83 + 39) % 770)
                var y: float = 154.0 + float((i * 67 + 51) % 333)
                # No strobing or screen flash; sparse fixed screen-space traces.
                draw_line(Vector2(x, y), Vector2(x - 8.0, y + 20.0), Color(0.73, 0.89, 0.97, 0.42), 1.2, true)
        _:
            pass
