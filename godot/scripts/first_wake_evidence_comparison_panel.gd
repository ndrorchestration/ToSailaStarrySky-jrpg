extends Control
## Optional native UI for evidence-based diagnosis. Caller supplies the
## authenticated revised-opening object; this panel owns no story or save state.
const Comparison = preload("res://scripts/first_wake_evidence_comparison_review.gd")
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
var opening: RefCounted
var comparison = Comparison.new()
var chosen: Array[String] = []
var status: Label
var buttons: Dictionary = {}
var compare_button: Button
var last_result: Dictionary = {}

func configure_story(source: RefCounted) -> bool:
    if source == null or source.get_script() != Opening:
        return false
    opening = source
    if is_inside_tree():
        refresh()
    return true

func _ready() -> void:
    custom_minimum_size = Vector2(520, 310)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    var heading := Label.new()
    heading.text = "AUREATE WAKE / EVIDENCE COMPARISON"
    heading.add_theme_font_size_override("font_size", 20)
    stack.add_child(heading)
    var explanation := Label.new()
    explanation.text = "Select two observations to discuss. Comparison cannot change the story."
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(explanation)
    for clue_id in Opening.CLUE_IDS:
        var button := CheckButton.new()
        button.text = str(Comparison.CLUE_LABELS[clue_id])
        button.toggled.connect(_on_clue_toggled.bind(clue_id))
        stack.add_child(button)
        buttons[clue_id] = button
    compare_button = Button.new()
    compare_button.text = "Compare observations"
    compare_button.pressed.connect(compare_selected)
    stack.add_child(compare_button)
    status = Label.new()
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(status)
    refresh()

func refresh() -> void:
    if status == null:
        return
    var recorded: Array = []
    var eligible := false
    if opening != null:
        var snapshot: Dictionary = opening.snapshot()
        recorded = snapshot.get("clues", [])
        eligible = snapshot.get("step", "") in ["family_reunion", "working_theory"] \
            and snapshot.get("safe_reunion_confirmed", false) \
            and snapshot.get("active_party_ids", []) == ["ender", "ionia", "lyra"]
    for clue_id in buttons:
        var button: CheckButton = buttons[clue_id]
        button.disabled = not eligible or clue_id not in recorded
        if button.disabled:
            button.set_pressed_no_signal(false)
            chosen.erase(clue_id)
    compare_button.disabled = chosen.size() != 2
    status.text = "Select two recorded clues." if eligible else "Evidence comparison is not available yet."

func _on_clue_toggled(pressed: bool, clue_id: String) -> void:
    if pressed:
        if clue_id not in chosen:
            chosen.append(clue_id)
    else:
        chosen.erase(clue_id)
    if chosen.size() > 2:
        var first: String = chosen.pop_front()
        buttons[first].set_pressed_no_signal(false)
    compare_button.disabled = chosen.size() != 2
    status.text = "Select two recorded clues."

func compare_selected() -> Dictionary:
    if opening == null:
        last_result = {"validComparison": false, "reason": "invalid_story_authority"}
    else:
        last_result = comparison.compare(opening, chosen)
    if status != null:
        status.text = str(last_result.get("observation", last_result.get("reason", "Unavailable"))) \
            + ("\n" + str(last_result.get("nextAction", "")) if last_result.get("validComparison", false) else "")
    return last_result.duplicate(true)
