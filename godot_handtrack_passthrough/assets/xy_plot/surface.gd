@tool
extends MeshInstance3D

@export var create = false
@export var update = false
@export var parse = false
const a_min: int = -10
const a_max: int = 10
@export_range(a_min, a_max, 0.01) var a: float = 0
@export var x_min: int
@export var x_max: int
@export var z_min: int
@export var z_max: int
@export var z_init: int
@export var g_init: Vector2
@export var runge_kutta_steps: int
@export var expression: String
#@export var start_left: float
#@export var start_right: float
#@export var find_root = false
@export var resolution: int
@export var render_type: int # 0 for nothing, 1 for checkers, 2 for height, 3 for gradient, 4 for curvature, 5 for levels
@export var checkers_size: int
@export var levels_size: float
@export var arrows_spacing: int
@export var is_rotating: bool = true
@export var locked_spatial_rotation: bool = true

@export_range(-20, 20, 0.01) var cursorX: float = 0
@export_range(-20, 20, 0.01) var cursorZ: float = 0
var last_cursorX: float
var last_cursorZ: float
@export var show_tangent_plane: bool
@export var show_gradient_arrow: bool
@export var show_level_curves: bool
@export var hide_surface: bool
var last_hide_surface: bool


@export var surface_material: Material
@export var surface_material_empty: Material
#@export var arrow : PackedScene

@export var function : Node3D
@export var cursor_dot : Node3D
@export var tangent_plane : Node3D
@export var gradient_arrow : Node3D
@export var level_curves : Node3D


var degree: int
var layerz: PackedInt32Array
var last_a: float

var vertices = []
var indices = []
var heights = []
var h_min: float
var h_max: float
var gradients = []
var g_min: float
var g_max: float
var curvatures = []
var c_min: float
var c_max: float

var heights_slider = []

var mdt : MeshDataTool

var _locked_basis: Basis



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#arrow = load("res://assets/arrow.tscn")
	_locked_basis = global_transform.basis
	GlobalSignals.connect("expression_entered", _on_expression_entered)
	GlobalSignals.connect("update_slider", _on_update_slider)
	GlobalSignals.connect("update_function_scale", _on_update_slider)
	GlobalSignals.connect("set_rotating", _on_set_rotating)
	GlobalSignals.connect("update_plot_scale", _on_update_plot_scale)
	
	# NEW: UI → surface controls
	if GlobalSignals.has_signal("set_level_curves"):
		GlobalSignals.connect("set_level_curves", _on_set_level_curves)
	if GlobalSignals.has_signal("set_tangent_plane"):
		GlobalSignals.connect("set_tangent_plane", _on_set_tangent_plane)
	if GlobalSignals.has_signal("set_grad_vector"):
		GlobalSignals.connect("set_grad_vector", _on_set_grad_vector)
	if GlobalSignals.has_signal("set_plane_grad_location"):
		GlobalSignals.connect("set_plane_grad_location", _on_set_plane_grad_location)
	if GlobalSignals.has_signal("set_plot_alpha"):
		GlobalSignals.connect("set_plot_alpha", _on_set_plot_alpha)
		
	if function:
		function.initialize()
	if tangent_plane:
		tangent_plane.visible = false
	_on_expression_entered("0")
	show_tangent_plane = false
	show_gradient_arrow = false
	show_level_curves = false
	hide_surface = false
	rotation_degrees = Vector3(0, 0, 0)
	#gen_mesh(x_min, x_max, z_min, z_max, resolution)


func _on_expression_entered(expr: String):
	#print("New Expression: " + expr)
	#expression_z = expr
	if (expr == ""): 
		function.set_string(expression, 0)
	else:
		function.set_string(expr, 0)
	gen()
	
func _on_update_slider(aye: float):
	a = aye
	upd_slider()
	
func _on_set_rotating(rotating: bool):
	is_rotating = rotating

func initialize_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	'''vertices = PackedVector3Array([])
	indices = PackedInt32Array([])
	heights = PackedFloat32Array([])
	gradients = PackedVector2Array([])
	curvatures = PackedVector2Array([])'''
	#var totalPoints = (xmax - xmin + 1) * (zmax - zmin + 1);
	#vertices.resize(totalPoints)
	#indices.resize(totalPoints * 6)
	#heights.resize(totalPoints)
	#gradients.resize(totalPoints)
	#curvatures.resize(totalPoints)

