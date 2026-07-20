class_name MoveTool extends Node
## Allows the movement of circuit components via pinching in their indeividual hitboxes.

## CircuitHands
@export var hands : CircuitHands
@export var group_hands : StringName = &"circuits/circuit_hands"

## Components live under
@export var components : Node3D
@export var group_components : StringName = &"circuits/circuit_components"

@export_flags_3d_physics var grab_mask : int = 1

## State
var active := false

## Active
var grabbing := false

var _grab_hand : Hand = null
var _held : CircuitComponent = null
var _grab_offset : Vector3


func _ready() -> void:
	if hands == null:
		hands = get_tree().get_first_node_in_group(group_hands)
	if components == null:
		components = get_tree().get_first_node_in_group(group_components)

	if hands:
		hands.hand_pinch_started.connect(_on_pinch_started)
		hands.hand_pinch_released.connect(_on_pinch_released)

## Global toggle
func set_active(value : bool) -> void:
	print("[CircuitSim/move_tool]: State recieved from menu: ", value)
	active = value
	if not active:
		_drop()


func _process(_delta : float) -> void:
	if not active or not grabbing or _held == null or _grab_hand == null:
		return
	
	# Follow the grabbing hand pinch center
	var hand_global := components.to_global(_grab_hand.pinch_center)
	_held.global_position = hand_global + _grab_offset


## A hand began pinching: if it landed on a component, grab it.
func _on_pinch_started(hand : Hand) -> void:
	if not active or grabbing:
		return
	var comp := _query_component(hand.pinch_center)
	if comp == null:
		return
	_grab_hand = hand
	_held = comp
	_grab_offset = comp.global_position - components.to_global(hand.pinch_center)
	grabbing = true


## A hand released: if it was the one holding, drop.
func _on_pinch_released(hand : Hand) -> void:
	if grabbing and hand == _grab_hand:
		_drop()


func _drop() -> void:
	grabbing = false
	_grab_hand = null
	_held = null


## Query the component at the pinch center for grabbing
## This function is still in development. Don't fully understand the
## collision system yet.
func _query_component(local_pos : Vector3) -> CircuitComponent:
	if components == null:
		return null

	var space_state := components.get_world_3d().direct_space_state
	var params := PhysicsPointQueryParameters3D.new()
	params.position = components.to_global(local_pos)
	params.collision_mask = grab_mask
	params.collide_with_areas = true
	params.collide_with_bodies = false

	var hits := space_state.intersect_point(params, 1)
	if hits.is_empty():
		return null

	var parent = hits[0].collider.get_parent()
	if parent is CircuitComponent:
		return parent
	return null
