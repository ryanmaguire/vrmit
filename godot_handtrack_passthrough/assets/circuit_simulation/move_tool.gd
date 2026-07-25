class_name MoveTool extends Node
## Allows the movement of circuit components via pinching in their indeividual hitboxes.

## CircuitHands
@export var hands : CircuitHands
@export var group_hands : StringName = &"circuits/circuit_hands"

## Components live under
@export var components : Node3D
@export var group_components : StringName = &"circuits/circuit_components"

@export_flags_3d_physics var grab_mask : int = 1

## Rotation smoothing. Lower value is smoother.
@export var rotation_sharpness : float = 12.0

## State
var active := false

## Grabstate used to represent hand grabbing per hand
class GrabState:
	var held : CircuitComponent
	var comp_pos : Vector3
	var hand_basis : Basis
	var comp_basis : Basis
	var scale : Vector3

## Currently grabbing hands are stored here with key [Hand] -> value [GrabState]
var _grabs : Dictionary = {}


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
		_grabs.clear()


func _process(delta : float) -> void:
	if not active:
		return

	for hand : Hand in _grabs:
		var grab : GrabState = _grabs[hand]

		var hand_global := components.to_global(hand.pinch_center)
		grab.held.global_position = hand_global + grab.comp_pos

		var rot_delta := hand.pinch_basis * grab.hand_basis.inverse()
		var target_q := (rot_delta * grab.comp_basis).get_rotation_quaternion()
		var current_q := grab.held.global_transform.basis.get_rotation_quaternion()
		var t := 1.0 - exp(-rotation_sharpness * delta)
		var smoothed_q := current_q.slerp(target_q, t)
		grab.held.global_transform.basis = Basis(smoothed_q).scaled(grab.scale)


## A hand began pinching: if it landed on a free component, grab it.
func _on_pinch_started(hand : Hand) -> void:
	if not active or _grabs.has(hand):
		return
	var comp := _query_component(hand.pinch_center)
	if comp == null:
		return
	# Stop grabbing an already grabbed component
	if _is_held(comp):
		return

	var grab := GrabState.new()
	grab.held = comp
	grab.comp_pos = comp.global_position - components.to_global(hand.pinch_center)
	grab.hand_basis = hand.pinch_basis
	grab.comp_basis = comp.global_transform.basis.orthonormalized()
	grab.scale = comp.scale
	_grabs[hand] = grab


## Process letting go of a component
func _on_pinch_released(hand : Hand) -> void:
	_grabs.erase(hand)


## Used to detect if one of the hand instances is actively holding the given component
func _is_held(comp : CircuitComponent) -> bool:
	for hand in _grabs:
		if _grabs[hand].held == comp:
			return true
	return false


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
