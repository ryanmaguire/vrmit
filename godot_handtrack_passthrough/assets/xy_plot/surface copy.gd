@tool
extends MeshInstance3D

@export var create = false
@export var update = false
@export var parse = false
@export var x_min: int
@export var x_max: int
@export var z_min: int
@export var z_max: int
@export var z_init: int
@export var g_init: Vector2
@export var runge_kutta_steps: int
@export var expression_z: String
@export var expression_dzdx: String
@export var expression_dzdy: String
@export var expression_d2zdx2: String
@export var expression_d2zdy2: String
@export var expression_d2zdxdy: String
@export var expression_implicit: String
@export var start_left: float
@export var start_right: float
@export var find_root = false
@export var resolution: int
@export var render_type: int # 0 for nothing, 1 for checkers, 2 for height, 3 for gradient, 4 for curvature, 5 for levels
@export var checkers_size: int
@export var levels_size: float
@export var arrows_spacing: int

@export var arrow : PackedScene

var function
var degree: int

var vertices : PackedVector3Array
var indices : PackedInt32Array
var heights : PackedFloat32Array
var h_min: float
var h_max: float
var gradients : PackedVector2Array
var g_min: float
var g_max: float
var curvatures : PackedVector2Array
var c_min: float
var c_max: float

var mdt : MeshDataTool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#arrow = load("res://assets/arrow.tscn")
	GlobalSignals.connect("expression_entered", _on_expression_entered)
	function = $Function
	function.initialize()
	#gen_mesh(x_min, x_max, z_min, z_max, resolution)
	
func _on_expression_entered(expr: String):
	#print("New Expression: " + expr)
	#expression_z = expr
	if expression_z != "":
		function.set_string(expression_z, 0)
	if expression_dzdx != "":
		function.set_string(expression_dzdx, 1)
	if expression_dzdy != "":
		function.set_string(expression_dzdy, -1)
	if expression_d2zdx2 != "":
		function.set_string(expression_d2zdx2, 2)
	if expression_d2zdy2 != "":
		function.set_string(expression_d2zdy2, -2)
	if expression_d2zdxdy != "":
		function.set_string(expression_d2zdxdy, 22)
	if expression_implicit != "":
		function.set_string(expression_implicit, 3)

func initialize_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	vertices = PackedVector3Array([])
	indices = PackedInt32Array([])
	heights = PackedFloat32Array([])
	gradients = PackedVector2Array([])
	curvatures = PackedVector2Array([])
	var totalPoints = ((xmax - xmin) * res + 1) * ((zmax - zmin) * res + 1);
	vertices.resize(totalPoints)
	indices.resize((xmax - xmin) * res * (zmax - zmin) * res * 6)
	heights.resize(totalPoints)
	gradients.resize(totalPoints)
	curvatures.resize(totalPoints)

