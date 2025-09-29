@tool
extends MeshInstance3D

@export var fill_material: StandardMaterial3D
@export var outline_material: StandardMaterial3D
@export var outline_offset: float = 0.01

var hasGenerated = false

var surface
var x_min
var x_max
var z_min
var z_max
var res

func _ready():
	hasGenerated = false
	surface = get_parent()
	
func generate_level_mesh_layers():
	"""
	Generates polygon layers for each integer y-level between the min and max y of the surface.
	"""
	for c in get_children():
		c.queue_free()

	x_min = surface.x_min
	x_max = surface.x_max
	z_min = surface.z_min
	z_max = surface.z_max
	res = surface.resolution

	# --- Find min and max y across the surface ---
	var min_y = INF
	var max_y = -INF
	for row in surface.heights:
		for col in row:
			for idx in col:
				var y_val = idx
				if y_val < min_y:
					min_y = y_val
				if y_val > max_y:
					max_y = y_val

	min_y = floor(min_y)
	max_y = ceil(max_y)

	# --- Generate polygon layers for each integer y ---
	for y_level in range(int(min_y), int(max_y) + 1):
		var loops = extract_level_loops(y_level)
		if loops.is_empty():
			continue
		var layer := create_polygon_layer_from_loops(loops, y_level)
		add_child(layer)
	
	hasGenerated = true;

func extract_level_loops(y_threshold: float) -> Array:
	var loops: Array = []
	if not surface.has_method("coordsToIndexReal") or surface.heights.is_empty():
		push_error("Surface does not provide heights or coordsToIndexReal")
		return loops

	var width = int((x_max - x_min) * res)
	var depth = int((z_max - z_min) * res)

	# --- Sample scalar field ---
	var values: Array = []
	values.resize((width + 1) * (depth + 1))
	for gz in range(depth + 1):
		for gx in range(width + 1):
			var x = x_min + gx / float(res)
			var z = z_min + gz / float(res)
			var idx = surface.coordsToIndexReal(int(x * res), int(z * res), true)
			var y_val = surface.heights[0][0][idx]
			values[gz * (width + 1) + gx] = y_val > y_threshold

	# --- Marching squares edge table ---
	var edge_table = {
		1:  [[Vector2(0,0.5), Vector2(0.5,0)]],
		2:  [[Vector2(0.5,0), Vector2(1,0.5)]],
		3:  [[Vector2(0,0.5), Vector2(1,0.5)]],
		4:  [[Vector2(1,0.5), Vector2(0.5,1)]],
		5:  [[Vector2(0,0.5), Vector2(0.5,0)], [Vector2(1,0.5), Vector2(0.5,1)]],
		6:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		7:  [[Vector2(0,0.5), Vector2(0.5,1)]],
		8:  [[Vector2(0.5,1), Vector2(0,0.5)]],
		9:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		10: [[Vector2(0.5,0), Vector2(1,0.5)], [Vector2(0.5,1), Vector2(0,0.5)]],
		11: [[Vector2(1,0.5), Vector2(0.5,1)]],
		12: [[Vector2(0,0.5), Vector2(1,0.5)]],
		13: [[Vector2(0.5,0), Vector2(1,0.5)]],
		14: [[Vector2(0,0.5), Vector2(0.5,0)]],
	}

	var segments: Array = []

	for gz in range(depth):
		for gx in range(width):
			var v0 = values[gz * (width + 1) + gx]
			var v1 = values[gz * (width + 1) + gx + 1]
			var v2 = values[(gz + 1) * (width + 1) + gx + 1]
			var v3 = values[(gz + 1) * (width + 1) + gx]
			var idx = int(v0) | int(v1) << 1 | int(v2) << 2 | int(v3) << 3

			# --- Interior edges via marching squares ---
			if idx != 0 and idx != 15 and edge_table.has(idx):
				for edge in edge_table[idx]:
					var p1 = Vector2(gx + edge[0].x, gz + edge[0].y)
					var p2 = Vector2(gx + edge[1].x, gz + edge[1].y)
					p1 = Vector2(x_min + p1.x / res, z_min + p1.y / res)
					p2 = Vector2(x_min + p2.x / res, z_min + p2.y / res)
					segments.append([p1, p2])

			# --- Boundary edges for active cells touching grid bounds ---
			var left   = gx == 0 or not values[gz * (width + 1) + (gx - 1)]
			var right  = gx == width - 1 or not values[gz * (width + 1) + (gx + 1)]
			var top    = gz == 0 or not values[(gz - 1) * (width + 1) + gx]
			var bottom = gz == depth - 1 or not values[(gz + 1) * (width + 1) + gx]

			if v0:
				if top:
					segments.append([
						Vector2(x_min + gx / res, z_min + gz / res),
						Vector2(x_min + (gx + 1) / res, z_min + gz / res)
					])
				if left:
					segments.append([
						Vector2(x_min + gx / res, z_min + gz / res),
						Vector2(x_min + gx / res, z_min + (gz + 1) / res)
					])
			if v2:
				if right:
					segments.append([
						Vector2(x_min + (gx + 1) / res, z_min + gz / res),
						Vector2(x_min + (gx + 1) / res, z_min + (gz + 1) / res)
					])
				if bottom:
					segments.append([
						Vector2(x_min + gx / res, z_min + (gz + 1) / res),
						Vector2(x_min + (gx + 1) / res, z_min + (gz + 1) / res)
					])

	# --- Chain into loops ---
	loops = _chain_segments_to_loops(segments)
	return loops





