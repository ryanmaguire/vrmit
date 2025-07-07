extends Node3D

@export var head: Node3D
@export var left_hand: Node3D
@export var wrist_offset: Vector3 = Vector3(0, 0, -0.1)  # Offset applied in left hand's local space
@export var rotation_offset_degrees: Vector3 = Vector3(0, 180, 0)  # Correction rotation

func _process(_delta):
	if not head or not left_hand:
		return

	# Compute world-space offset position relative to left hand
	var wrist_position = left_hand.global_transform.origin + left_hand.global_transform.basis * wrist_offset

	# Set the origin without affecting rotation yet
	global_transform.origin = wrist_position

	# Look at the head from the new position
	look_at(head.global_transform.origin, Vector3.UP)

	# Apply a local rotation offset (e.g., flip 180 degrees if needed)
	rotate_object_local(Vector3.RIGHT, deg_to_rad(rotation_offset_degrees.x))
	rotate_object_local(Vector3.UP, deg_to_rad(rotation_offset_degrees.y))
	rotate_object_local(Vector3.FORWARD, deg_to_rad(rotation_offset_degrees.z))
