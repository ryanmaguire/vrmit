class_name SnapPoint extends Node3D

## Manages the connections between two electrical components.
## Owned by the component itself and only handles connections.
## This class does not handle simulation computation.

## Parent component (will typically own two to three of these depending on component type)
var component: Node

## Connected [SnapPoint] or null
var connection: SnapPoint

func _ready() -> void:
	var parent = get_parent()
	if parent == null:
		print("[CircuitSim/SnapPointManager]: (WARN) Null parent on snapPoint. Did you forget to parent it to the component?")
	else:
		component = parent
		
## Returns true if the instance is currently connected.
func has_active_connection() -> bool:
	return connection != null

## Connect the snapPoint to another. Returns true on success and false if already connected.
## Will connect both snapPoints symetrically. Run only on one.
func connect_to_snappoint(other: SnapPoint) -> bool:
	# Already connected
	if (connection != null) or (other.connection != null):
		print("[CircuitSim/SnapPointManager]: (WARN) Tried to connect already connected snapPoints")
		return false

	# Self connection
	if self == other:
		print("[CircuitSim/SnapPointManager]: (WARN) Tried to connect self connect snapPoints")
		return false

	# Cyclical connection
	if component == other.component:
		print("[CircuitSim/SnapPointManager]: (WARN) Tried to connect multiple snapPoints on the same component")
		return false

	other.connection = self
	connection = other
	print("[CircuitSim/SnapPointManager]: Connection succesfully established")
	return true

## Disconnect this snapPoint and the other connected one. Returns true on success and false
## if the snapPoint is not currently connected or connection state is broken.
func disconnect_snappoint() -> bool:
	if (connection == null):
		print("[CircuitSim/SnapPointManager]: Failed to disconnect, no active connection")
		return false

	# connection.connection simply refers to the connected snapPoint's connection back to this instance. SHOULD be self.
	# I do not check for connection.connection == self, but may be good to check in the future.
	connection.connection = null
	connection = null
	print("[CircuitSim/SnapPointManager]: Succesfully disconnected")
	return true