func _chain_segments_to_loops(segments: Array) -> Array:
	"""
	Chain raw line segments into closed loops.
	"""
	var loops: Array = []
	var used = {}

	for seg in segments:
		if seg in used:
			continue
		var loop: Array = [seg[0], seg[1]]
		used[seg] = true
		var extended = true
		while extended:
			extended = false
			for other in segments:
				if other in used:
					continue
				if loop.back().distance_to(other[0]) < 1e-4:
					loop.append(other[1])
					used[other] = true
					extended = true
				elif loop.back().distance_to(other[1]) < 1e-4:
					loop.append(other[0])
					used[other] = true
					extended = true
		if loop.size() > 2 and loop.front().distance_to(loop.back()) < 1e-3:
			loop.pop_back() # close
			loops.append(PackedVector2Array(loop))

	return loops



func create_polygon_layer_from_loops(loops: Array, y: float) -> Node3D:
	"""
	Creates a single Node3D layer for multiple disjoint loops.
	Each loop is a PackedVector2Array or Array of Vector2.
	"""
	var container := Node3D.new()
	if loops.is_empty():
		return container  # return an empty Node3D instead of null

	for loop in loops:
		if loop.size() < 3:
			continue

	for loop in loops:
		if loop.size() < 3:
			continue

		# convert 2D loop to 3D vertices
		var verts3: Array = []
		for p in loop:
			verts3.append(Vector3(p.x, y, p.y))

		# --- Fill mesh ---
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var poly: PackedVector2Array
		if typeof(loop) == TYPE_PACKED_VECTOR2_ARRAY:
			poly = loop
		else:
			poly = PackedVector2Array(loop)

		var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
		if indices.is_empty():
			indices = _ear_clip_triangulate(loop)

		for i in range(0, indices.size(), 3):
			var i0 = indices[i]
			var i1 = indices[i + 1]
			var i2 = indices[i + 2]
			st.set_normal(Vector3.UP)
			st.add_vertex(verts3[i0])
			st.set_normal(Vector3.UP)
			st.add_vertex(verts3[i1])
			st.set_normal(Vector3.UP)
			st.add_vertex(verts3[i2])

		var mesh := st.commit()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		if fill_material:
			mesh_instance.material_override = fill_material
		container.add_child(mesh_instance)

		# --- Outline ---
		'''var outline_mesh := ImmediateMesh.new()
		outline_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for v in verts3:
			outline_mesh.surface_add_vertex(Vector3(v.x, v.y + outline_offset, v.z))
		# close loop
		if verts3.size() > 0:
			var fv = verts3[0]
			outline_mesh.surface_add_vertex(Vector3(fv.x, fv.y + outline_offset, fv.z))
		outline_mesh.surface_end()

		var outline_instance := MeshInstance3D.new()
		outline_instance.mesh = outline_mesh
		if outline_material:
			outline_instance.material_override = outline_material
		container.add_child(outline_instance)'''

	return container


func _ear_clip_triangulate(points: Array) -> PackedInt32Array:
	"""
	Ear clipping triangulation fallback.
	Input: Array[Vector2] (must be simple polygon, counterclockwise preferred)
	Output: PackedInt32Array of triangle vertex indices
	"""
	var n = points.size()
	var indices: Array = []
	for i in range(n):
		indices.append(i)

	var triangles: Array = []

	while indices.size() > 3:
		var ear_found = false
		for i in range(indices.size()):
			var i0 = indices[(i - 1 + indices.size()) % indices.size()]
			var i1 = indices[i]
			var i2 = indices[(i + 1) % indices.size()]

			var p0: Vector2 = points[i0]
			var p1: Vector2 = points[i1]
			var p2: Vector2 = points[i2]

			# Check if convex
			if (p1 - p0).cross(p2 - p0) <= 0:
				continue

			# Check no other point inside triangle
			var ear_valid = true
			for j in indices:
				if j == i0 or j == i1 or j == i2:
					continue
				if _point_in_triangle(points[j], p0, p1, p2):
					ear_valid = false
					break

			if ear_valid:
				triangles.append_array([i0, i1, i2])
				indices.remove_at(i)
				ear_found = true
				break

		if not ear_found:
			push_warning("Ear clipping failed: polygon may be self-intersecting or not simple")
			break

	# Last triangle
	if indices.size() == 3:
		triangles.append_array([indices[0], indices[1], indices[2]])

	return PackedInt32Array(triangles)


func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a

	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)

	var denom = dot00 * dot11 - dot01 * dot01
	if abs(denom) < 1e-6:
		return false

	var u = (dot11 * dot02 - dot01 * dot12) / denom
	var v = (dot00 * dot12 - dot01 * dot02) / denom
	return u >= 0 and v >= 0 and (u + v) < 1
