extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool : Button
@export var btn_particle_flow : Button

@export var pos_charge_mesh : PackedScene
@export var neg_charge_mesh : PackedScene

@export var particle_mesh : PackedScene

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var selected_stylebox = StyleBoxFlat.new()

# --- Euler ---
#var EPSILON_0 = 8.85 * pow(10, -12)
#var k = round(1 / (4 * PI * EPSILON_0))
var k = 1

#var force_x = Expression.new()
#var force_y = Expression.new()
#var force_z = Expression.new()

# Tools:
# 1. Point Charges
# 2. Charged Rod
var tools = {"pt_charge": false, "charged_rod": false}
var functions = {"particle_flow" : false}
var selected_tool = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vector_field = get_tree().get_first_node_in_group("fields")
	r_hand_pose_detector = get_tree().get_first_node_in_group("r_hand_pose_detector")
	l_hand_pose_detector = get_tree().get_first_node_in_group("l_hand_pose_detector")
	r_poke = get_tree().get_first_node_in_group("r_poke")
	l_poke = get_tree().get_first_node_in_group("l_poke")
	
	selected_stylebox.set_bg_color(Color("#ce2e2b"))
	selected_stylebox.set_corner_radius_all(4)
	selected_stylebox.set_border_width_all(2)
	
	_connect(btn_pt_charge_tool, _on_tool_switch.bind("pt_charge"))
	_connect(btn_particle_flow, enable_particle_flow)
	
	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)

var n = 0
func _process(delta) -> void:
	if functions["particle_flow"]:
		particle_flow_upd(delta * 0.05, n)
		n += 1


# ---------- Connection helpers ----------
func _connect(btn: BaseButton, fn: Callable) -> void:
	if btn:
		btn.pressed.connect(fn)

func _on_tool_switch(tool: String) -> void:
	select_tool(tool)

func select_tool(tool: String):
	if tools[tool] != selected_tool:
		if selected_tool:
			selected_tool = false
		tools[tool] = true
		selected_tool = tools[tool]
	# need to rewrite this code below to scale better
	
	if tools["pt_charge"]:
		if !btn_pt_charge_tool.has_theme_stylebox_override("normal"):
			btn_pt_charge_tool.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
		else:
			btn_pt_charge_tool.remove_theme_stylebox_override("normal")
			

var pt_charges = []
var E_fields = []
var charge
# [{"location": Vector3, "charge": q}]
var Net_E_x = []
var Net_E_y = []
var Net_E_z = []
func spawn_pt_charge(a_x, a_y, a_z, q):
	Net_E_x.clear()
	Net_E_y.clear()
	Net_E_z.clear()
	# Note: for VECTOR FIELDS, need to flip a_y and a_z
	if tools["pt_charge"] and {"location": Vector3(a_x,a_y,a_z), "charge": q} not in pt_charges:
		#var E_x = "((%s*%s)/(pow(pow(x-%s,2)+pow(y-%s,2)+pow(z-%s,2),1.5)+0.001))*(x-%s)" % [k, q, a_x, a_z, a_y, a_x]
		#var E_y = "((%s*%s)/(pow(pow(x-%s,2)+pow(y-%s,2)+pow(z-%s,2),1.5)+0.001))*(y-%s)" % [k, q, a_x, a_z, a_y, a_y]
		#var E_z = "((%s*%s)/(pow(pow(x-%s,2)+pow(y-%s,2)+pow(z-%s,2),1.5)+0.001))*(z-%s)" % [k, q, a_x, a_z, a_y, a_z]
		
		pt_charges.append({"location": Vector3(a_x,a_y,a_z), "charge": q})
		#E_fields.append([E_x, E_y, E_z])

		for E_field in E_fields:
			Net_E_x.append(E_field[0])
			Net_E_y.append(E_field[1])
			Net_E_z.append(E_field[2])
		
		if q < 0:
			charge = neg_charge_mesh.instantiate()
		elif q > 0:
			charge = pos_charge_mesh.instantiate()
		charge.position = Vector3(a_x, a_y, a_z)
		vector_field.add_child(charge)
		
		#GlobalSignals.expressions_entered.emit(" + ".join(Net_E_x), " + ".join(Net_E_y), " + ".join(Net_E_z))
		#force_x.parse(" + ".join(Net_E_x), ["x", "y", "z"])
		#force_y.parse(" + ".join(Net_E_y), ["x", "y", "z"])
		#force_z.parse(" + ".join(Net_E_z), ["x", "y", "z"])


