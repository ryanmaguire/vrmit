class_name Hand extends RefCounted

## State for a single tracked hand.
## Use with [CircuitHands]

## Emitted when a pinch begins
signal pinch_started

## Emitted when a pinch ends
signal pinch_released

## Detector associated with the hand
var detector : HandPoseDetector

## May initially be undefined by testing
var tracker : XRHandTracker

## Latest pose data pulled from the last [methodupdate]
var data : HandPoseData

## Thumb-to-index distance (mm)
var dst : float = 0.0

## Midpoint of thumb and index tips relative to the space
var pinch_center : Vector3

## Provides a rotation for the pinches. Is currently based
## off of your palm for stability.
var pinch_basis : Basis

## Distance below which a pinch engages (mm). MUST be less than
## [member release_threshold] for proper hysteresis
var pinch_threshold : float = 30.0

## Distance above which a pinch releases (mm). MUST be greater
## than [member pinch_threshold] for proper hysteresis
var release_threshold : float = 40.0

# Current pinch state.
var _pinching : bool = false

## Initialization. Pass in the proper [HandPoseDetector] for the correct side
func _init(detectorInput : HandPoseDetector) -> void:
	detector = detectorInput
	if detectorInput:
		tracker = detectorInput.get_hand_tracker()


## Get refreshed data about this hand. Ideally this should be called once a frame.
## Pass in a [Node3D] that is where coordinates will be relative to.
func update(space : Node3D) -> void:
	if detector == null:
		return

	# Tracker still may not have returned
	if tracker == null:
		tracker = detector.get_hand_tracker()
		if tracker == null:
			return

	# Get latest data
	data = detector.get_current_data()
	if data == null:
		return

	# Actually pick out useful data
	dst = data.dst_index
	var index_pos := tracker.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP).origin
	var thumb_pos := tracker.get_hand_joint_transform(XRHandTracker.HAND_JOINT_THUMB_TIP).origin
	var center := (index_pos + thumb_pos) * 0.5
	pinch_center = space.to_local(center)
	pinch_basis = tracker.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM).basis

	# Hysteresis
	if _pinching:
		if dst > release_threshold:
			_pinching = false
			pinch_released.emit()
	else:
		if dst < pinch_threshold:
			_pinching = true
			pinch_started.emit()


## Returns true while the hand is pinching
func is_pinching() -> bool:
	return _pinching


## Debug function to indivate whether both the tracker exists and is outputting data
func is_tracked() -> bool:
	return tracker != null and data != null