func calculate_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	degree = function.getDegree()
	layerz = [1, 1, 1]
	h_min = 1.79769e308
	h_max = -1.79769e308
	g_min = 1.79769e308
	g_max = -1.79769e308
	c_min = 1.79769e308
	c_max = -1.79769e308
	
	vertices = [[], [], []]
	indices = [[], [], []]
	heights = [[], [], []]
	gradients = [[], [], []]
	curvatures = [[], [], []]
	
	heights_slider = [[], [], []] # axis (z, x, y), layers, a's, heights
	
	var X: float
	var Z: float
	var H: float
	var Hs: PackedFloat32Array
	var Htemp = []
	
	if function.hasSlider:
		for i in 3:
			heights_slider[i].append([])
			for A in range(a_min, a_max + 1):
				heights_slider[i][len(heights_slider[i]) - 1].append(PackedFloat32Array())
	for x in range(xmin * res, xmax * res + 1):
		for z in range(zmin * res, zmax * res + 1):
			X = float(x) / res
			Z = float(z) / res
			var G: Vector2
			if degree == 0:
				if function.hasSlider:
					H = function.calculate_a(X, Z, 0, a, 0)
					for A in range(a_min, a_max + 1):
						heights_slider[0][0][sliderToIndex(A)].append(function.calculate_a(X, Z, 0, A, 0));
				else:
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
				gradients.append(G)
				if (G.length() < g_min):
					g_min = G.length()
				if (G.length() > g_max):
					g_max = G.length()
			elif degree == 3:
				if function.hasSlider:
					Hs = function.find_all_roots(X, Z, a, 0)
					Htemp = [] # a's, layers
					for A in range(a_min, a_max + 1):
						Htemp.append(function.find_all_roots(X, Z, A, 0));
						for i in len(Htemp[len(Htemp) - 1]):
							if Htemp[len(Htemp) - 1][i] < h_min:
								h_min = Htemp[len(Htemp) - 1][i]
							if Htemp[len(Htemp) - 1][i] > h_max:
								h_max = Htemp[len(Htemp) - 1][i]
						if len(Htemp[len(Htemp) - 1]) > layerz[0]:
							layerz[0] = len(Htemp[len(Htemp) - 1])
				else:
					Hs = function.find_all_roots(X, Z, a, 0)
					for i in len(Hs):
						if Hs[i] < h_min:
							h_min = Hs[i]
						if Hs[i] > h_max:
							h_max = Hs[i]
				if len(Hs) > layerz[0]:
					layerz[0] = len(Hs)
			while len(vertices[0]) < layerz[0]:
				vertices[0].append(PackedVector3Array())
				indices[0].append(PackedInt32Array())
				heights[0].append(PackedFloat32Array())
				gradients[0].append(PackedVector2Array())
				curvatures[0].append(PackedVector2Array())
				for i in len(vertices[0][0]):
					vertices[0][len(vertices[0]) - 1].append(Vector3(X, NAN, Z))
					heights[0][len(vertices[0]) - 1].append(NAN)
					gradients[0][len(vertices[0]) - 1].append(Vector2(0, 0))
					curvatures[0][len(vertices[0]) - 1].append(Vector2(0, 0))
			if function.hasSlider:
				#print(Htemp)
				while len(heights_slider[0]) < layerz[0]:
					heights_slider[0].append([])
					for A in range(a_min, a_max + 1):
						heights_slider[0][len(heights_slider[0]) - 1].append(PackedFloat32Array())
						for i in len(heights_slider[0][0][0]):
							heights_slider[0][len(heights_slider[0]) - 1][sliderToIndex(A)].append(NAN)
				#print(heights_slider)
				if degree == 3:
					for A in range(a_min, a_max + 1):
						for i in len(Htemp[sliderToIndex(A)]):
							#print(len(heights_slider))
							#print(len(heights_slider[0]))
							#print(len(heights_slider[0][0]))
							#print(len(Htemp))
							#print(len(Htemp[0]))
							heights_slider[0][i][sliderToIndex(A)].append(Htemp[sliderToIndex(A)][i])
						for i in range(len(Htemp[sliderToIndex(A)]), layerz[0]):
							heights_slider[0][i][sliderToIndex(A)].append(NAN)
			if degree == 3:
				for i in len(Hs):
					H = Hs[i]
					vertices[0][i].append(Vector3(X, H, Z))
					#if (x < xmax * res and z < zmax * res or true):
					heights[0][i].append(H);
				for i in range(len(Hs), len(vertices[0])):
					H = NAN
					vertices[0][i].append(Vector3(X, H, Z))
					#if (x < xmax * res and z < zmax * res or true):
					heights[0][i].append(H);
			else:
				vertices[0][0].append(Vector3(X, H, Z))
				heights[0][0].append(H);
			if H < h_min:
				h_min = H
			if H > h_max:
				h_max = H
	
	# solve for x
	if degree == 3 and false:
		for x in range(zmin * res, zmax * res + 1):
			for z in range(floor(h_min) * res, ceil(h_max) * res + 1):
				X = float(x) / res
				Z = float(z) / res
				if function.hasSlider:
					Hs = function.find_all_roots(X, Z, a, 0)
					#Hs = function.find_all_roots(Y, X, a, 0)
					Htemp = [] # a's, layers
					for A in range(a_min, a_max + 1):
						Htemp.append(function.find_all_roots(X, Z, A, 1));
						if len(Htemp[len(Htemp) - 1]) > layerz[1]:
							layerz[1] = len(Htemp[len(Htemp) - 1])
				else:
					Hs = function.find_all_roots(X, Z, a, 1)
				if len(Hs) > layerz[1]:
					layerz[1] = len(Hs)
				while len(vertices[1]) < layerz[1]:
					vertices[1].append(PackedVector3Array())
					indices[1].append(PackedInt32Array())
					heights[1].append(PackedFloat32Array())
					gradients[1].append(PackedVector2Array())
					curvatures[1].append(PackedVector2Array())
					for i in len(vertices[1][0]):
						vertices[1][len(vertices[1]) - 1].append(Vector3(X, NAN, Z))
						heights[1][len(vertices[1]) - 1].append(NAN)
						gradients[1][len(vertices[1]) - 1].append(Vector2(0, 0))
						curvatures[1][len(vertices[1]) - 1].append(Vector2(0, 0))
				if function.hasSlider:
					#print(Htemp)
					while len(heights_slider[1]) < layerz[1]:
						heights_slider[1].append([])
						for A in range(a_min, a_max + 1):
							heights_slider[1][len(heights_slider[1]) - 1].append(PackedFloat32Array())
							for i in len(heights_slider[1][0][0]):
								heights_slider[1][len(heights_slider[1]) - 1][sliderToIndex(A)].append(NAN)
					#print(heights_slider)
					for A in range(a_min, a_max + 1):
						for i in len(Htemp[sliderToIndex(A)]):
							#print(len(heights_slider))
							#print(len(heights_slider[0]))
							#print(len(heights_slider[0][0]))
							#print(len(Htemp))
							#print(len(Htemp[0]))
							heights_slider[1][i][sliderToIndex(A)].append(Htemp[sliderToIndex(A)][i])
						for i in range(len(Htemp[sliderToIndex(A)]), layerz[1]):
							heights_slider[1][i][sliderToIndex(A)].append(NAN)
				for i in len(Hs):
					H = Hs[i]
					vertices[1][i].append(Vector3(H, Z, X))
					#if (x < xmax * res and z < zmax * res or true):
					heights[1][i].append(H);
				for i in range(len(Hs), len(vertices[1])):
					H = NAN
					vertices[1][i].append(Vector3(H, Z, X))
					#if (x < xmax * res and z < zmax * res or true):
					heights[1][i].append(H);
					
		for x in range(floor(h_min) * res, ceil(h_max) * res + 1):
			for z in range(xmin * res, xmax * res + 1):
				X = float(x) / res
				Z = float(z) / res
				if function.hasSlider:
					Hs = function.find_all_roots(X, Z, a, 0)
					#Hs = function.find_all_roots(Y, X, a, 0)
					Htemp = [] # a's, layers
					for A in range(a_min, a_max + 1):
						Htemp.append(function.find_all_roots(X, Z, A, 2));
						if len(Htemp[len(Htemp) - 1]) > layerz[2]:
							layerz[2] = len(Htemp[len(Htemp) - 1])
				else:
					Hs = function.find_all_roots(X, Z, a, 2)
				if len(Hs) > layerz[2]:
					layerz[2] = len(Hs)
				while len(vertices[2]) < layerz[2]:
					vertices[2].append(PackedVector3Array())
					indices[2].append(PackedInt32Array())
					heights[2].append(PackedFloat32Array())
					gradients[2].append(PackedVector2Array())
					curvatures[2].append(PackedVector2Array())
					for i in len(vertices[2][0]):
						vertices[2][len(vertices[2]) - 1].append(Vector3(X, NAN, Z))
						heights[2][len(vertices[2]) - 1].append(NAN)
						gradients[2][len(vertices[2]) - 1].append(Vector2(0, 0))
						curvatures[2][len(vertices[2]) - 1].append(Vector2(0, 0))
				if function.hasSlider:
					#print(Htemp)
					while len(heights_slider[2]) < layerz[2]:
						heights_slider[2].append([])
						for A in range(a_min, a_max + 1):
							heights_slider[2][len(heights_slider[2]) - 1].append(PackedFloat32Array())
							for i in len(heights_slider[2][0][0]):
								heights_slider[2][len(heights_slider[2]) - 1][sliderToIndex(A)].append(NAN)
					#print(heights_slider)
					for A in range(a_min, a_max + 1):
						for i in len(Htemp[sliderToIndex(A)]):
							#print(len(heights_slider))
							#print(len(heights_slider[0]))
							#print(len(heights_slider[0][0]))
							#print(len(Htemp))
							#print(len(Htemp[0]))
							heights_slider[2][i][sliderToIndex(A)].append(Htemp[sliderToIndex(A)][i])
						for i in range(len(Htemp[sliderToIndex(A)]), layerz[2]):
							heights_slider[2][i][sliderToIndex(A)].append(NAN)
				for i in len(Hs):
					H = Hs[i]
					vertices[2][i].append(Vector3(Z, X, H))
					#if (x < xmax * res and z < zmax * res or true):
					heights[2][i].append(H);
				for i in range(len(Hs), len(vertices[2])):
					H = NAN
					vertices[2][i].append(Vector3(Z, X, H))
					#if (x < xmax * res and z < zmax * res or true):
					heights[2][i].append(H);
	
	var offset = (zmax - zmin) * res + 1
	
	var hxl : float = 0
	var hxr : float = 0
	var hzl : float = 0
	var hzr : float = 0
	
	for x in range(0, (xmax - xmin) * res + 1):
		for z in range(0, (zmax - zmin) * res + 1):
			H = heights[0][0][coordsToIndex(x, z, true)]
			hxl = 0
			hxr = 0
			hzl = 0
			hzr = 0
			if (x > 0):
				hxl = heights[0][0][coordsToIndex(x - 1, z, true)]
			if (x < (xmax - xmin) * res):
				hxr = heights[0][0][coordsToIndex(x + 1, z, true)]
			if (z > 0): 
				hzl = heights[0][0][coordsToIndex(x, z - 1, true)]
			if (z < (zmax - zmin) * res):
				hzr = heights[0][0][coordsToIndex(x, z + 1, true)]
			var G : Vector2
			G = Vector2((hxr-H)*res if x == 0 else (H-hxl)*res if x == (x_max - x_min) * res else (hxr-hxl)*res/2, (hzr-H)*res if z == 0 else (H-hzl)*res if z == (z_max - z_min) * res else (hzr-hzl)*res/2)	
			#elif degree == 1:
				#G = Vector2(function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], 1), function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], -1))
			gradients[0].append(G)
			if (G.length() < g_min):
				g_min = G.length()
			if (G.length() > g_max):
				g_max = G.length()
	
	if (render_type == 3 || render_type == 4):
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
				var G : Vector2
				if degree == 0 && degree == 3:
					G = Vector2((hxr-H)*res if x == 0 else (H-hxl)*res if x == (x_max - x_min) * res else (hxr-hxl)*res/2, (hzr-H)*res if z == 0 else (H-hzl)*res if z == (z_max - z_min) * res else (hzr-hzl)*res/2)	
				elif degree == 1:
					G = Vector2(function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], 1), function.calculate(float(x) / res + xmin, float(z) / res + zmin, heights[coordsToIndex(x, z, true)], -1))
				if degree != 2:
					gradients.append(G)
					if (G.length() < g_min):
						g_min = G.length()
					if (G.length() > g_max):
						g_max = G.length()
				var C = Vector2(0 if x == 0 else 0 if x == (x_max - x_min) * res else (hxr+hxl-H*2)*res*res, 0 if z == 0 else 0 if z == (z_max - z_min) * res else (hzr+hzl-H*2)*res*res)
				if (x < (xmax - xmin) * res and z < (zmax - zmin) * res or true):
					curvatures.append(C)
					if (C.length() < c_min):
						c_min = C.length()
					if (C.length() > c_max):
						c_max = C.length()
	
	for i in len(heights[0]):
		for x in range(0, (xmax - xmin) * res):
			for z in range(0, (zmax - zmin) * res):
				
				#if (coordsToIndex(x + 1, z + 1, true) < len(vertices[i])):
					# front
				indices[0][i].append(coordsToIndex(x, z, true))
				indices[0][i].append(coordsToIndex(x + 1, z, true))
				indices[0][i].append(coordsToIndex(x, z + 1, true))
				
				indices[0][i].append(coordsToIndex(x + 1, z, true))
				indices[0][i].append(coordsToIndex(x + 1, z + 1, true))
				indices[0][i].append(coordsToIndex(x, z + 1, true))
				
				# bottom
				'''indices.append(x * offset + z)
				indices.append(x * offset + z + 1)
				indices.append((x + 1) * offset + z)
				
				indices.append((x + 1) * offset + z)
				indices.append(x * offset + z + 1)
				indices.append((x + 1) * offset + z + 1)'''
				
	return
	for i in len(heights[1]):
		for x in range(0, (zmax - zmin) * res):
			for z in range(0, (ceil(h_max) - floor(h_min)) * res):
				
				#if (coordsToIndex(x + 1, z + 1, true) < len(vertices[i])):
					# front
				indices[1][i].append(coordsToIndexH(x, z, true))
				indices[1][i].append(coordsToIndexH(x + 1, z, true))
				indices[1][i].append(coordsToIndexH(x, z + 1, true))
				
				indices[1][i].append(coordsToIndexH(x + 1, z, true))
				indices[1][i].append(coordsToIndexH(x + 1, z + 1, true))
				indices[1][i].append(coordsToIndexH(x, z + 1, true))
				
	for i in len(heights[2]):
		for x in range(0, (ceil(h_max) - floor(h_min)) * res):
			for z in range(0, (xmax - xmin) * res):
				
				#if (coordsToIndex(x + 1, z + 1, true) < len(vertices[i])):
					# front
				indices[2][i].append(coordsToIndexX(x, z, true))
				indices[2][i].append(coordsToIndexX(x + 1, z, true))
				indices[2][i].append(coordsToIndexX(x, z + 1, true))
				
				indices[2][i].append(coordsToIndexX(x + 1, z, true))
				indices[2][i].append(coordsToIndexX(x + 1, z + 1, true))
				indices[2][i].append(coordsToIndexX(x, z + 1, true))

	'''for i in 3:
		print(layerz[i])
		for j in layerz[i]:
			print("Total vertices: " + str(vertices[i][j].size()))'''

