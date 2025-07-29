@tool
extends MeshInstance3D

@export var x_min: int = -5
@export var x_max: int = 5
@export var z_min: int = -5
@export var z_max: int = 5
@export var resolution: int = 20
@export var render_type: int = 2 # 0 for checkers, 1 for height, 2 for gradient, 3 for curvature
@export var checkers_size: int = 1
@export var expression: String = ""

var parsed_expression: Expression = Expression.new()

func _ready() -> void:
	GlobalSignals.connect("expression_entered", _on_expression_entered)

func _on_expression_entered(expr: String):
	print("New Expression: " + expr)
	expression = expr
	var parse_err = parsed_expression.parse(expression, ["x", "z"])
	if parse_err != OK:
		push_error("Failed to parse expression: '%s'" % expression)
		return
	_gen_mesh()

func _evaluate(x: float, z: float) -> float:
	var result = parsed_expression.execute([x, z])
	if parsed_expression.has_execute_failed():
		push_error("Evaluation failed for x=%.2f, z=%.2f" % [x, z])
		return 0.0
	return result

func _gen_mesh():
	print("Generating Mesh")
	var a_mesh = ArrayMesh.new()
	var vertices := PackedVector3Array([])
	var indices := PackedInt32Array([])
	var heights := PackedFloat32Array([])
	var h_min = INF
	var h_max = -INF
	var gradients := PackedVector2Array([])
	var g_min = INF
	var g_max = -INF
	var curvatures := PackedVector2Array([])
	var c_min = INF
	var c_max = -INF
	
	for x in range(x_min * resolution, x_max * resolution + 1):
		for z in range(z_min * resolution, z_max * resolution + 1):
			var X = float(x) / resolution
			var Z = float(z) / resolution
			var H = _evaluate(X, Z)
			vertices.append(Vector3(X, H, Z))
			if (x < x_max * resolution and z < z_max * resolution):
				heights.append(H)
			h_min = min(H, h_min)
			h_max = max(H, h_max)

	var offset = (z_max - z_min) * resolution + 1

	for x in range((x_max - x_min) * resolution):
		for z in range((z_max - z_min) * resolution):
			var h = heights[x * (offset - 1) + z]
			var hxl = heights[(x - 1) * (offset - 1) + z] if x > 0 else 0
			var hxr = heights[(x + 1) * (offset - 1) + z] if x < (x_max - x_min) * resolution - 1 else 0
			var hzl = heights[x * (offset - 1) + z - 1] if z > 0 else 0
			var hzr = heights[x * (offset - 1) + z + 1] if z < (z_max - z_min) * resolution - 1 else 0
			var G = Vector2(
				(hxr - h) * resolution if x == 0 else (h - hxl) * resolution if x == (x_max - x_min) * resolution - 1 else (hxr - hxl) * resolution / 2,
				(hzr - h) * resolution if z == 0 else (h - hzl) * resolution if z == (z_max - z_min) * resolution - 1 else (hzr - hzl) * resolution / 2
			)
			gradients.append(G)
			g_min = min(G.length(), g_min)
			g_max = max(G.length(), g_max)

			var C = Vector2(
				(hxr + hxl - h * 2) * resolution * resolution if x > 0 and x < (x_max - x_min) * resolution - 1 else 0,
				(hzr + hzl - h * 2) * resolution * resolution if z > 0 and z < (z_max - z_min) * resolution - 1 else 0
			)
			curvatures.append(C)
			c_min = min(C.length(), c_min)
			c_max = max(C.length(), c_max)

	for x in range((x_max - x_min) * resolution):
		for z in range((z_max - z_min) * resolution):
			indices.append(x * offset + z)
			indices.append((x + 1) * offset + z)
			indices.append(x * offset + z + 1)

			indices.append((x + 1) * offset + z)
			indices.append((x + 1) * offset + z + 1)
			indices.append(x * offset + z + 1)

	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)

	mesh = a_mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	for face_i in range(mdt.get_face_count()):
		var c: Color
		if render_type == 0:
			var row = ((face_i / 2) / (offset - 1)) / checkers_size
			var column = ((face_i / 2) % (offset - 1)) / checkers_size
			c = Color(1, 1, 1) if int(row + column) % 2 == 0 else Color(0, 0, 0)
		elif render_type == 1:
			var fraction = (heights[face_i / 2] - h_min) / (h_max - h_min)
			c = Color(fraction, fraction, fraction)
		elif render_type == 2:
			var fraction = (gradients[face_i / 2].length() - g_min) / (g_max - g_min)
			c = Color(fraction, fraction, fraction)
		elif render_type == 3:
			var fraction = (curvatures[face_i / 2].length() - c_min) / (c_max - c_min)
			c = Color(fraction, fraction, fraction)

		for v_i in range(3):
			var vid = mdt.get_face_vertex(face_i, v_i)
			mdt.set_vertex_color(vid, c)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
