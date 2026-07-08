class_name CircuitHands
extends Node

## Manager for hand tracking in the circuit system, though this class is extensible
## to other uses if needed.
## Maintains a left and right [Hand], resolves their [HandPoseDetector] from the
## scene, and their pwer frame behavior. Don't forget to manually set nodes
## through exported variables or assign proper group names


## Emitted when [param hand] begins pinching. Hand specific
signal hand_pinch_started(hand : Hand)

## Emitted when [param hand] releases a pinch. Hand specific
signal hand_pinch_released(hand : Hand)

const Hand = preload("res://assets/circuit_simulation/hand.gd")


## Manual setting for the left hand. Unset will default to [member left_detector_group]
@export var left_detector : HandPoseDetector

## Manual setting for the left hand. Unset will default to [member right_detector_group]
@export var right_detector : HandPoseDetector


## Group name for the left detector if not set manually. Stored in an immutable string
@export var group_left : StringName = &"l_hand_pose_detector"

## Group name for the left detector if not set manually. ren n imtable sting
@export var group_right : StringName = &"r_hand_pose_detector"


## Hand positionals (pinch centers, etc.) are expressed in local coordinates relative to this node:
@export var space : Node3D

## [member space] group to find the node in when it is unset
@export var group_space : StringName = &"circuit_components"

## Left hand state
var left : Hand

## Right hand state
var right : Hand


func _ready() -> void:
	# Handle resolving the proper objects and where to find everything
	if left_detector == null:
		left_detector = get_tree().get_first_node_in_group(group_left)
	if right_detector == null:
		right_detector = get_tree().get_first_node_in_group(group_right)
	if space == null:
		space = get_tree().get_first_node_in_group(group_space)

	# Create hand objects
	left = Hand.new(left_detector)
	right = Hand.new(right_detector)

	# Pass through the pinch signals to work at this level
	left.pinch_started.connect(func(): hand_pinch_started.emit(left))
	left.pinch_released.connect(func(): hand_pinch_released.emit(left))
	right.pinch_started.connect(func(): hand_pinch_started.emit(right))
	right.pinch_released.connect(func(): hand_pinch_released.emit(right))


func _process(_delta : float) -> void:
	# Update both hands
	left.update(space)
	right.update(space)


## Returns true when both hands are pinching
func both_pinching() -> bool:
	return left.is_pinching() and right.is_pinching()


## Distance in meters between the two pinch centers. Returns [constant -1] if either hand is not tracked.
func pinch_separation() -> float:
	if not left.is_tracked() or not right.is_tracked():
		return -1
	return left.pinch_center.distance_to(right.pinch_center)
