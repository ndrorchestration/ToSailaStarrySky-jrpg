extends Node2D
## Optional executable TEST SCENE for the established Chapter I migration
## content. The actual world/controller is unchanged except a passive signal.
## Play this review scene directly (F6) to compare event-driven staff visuals.
const FirstWake = preload("res://scenes/first_wake_chapter1_review.tscn")
const Presenter = preload("res://scripts/first_wake_staff_signal_visual_presenter.gd")
const PresentationHUD = preload("res://scripts/first_wake_staff_presentation_hud.gd")

@export var staff_visual_preview_enabled: bool = true
@export var reduced_motion: bool = false

var chapter_scene: Node2D
var presenter: Node2D
var presentation_layer: CanvasLayer
var presentation_hud: Control

func _ready() -> void:
    chapter_scene = FirstWake.instantiate()
    chapter_scene.name = "UnmodifiedChapterOneMigrationWorld"
    add_child(chapter_scene)
    presenter = Presenter.new()
    presenter.name = "OptInSignalDrivenStaffVisualPresenter"
    chapter_scene.add_child(presenter)
    presenter.set_reduced_motion(reduced_motion)
    presenter.set_pilot_enabled(staff_visual_preview_enabled)
    if not presenter.attach_to_scene(chapter_scene):
        push_error("FIRST_WAKE_STAFF_SIGNAL_PILOT_ATTACH_FAILED")
    # This entire HUD layer exists only in the opt-in scene wrapper.
    presentation_layer = CanvasLayer.new()
    presentation_layer.layer = 11
    presentation_layer.name = "ReadOnlyStaffPresentationLayer"
    add_child(presentation_layer)
    presentation_hud = PresentationHUD.new()
    presentation_hud.name = "ReadOnlyStaffPresentationHUD"
    presentation_layer.add_child(presentation_hud)
    if not presentation_hud.bind_presenter(presenter):
        push_error("FIRST_WAKE_PRESENTATION_HUD_BIND_FAILED")

func pilot_contract() -> Dictionary:
    if presenter == null:
        return {}
    return {
        "prototypeOnly":true,
        "sourceScene":"res://scenes/first_wake_chapter1_review.tscn",
        "defaultChapterOneSceneReplaced":false,
        "combatActionAuthorityChanged":false,
        "saveCodecChanged":false,
        "presenter":presenter.visual_contract(),
        "hud":presentation_hud.visual_contract() if presentation_hud != null else {}
    }
