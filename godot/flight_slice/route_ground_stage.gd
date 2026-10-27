extends Node3D
## Noncanonical ground-stage fixture. Only marks readiness after entering
## the Godot scene tree; no player controller, boarding or save semantics.
var ready_for_disembark: bool = false

func _ready() -> void:
    ready_for_disembark = true