func gen_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	mesh.clear_surfaces()
	var a_mesh = ArrayMesh.new()
	var offset = (zmax - zmin) * res + 1
	#print((x_max - x_min) * resolution * offset + (z_max - z_min) * resolution)
	
	'''var uvs = PackedVector2Array([
		Vector2(0,0),
		Vector2(1,0),
		Vector2(1,1),
	])'''
	
	
	mdt = MeshDataTool.new()
	var n = 0
	for i in (1 if degree == 3 else 1):
		for j in len(heights[i]):
			var array = []
			array.resize(Mesh.ARRAY_MAX)
			array[Mesh.ARRAY_VERTEX] = vertices[i][j]
			array[Mesh.ARRAY_INDEX] = indices[i][j]
			a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
			
			mesh = a_mesh
			mesh.surface_set_material(n, surface_material)
			mdt.create_from_surface(mesh, n)

			for face_i in range(mdt.get_face_count()):
				# Pick or compute a Color for this triangle
				var c: Color
				if (render_type == 0):
					c = Color(1, 1, 1)
				if (render_type == 1):
					var row : int = ((face_i / 2) / (offset - 1)) / res
					var column : int = ((face_i / 2) % (offset - 1)) / res
					if degree == 3:
						#for v_i in range(3):
						var vrd = mdt.get_face_vertex(face_i, 0)
						row = vertices[i][j][vrd].x
						column = vertices[i][j][vrd].z
					if ((row / checkers_size + column / checkers_size) % 2 == 0):
						c = Color(0.4, 1, 0.4, 1)
					else:
						c = Color(0.2, 0.8, 0.2, 1)
				elif (render_type == 2):
					var fraction = (heights[i][j][indexToIndex(face_i / 2, false)] - h_min) / (h_max - h_min);
					c = Color(fraction, fraction, fraction)
				elif (render_type == 3):
					var fraction = (gradients[i][j][indexToIndex(face_i / 2, false)].length() - g_min) / (g_max - g_min);
					c = Color(fraction, fraction, fraction)
				elif (render_type == 4):
					var fraction = (curvatures[i][j][indexToIndex(face_i / 2, false)].length() - c_min) / (c_max - c_min);
					c = Color(fraction, fraction, fraction)
				elif (render_type == 5):
					var fraction = (sin(resolution / 5 * heights[i][j][indexToIndex(face_i / 2, false)] * 2*PI / levels_size)/sin(heights[i][j][indexToIndex(face_i / 2, false)] * 2*PI / levels_size));
					c = Color(fraction, fraction, fraction)
				for v_i in range(3):
					var vid = mdt.get_face_vertex(face_i, v_i)
					mdt.set_vertex_color(vid, c)

			mesh.surface_remove(n)
			#mesh.clear_surfaces()
			mdt.commit_to_surface(mesh)
			n += 1
	#mesh.get_surface_override_material().albedo_color = Color(1, 0, 0, 1)

	'''if arrow != null and false:
		print("arrowed")
		for x in range(0, (xmax - xmin) * res):
			for z in range(0, (zmax - zmin) * res):
				if x % arrows_spacing == 0 && z % arrows_spacing == 0:
					var new_arrow = arrow.instantiate()
					add_child(new_arrow)
					new_arrow.transform.origin = Vector3(float(x) / res + xmin, heights[x * (offset - 1) + z] + 0.1, float(z) / res + zmin)
					var g = gradients[x * (offset - 1) + z]
					new_arrow.setLength(g.length())
					new_arrow.setRotation(atan(g.y/g.x) + 0 if g.x > 0 else PI)'''

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

	#var surface_data = mesh.surface_get_arrays(0) # Assuming surface 0
	#var verts = surface_data[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for n in (1 if degree == 3 else 1):
		for i in len(heights[n]):
			mdt.create_from_surface(mesh, 0)

			for j in range(mdt.get_vertex_count()):
				# Modify vertex position (e.g., move it along its normal)
				#vertex += mdt.get_vertex_normal(i) * 0.1
				var xz := indexToCoordsReal(j, true)
				mdt.set_vertex(j, Vector3(xz.x / res, heights[n][i][j], xz.y / res))
				#vertices[i].x = xz.x / res
				#verts[i].y = heights[i]
				#vertices[i].z = xz.y / res


		#mesh = ArrayMesh.new()
		#mdt.commit_to_surface(mesh)
		# Replace the old mesh
		
		mesh.surface_remove(0)
		#mesh.clear_surfaces()
		mdt.commit_to_surface(mesh)

	#$MeshInstance3D.mesh = mesh

