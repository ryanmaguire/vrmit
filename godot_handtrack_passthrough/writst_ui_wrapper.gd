extends Node3D

@export var skeleton_path : NodePath   # path to your Skeleton3D
@export var head_path     : NodePath   # path to your XRCamera3D (your “head”)
@export var bone_name     : String     = "LeftHand"   # your palm bone name
@export var menu_path     : NodePath   # path to the XRToolsViewport2DIn3D (or its parent) under this node

@export var flat_threshold : float = 0.8   # how “flat” the palm must be (dot with Vector3.UP)
@export var tilt_threshold : float = 0.5   # how much the palm must tilt toward your face

var skeleton : Skeleton3D
var head     : Camera3D
var bone_idx : int
var menu     : Node   # the menu instance

func _ready():
	skeleton = get_node(skeleton_path)
	head     = get_node(head_path)
	bone_idx = skeleton.find_bone(bone_name)
	menu     = get_node(menu_path)
	# start hidden
	menu.visible = false
	set_process(true)

func _process(_dt):
	if bone_idx < 0:
		return

	# 1) get the palm bone's global transform
	var bone_xform : Transform3D = skeleton.get_bone_global_pose(bone_idx)

	# 2) orient this container to match the palm
	#    (preserves your local menu offset under this node)
	global_transform.basis = bone_xform.basis

	# 3) compute the “up” vector of the palm in world space
	var palm_up : Vector3 = bone_xform.basis.y.normalized()
	# 4) compute the camera’s forward direction
	var cam_fwd : Vector3 = -head.global_transform.basis.z.normalized()

	# 5) check pose: palm flat enough and tilted toward the face
	var is_flat   = palm_up.dot(Vector3.UP) > flat_threshold
	var is_tilted = palm_up.dot(cam_fwd) > tilt_threshold

	# 6) show or hide the menu
	menu.visible = (is_flat and is_tilted)