func calculate_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	degree = function.getDegree()
	h_min = 1.79769e308
	h_max = -1.79769e308
	g_min = 1.79769e308
	g_max = -1.79769e308
	c_min = 1.79769e308
	c_max = -1.79769e308
	
	var X: float
	var Z: float
	var H: float
	var G: Vector2 = Vector2(0, 0)
	var C: Vector2 = Vector2(0, 0)
	
	var offset = (zmax - zmin) * res + 1
	
	for x in range(xmin * res, xmax * res + 1):
		for z in range(zmin * res, zmax * res + 1):
			X = float(x) / res
			Z = float(z) / res
			if degree == 0:	
				H = function.calculate(X, Z, 0, 0)
			elif degree == 1:
				#print(heights.size())
				if x == xmin * res and z == zmin * res:
					H = z_init
				elif x == xmin * res:
					H = runge_kutta(-1, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], 0, runge_kutta_steps, res).x
				elif z == zmin * res:
					H = runge_kutta(1, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], 0, runge_kutta_steps, res).x
				else:
					H = (runge_kutta(1, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], 0, runge_kutta_steps, res).x + runge_kutta(-1, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], 0, runge_kutta_steps, res).x) / 2
			elif degree == 2:
				#print(heights.size())
				if x == xmin * res and z == zmin * res:
					H = z_init
					G = g_init
				elif x == xmin * res:
					var temp = runge_kutta(-2, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], gradients[coordsToIndexReal(x, z - 1, true)].y, runge_kutta_steps, res)
					H = temp.x
					G.x = runge_kutta_cross(-2, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], gradients[coordsToIndexReal(x, z - 1, true)].x, gradients[coordsToIndexReal(x, z - 1, true)].y, runge_kutta_steps, res).x
					G.y = temp.y
				elif z == zmin * res:
					var temp = runge_kutta(2, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], gradients[coordsToIndexReal(x - 1, z, true)].x, runge_kutta_steps, res)
					H = temp.x
					G.x = temp.y
					G.y = runge_kutta_cross(2, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], gradients[coordsToIndexReal(x - 1, z, true)].x, gradients[coordsToIndexReal(x - 1, z, true)].y, runge_kutta_steps, res).y
				else:
					var tempX = runge_kutta(2, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], gradients[coordsToIndexReal(x - 1, z, true)].x, runge_kutta_steps, res)
					var tempZ = runge_kutta(-2, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], gradients[coordsToIndexReal(x, z - 1, true)].y, runge_kutta_steps, res)
					H = (tempX.x + tempZ.x) / 2
					var tempG = Vector2(runge_kutta_cross(-2, X, float(z - 1) / res, heights[coordsToIndexReal(x, z - 1, true)], gradients[coordsToIndexReal(x, z - 1, true)].x, gradients[coordsToIndexReal(x, z - 1, true)].y, runge_kutta_steps, res).x, runge_kutta_cross(2, float(x - 1) / res, Z, heights[coordsToIndexReal(x - 1, z, true)], gradients[coordsToIndexReal(x - 1, z, true)].x, gradients[coordsToIndexReal(x - 1, z, true)].y, runge_kutta_steps, res).y)
					G.x = (tempX.y + tempG.x) / 2
					G.y = (tempZ.y + tempG.y) / 2
				gradients[coordsToIndexReal(x, z, true)].x = G.x
				gradients[coordsToIndexReal(x, z, true)].y = G.y
				if (G.length() < g_min):
					g_min = G.length()
				if (G.length() > g_max):
					g_max = G.length()
			elif degree == 3:
				H = function.bisection(X, Z, 0, 1000)
			#vertices[coordsToIndexReal(x, z, true)].x = X
			#vertices[coordsToIndexReal(x, z, true)].y = H
			#vertices[coordsToIndexReal(x, z, true)].z = Z
			if (x < xmax * res and z < zmax * res or true):
				heights[coordsToIndexReal(x, z, true)] = H
			if H < h_min:
				h_min = H
			if H > h_max:
				h_max = H
	
	var hxl := 0
	var hxr := 0
	var hzl := 0
	var hzr := 0
	for x in range(0, (xmax - xmin) * res + 1):
		for z in range(0, (zmax - zmin) * res + 1):
			H = heights[coordsToIndex(x, z, true)]
			if (x > 0):
				hxl = heights[coordsToIndex(x - 1, z, true)]
			if (x < (xmax - xmin) * res):
				hxr = heights[coordsToIndex(x + 1, z, true)]
			if (z > 0): 
				hzl = heights[coordsToIndex(x, z - 1, true)]
			if (z < (zmax - zmin) * res):
				hzr = heights[coordsToIndex(x, z + 1, true)]
			if degree == 0 && degree == 3:
				G.x = (hxr-H)*res if x == 0 else (H-hxl)*res if x == (x_max - x_min) * res else (hxr-hxl)*res/2
				G.y = (hzr-H)*res if z == 0 else (H-hzl)*res if z == (z_max - z_min) * res else (hzr-hzl)*res/2
			elif degree == 1:
				G.x = function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], 1)
				G.y = function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], -1)
			if degree != 2:
				gradients[coordsToIndex(x, z, true)].x = G.x
				gradients[coordsToIndex(x, z, true)].y = G.y
				if (G.length() < g_min):
					g_min = G.length()
				if (G.length() > g_max):
					g_max = G.length()
			C.x = 0 if x == 0 else 0 if x == (x_max - x_min) * res else (hxr+hxl-H*2)*res*res
			C.y = 0 if z == 0 else 0 if z == (z_max - z_min) * res else (hzr+hzl-H*2)*res*res
			if (x < (xmax - xmin) * res and z < (zmax - zmin) * res or true):
				curvatures[coordsToIndex(x, z, true)].x = C.x
				curvatures[coordsToIndex(x, z, true)].y = C.y
				if (C.length() < c_min):
					c_min = C.length()
				if (C.length() > c_max):
					c_max = C.length()
	
	for x in range(0, (xmax - xmin) * res):
		for z in range(0, (zmax - zmin) * res):
			
			# front
			indices[coordsToIndex(x, z, false) * 6] = coordsToIndex(x, z, true)
			indices[coordsToIndex(x, z, false) * 6 + 1] = coordsToIndex(x + 1, z, true)
			indices[coordsToIndex(x, z, false) * 6 + 2] = coordsToIndex(x, z + 1, true)
			
			indices[coordsToIndex(x, z, false) * 6 + 3] = coordsToIndex(x + 1, z, true)
			indices[coordsToIndex(x, z, false) * 6 + 4] = coordsToIndex(x + 1, z + 1, true)
			indices[coordsToIndex(x, z, false) * 6 + 5] = coordsToIndex(x, z + 1, true)
			
			# bottom
			'''indices.append(x * offset + z)
			indices.append(x * offset + z + 1)
			indices.append((x + 1) * offset + z)
			
			indices.append((x + 1) * offset + z)
			indices.append(x * offset + z + 1)
			indices.append((x + 1) * offset + z + 1)'''

	print("Total vertices: " + str(vertices.size()))