func update_mesh_slider(xmin: int, xmax: int, zmin: int, zmax: int, A: float, res: int):
	for n in (1 if degree == 3 else 1):
		for i in len(heights[n]):
			mdt.create_from_surface(mesh, 0)

			for j in range(mdt.get_vertex_count()):
				if A == a_max:
					if n == 0:
						var xz := indexToCoordsReal(j, true)
						mdt.set_vertex(j, Vector3(xz.x / res, heights_slider[n][i][sliderToIndex(A)][j], xz.y / res))
					elif n == 1:
						var xz := indexToCoordsRealH(j, true)
						mdt.set_vertex(j, Vector3(heights_slider[n][i][sliderToIndex(A)][j], xz.y / res, xz.x / res))
					elif n == 2:
						var xz := indexToCoordsRealX(j, true)
						mdt.set_vertex(j, Vector3(xz.y / res, xz.x / res, heights_slider[n][i][sliderToIndex(A)][j]))
				else:
					if n == 0:
						var xz := indexToCoordsReal(j, true)
						mdt.set_vertex(j, Vector3(xz.x / res, heights_slider[n][i][sliderToIndex(floor(A))][j] * (floor(A) + 1 - A) + heights_slider[n][i][sliderToIndex(floor(A) + 1)][j] * (A - floor(A)), xz.y / res))
					elif n == 1:
						var xz := indexToCoordsRealH(j, true)
						mdt.set_vertex(j, Vector3(heights_slider[n][i][sliderToIndex(floor(A))][j] * (floor(A) + 1 - A) + heights_slider[n][i][sliderToIndex(floor(A) + 1)][j] * (A - floor(A)), xz.y / res, xz.x / res))
					elif n == 2:
						var xz := indexToCoordsRealX(j, true)
						mdt.set_vertex(j, Vector3(xz.y / res, xz.x / res, heights_slider[n][i][sliderToIndex(floor(A))][j] * (floor(A) + 1 - A) + heights_slider[n][i][sliderToIndex(floor(A) + 1)][j] * (A - floor(A))))
			
			mesh.surface_remove(0)
			mdt.commit_to_surface(mesh)

