extends Node

# ← adjust this path so it points at your SceneManager node
@onready var scene_mgr: OpenXRFbSceneManager = get_node("../OpenXRFbSceneManager")

func _ready():
	# 1) Wire up the capture-completed callback
	scene_mgr.openxr_fb_scene_capture_completed.connect(_on_capture_done)

	# 2) Listen for your custom “scan_surroundings” signal
	#    Make sure GlobalSignals is an Autoload singleton
	GlobalSignals.connect("scan_surroundings", _on_scan_surroundings)

func _on_scan_surroundings() -> void:
	# By now your XR session is running, so this will actually
	# pop up the Quest “Scan your room” UI.
	scene_mgr.request_scene_capture()

func _on_capture_done(success: bool) -> void:
	if not success:
		push_error("Scene capture failed or was cancelled")
		GlobalSignals.debug_message.emit("Scene captured failed")
		return

	# rebuild your anchors and spawn the SpatialEntity instances
	if scene_mgr.are_scene_anchors_created():
		scene_mgr.remove_scene_anchors()
	scene_mgr.create_scene_anchors()
