extends XROrigin3D

var selected_cube_scene: PackedScene = null
var times := 2  # Assuming you use this to stack cubes for testing

func _ready():
	await get_tree().process_frame

	# Connect to signal emitted when user selects a cube type
	GlobalSignals.spawn_mode_selected.connect(_on_spawn_mode_selected)
	
	# Optional: still support old signal if used
	if GlobalSignals.has_signal("place_cube_requested"):
		GlobalSignals.place_cube_requested.connect(_on_place_cube_requested)

func _on_spawn_mode_selected(scene: PackedScene):
	selected_cube_scene = scene
	# Optional: you can place immediately for testing
	# _on_place_cube_requested()

func _on_place_cube_requested():
	if selected_cube_scene:
		var cube = selected_cube_scene.instantiate()
		cube.global_transform.origin = Vector3(0, times, 0)
		#times += 1
		get_tree().current_scene.add_child(cube)
