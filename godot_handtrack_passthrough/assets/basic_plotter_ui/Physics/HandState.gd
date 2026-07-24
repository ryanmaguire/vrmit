class_name HandState extends RefCounted

var hand_pose_detector : HandPoseDetector
var hand_tracker : XRHandTracker
var hand_data : HandPoseData

var pinch_center : Vector3
var direction : Vector3
var pinch_separation := 0.0
var direction_is_valid := false
var dst : float

var index_area : Area3D
var thumb_area : Area3D

# Magnet rotation state is kept per hand so two-hand interaction cannot
# overwrite a shared grab orientation.
var rotation_object = null
var rotation_initial_direction := Vector3.ZERO
var rotation_smoothed_direction := Vector3.ZERO
var rotation_initial_basis := Basis.IDENTITY
var rotation_initial_moment := Vector3.ZERO
var rotation_last_submitted_direction := Vector3.ZERO

func _init(hand_pose_detector : HandPoseDetector, index_area : Area3D, thumb_area : Area3D):
	self.hand_pose_detector = hand_pose_detector
	self.index_area = index_area
	self.thumb_area = thumb_area
	hand_tracker = self.hand_pose_detector.get_hand_tracker()
	
	
func update(vector_field : MeshInstance3D) -> void:
	if hand_pose_detector == null:
		return
	
	if hand_tracker == null:
		hand_tracker = hand_pose_detector.get_hand_tracker()
	
	hand_data = hand_pose_detector.get_current_data()
	dst = hand_data.dst_index
	
	var index_pos = hand_data._get_tip(
		hand_tracker,
		HandPoseData.Finger.INDEX
	).origin
	var thumb_pos = hand_data._get_tip(
		hand_tracker,
		HandPoseData.Finger.THUMB
	).origin
	
	pinch_center = vector_field.to_local((index_pos + thumb_pos) * 0.5)
	var pinch_vector: Vector3 = index_pos - thumb_pos
	pinch_separation = pinch_vector.length()
	direction_is_valid = pinch_separation >= 0.006
	if direction_is_valid:
		direction = (
			vector_field.global_transform.basis.inverse()
			* pinch_vector
		).normalized()

func begin_magnet_rotation(obj) -> void:
	if obj == null or not direction_is_valid:
		return
	rotation_object = obj
	rotation_initial_direction = direction
	rotation_smoothed_direction = direction
	rotation_initial_basis = obj.area.transform.basis.orthonormalized()
	rotation_initial_moment = obj.m
	rotation_last_submitted_direction = obj.m.normalized()

func clear_magnet_rotation() -> void:
	rotation_object = null
	rotation_initial_direction = Vector3.ZERO
	rotation_smoothed_direction = Vector3.ZERO
	rotation_initial_basis = Basis.IDENTITY
	rotation_initial_moment = Vector3.ZERO
	rotation_last_submitted_direction = Vector3.ZERO

func is_pinching() -> bool:
	if dst < 65:
		return true
	return false
	
func released() -> bool:
	if dst > 80:
		return true
	return false
