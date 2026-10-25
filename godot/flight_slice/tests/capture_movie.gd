extends SceneTree
## Native fixed-step Movie Maker capture; not a real-time FPS measurement.
const FRAME_COUNT: int = 720
var scene: Node3D
var frame: int = 0
func _initialize() -> void:
    call_deferred("_start")
func _start() -> void:
    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.set_process(false)
    scene._clock = 6.0
    scene._update_scene(10.0)
func _process(_delta: float) -> bool:
    if scene == null: return false
    scene._clock = 6.0 + float(frame) / 30.0 * 1.2
    scene._update_scene(1.0 / 30.0)
    scene.overlay.text = "TO SAIL THE STARRY SKY  /  FLIGHT STUDY\nNATIVE 960×640  ·  NON-CANON MATERIAL REVIEW\nFIXED-STEP FLYOVER  ·  NOT REAL-TIME PERFORMANCE"
    frame += 1
    if frame >= FRAME_COUNT:
        print("NATIVE_FLIGHT_MOVIE_PASS frames=", FRAME_COUNT, " fps=30 fixed-step")
        quit(0)
    return false
