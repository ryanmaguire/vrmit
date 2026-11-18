extends Control

@onready var charge_button: Button = $PointCharge
@onready var magnet_button: Button = $BarMagnet
@onready var math_tab: Button = $ModeSwitch/Math
@onready var physics_tab: Button = $ModeSwitch/Physics

var current_mode := "physics"

func _ready() -> void:
	charge_button.pressed.connect(_select_tool.bind("pt_charge"))
	magnet_button.pressed.connect(_select_tool.bind("bar_magnet"))
	math_tab.pressed.connect(set_mode.bind("math"))
	physics_tab.pressed.connect(set_mode.bind("physics"))
	_update_mode_display()

func _select_tool(tool: String) -> void:
	if current_mode != "physics":
		return
	var controller = get_tree().get_first_node_in_group("physics_tool_controller")
	if controller == null:
		return
	controller.select_inventory_tool(tool)
	charge_button.set_pressed_no_signal(tool == "pt_charge")
	magnet_button.set_pressed_no_signal(tool == "bar_magnet")


func set_mode(mode: String) -> void:
	if mode not in ["math", "physics"] or mode == current_mode:
		return
	current_mode = mode
	var controller = get_tree().get_first_node_in_group("physics_tool_controller")
	if controller:
		controller.clear_inventory_tool()
	charge_button.set_pressed_no_signal(false)
	magnet_button.set_pressed_no_signal(false)
	_update_mode_display()


func _update_mode_display() -> void:
	var is_physics := current_mode == "physics"
	math_tab.set_pressed_no_signal(not is_physics)
	physics_tab.set_pressed_no_signal(is_physics)
	charge_button.disabled = not is_physics
	magnet_button.disabled = not is_physics
	charge_button.get_node("Icon").visible = is_physics
	magnet_button.get_node("Icon").visible = is_physics
	charge_button.text = "" if is_physics else "—"
	magnet_button.text = "" if is_physics else "—"
	$MathHint.visible = not is_physics
