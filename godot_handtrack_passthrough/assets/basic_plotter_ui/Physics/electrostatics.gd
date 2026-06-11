extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool : Button
@export var btn_particle_flow : Button

@export var pos_charge_scene : PackedScene
@export var neg_charge_scene : PackedScene

@export var particle_multimesh : PackedScene

var holding_sfx : AudioStreamPlayer3D
var pickup_sfx : AudioStreamPlayer3D
var release_sfx : AudioStreamPlayer3D

# Classes
const HandState = preload("res://assets/basic_plotter_ui/Physics/HandState.gd")
const PointCharge = preload("res://assets/basic_plotter_ui/Physics/PointCharge.gd")

var r_hand_state = null
var l_hand_state = null

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var selected_stylebox = StyleBoxFlat.new()

@onready var rk4: RK4Wrapper = RK4Wrapper.new()

var red = Color(0.67, 0.0, 0.0, 1.0)
var blue = Color(0.0, 0.54, 0.79, 1.0)

# --- Physics Constants ---
var k = 1

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
	trail_instance.material_override = mat
	
	vector_field = get_tree().get_first_node_in_group("fields")
	r_hand_pose_detector = get_tree().get_first_node_in_group("r_hand_pose_detector")
	l_hand_pose_detector = get_tree().get_first_node_in_group("l_hand_pose_detector")
	r_poke = get_tree().get_first_node_in_group("r_poke")
	l_poke = get_tree().get_first_node_in_group("l_poke")
	
	r_hand_state = HandState.new(r_hand_pose_detector)
	l_hand_state = HandState.new(l_hand_pose_detector)
	
	holding_sfx = get_tree().get_first_node_in_group("holding")
	pickup_sfx = get_tree().get_first_node_in_group("pickup")
	release_sfx = get_tree().get_first_node_in_group("release")
	
	selected_stylebox.set_bg_color(Color("#ce2e2b"))
	selected_stylebox.set_corner_radius_all(4)
	selected_stylebox.set_border_width_all(2)
	
	_connect(btn_pt_charge_tool, _on_tool_switch.bind("pt_charge"))
	_connect(btn_particle_flow, enable_particle_flow)
	
	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)

var r_charge_index = null
var r_previous_charge_index = null
var l_charge_index = null
var l_previous_charge_index = null

var r_moving_charge = false
var l_moving_charge = false

func _process(delta) -> void:
	if functions["particle_flow"]:
		particle_flow_upd(delta * 0.15)
		
	if pt_charges:
		r_hand_state.update(vector_field)
		l_hand_state.update(vector_field)
		
		r_charge_index = select_charge(r_hand_state, r_previous_charge_index)
		l_charge_index = select_charge(l_hand_state, l_previous_charge_index)
		
		r_moving_charge = is_moving_charge(r_charge_index, r_previous_charge_index)
		l_moving_charge = is_moving_charge(l_charge_index, l_previous_charge_index)
	
	if r_moving_charge and r_charge_index != null:
		move_selected_charges(r_hand_state, r_charge_index)
		r_moving_charge = !r_hand_state.released()
		
	if l_moving_charge and l_charge_index != null:
		move_selected_charges(l_hand_state, l_charge_index)
		l_moving_charge = !l_hand_state.released()
		
	r_previous_charge_index = r_charge_index
	l_previous_charge_index = l_charge_index		


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
			

var pt_charges : Array[PointCharge] = []
var charge_node : Node3D

func spawn_pt_charge(pos, q):
	var too_close = false

	for c in pt_charges:
		if pos.distance_to(c.pos) < 0.07:
			too_close = true
			break
			
	if tools["pt_charge"] and not too_close:		
		if q < 0:
			charge_node = neg_charge_scene.instantiate()
		else:
			charge_node = pos_charge_scene.instantiate()

		var pt_charge = PointCharge.new(pos, q, charge_node)
		pt_charges.append(pt_charge)
		rk4.AddCharge(pt_charge) # add/remove charge functions might be more efficient

		charge_node.position = pos
		vector_field.add_child(charge_node)
		
		if pt_charge.mesh.material_override:
			pt_charge.mesh.material_override = pt_charge.mesh.material_override.duplicate()
		else:
			pt_charge.mesh.material_override = pt_charge.mesh.get_active_material(0).duplicate()
		
func select_charge(hand_state : HandState, previous_charge_index):
	if !debounce:
		return null 
		
	for i in range(pt_charges.size()):
		if hand_state.is_pinching() and pt_charges[i].pos.distance_to(hand_state.pinch_center) < 0.085:
			pickup_sfx.position = hand_state.pinch_center
			if previous_charge_index != i:
				pickup_sfx.play()
			return i
	return null

	
func is_moving_charge(c_index, previous_c_index):
	if previous_c_index != null and c_index != previous_c_index:
		var previous_c = pt_charges[previous_c_index]

		if previous_c.q > 0:
			previous_c.mesh.material_override.albedo_color = red
		else:
			previous_c.mesh.material_override.albedo_color = blue

		holding_sfx.stop()
		release_sfx.position = previous_c.pos
		release_sfx.play()

	if c_index != null:
		var c = pt_charges[c_index]
		c.mesh.material_override.albedo_color = Color.WHITE
		return true
	return false
	
func move_selected_charges(hand_state : HandState, c_index):
	var c = pt_charges[c_index]

	c.node.position = hand_state.pinch_center
	c.pos = hand_state.pinch_center
	holding_sfx.position = hand_state.pinch_center
	if !holding_sfx.playing:
		holding_sfx.play()
	rk4.UpdateCharge(c, c_index)
	

# ------------------- PARTICLE FLOW ----------------------------------------------
var mm_instance : MultiMeshInstance3D
var particle_count = 700

func enable_particle_flow():
	functions["particle_flow"] = !functions["particle_flow"]
	if functions["particle_flow"]:
		if !btn_particle_flow.has_theme_stylebox_override("normal"):
			btn_particle_flow.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
			
		mm_instance = particle_multimesh.instantiate()
		mm_instance.multimesh.instance_count = particle_count
		
		var initial_positions = rk4.SetParticles(particle_count)
		for i in range(mm_instance.multimesh.instance_count):
			mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), initial_positions[i]))
			
		trail_instance.mesh = trail_mesh
		vector_field.add_child(mm_instance)
		vector_field.add_child(trail_instance)
	else:
		btn_particle_flow.remove_theme_stylebox_override("normal")
	
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
		if new_states[i][2]: # Regenerated
			trails[i].clear()
		positions.append(new_states[i][0])
		
	update_trails(positions)
		

# ------------------- MORE UI ---------------------------------------------
var debounce = true

func right(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if r_poke:
			var pos = vector_field.to_local(r_poke.global_position)
			spawn_pt_charge(pos, 750.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true

func left(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if l_poke:
			var pos = vector_field.to_local(l_poke.global_position)
			spawn_pt_charge(pos, -750.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true
		
