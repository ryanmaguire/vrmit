extends XRNode3D

# wherever you have your right-hand scene instanced:
func _ready():
	# 1) Grab your Skeleton3D
	var skeleton := $RightHandHumanoid2/RightHandHumanoid/Skeleton3D
	# 2) Create a BoneAttachment3D on the RightIndexTip bone
	var attach := BoneAttachment3D.new()
	attach.bone_name = "RightIndexTip"
	skeleton.add_child(attach)
	# 3) Load and instance the poke pointer under it
	var poke = "res://addons/godot-xr-tools/player/poke/poke.tscn"
	var poke_scn = load(poke)
	attach.add_child(poke_scn.instantiate())
