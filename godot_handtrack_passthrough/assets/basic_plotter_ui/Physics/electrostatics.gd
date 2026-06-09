extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool : Button
@export var btn_particle_flow : Button

@export var pos_charge_mesh : PackedScene
@export var neg_charge_mesh : PackedScene

@export var particle_multimesh : PackedScene

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var selected_stylebox = StyleBoxFlat.new()

@onready var rk4: RK4Wrapper = RK4Wrapper.new()

# --- Physics Constants ---
var k = 1

# Tools:
# 1. Point Charges
# 2. Charged Rod
var tools = {"pt_charge": false, "charged_rod": false}
var functions = {"particle_flow" : false}
var selected_tool = null

const TRAIL_LENGTH := 16
var trails: Array = [] # trails[i] = PackedVector3Array
var trail_mesh := ImmediateMesh.new()
var mat := StandardMaterial3D.new()
@onready var trail_instance := MeshInstance3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(rk4)
	
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#mat.emission_enabled = true
	#mat.emission = Color.CYAN
	#mat.emission_energy_multiplier = 2.0
	trail_instance.material_override = mat
	
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

func _process(delta) -> void:
	if functions["particle_flow"]:
		particle_flow_upd(delta * 0.15)


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
		rk4.SetCharges(pt_charges)
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


# ------------------- PARTICLE FLOW ----------------------------------------------
var mm_instance : MultiMeshInstance3D
var particle_count = 700

func enable_particle_flow():
	functions["particle_flow"] = !functions["particle_flow"]
	if functions["particle_flow"]:
		if !btn_particle_flow.has_theme_stylebox_override("normal"):
			btn_particle_flow.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
	else:
		btn_particle_flow.remove_theme_stylebox_override("normal")
		
	mm_instance = particle_multimesh.instantiate()
	mm_instance.multimesh.instance_count = particle_count
	
	var initial_positions = rk4.SetParticles(particle_count)
	for i in range(mm_instance.multimesh.instance_count):
		mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), initial_positions[i]))
		
	trail_instance.mesh = trail_mesh
	vector_field.add_child(mm_instance)
	vector_field.add_child(trail_instance)
	
	
	for i in range(particle_count):
		trails.append(PackedVector3Array())

# trails : PackedVector3Array
# trail_instance -> assigned trail mesh
func update_trails(positions : PackedVector3Array):
	for i in positions.size():
		var trail = trails[i]
		trail.append(positions[i])
		if trail.size() > TRAIL_LENGTH:
			trail.remove_at(0)
		trails[i] = trail
	rebuild_trail_mesh()
	
func rebuild_trail_mesh():
	trail_mesh.clear_surfaces()
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for trail in trails:
		for j in range(trail.size() - 1):
			trail_mesh.surface_add_vertex(trail[j])
			trail_mesh.surface_add_vertex(trail[j + 1])
	trail_mesh.surface_end()

var positions = PackedVector3Array()
func particle_flow_upd(h):
	if pt_charges.is_empty():
		return
		
	var new_states = rk4.StepIntegrate(h, 1)
	
	positions.clear()
	
	for i in range(mm_instance.multimesh.instance_count):
		mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), new_states[i][0]))
		if new_states[i][2]:
			trails[i].clear()
		positions.append(new_states[i][0])
		
	update_trails(positions)
		

# ------------------- UI ----------------------------------------------
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
		
