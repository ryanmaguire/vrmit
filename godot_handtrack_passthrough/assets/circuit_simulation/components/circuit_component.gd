class_name CircuitComponent extends Node3D

## Class used to represent an arbitrary circuit component in the simulator.
## Holds its own [SnapPoint] instances. For example, a wire would hold the
## two snapPoints it has on its ends. Similarly with a resistor.
##
## When designing subclasses, do not override [method _ready], instead, override
## [method _on_ready]. _ready contains crucial snapPoint setup code.

## Every [SnapPoint] owned by this component. Automatically populated.
var snapPoints: Array[SnapPoint]

var snap_manager: SnapPointManager

@export var group_snap_manager: StringName = &"snap_point_manager"


func _ready() -> void:
	snap_manager = get_tree().get_first_node_in_group(group_snap_manager)

	if snap_manager == null:
		print("[CircuitSim/Component]: (ERR) No SnapPointManager found in group ", group_snap_manager, ". Components will not function")
	_get_snap_points()
	_register_snap_points()
	_on_ready()


## Gather all direct [SnapPoint] children into [member snapPoints]
func _get_snap_points() -> void:
	snapPoints.clear()
	for child in get_children():
		if child is SnapPoint:
			snapPoints.append(child)

	if snapPoints.is_empty():
		print("[CircuitSim/Component]: (WARN) '", name, "' has no SnapPoint children. It will not function")


## Register every terminal with the [SnapPointManager] so it can be found by tools.
func _register_snap_points() -> void:
	if snap_manager == null:
		return
	for sp in snapPoints:
		snap_manager.register(sp)


## Template for subclasses to run their own initialization. Called once after snapPoints are gathered.
func _on_ready() -> void:
	pass


## Return this component's [snapPoint] instances.
func get_snap_points() -> Array[SnapPoint]:
	return snapPoints


## SAFELY destroy the compont and remove it from the simulator.
func destroy() -> void:
	for sp in snapPoints:
		if sp.has_active_connection():
			sp.disconnect_snappoint()
		if snap_manager:
			snap_manager.unregister(sp)
	queue_free()
