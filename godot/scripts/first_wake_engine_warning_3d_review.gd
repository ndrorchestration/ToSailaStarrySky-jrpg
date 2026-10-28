extends "res://scripts/first_wake_engine_warning_review.gd"
## PW-02 opt-in 2D authoritative flight + provenance-copied 3D hull cockpit inset.
## Independent live GPU viewport: original local 2D physics remains the only truth.
const ShipCandidate = preload("res://scripts/aureate_wake_ship_3d_candidate.gd")
const INSET_SIZE := Vector2i(428, 240)
const INSET_POSITION := Vector2(516, 188)
const BRIDGE_CAMERA := Vector3(6.8, 3.7, 8.9)
const ENGINE_MARKER := Vector3(0.0, 0.0, 2.61)

var ship3d: Node3D
var camera3d: Camera3D
var viewport3d: SubViewport
var halo3d: MeshInstance3D
var light3d: OmniLight3D
var inset_rect: TextureRect
var world3d: Node3D
var applied_visual_state: bool = false

func _ready() -> void:
    super._ready()
    _setup_real_3d_view()
    synchronize_3d_alarm()
    
func _setup_real_3d_view() -> void:
    viewport3d = SubViewport.new()
    viewport3d.name = "Independent3DShipViewport"
    viewport3d.size = INSET_SIZE
    viewport3d.own_world_3d = true
    viewport3d.transparent_bg = false
    viewport3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport3d)

    world3d = Node3D.new()
    world3d.name = "PW02RenderedShipWorld"
    viewport3d.add_child(world3d)
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#152b40")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#899dad")
    environment.ambient_light_energy = 0.6
    var backdrop := WorldEnvironment.new()
    backdrop.name = "PW02GoldenClearBackgroundOnly"
    backdrop.environment = environment
    world3d.add_child(backdrop)

    ship3d = ShipCandidate.new()
    ship3d.name = "AureateWakeProcedural3DCandidate"
    world3d.add_child(ship3d)
    ship3d.set_motion(0.0, true)

    var key := DirectionalLight3D.new()
    key.name = "GoldenClearStudyKey"
    key.rotation = Vector3(-0.64, 0.51, -0.15)
    key.light_color = Color("#ffdfaa")
    key.light_energy = 1.15
    key.shadow_enabled = false
    world3d.add_child(key)

    camera3d = Camera3D.new()
    camera3d.name = "Real3DSternQuarterCamera"
    camera3d.position = BRIDGE_CAMERA
    camera3d.fov = 54.0
    camera3d.near = 0.12
    camera3d.far = 64.0
    world3d.add_child(camera3d)
    camera3d.look_at(Vector3(0.0, 0.16, 0.14), Vector3.UP)
    camera3d.current = true

    halo3d = MeshInstance3D.new()
    halo3d.name = "SternEnginePhaseWarning3D"
    var torus := TorusMesh.new()
    torus.inner_radius = 0.26
    torus.outer_radius = 0.44
    torus.rings = 16
    torus.ring_segments = 20
    halo3d.mesh = torus
    halo3d.position = ENGINE_MARKER
    halo3d.rotation.x = PI * 0.5
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color("#ecc075")
    material.emission_enabled = true
    material.emission = Color("#eeb77d")
    material.emission_energy_multiplier = 0.55
    halo3d.material_override = material
    halo3d.visible = false
    ship3d.add_child(halo3d)

    light3d = OmniLight3D.new()
    light3d.name = "SternEnginePhysical3DLight"
    light3d.position = ENGINE_MARKER
    light3d.light_color = Color("#f5bb72")
    light3d.light_energy = 0.78
    light3d.omni_range = 3.2
    light3d.shadow_enabled = false
    light3d.visible = false
    ship3d.add_child(light3d)

    var ui := CanvasLayer.new()
    ui.name = "PW02InScene3DViewportOverlay"
    ui.layer = 2
    add_child(ui)
    var border := ColorRect.new()
    border.name = "CameraInsetFrame"
    border.position = INSET_POSITION - Vector2(5.0, 5.0)
    border.size = Vector2(INSET_SIZE) + Vector2(10.0, 10.0)
    border.color = Color("#172932")
    border.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(border)

    inset_rect = TextureRect.new()
    inset_rect.name = "Actual3DShipFrame"
    inset_rect.position = INSET_POSITION
    inset_rect.size = Vector2(INSET_SIZE)
    inset_rect.texture = viewport3d.get_texture()
    inset_rect.stretch_mode = TextureRect.STRETCH_SCALE
    inset_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(inset_rect)

func _process(delta: float) -> void:
    super._process(delta)
    synchronize_3d_alarm()

func synchronize_3d_alarm() -> void:
    if not is_instance_valid(halo3d) or not is_instance_valid(light3d):
        return
    # The original 2D visual is the single authority for whether a 3D
    # presentation is shown; the 3D scene never initiates warning or descent.
    applied_visual_state = bool(warning_visual.active) and bool(warning_visual.visible)
    halo3d.visible = applied_visual_state
    light3d.visible = applied_visual_state