# ------------------- PARTICLE FLOW -----------------------------------------------------
var m = 1.0
func accel(t, R, V):	
	# Currently not dependent on time, velocity
	if pt_charges.is_empty():
		return Vector3.ZERO
	else:
		var Net_F = Vector3.ZERO
		for pt_charge in pt_charges:
			var r = pt_charge["location"]
			var q = pt_charge["charge"]
			var vector = R - r
			var magnitude = (k * q) / (((R.x - r.x) * (R.x - r.x) +
			 						(R.y - r.y) * (R.y - r.y) +
									(R.z - r.z) * (R.z - r.z)) 
									* sqrt((R.x - r.x) * (R.x - r.x) +
			 						(R.y - r.y) * (R.y - r.y) +
									(R.z - r.z) * (R.z - r.z)))
			Net_F += vector * magnitude
		return Net_F
		#return Vector3(
			#force_x.execute([R.x, R.y, R.z]) / m, 
			#force_y.execute([R.x, R.y, R.z]) / m, 
			#force_z.execute([R.x, R.y, R.z]) / m
		#)
		

func rk4(t_n, R : Vector3, V : Vector3, h):
	var k_1_x = V
	var k_1_v = accel(t_n, R, V)
	
	var k_2_x = V + k_1_v * (h/2)
	var k_2_v = accel(t_n + h/2, R + k_1_x * (h/2), V + k_1_v * (h/2))
	
	var k_3_x = V + k_2_v * (h/2)
	var k_3_v = accel(t_n + h/2,  R + k_2_x * (h/2), V + k_2_v * (h/2))
	
	var k_4_x = V + h * k_3_v
	var k_4_v = accel(t_n + h, R + h * k_3_x, V + h * k_3_v)
	
	var R_next = R + (h / 6) * (k_1_x + 2 * k_2_x + 2 * k_3_x + k_4_x)
	var V_next = V + (h / 6) * (k_1_v + 2 * k_2_v + 2 * k_3_v + k_4_v)
	
	return [R_next, V_next]

var particles = []
func enable_particle_flow():
	functions["particle_flow"] = !functions["particle_flow"]
	if functions["particle_flow"]:
		if !btn_particle_flow.has_theme_stylebox_override("normal"):
			btn_particle_flow.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
	else:
		btn_particle_flow.remove_theme_stylebox_override("normal")
	for i in range(1250):
		particles.append(particle_mesh.instantiate())
		particles[i].position = Vector3(
			randi_range(-7, 7),
			randi_range(-7, 7),
			randi_range(-7, 7)
		)
		vector_field.add_child(particles[i])
		
func particle_flow_upd(h, n):
	if pt_charges.is_empty():
		return
		
	var t_n = n * h
	for i in range(particles.size()):	
		var state = rk4(t_n, particles[i].position, particles[i].velocity, h)
		var too_close = false
		
		for pt_charge in pt_charges:
			if state[0].distance_to(pt_charge["location"]) < 0.2:
				too_close = true
				break
				
		if too_close or abs(state[0].x) > 10 or abs(state[0].y) > 10 or abs(state[0].z) > 35:
			particles[i].velocity = Vector3.ZERO
			particles[i].position = Vector3(
				randi_range(-7, 7),
				randi_range(-7, 7),
				randi_range(-7, 7)
			)
		else:
			particles[i].position = state[0]
			particles[i].velocity = state[1]
	# ------------------------------------------------------------------------------------------	
var debounce = true
func right(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if r_poke:
			var pos = vector_field.to_local(r_poke.global_position)
			spawn_pt_charge(pos.x, pos.y, pos.z, 750.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true

func left(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if l_poke:
			var pos = vector_field.to_local(l_poke.global_position)
			spawn_pt_charge(pos.x, pos.y, pos.z, -750.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true
		