func gen():
	var start_time = Time.get_ticks_msec()
	#initialize_mesh(x_min, x_max, z_min, z_max, resolution)
	calculate_mesh(x_min, x_max, z_min, z_max, resolution)
	gen_mesh(x_min, x_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	update_extensions()
	#print("Elapsed time: " + str(end_time - start_time) + " ms")
	#place_tangent_plane(5, -5);

func upd():
	calculate_mesh(x_min, x_max, z_min, z_max, resolution)
	var start_time = Time.get_ticks_msec()
	update_mesh(x_min, x_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	update_extensions()
	#print("Elapsed time: " + str(end_time - start_time) + " ms")
	
func upd_slider():
	var start_time = Time.get_ticks_msec()
	update_mesh_slider(x_min, x_max, z_min, z_max, a, resolution)
	var end_time = Time.get_ticks_msec()
	update_extensions()
	#print("Elapsed time: " + str(end_time - start_time) + " ms")
	
func coordsToIndex(x: int, y: int, isBounds: bool) -> int:
	return x * ((z_max - z_min) * resolution + (1 if isBounds else 0)) + y
	
func coordsToIndexReal(x: int, y: int, isBounds: bool) -> int:
	return (x - x_min * resolution) * ((z_max - z_min) * resolution + (1 if isBounds else 0)) + y - z_min * resolution
	
func indexToCoords(index: int, isBounds: bool) -> Vector2:
	var offset = (z_max - z_min) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset, index % offset)

func indexToCoordsReal(index: int, isBounds: bool) -> Vector2:
	var offset = (z_max - z_min) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset + x_min * resolution, index % offset + z_min * resolution)

