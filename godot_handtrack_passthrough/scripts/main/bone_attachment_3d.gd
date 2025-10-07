extends BoneAttachment3D

@export var head_path       : NodePath  # your XRCamera3D
@export var palm_axis       : String    = "y"    # "x", "y" or "z" 
@export var palm_sign       : float     =  1.0   # flip axis if needed
@export var show_threshold  : float     =  0.8   # how tightly you must look at palm to show menu
@export var hide_threshold  : float     =  0.6   # how far you must look away from menu to hide it
@export var menu_scale      : float     =  0.15
@export var menu_tilt_degrees : float = 15.0

# Cube Scenes
@export var cardozo_cube_scene : PackedScene
@export var bloom_cube_scene   : PackedScene
@export var hagood_cube_scene  : PackedScene
@export var chen_cube_scene    : PackedScene
@export var maguire_cube_scene : PackedScene

var head : Camera3D
var menu_node : Node3D = null
var has_positioned = false
var menu_visible = false

func _ready():
	head = get_node(head_path)
	set_process(true)
	menu_node = get_node("../../../../../../Viewport2Din3D")
	GlobalSignals.connect("block_button_pressed", _on_block_button_pressed)

func _process(_dt):
	var palm_pos = global_transform.origin
	var head_pos = head.global_transform.origin

	# Palm normal
	var palm_basis = global_transform.basis
	var palm_normal : Vector3 = palm_basis.z * palm_sign
	palm_normal = palm_normal.normalized()

	# Dir palm → head
	var dir_palm_to_head = (head_pos - palm_pos).normalized()
	var palm_dot = palm_normal.dot(dir_palm_to_head)

	# Dir head → palm
	var dir_head_to_palm = (palm_pos - head_pos).normalized()
	var head_forward = -head.global_transform.basis.z.normalized()
	var head_dot = head_forward.dot(dir_head_to_palm)

	# GlobalSignals.emit_signal("dot_products_updated", palm_dot, head_dot)

	# If menu is not shown, use palm visibility logic
	if not menu_visible:
		if palm_dot > show_threshold and head_dot > show_threshold:
			show_menu()
	else:
		# If menu is shown, use head→menu direction to hide it
		var to_menu = (menu_node.global_transform.origin - head.global_transform.origin).normalized()
		var dot_to_menu = head_forward.dot(to_menu)

		if dot_to_menu < hide_threshold:
			hide_menu()

func show_menu():
	menu_visible = true
	has_positioned = false

	if not menu_node.visible:
		menu_node.visible = true

	if not has_positioned:
		has_positioned = true

		# Position slightly above palm
		var palm_pos = global_transform.origin
		var offset = global_transform.basis.y.normalized() * 0.1
		menu_node.global_transform.origin = palm_pos + offset

		# Compute direction to camera and yaw only (project onto XZ)
		var to_camera = (head.global_transform.origin - menu_node.global_transform.origin)
		var to_camera_xz = Vector3(to_camera.x, 0.0, to_camera.z)
		if to_camera_xz.length_squared() < 1e-6:
			to_camera_xz = Vector3(0, 0, -1) # fallback

		to_camera_xz = to_camera_xz.normalized()
		# yaw that faces the camera. atan2 arguments: x then z gives yaw around Y.
		var yaw := atan2(to_camera_xz.x, to_camera_xz.z)

		# fixed pitch (tilt) in radians. Negative tilts 'up' toward world +Y.
		var pitch := -deg_to_rad(menu_tilt_degrees)
		var roll := 0.0

		# Build basis from (pitch, yaw + PI, roll) so the textured face faces camera.
		var rot_basis := Basis.from_euler(Vector3(pitch, yaw, roll)).orthonormalized()

		# Preserve any existing scale
		var cur_scale := menu_node.global_transform.basis.get_scale()
		menu_node.global_transform.basis = rot_basis.scaled(cur_scale)

		menu_node.scale = Vector3.ONE * menu_scale

		if menu_node.get_parent() != get_tree().current_scene:
			get_tree().current_scene.add_child(menu_node)
			menu_node.owner = get_tree().current_scene


func hide_menu():
	menu_visible = false
	menu_node.visible = false
	has_positioned = false

func _on_block_button_pressed(person):
	var scene : PackedScene
	match person:
		"cardozo": scene = cardozo_cube_scene
		"bloom":   scene = bloom_cube_scene
		"chen":    scene = chen_cube_scene
		"hagood":  scene = hagood_cube_scene
		"maguire": scene = maguire_cube_scene
		_: null

	if scene:
		var cube = scene.instantiate()
		cube.global_transform = self.global_transform
		$"../../../../../../Blocks".add_child(cube)
