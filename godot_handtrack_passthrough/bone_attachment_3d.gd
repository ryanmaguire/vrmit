extends BoneAttachment3D

@export var head_path       : NodePath  # your XRCamera3D
@export var palm_axis       : String    = "y"    # "x", "y" or "z" 
@export var palm_sign       : float     =  1.0   # use –1 if you need the negative of that axis
@export var threshold       : float     =  0.8   # how tightly they must point at each other


# Cube Scenes
@export var cardozo_cube_scene : PackedScene
@export var bloom_cube_scene   : PackedScene
@export var hagood_cube_scene  : PackedScene
@export var chen_cube_scene  : PackedScene

var head : Camera3D

func _ready():
	head = get_node(head_path)
	set_process(true)
	GlobalSignals.connect("block_button_pressed", _on_block_button_pressed)

func _process(_dt):
	# 1) World positions
	var palm_pos = global_transform.origin
	var head_pos = head.global_transform.origin

	# 2) Direction from palm → head
	var dir_palm_to_head : Vector3 = (head_pos - palm_pos).normalized()

	# 3) Palm “normal” vector in world space
	var palm_basis : Basis = global_transform.basis
	var palm_normal : Vector3 = palm_basis.z * palm_sign # match palm_axis:
		#"x": palm_basis.x * palm_sign
		#"y": palm_basis.y * palm_sign
		#"z": palm_basis.z * palm_sign
		#_: Vector3.ZERO
	palm_normal = palm_normal.normalized()

	# 4) Dot-product for palm facing head
	var palm_dot = palm_normal.dot(dir_palm_to_head)

	# 5) Head forward vector (–Z is typically “forward” for cameras)
	var head_forward : Vector3 = -head.global_transform.basis.z.normalized()
	# Direction from head → palm
	var dir_head_to_palm : Vector3 = (palm_pos - head_pos).normalized()
	var head_dot = head_forward.dot(dir_head_to_palm)

	# 6) Are both pointing at each other?
	#print("palm_dot: " + str(palm_dot) + " | head_dot: " + str(head_dot))
	GlobalSignals.emit_signal("dot_products_updated", palm_dot, head_dot)
	if palm_dot > threshold and head_dot > threshold:
		show_menu()
	else:
		hide_menu()

func show_menu():
	#print("SHOW")
	$"../Wrist UI".visible = true

func hide_menu():
	#print("HIDE")
	$"../Wrist UI".visible = false
	
func _on_block_button_pressed(person):
	var scene : PackedScene
	match person:
		"cardozo": 
			scene = cardozo_cube_scene
		"bloom": 
			scene = bloom_cube_scene
		"chen": 
			scene = chen_cube_scene
		"hagood":
			scene = hagood_cube_scene
		_: null
	
	if scene:
		var cube = scene.instantiate()
		cube.global_transform = self.global_transform
		$"../../../../../../Blocks".add_child(cube)
	
