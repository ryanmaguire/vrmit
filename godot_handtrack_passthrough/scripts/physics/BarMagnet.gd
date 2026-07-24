class_name BarMagnet extends FieldObject

var m : Vector3

func _init(pos : Vector3, m : Vector3, area : Area3D):
	self.object_type = ObjectType.BAR_MAGNET
	self.pos = pos
	self.m = m
	self.area = area
	mesh = area.find_child("MeshInstance3D")

func generate_field_line_seeds(count: int, radius: float, vector_field: Node3D) -> PackedVector3Array:
	var seeds := PackedVector3Array()
	if count <= 0:
		return seeds
		
	var m_dir := Vector3.UP
	if m.length() > 0.0001:
		m_dir = m.normalized()
		
	var side_a := m_dir.cross(Vector3.UP)
	if side_a.length() < 0.0001:
		side_a = m_dir.cross(Vector3.RIGHT)
	side_a = side_a.normalized()
	var side_b := m_dir.cross(side_a).normalized()

	var center := pos
	var golden_angle := PI * (3.0 - sqrt(5.0))
	var min_axial := 0.05
	var max_axial := 0.96

	for i in range(count):
		var distribution := (float(i) + 0.5) / float(count)
		var axial := lerpf(min_axial, max_axial, distribution)
		var radial_scale := sqrt(max(0.0, 1.0 - axial * axial))
		var angle := golden_angle * float(i)
		var radial := cos(angle) * side_a + sin(angle) * side_b
		var direction := (
			m_dir * axial +
			radial * radial_scale
		).normalized()
		seeds.append(center + direction * radius)

	return seeds
