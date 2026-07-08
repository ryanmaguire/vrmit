extends HBoxContainer

## Circuit menu bar.
## UI and the global sim toggle. Hand tracking lives in [CircuitHands]
## and wire drawing in [WireTool] (both their own nodes).
## This script runs the [member sim_enabled] state and pushes it to each subsystem when it changes

@export var btn_global_circuits : Button
@export var btn_clear_components : Button

@export var wire_tool: WireTool
@export var group_wire_tool := &"wire_tool"

## Master switch for the entire circuit backend
var sim_enabled := false

# LLM written debug messages in here. Will remove later.
func _ready() -> void:
	print("[CircuitSim/menu]: Initializing menu bar...")

	if wire_tool == null:
		wire_tool = get_tree().get_first_node_in_group(group_wire_tool)
		if wire_tool:
			print("[CircuitSim/menu]: Found wire_tool via group lookup.")
		else:
			print("[CircuitSim/menu]: WARNING: Could not find wire_tool in group '", group_wire_tool, "'")

	if btn_global_circuits:
		btn_global_circuits.pressed.connect(_on_global_toggle)
	else:
		print("[CircuitSim/menu]: WARNING: btn_global_circuits is not assigned!")

	if btn_clear_components:
		btn_clear_components.pressed.connect(_on_clear)
	else:
		print("[CircuitSim/menu]: WARNING: btn_clear_components is not assigned!")

	# Apply initial off to all systems.
	_apply_sim_state()


func _on_global_toggle() -> void:
	sim_enabled = not sim_enabled
	print("[CircuitSim/menu]: Global toggle pressed. New sim_enabled state: ", sim_enabled)
	_apply_sim_state()


## Apply the current state of the sim to every connected subsystem.
func _apply_sim_state() -> void:
	print("[CircuitSim/menu]: Pushing state to subsystems -> sim_enabled = ", sim_enabled)

	if wire_tool:
		wire_tool.set_active(sim_enabled)
	else:
		print("[CircuitSim/menu]: Failed to push state to wire_tool (null reference).")


	if btn_global_circuits:
		btn_global_circuits.text = "Disable Circuits" if sim_enabled else "Enable Circuits"


func _on_clear() -> void:
	print("[CircuitSim/menu]: Clear button pressed.")
	if wire_tool:
		print("[CircuitSim/menu]: Delegating clear command to wire_tool.")
		wire_tool.clear()
	else:
		print("[CircuitSim/menu]: Cannot clear. wire_tool reference is missing.")
