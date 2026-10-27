extends Control
## Playable design-review fixture. No protagonist equipment, saves or formulas.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const Silhouette = preload("res://scripts/weapon_silhouette_review.gd")
const WEAPON_IDS: Array[String] = [
    "full_length_staff","practice_sword","field_pike","service_rifle"
]
const PAPER := Color("#f2e6d0")
const MUTED := Color("#a8c4c4")

var catalog = Catalog.new()
var weapon_index: int = 0
var training_rank: int = 1
var points: int = 3
var learned: Array[String] = []
var weapon_display: Node2D
var title_label: Label
var summary_label: Label
var rank_button: Button
var points_label: Label
var battle_label: Label
var skill_buttons: Array[Button] = []

func _ready() -> void:
    size = Vector2(960,640)
    _build()
    _refresh()

func _label(value: String, at: Vector2, dimensions: Vector2, font_size: int = 16) -> Label:
    var label := Label.new()
    label.text = value
    label.position = at
    label.size = dimensions
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",PAPER)
    add_child(label)
    return label

func _button(value: String, at: Vector2, dimensions: Vector2) -> Button:
    var button := Button.new()
    button.text = value
    button.position = at
    button.size = dimensions
    button.add_theme_font_size_override("font_size",15)
    add_child(button)
    return button

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color("#101d30")
    background.size = Vector2(960,640)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    _label("WEAPON MASTERY  /  NATIVE DESIGN REVIEW",Vector2(35,19),Vector2(890,40),26)
    _label("Nonmagical disciplines; a character's plot affinity remains independent.",Vector2(37,58),Vector2(885,28))
    _label("EQUIPPED SILHOUETTE",Vector2(644,102),Vector2(290,28))
    title_label = _label("",Vector2(39,114),Vector2(535,36),24)
    summary_label = _label("",Vector2(39,158),Vector2(546,58),14)

    var previous := _button("< Previous",Vector2(617,430),Vector2(147,42))
    previous.pressed.connect(_cycle_weapon.bind(-1))
    var next := _button("Next >",Vector2(773,430),Vector2(149,42))
    next.pressed.connect(_cycle_weapon.bind(1))

    rank_button = _button("",Vector2(39,236),Vector2(184,39))
    rank_button.pressed.connect(_cycle_rank)
    points_label = _label("",Vector2(237,241),Vector2(370,29))
    _label("SKILL TREE   /   Spend practice points",Vector2(40,293),Vector2(502,26))

    var rail := Line2D.new()
    rail.points = PackedVector2Array([Vector2(27,362),Vector2(27,502)])
    rail.width = 3.0
    rail.default_color = Color("#5e9998")
    add_child(rail)
    for i in range(3):
        var connector := Line2D.new()
        connector.points = PackedVector2Array([
            Vector2(27,362+i*70),Vector2(39,362+i*70)
        ])
        connector.width = 3.0
        connector.default_color = Color("#5e9998")
        add_child(connector)
        var node := _button("",Vector2(41,332+i*70),Vector2(531,60))
        node.pressed.connect(_learn_node.bind(i))
        skill_buttons.append(node)

    weapon_display = Silhouette.new()
    weapon_display.name = "WeaponSilhouette"
    weapon_display.position = Vector2(764,273)
    add_child(weapon_display)

    battle_label = _label("",Vector2(39,561),Vector2(685,28),14)
    var disclaimer := _label(
        "REVIEW ONLY - techniques are not executable in Chapter I combat.",
        Vector2(39,604),Vector2(900,26),14
    )
    disclaimer.add_theme_color_override("font_color",MUTED)

func current_weapon_id() -> String:
    return WEAPON_IDS[weapon_index]

func _cycle_weapon(direction: int) -> void:
    weapon_index = posmod(weapon_index+direction,WEAPON_IDS.size())
    _refresh()

func _cycle_rank() -> void:
    training_rank = 1 if training_rank >= 3 else training_rank+1
    _refresh()

func _learn_node(index: int) -> void:
    var nodes := catalog.skills_for(current_weapon_id())
    if index < 0 or index >= nodes.size():
        return
    var outcome := catalog.learn(
        current_weapon_id(),str(nodes[index]["id"]),learned,training_rank,points
    )
    if not bool(outcome.get("ok",false)):
        return
    learned = outcome["known"]
    points = int(outcome["points"])
    _refresh()

func _refresh() -> void:
    var item := catalog.weapon(current_weapon_id())
    weapon_display.select_weapon(current_weapon_id())
    title_label.text = str(item.get("label","Unknown weapon"))
    summary_label.text = str(item.get("note",""))
    rank_button.text = "Training rank: %d" % training_rank
    points_label.text = "%d practice points   |   rank is review input only" % points
    var nodes := catalog.skills_for(current_weapon_id())
    for i in range(skill_buttons.size()):
        var skill: Dictionary = nodes[i]
        var status := catalog.unlock_status(
            current_weapon_id(),str(skill["id"]),learned,training_rank,points
        )
        skill_buttons[i].text = "%d. %s - %s\n%s" % [
            i+1,str(skill["name"]),status.replace("_"," ").to_upper(),str(skill["intent"])
        ]
        skill_buttons[i].tooltip_text = str(skill["cue"])
        skill_buttons[i].disabled = status != "ready"
    var available := catalog.battle_preview(current_weapon_id(),learned)
    battle_label.text = "Equipped weapon skills: %d learned   |   0 executable actions" % available.size()
