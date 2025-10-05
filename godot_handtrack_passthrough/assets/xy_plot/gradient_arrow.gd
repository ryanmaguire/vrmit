@tool
# In a script attached to your MeshInstance3D
extends MeshInstance3D

'''func _ready() -> void:
	var vec = Vector3(0, 2, 0)
	var arrow_node = create_arrow(Vector3.ZERO, vec, Color.GREEN)
	add_child(arrow_node)'''

func create_arrow(direction: Vector3, color: Color = Color.RED):
	rotation = Vector3.ZERO
	transform.basis = Basis(Quaternion(transform.basis.y, direction))
	
	for c in get_children():
		c.queue_free()
				
	'''var arrow = Node3D.new()
	arrow.position = origin

	var length = direction.length()
	if length == 0:
		return arrow

	#var dir_norm = direction.normalized()

	# Construct a basis where Y points along dir_norm
	var up = Vector3.UP
	if abs(dir_norm.dot(up)) > 0.999:  # parallel, pick different up
		up = Vector3.RIGHT
	var basis = Basis().looking_at(global_position+dir_norm, up)'''

	# Shaft
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.bottom_radius = 0.05
	cylinder.top_radius = 0.05
	cylinder.height = direction.length() * 0.8
	shaft.mesh = cylinder
	var mat_shaft = StandardMaterial3D.new()
	mat_shaft.albedo_color = color
	shaft.material_override = mat_shaft

	# Shaft position: base at origin in local space
	var shaft_transform = Transform3D()
	shaft_transform.origin = Vector3(0, cylinder.height/2, 0)
	shaft.transform = shaft_transform
	add_child(shaft)

	# Head
	var head = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.bottom_radius = 0.1
	cone.top_radius = 0.0
	cone.height = direction.length() * 0.2
	head.mesh = cone
	var mat_head = StandardMaterial3D.new()
	mat_head.albedo_color = color
	head.material_override = mat_head

	var head_transform = Transform3D()
	head_transform.origin = Vector3(0, cylinder.height + cone.height/2, 0)
	head.transform = head_transform
	add_child(head)

	# Apply transform so Y-axis aligns with vector
	#arrow.transform = Transform3D(basis, origin)

	#add_child(arrow)
	#return arrow
	
