extends Node

# Make sure this path matches your scene tree
@onready var scene_mgr: OpenXRFbSceneManager = $"../OpenXRFbSceneManager"

func _ready():
	# 1) Connect the completed signal
	scene_mgr.openxr_fb_scene_capture_completed.connect(_on_capture_done)

	# 2) Listen for your scan_surroundings signal
	#    (GlobalSignals must be an Autoload with that signal declared)
	GlobalSignals.connect("scan_surroundings", _on_scan_request)

func _on_scan_request() -> void:
	# At this point your XR session is running
	print("Requesting room scan…")
	scene_mgr.request_scene_capture()

func _on_capture_done(success: bool) -> void:
	if not success:
		GlobalSignals.debug_message.emit("Scene Capture Fail :'(")
		return

	GlobalSignals.debug_message.emit("Scene capture succeeded—building anchors!")
	# Remove old anchors if any
	if scene_mgr.are_scene_anchors_created():
		scene_mgr.remove_scene_anchors()
	# This will instance SpatialEntity.tscn for each piece of mesh
	scene_mgr.create_scene_anchors()
