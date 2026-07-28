extends HBoxContainer

## Circuit menu bar.
## UI and the global sim toggle. Hand tracking lives in [CircuitHands]
## and wire drawing in [WireTool] (both their own nodes).
## This script runs the [member sim_enabled] state and pushes it to each subsystem when it changes

@export var btn_global_circuits : Button
@export var btn_clear_components : Button

## Debug buttons, will be removed
@export var btn_print_net: Button
@export var btn_resitor: Button
@export var btn_vsrc: Button
@export var btn_gnd: Button

@export var wire_tool: WireTool
@export var group_wire_tool := &"circuits/wire_tool"

@export var move_tool: MoveTool
@export var group_move_tool := &"circuits/move_tool"

@export var components: Node3D
@export var group_components := &"circuits/circuit_components"

const RESISTOR_SCENE := preload("res://assets/circuit_simulation/components/scenes/resistor.tscn")
const VSRC_SCENE := preload("res://assets/circuit_simulation/components/scenes/vsrc.tscn")
const GROUND_SCENE := preload("res://assets/circuit_simulation/components/scenes/ground.tscn")

const SPAWN_ORIGIN := Vector3(0.3, 0.85, 0.0)

## Variation between spawned components to avoid stacking
const SPAWN_VARATION := 0.08

## Master switch for the entire circuit backend
var sim_enabled := false

func _ready() -> void:

	if wire_tool == null:
		wire_tool = get_tree().get_first_node_in_group(group_wire_tool)

	if move_tool == null:
		move_tool = get_tree().get_first_node_in_group(group_move_tool)

	if components == null:
		components = get_tree().get_first_node_in_group(group_components)

	if btn_global_circuits:
		btn_global_circuits.pressed.connect(_on_global_toggle)

	if btn_clear_components:
		btn_clear_components.pressed.connect(_on_clear)

	if btn_print_net:
		btn_print_net.pressed.connect(_on_print_net)

	if btn_resitor:
		btn_resitor.pressed.connect(_on_spawn_resistor)

	if btn_vsrc:
		btn_vsrc.pressed.connect(_on_spawn_vsrc)

	if btn_gnd:
		btn_gnd.pressed.connect(_on_spawn_ground)

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

func _on_spawn_resistor() -> void:
	_spawn_component(RESISTOR_SCENE)


func _on_spawn_vsrc() -> void:
	_spawn_component(VSRC_SCENE)


func _on_spawn_ground() -> void:
	_spawn_component(GROUND_SCENE)


func _spawn_component(scene: PackedScene) -> void:
	if components == null:
		components = get_tree().get_first_node_in_group(group_components)

	var comp = scene.instantiate()
	components.add_child(comp)
	comp.position = SPAWN_ORIGIN + Vector3(
		randf_range(-SPAWN_VARATION, SPAWN_VARATION),
		randf_range(-SPAWN_VARATION, SPAWN_VARATION),
		randf_range(-SPAWN_VARATION, SPAWN_VARATION),
	)

func _on_print_net() -> void:
	var root := get_tree().get_first_node_in_group(&"circuits/circuit_components")
	var comps := []
	for child in root.get_children():
		if child is CircuitComponent:
			comps.append(child)
	var islands := NetListGenerator.extract_netlist(comps)
	print("[CircuitSim/menu]: islands=", islands.size())
	_run_solver(islands)

## Temporary (Kind of, will be moved but kept largely the same)
## function to run the solver on an islands array. Will be moved
## into its own RefCounted object later on.
func _run_solver(islands: Array) -> void:
	var solver = ClassDB.instantiate(&"CircuitSolver")
	if solver == null:
		print("[CircuitSim] CircuitSolver not found. The circuit will not be solved.")
		return
		
	for i in range(islands.size()):
		var island: Dictionary = islands[i]

		# The only thing the solver needs are the actual elements
		# Drop everything else here:
		var final_elements: Array = []
		for element in island["elements"]:
			final_elements.append({
				"type": element["type"],
				"nets": element["nets"],
				"value": element["value"],
			})
		var send := {
			"net_count": island["net_count"],
			"ground_nets": island["ground_nets"],
			"elements": final_elements,
		}

		var result: Dictionary = solver.solve(send)

		if not result["ok"]:
			print("[CircuitSim] WARN: island N:%d solve failed: %s" % [i, result["error"]])
			continue
		if not result["grounded"]:
			push_warning("[CircuitSim] WARN island %d has no ground; used arbitrary reference, final result may be unexpected" % i)

		# Write the solved voltages to the SnapPoints
		var voltages: Array = result["node_voltages"]
		var net_sps: Array = island["net_to_snappoints"]
		for idx in range(net_sps.size()): # i already used :(
			for sp in net_sps[idx]:
				sp.set_voltage(voltages[idx])

		# Write the solved currents to the elements
		var currents: Array = result["element_currents"]
		for j in range(island["elements"].size()):
			island["elements"][j]["component"].set_current(currents[j])

		print("[CircuitSim] island %d solved: V=%s I=%s"
			% [i, voltages, currents])
