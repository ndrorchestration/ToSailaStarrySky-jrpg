extends Node3D
## Native test double for a presentation-only ship wing controller.
## Not a real model, physics rig or gameplay entity.
var current_fraction: float = 0.0
var updates: int = 0

func set_wing_review_sweep(progress: float) -> bool:
    if not is_finite(progress) or progress < 0.0 or progress > 1.0:
        return false
    current_fraction = progress
    updates += 1
    return true
