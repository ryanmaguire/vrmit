class_name HandState extends RefCounted

var hand_pose_detector : HandPoseDetector
var hand_tracker : XRHandTracker
var hand_data : HandPoseData

var pinch_center : Vector3
var dst : float

func _init(hand_pose_detector : HandPoseDetector):
	self.hand_pose_detector = hand_pose_detector
	hand_tracker = self.hand_pose_detector.get_hand_tracker()
	
func update(vector_field : MeshInstance3D) -> void:
	if hand_pose_detector == null:
		return
	
	if hand_tracker == null:
		hand_tracker = hand_pose_detector.get_hand_tracker()
	
	hand_data = hand_pose_detector.get_current_data()
	dst = hand_data.dst_index
	
	var index_pos = hand_data._get_tip(hand_tracker, HandPoseData.Finger.INDEX).origin
	var thumb_pos = hand_data._get_tip(hand_tracker, HandPoseData.Finger.THUMB).origin
	
	pinch_center = vector_field.to_local((index_pos + thumb_pos) * 0.5)

func is_pinching() -> bool:
	if dst < 65:
		return true
	return false
	
func released() -> bool:
	if dst > 80:
		return true
	return false