func coordsToIndexH(x: int, y: int, isBounds: bool) -> int:
	return x * ((ceil(h_max) - floor(h_min)) * resolution + (1 if isBounds else 0)) + y
	
func coordsToIndexRealH(x: int, y: int, isBounds: bool) -> int:
	return (x - x_min * resolution) * ((ceil(h_max) - floor(h_min)) * resolution + (1 if isBounds else 0)) + y - z_min * resolution
	
func indexToCoordsH(index: int, isBounds: bool) -> Vector2:
	var offset = (ceil(h_max) - floor(h_min)) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset, index % offset)

func indexToCoordsRealH(index: int, isBounds: bool) -> Vector2:
	var offset = (int(ceil(h_max)) - int(floor(h_min))) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset + x_min * resolution, index % offset + z_min * resolution)

func coordsToIndexX(x: int, y: int, isBounds: bool) -> int:
	return x * ((x_max - x_min) * resolution + (1 if isBounds else 0)) + y
	
func coordsToIndexRealX(x: int, y: int, isBounds: bool) -> int:
	return (x - x_min * resolution) * ((z_max - z_min) * resolution + (1 if isBounds else 0)) + y - z_min * resolution
	
func indexToCoordsX(index: int, isBounds: bool) -> Vector2:
	var offset = (z_max - z_min) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset, index % offset)

