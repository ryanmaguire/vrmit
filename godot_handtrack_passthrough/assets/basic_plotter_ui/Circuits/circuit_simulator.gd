extends HBoxContainer

## Circuit menu bar.
## UI and the global sim toggle. Hand tracking lives in [CircuitHands]
## and wire drawing in [WireTool] (both their own nodes).
## This script runs the [member sim_enabled] state and pushes it to each subsystem when it changes

@export var btn_global_circuits : Button
@export var btn_clear_components : Button

@export var wire_tool: WireTool
@export var group_wire_tool := &"wire_tool"

@export var move_tool: MoveTool
@export var group_move_tool := &"move_tool"

## Master switch for the entire circuit backend
var sim_enabled := false

func _ready() -> void:

	if wire_tool == null:
		wire_tool = get_tree().get_first_node_in_group(group_wire_tool)

	if move_tool == null:
		move_tool = get_tree().get_first_node_in_group(group_move_tool)

	if btn_global_circuits:
		btn_global_circuits.pressed.connect(_on_global_toggle)

	if btn_clear_components:
		btn_clear_components.pressed.connect(_on_clear)

	# Apply initial off to all systems.
	_apply_sim_state()


func _on_global_toggle() -> void:
	sim_enabled = not sim_enabled
	print("[CircuitSim/menu]: Global Toggle. sim_enabled state: ", sim_enabled)
	_apply_sim_state()


## Apply the current state of the sim to every connected subsystem.
func _apply_sim_state() -> void:
	print("[CircuitSim/menu]: Updating subsystems to sim_enabled = ", sim_enabled)

	if wire_tool:
		wire_tool.set_active(sim_enabled)

	if move_tool:
		move_tool.set_active(sim_enabled)

	if btn_global_circuits:
		btn_global_circuits.text = "Disable Circuits" if sim_enabled else "Enable Circuits"


func _on_clear() -> void:
	print("[CircuitSim/menu]: Calling global reset.")
	if wire_tool:
		print("[CircuitSim/menu]: Pushing reset to wire_tool")
		wire_tool.clear()
