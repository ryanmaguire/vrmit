class_name PointCharge extends FieldObject

var q : float

func _init(pos : Vector3, q : float, area : Area3D):
	self.object_type = ObjectType.POINT_CHARGE
	self.pos = pos
	self.q = q
	self.area = area
	mesh = area.find_child("MeshInstance3D")
	
func fibonacci_sphere_dir(i, N):
	var golden_angle = PI * (3.0 - sqrt(5.0))
	var y = 1.0 - (2.0 * i) / (N - 1.0)

	var radius = sqrt(1.0 - y * y)
	var theta = golden_angle * i
	var x = cos(theta) * radius
	var z = sin(theta) * radius
	
	return Vector3(x, y, z).normalized()
	
func generate_field_line_seeds(N, radius, vector_field):
	var positions : Array
	for i in range(N):
		var dir = fibonacci_sphere_dir(i, N)
		var local_pos = vector_field.to_local(mesh.global_position)
		positions.append(local_pos + dir * radius)
	return positions
