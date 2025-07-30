extends XRNode3D

# wherever you have your right-hand scene instanced:
func _ready():
	# 1) Grab your Skeleton3D
	var skeleton := $RightHandHumanoid2/RightHandHumanoid/Skeleton3D
	# 2) Create a BoneAttachment3D on the RightIndexTip bone
	var poke_attach := BoneAttachment3D.new()
	var laser_attach := BoneAttachment3D.new()
	
	poke_attach.bone_name = "RightIndexTip"
	laser_attach.bone_name = "RightIndexTip"
	skeleton.add_child(poke_attach)
	skeleton.add_child(laser_attach)
	# 3) Load and instance the poke pointer under it
	var poke = "res://addons/godot-xr-tools/player/poke/poke.tscn"
	var poke_scn = load(poke)
	poke_attach.add_child(poke_scn.instantiate())

	var laser = "res://addons/godot-xr-tools/functions/function_pointer.tscn"
	var laser_scn = load(laser)
	laser_attach.add_child(laser_scn.instanciate())