func indexToCoordsRealX(index: int, isBounds: bool) -> Vector2:
	var offset = (z_max - z_min) * resolution + (1 if isBounds else 0)
	return Vector2(index / offset + x_min * resolution, index % offset + z_min * resolution)

func indexToIndex(index: int, isBounds: bool) -> int:
	return coordsToIndex(indexToCoords(index, isBounds).x, indexToCoords(index, isBounds).y, !isBounds)
	
func sliderToIndex(x: int) -> int:
	return x - a_min

func indexToSlider(x: int) -> int:
	return x + a_min
	
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
	if last_a != a:
		if function.hasSlider:
			upd_slider()
		last_a = a
	if cursorX <= x_min:
		cursorX = x_min
	if cursorX >= x_max:
		cursorX = x_max
	if cursorZ <= z_min:
		cursorZ = z_min
	if cursorZ >= z_max:
		cursorZ = z_max
	if last_cursorX != cursorX:
		if tangent_plane && tangent_plane.visible:
			place_tangent_plane(cursorX, cursorZ)
		if gradient_arrow && gradient_arrow.visible:
			place_gradient_arrow(cursorX, cursorZ)
		last_cursorX = cursorX
	if last_cursorZ != cursorZ:
		if tangent_plane && tangent_plane.visible:
			place_tangent_plane(cursorX, cursorZ)
		if gradient_arrow && gradient_arrow.visible:
			place_gradient_arrow(cursorX, cursorZ)
		last_cursorZ = cursorZ
	if tangent_plane:
		if show_tangent_plane:
			if !tangent_plane.visible:
				place_tangent_plane(cursorX, cursorZ)
				tangent_plane.visible = true
		else:
			if tangent_plane.visible:
				tangent_plane.visible = false
	if gradient_arrow:
		if show_gradient_arrow:
			if !gradient_arrow.visible:
				place_gradient_arrow(cursorX, cursorZ)
				gradient_arrow.visible = true
		else:
			if gradient_arrow.visible:
				gradient_arrow.visible = false
	if level_curves:
		if show_level_curves:
			if !level_curves.visible:
				if !level_curves.hasGenerated:
					level_curves.generate_level_mesh_layers()
				level_curves.visible = true
		else:
			if level_curves.visible:
				level_curves.visible = false
	if hide_surface != last_hide_surface:
		if hide_surface:
			for i in mesh.get_surface_count():
				mesh.surface_set_material(i, surface_material_empty)
		else:
			for i in mesh.get_surface_count():
				mesh.surface_set_material(i, surface_material)
		last_hide_surface = hide_surface
	if parse:
		_on_expression_entered("")
		parse = false
	'''if find_root:
		print(function.bisection(1.5, 1.5, start_left, start_right))
		find_root = false'''
		
# call every physics frame to enforce lock
var _locked_euler := Vector3.ZERO

@export var yaw_speed: float = 1.0  # radians per second

func _physics_process(delta: float) -> void:
	# If not locked just rotate in local space (unchanged behavior).
	if not locked_spatial_rotation:
		if is_rotating:
			rotate_y(yaw_speed * delta)
		return

	# Locked: apply yaw in WORLD Y and keep pitch/roll locked.
	# Read current global yaw, add consistent yaw increment,
	# then build a world basis from (locked_pitch, new_yaw, locked_roll).
	if locked_spatial_rotation:
		var t := global_transform
		var cur_scale := t.basis.get_scale()
		var cur_e := t.basis.get_euler()
		var new_yaw := cur_e.y
		if is_rotating:
			new_yaw += yaw_speed * delta
		var new_e := Vector3(_locked_euler.x, new_yaw, _locked_euler.z)
		var rot_basis := Basis.from_euler(new_e).orthonormalized()
		t.basis = rot_basis.scaled(cur_scale)
		global_transform = t
		
