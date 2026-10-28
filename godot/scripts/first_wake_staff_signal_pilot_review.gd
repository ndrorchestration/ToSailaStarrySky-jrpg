extends Node2D
## Optional executable TEST SCENE for the established Chapter I migration
## content. The actual world/controller is unchanged except a passive signal.
## Play this review scene directly (F6) to compare event-driven staff visuals.
const FirstWake = preload("res://scenes/first_wake_chapter1_review.tscn")
const Presenter = preload("res://scripts/first_wake_staff_signal_visual_presenter.gd")

@export var staff_visual_preview_enabled: bool = true
@export var reduced_motion: bool = false

var chapter_scene: Node2D
var presenter: Node2D

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

func pilot_contract() -> Dictionary:
    if presenter == null:
        return {}
    return {
        "prototypeOnly":true,
        "sourceScene":"res://scenes/first_wake_chapter1_review.tscn",
        "defaultChapterOneSceneReplaced":false,
        "combatActionAuthorityChanged":false,
        "saveCodecChanged":false,
        "presenter":presenter.visual_contract()
    }
