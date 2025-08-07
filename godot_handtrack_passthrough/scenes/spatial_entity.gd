extends StaticBody3D

@onready var label: Label3D = $"Label3D"
func _ready():
	GlobalSignals.connect("toggle_mesh_visibility", _on_toggle_mesh_visibility)
func setup_scene(entity: OpenXRFbSpatialEntity) -> void:
	# 1) Semantic label (e.g. "TABLE")
	var tags = entity.get_semantic_labels()
	if tags.size():
		label.text = tags[0]
	else:
		label.text = "?"

	# 2) Collision shape
	var cs = entity.create_collision_shape()
	if cs:
		add_child(cs)  # CollisionShape3D under this StaticBody3D

	# 3) Visible mesh
	var mi: MeshInstance3D = entity.create_mesh_instance()
	if mi:
		add_child(mi)

		# 4) Occluder for proper depth occlusion
		#var oc = Occluder3D.new()
		#oc.mesh = mi.mesh
		#add_child(oc)
func _on_toggle_mesh_visibility():
	self.visible = !self.visible