func gen_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	var a_mesh = ArrayMesh.new()
	var offset = (zmax - zmin) * res + 1
	#print((x_max - x_min) * resolution * offset + (z_max - z_min) * resolution)
	
	'''var uvs = PackedVector2Array([
		Vector2(0,0),
		Vector2(1,0),
		Vector2(1,1),
	])'''
	
	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	
	mesh = a_mesh
	mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	for face_i in range(mdt.get_face_count()):
		# Pick or compute a Color for this triangle
		var c: Color
		if (render_type == 0):
			c = Color(1, 1, 1)
		if (render_type == 1):
			var row = ((face_i / 2) / (offset - 1)) / res
			var column = ((face_i / 2) % (offset - 1)) / res
			if ((row / checkers_size + column / checkers_size) % 2 == 0):
				c = Color(1, 1, 1)
			else:
				c = Color(0, 0, 0)
		elif (render_type == 2):
			var fraction = (heights[indexToIndex(face_i / 2, false)] - h_min) / (h_max - h_min);
			c = Color(fraction, fraction, fraction)
		elif (render_type == 3):
			var fraction = (gradients[indexToIndex(face_i / 2, false)].length() - g_min) / (g_max - g_min);
			c = Color(fraction, fraction, fraction)
		elif (render_type == 4):
			var fraction = (curvatures[indexToIndex(face_i / 2, false)].length() - c_min) / (c_max - c_min);
			c = Color(fraction, fraction, fraction)
		elif (render_type == 5):
			var fraction = (sin(resolution / 5 * heights[indexToIndex(face_i / 2, false)] * 2*PI / levels_size)/sin(heights[indexToIndex(face_i / 2, false)] * 2*PI / levels_size));
			c = Color(fraction, fraction, fraction)
		for v_i in range(3):
			var vid = mdt.get_face_vertex(face_i, v_i)
			mdt.set_vertex_color(vid, c)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	#mesh.get_surface_override_material().albedo_color = Color(1, 0, 0, 1)

	if arrow != null and false:
		print("arrowed")
		for x in range(0, (xmax - xmin) * res):
			for z in range(0, (zmax - zmin) * res):
				if x % arrows_spacing == 0 && z % arrows_spacing == 0:
					var new_arrow = arrow.instantiate()
					add_child(new_arrow)
					new_arrow.transform.origin = Vector3(float(x) / res + xmin, heights[x * (offset - 1) + z] + 0.1, float(z) / res + zmin)
					var g = gradients[x * (offset - 1) + z]
					new_arrow.setLength(g.length())
					new_arrow.setRotation(atan(g.y/g.x) + 0 if g.x > 0 else PI)

	'''var contours = []
	var threshold = 0
	for x in range(0, (xmax - xmin) * res - 1):
		for z in range(0, (zmax - zmin) * res - 1):
			var value: int = (1 if heights[x * (offset - 1) + z] > threshold else 0) + (2 if heights[(x + 1) * (offset - 1) + z] > threshold else 0) + (4 if heights[(x + 1) * (offset - 1) + z + 1] > threshold else 0) + (1 if heights[x * (offset - 1) + z + 1] > threshold else 0)
			if value == 0:
				pass
				#contours.append([Vector2((float(x) / res + xmin), Vector2()])
			elif value == 1:
				contours.append([Vector3(float(x + 0.5) / res + xmin, threshold + 10, float(z) / res + zmin), Vector3(float(x) / res + xmin, threshold + 10, float(z + 0.5) / res + zmin)])

	# Convert contours to line mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var curve := Curve3D.new()
	for seg in contours:
		st.add_vertex(seg[0])
		st.add_vertex(seg[1])
		curve.add_point(seg[0])
		curve.add_point(seg[1])
	$Path3D.set_curve(curve)
	var mesh = st.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)'''
	
	'''var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(vertices.size()):
		surface_tool.set_uv(uvs[i])
		surface_tool.add_vertex(vertices[i])
	for i in indices:
		surface_tool.add_index(i)
	surface_tool.generate_normals()
	a_mesh = surface_tool.commit()
	mesh = a_mesh'''
	
