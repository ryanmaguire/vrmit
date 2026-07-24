class_name SnapPoint extends Node3D

## Manages the connections between two electrical components.
## Owned by the component itself and only handles connections.
## This class does not handle simulation computation.

## Parent component (will typically own two to three of these depending on component type)
var component: Node

## Connected [SnapPoint]s or null
var connections: Array[SnapPoint] = []

## Last know voltage returned from the solver.
## Uses NaN instead of null for float typing
var solved_voltage: float = NAN

func _ready() -> void:
	var parent = get_parent()
	if parent == null:
		print("[CircuitSim/SnapPoint]: (WARN) Null parent on snapPoint. Did you forget to parent it to the component?")
	else:
		component = parent
		
## Returns true if the instance is currently connected.
func has_active_connection() -> bool:
	return not connections.is_empty()

## Connect the snapPoint to another. Returns true on success and false if already connected.
## Will connect both snapPoints symetrically. Run only on one.
func connect_to_snappoint(other: SnapPoint) -> bool:
	# Multi-connect is allowed, but the SAME pair must not be connected twice
	# (a duplicate edge would misrepresent one wire as two in the graph).
	if other in connections:
		print("[CircuitSim/SnapPoint]: (WARN) Tried to connect an already-connected pair")
		return false

	# Self connection
	if self == other:
		print("[CircuitSim/SnapPoint]: (WARN) Tried to connect self connect snapPoints")
		return false

	# Cyclical connection
	if component == other.component:
		print("[CircuitSim/SnapPoint]: (WARN) Tried to connect multiple snapPoints on the same component")
		return false

	# Create symmetric connection
	other.connections.append(self)
	connections.append(other)
	print("[CircuitSim/SnapPoint]: Connection succesfully established")
	return true

## Disconnect this snapPoint and all connected ones.
func disconnect_all() -> bool:
	if (connections.is_empty()):
		print("[CircuitSim/SnapPoint]: Failed to disconnect, no active connection")
		return false

	for sp in connections:
		sp.connections.erase(self)
	connections.clear()
	print("[CircuitSim/SnapPoint]: Succesfully disconnected from all")
	return true

## Function to disconnect from ONE specific [SnapPoint] instead of all.
func disconnect_from(other: SnapPoint) -> bool:
	if other not in connections:
		print("[CircuitSim/SnapPoint]: Failed to disconnect, not connected in the first place.")
		return false
	
	# Remove self from other snap
	other.connections.erase(self)

	# Remove now asymmetric entry on own connections
	connections.erase(other)
	return true

## Return the first SnapPoint in the list. Useful if you only want the transform
func get_master_connection() -> SnapPoint:
	if connections.is_empty():
		return null
	return connections[0] 