func _on_update_plot_scale(value: float) -> void:
	# Apply scale to the mesh itself
	scale = Vector3(value, value, value)
	
	# Apply scale to the sibling CollisionShape3D
	if $"../CollisionShape3D":
		$"../CollisionShape3D".scale = Vector3(value, value, value)
		
func update_extensions():
	if cursor_dot:
		place_cursor_dot(cursorX, cursorZ)
	if tangent_plane:
		place_tangent_plane(cursorX, cursorZ)
	if gradient_arrow:
		place_gradient_arrow(cursorX, cursorZ)
	if level_curves:
		level_curves.hasGenerated = false
		if show_level_curves:
			level_curves.generate_level_mesh_layers()
	
func place_cursor_dot(x, y):
	var xx = round(x * resolution)
	var yy = round(y * resolution)
	tangent_plane.position = Vector3(xx / resolution, heights[0][0][coordsToIndexReal(xx, yy, true)], yy / resolution)
	
func place_tangent_plane(x, y):
	var xx = round(x * resolution)
	var yy = round(y * resolution)
	tangent_plane.turn_plane(Vector3(-gradients[0][coordsToIndexReal(xx, yy, true)].x, 1, -gradients[0][coordsToIndexReal(xx, yy, true)].y))
	tangent_plane.position = Vector3(xx / resolution, heights[0][0][coordsToIndexReal(xx, yy, true)], yy / resolution)
	#tangent_plane.look_at(tangent_plane.global_position + Basis(Vector3.UP, rotation.y) * Vector3(1, gradients[0][coordsToIndexReal(xx, yy, true)].x, 0).cross(Vector3(0, gradients[0][coordsToIndexReal(xx, yy, true)].y, 1)), Vector3.UP)
	#tangent_plane.visible = true
	
func place_gradient_arrow(x, y):
	var xx = round(x * resolution)
	var yy = round(y * resolution)
	gradient_arrow.create_arrow(Vector3(-gradients[0][coordsToIndexReal(xx, yy, true)].x, 1, -gradients[0][coordsToIndexReal(xx, yy, true)].y))
	gradient_arrow.position = Vector3(xx / resolution, heights[0][0][coordsToIndexReal(xx, yy, true)], yy / resolution)


# --- Signal handlers ---

func _on_set_level_curves(is_on: bool) -> void:
	show_level_curves = is_on
	if is_on:
		if not level_curves.hasGenerated:
			level_curves.generate_level_mesh_layers()
	level_curves.visible = is_on

func _on_set_tangent_plane(is_on: bool) -> void:
	show_tangent_plane = is_on
	tangent_plane.visible = is_on
	if is_on:
		place_tangent_plane(cursorX, cursorZ)

func _on_set_grad_vector(is_on: bool) -> void:
	show_gradient_arrow = is_on
	gradient_arrow.visible = is_on
	if is_on:
		place_gradient_arrow(cursorX, cursorZ)

func _on_set_plane_grad_location(x: float, y: float) -> void:
	# map x→cursorX and y→cursorZ with clamping to domain
	cursorX = clamp(x, float(x_min), float(x_max))
	cursorZ = clamp(y, float(z_min), float(z_max))
	# refresh dependent gizmos if visible
	if tangent_plane.visible:
		place_tangent_plane(cursorX, cursorZ)
	if gradient_arrow.visible:
		place_gradient_arrow(cursorX, cursorZ)

func _on_set_plot_alpha(alpha: float) -> void:
	_apply_plot_alpha(clamp(alpha, 0.0, 1.0))

# --- Material alpha application ---

func _apply_plot_alpha(alpha: float) -> void:
	# update the stored materials so future surface toggles keep the alpha
	for mat_var in ["surface_material", "surface_material_empty"]:
		var mat: Material = get(mat_var)
		if mat and mat is BaseMaterial3D:
			var dup := mat.duplicate() as BaseMaterial3D
			dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var c := dup.albedo_color
			c.a = alpha
			dup.albedo_color = c
			set(mat_var, dup)

	# apply to current mesh surfaces
	if mesh:
		for i in range(mesh.get_surface_count()):
			var m := mesh.surface_get_material(i)
			if m and m is BaseMaterial3D:
				var d := m.duplicate() as BaseMaterial3D
				d.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				var cc := d.albedo_color
				cc.a = alpha
				d.albedo_color = cc
				mesh.surface_set_material(i, d)