func update_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	#var a_mesh = ArrayMesh.new()
	# Assuming 'original_mesh' is an existing Mesh resource
	#a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())

	#mdt = MeshDataTool.new()
	#mdt.create_from_surface(mesh, 0) # Assuming surface 0

	var surface_data = mesh.surface_get_arrays(0) # Assuming surface 0
	var verts = surface_data[Mesh.ARRAY_VERTEX] as PackedVector3Array

	for i in range(mdt.get_vertex_count()):
		# Modify vertex position (e.g., move it along its normal)
		#vertex += mdt.get_vertex_normal(i) * 0.1
		#var xz := indexToCoordsReal(i, true)
		#mdt.set_vertex(i, Vector3(xz.x / res, heights[i], xz.y / res))
		#vertices[i].x = xz.x / res
		verts[i].y = heights[i]
		#vertices[i].z = xz.y / res


	#mesh = ArrayMesh.new()
	#mdt.commit_to_surface(mesh)
	# Replace the old mesh
	
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)

	#$MeshInstance3D.mesh = mesh

func gen():
	var start_time = Time.get_ticks_msec()
	initialize_mesh(x_min, x_max, z_min, z_max, resolution)
	calculate_mesh(x_min, x_max, z_min, z_max, resolution)
	gen_mesh(x_min, x_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	print("Elapsed time: " + str(end_time - start_time) + " ms")

	
func upd():
	var start_time = Time.get_ticks_msec()
	calculate_mesh(x_min, x_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	update_mesh(x_min, x_max, z_min, z_max, resolution)
	print("Elapsed time: " + str(end_time - start_time) + " ms")
	
func coordsToIndex(x: int, y: int, isBounds: bool) -> int:
	return x * ((z_max - z_min) * resolution + (1 if isBounds else 0)) + y
	
func coordsToIndexReal(x: int, y: int, isBounds: bool) -> int:
	return (x - x_min * resolution) * ((z_max - z_min) * resolution + (1 if isBounds else 0)) + y - z_min * resolution
	
func indexToCoords(index: int, isBounds: bool) -> Vector2:
	return Vector2(index / ((z_max - z_min) * resolution + (1 if isBounds else 0)), index % ((z_max - z_min) * resolution + (1 if isBounds else 0)))

func indexToCoordsReal(index: int, isBounds: bool) -> Vector2:
	return Vector2(index / ((z_max - z_min) * resolution + (1 if isBounds else 0)) + x_min * resolution, index % ((z_max - z_min) * resolution + (1 if isBounds else 0)) + z_min * resolution)
	
func indexToIndex(index: int, isBounds: bool) -> int:
	return coordsToIndex(indexToCoords(index, isBounds).x, indexToCoords(index, isBounds).y, !isBounds)
	
func runge_kutta(type: int, x_0: float, y_0: float, z_0: float, g_0: float, n: int, res: int) -> Vector2:
	var X: float = x_0
	var Y: float = y_0
	var Z: float = z_0
	var G: float = g_0

	if type == 1:
		for i in n:
			var k1: float = function.calculate(X, Y, Z, type)
			var k2: float = function.calculate(X + 0.5 / res / n, Y, Z + k1 * 0.5 / res / n, type)
			var k3: float = function.calculate(X + 0.5 / res / n, Y, Z + k2 * 0.5 / res / n, type)
			var k4: float = function.calculate(X + 1.0 / res / n, Y, Z + k3 / res / n, type)

			Z = Z + (k1 + 2*k2 + 2*k3 + k4) / 6 / res / n
			X = X + 1.0 / res / n
	if type == -1:
		for i in n:
			var k1: float = function.calculate(X, Y, Z, type)
			var k2: float = function.calculate(X, Y + 0.5 / res / n, Z + k1 * 0.5 / res / n, type)
			var k3: float = function.calculate(X, Y + 0.5 / res / n, Z + k2 * 0.5 / res / n, type)
			var k4: float = function.calculate(X, Y + 1.0 / res / n, Z + k3 / res / n, type)

			Z = Z + (k1 + 2*k2 + 2*k3 + k4) / 6 / res / n
			Y = Y + 1.0 / res / n
	if type == 2:
		for i in n:
			var k1: float = G
			var kk1: float = function.calculate(X, Y, Z, type)
			var k2: float = G + kk1 * 0.5 / res / n
			var kk2: float = function.calculate(X + 0.5 / res / n, Y, Z + k1 * 0.5 / res / n, type)
			var k3: float = G + kk2 * 0.5 / res / n
			var kk3: float = function.calculate(X + 0.5 / res / n, Y, Z + k2 * 0.5 / res / n, type)
			var k4: float = G + kk3 / res / n
			var kk4: float = function.calculate(X + 1.0 / res / n, Y, Z + k3 / res / n, type)

			G = G + (kk1 + 2*kk2 + 2*kk3 + kk4) / 6 / res / n
			Z = Z + (k1 + 2*k2 + 2*k3 + k4) / 6 / res / n
			X = X + 1.0 / res / n
	if type == -2:
		for i in n:
			var k1: float = G
			var kk1: float = function.calculate(X, Y, Z, type)
			var k2: float = G + kk1 * 0.5 / res / n
			var kk2: float = function.calculate(X, Y + 0.5 / res / n, Z + k1 * 0.5 / res / n, type)
			var k3: float = G + kk2 * 0.5 / res / n
			var kk3: float = function.calculate(X, Y + 0.5 / res / n, Z + k2 * 0.5 / res / n, type)
			var k4: float = G + kk3 / res / n
			var kk4: float = function.calculate(X, Y + 1.0 / res / n, Z + k3 / res / n, type)

			G = G + (kk1 + 2*kk2 + 2*kk3 + kk4) / 6 / res / n
			Z = Z + (k1 + 2*k2 + 2*k3 + k4) / 6 / res / n
			Y = Y + 1.0 / res / n

	return Vector2(Z, G)
	
func runge_kutta_cross(type: int, x_0: float, y_0: float, z_0: float, gx_0: float, gy_0: float, n: int, res: int) -> Vector2:
	var X: float = x_0
	var Y: float = y_0
	var Z: float = z_0
	var Gx: float = gx_0
	var Gy: float = gy_0

	if type == 2:
		for i in n:
			var k1: float = Gx
			var kk1: float = function.calculate(X, Y, Z, type)
			var kx1: float = function.calculate(X, Y, Z, 22)
			var k2: float = Gx + kk1 * 0.5 / res / n
			var kk2: float = function.calculate(X + 0.5 / res / n, Y, Z + k1 * 0.5 / res / n, type)
			var kx2: float = function.calculate(X + 0.5 / res / n, Y, Z + k1 * 0.5 / res / n, 22)
			var k3: float = Gx + kk2 * 0.5 / res / n
			var kk3: float = function.calculate(X + 0.5 / res / n, Y, Z + k2 * 0.5 / res / n, type)
			var kx3: float = function.calculate(X + 0.5 / res / n, Y, Z + k2 * 0.5 / res / n, 22)
			var k4: float = Gx + kk3 / res / n
			var kk4: float = function.calculate(X + 1.0 / res / n, Y, Z + k3 / res / n, type)
			var kx4: float = function.calculate(X + 1.0 / res / n, Y, Z + k3 / res / n, 22)

			Gx = Gx + (kk1 + 2*kk2 + 2*kk3 + kk4) / 6 / res / n
			Gy = Gy + (kx1 + 2*kx2 + 2*kx3 + kx4) / 6 / res / n
			Z = Z + (k1 + 2*k2 + 2*k3 + k4) / 6 / res / n
			X = X + 1.0 / res / n
	if type == -2:
		for i in n:
			var k1: float = Gy
			var kk1: float = function.calculate(X, Y, Z, type)
			var kx1: float = function.calculate(X, Y, Z, 22)
			var k2: float = Gy + kk1 * 0.5 / res / n
			var kk2: float = function.calculate(X, Y + 0.5 / res / n, Z + k1 * 0.5 / res / n, type)
			var kx2: float = function.calculate(X, Y + 0.5 / res / n, Z + k1 * 0.5 / res / n, 22)
			var k3: float = Gy + kk2 * 0.5 / res / n
			var kk3: float = function.calculate(X, Y + 0.5 / res / n, Z + k2 * 0.5 / res / n, type)
			var kx3: float = function.calculate(X, Y + 0.5 / res / n, Z + k2 * 0.5 / res / n, 22)
			var k4: float = Gy + kk3 / res / n
			var kk4: float = function.calculate(X, Y + 1.0 / res / n, Z + k3 / res / n, type)
			var kx4: float = function.calculate(X, Y + 1.0 / res / n, Z + k3 / res / n, 22)

			Gx = Gx + (kx1 + 2*kx2 + 2*kx3 + kx4) / 6 / res / n
			Gy = Gy + (kk1 + 2*kk2 + 2*kk3 + kk4) / 6 / res / n
			Z = Z + (kk1 + 2*kk2 + 2*kk3 + kk4) / 6 / res / n
			Y = Y + 1.0 / res / n

	return Vector2(Gx, Gy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if create:
		gen()
		create = false
	if update:
		upd()
		update = false
	if parse:
		_on_expression_entered("")
		parse = false
	if find_root:
		print(function.bisection(1.5, 1.5, start_left, start_right))
		find_root = false
