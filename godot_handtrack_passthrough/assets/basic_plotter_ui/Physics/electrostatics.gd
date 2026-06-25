extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool : Button
@export var btn_bar_magnet_tool : Button
@export var btn_particle_flow : Button
@export var btn_field_lines : Button

@export var pos_charge_scene : PackedScene
@export var neg_charge_scene : PackedScene
@export var bar_magnet_scene : PackedScene

@export var particle_multimesh : PackedScene

var holding_sfx : AudioStreamPlayer3D
var pickup_sfx : AudioStreamPlayer3D
var release_sfx : AudioStreamPlayer3D
var whoosh_sfx : AudioStreamPlayer3D

# --- Classes ---
const HandState = preload("res://assets/basic_plotter_ui/Physics/HandState.gd")
const FieldObject = preload("res://assets/basic_plotter_ui/Physics/FieldObject.gd")
const PointCharge = preload("res://assets/basic_plotter_ui/Physics/PointCharge.gd")
const BarMagnet = preload("res://assets/basic_plotter_ui/Physics/BarMagnet.gd")

enum ObjectType 
{
	POINT_CHARGE,
	BAR_MAGNET
}

enum FieldType 
{
	ELECTRIC_FIELD,
	MAGNETIC_FIELD
}

var r_hand_state = null
var l_hand_state = null

var current_dir = null
var current_basis = null

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var r_palm = null
var l_palm = null

var selected_stylebox = StyleBoxFlat.new()

@onready var rk4: RK4Wrapper = RK4Wrapper.new()

var red = Color(0.67, 0.0, 0.0, 1.0)
var blue = Color(0.0, 0.54, 0.79, 1.0)

# --- Physics Tools ---
var tools = {"pt_charge": false, "bar_magnet": false}
var functions = {"particle_flow" : false, "field_lines" : false}
var selected_tool = "N/A"

const TRAIL_LENGTH := 16
var trails: Array = [] # trails[i] = PackedVector3Array
var trail_mesh := ImmediateMesh.new()
var mat := StandardMaterial3D.new()
@onready var trail_instance := MeshInstance3D.new()

@onready var field_line_instance := MeshInstance3D.new()
var field_line_mesh := ImmediateMesh.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(rk4)
	
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	trail_instance.material_override = mat
	
	field_line_instance.material_override = mat
	
	var tree = get_tree()
	vector_field = tree.get_first_node_in_group("fields")
	r_hand_pose_detector = tree.get_first_node_in_group("r_hand_pose_detector")
	l_hand_pose_detector = tree.get_first_node_in_group("l_hand_pose_detector")
	r_poke = tree.get_first_node_in_group("r_poke")
	l_poke = tree.get_first_node_in_group("l_poke")
	
	var r_index_area = tree.get_first_node_in_group("r_index_area")
	var r_thumb_area = tree.get_first_node_in_group("r_thumb_area")
	var l_index_area = tree.get_first_node_in_group("l_index_area")
	var l_thumb_area = tree.get_first_node_in_group("l_thumb_area")
	
	r_hand_state = HandState.new(r_hand_pose_detector, r_index_area, r_thumb_area)
	l_hand_state = HandState.new(l_hand_pose_detector, l_index_area, l_thumb_area)
		
	l_palm = tree.get_first_node_in_group("l_palm")
	r_palm = tree.get_first_node_in_group("r_palm")
	l_palm.connect("area_entered", Callable(self, "_on_area_entered"))
	r_palm.connect("area_entered", Callable(self, "_on_area_entered"))
	
	holding_sfx = get_tree().get_first_node_in_group("holding")
	pickup_sfx = get_tree().get_first_node_in_group("pickup")
	release_sfx = get_tree().get_first_node_in_group("release")
	whoosh_sfx = get_tree().get_first_node_in_group("whoosh")
	
	selected_stylebox.set_bg_color(Color("#ce2e2b"))
	selected_stylebox.set_corner_radius_all(4)
	selected_stylebox.set_border_width_all(2)
		
	_connect(btn_pt_charge_tool, _on_tool_switch.bind("pt_charge"))
	_connect(btn_bar_magnet_tool, _on_tool_switch.bind("bar_magnet"))
	_connect(btn_particle_flow, enable_particle_flow)
	_connect(btn_field_lines, enable_e_field_lines)
	
	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)

var r_obj_index = null
var r_previous_obj_index = null
var l_obj_index = null
var l_previous_obj_index = null

var r_moving_obj = false
var l_moving_obj = false

var e_field_changed = false

func _process(delta) -> void:	
	if functions["particle_flow"]:
		particle_flow_upd(delta * 0.06)
	if functions["field_lines"] and e_field_changed:
		e_field_lines_upd(0.05)	
		e_field_changed = false
		
	if field_objects:
		r_hand_state.update(vector_field)
		l_hand_state.update(vector_field)
		
		r_obj_index = select_obj(r_hand_state, r_previous_obj_index)
		l_obj_index = select_obj(l_hand_state, l_previous_obj_index)
		
		r_moving_obj = is_moving_obj(r_obj_index, r_previous_obj_index)
		l_moving_obj = is_moving_obj(l_obj_index, l_previous_obj_index)
			
	if r_moving_obj and r_obj_index != null:
		move_selected_obj(r_hand_state, r_obj_index)
		r_moving_obj = !r_hand_state.released()
		
	if l_moving_obj and l_obj_index != null:
		move_selected_obj(l_hand_state, l_obj_index)
		l_moving_obj = !l_hand_state.released()
		
	r_previous_obj_index = r_obj_index
	l_previous_obj_index = l_obj_index


# ---------- Connection helpers ----------
func _connect(btn: BaseButton, fn: Callable) -> void:
	if btn:
		btn.pressed.connect(fn)

func _on_tool_switch(tool: String) -> void:
	select_tool(tool)

func select_tool(tool: String):
	if tool != selected_tool:
		if tools.has(selected_tool) and tools[selected_tool]:
			tools[selected_tool] = false
		tools[tool] = true
		selected_tool = tool
	# need to rewrite this code below to scale better
	
	if tools["pt_charge"]:
		if !btn_pt_charge_tool.has_theme_stylebox_override("normal"):
			btn_pt_charge_tool.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
		else:
			btn_pt_charge_tool.remove_theme_stylebox_override("normal")
	if tools["bar_magnet"]:
		if !btn_bar_magnet_tool.has_theme_stylebox_override("normal"):
			btn_bar_magnet_tool.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout
		else:
			btn_bar_magnet_tool.remove_theme_stylebox_override("normal")
			

var field_objects : Array[FieldObject] = []

func spawn_pt_charge(pos, q):
	var charge_area : Area3D
	if q < 0:
		charge_area = neg_charge_scene.instantiate()
	else:
		charge_area = pos_charge_scene.instantiate()

	var pt_charge = PointCharge.new(pos, q, charge_area)
	e_field_changed = true
	spawn_object(pos, pt_charge)

func spawn_bar_magnet(pos, m):
	var bar_magnet_area = bar_magnet_scene.instantiate()
	var bar_magnet = BarMagnet.new(pos, m, bar_magnet_area)
	spawn_object(pos, bar_magnet)

func spawn_object(pos, object : FieldObject):
	var too_close = false
	for obj in field_objects:
		if pos.distance_to(obj.pos) < 0.07:
			too_close = true
			break
	
	if not too_close:		
		field_objects.append(object)
		rk4.AddObject(object)
		object.area.position = pos
		vector_field.add_child(object.area)
		if object.mesh.material_override:
			object.mesh.material_override = object.mesh.material_override.duplicate()
		else:
			object.mesh.material_override = object.mesh.get_active_material(0).duplicate()
		
func select_obj(hand_state : HandState, previous_obj_index):
	if !debounce:
		return null 
		
	for i in range(field_objects.size()):
		if field_objects[i].object_type == ObjectType.POINT_CHARGE:
			if hand_state.is_pinching() and field_objects[i].pos.distance_to(hand_state.pinch_center) < 0.085:
				pickup_sfx.position = hand_state.pinch_center
				if previous_obj_index != i:
					pickup_sfx.play()
					current_dir = hand_state.direction
					smoothed_dir = current_dir
					current_basis = field_objects[i].area.global_transform.basis
				return i
		elif field_objects[i].object_type == ObjectType.BAR_MAGNET:
			if field_objects[i].area.has_overlapping_areas():
				var areas = field_objects[i].area.get_overlapping_areas()
				if hand_state.index_area in areas and hand_state.thumb_area in areas:
					pickup_sfx.position = hand_state.pinch_center
					if previous_obj_index != i:
						pickup_sfx.play()
						current_dir = hand_state.direction
						current_basis = field_objects[i].area.global_transform.basis
					return i
			
	return null

	
func is_moving_obj(obj_i, previous_obj_i):
	if previous_obj_i != null and obj_i != previous_obj_i:
		var previous_obj = field_objects[previous_obj_i]
		
		if previous_obj.object_type == ObjectType.POINT_CHARGE:
			if previous_obj.q > 0:
				previous_obj.mesh.material_override.albedo_color = red
			else:
				previous_obj.mesh.material_override.albedo_color = blue
		elif previous_obj.object_type == ObjectType.BAR_MAGNET:
			previous_obj.mesh.set_instance_shader_parameter("blue", Vector3(0.0, 0.0, 1.0))
			previous_obj.mesh.set_instance_shader_parameter("red", Vector3(1.0, 0.0, 0.0))

		holding_sfx.stop()
		release_sfx.position = previous_obj.pos
		release_sfx.play()

	if obj_i != null:
		var obj = field_objects[obj_i]
		if obj.object_type == ObjectType.POINT_CHARGE:
			obj.mesh.material_override.albedo_color = Color.WHITE
			e_field_changed = true
		elif obj.object_type == ObjectType.BAR_MAGNET:
			obj.mesh.set_instance_shader_parameter("blue", Vector3(1.0, 1.0, 1.0))
			obj.mesh.set_instance_shader_parameter("red", Vector3(1.0, 1.0, 1.0))
		return true
	return false

var smoothed_dir = Vector3.ZERO

func move_selected_obj(hand_state : HandState, obj_i):
	var obj = field_objects[obj_i]
	if obj.object_type == ObjectType.BAR_MAGNET:
		var new_dir = hand_state.direction
		
		if smoothed_dir == Vector3.ZERO:
			smoothed_dir = new_dir
		else:
			smoothed_dir = smoothed_dir.slerp(new_dir, 0.15).normalized()
		
		if current_dir.angle_to(smoothed_dir) >= deg_to_rad(2.0):
			var delta_rot = Quaternion(current_dir, new_dir)
			obj.area.global_transform.basis = Basis(delta_rot) * current_basis

	obj.area.position = hand_state.pinch_center
	obj.pos = hand_state.pinch_center
	holding_sfx.position = hand_state.pinch_center
	if !holding_sfx.playing:
		holding_sfx.play()
	rk4.UpdateObject(obj, obj_i)
	
func _on_area_entered(area: Area3D):
	if field_objects:
		for i in range(field_objects.size()):
			if area == field_objects[i].area:
				whoosh_sfx.position = field_objects[i].pos
				whoosh_sfx.play()
				
				rk4.RemoveObject(i)
				vector_field.remove_child(field_objects[i].area)
				if field_objects[i].object_type == ObjectType.POINT_CHARGE:
					e_field_changed = true
				
				field_objects[i].area.queue_free()
				field_objects.remove_at(i)
				break

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
	
	trails.clear()
	for i in range(particle_count):
		trails.append(PackedVector3Array())

# ------------------- FIELD LINES ----------------------------------------------
var field_mm_instance : MultiMeshInstance3D
var N = 64 # Num of field lines

func enable_e_field_lines():
	functions["field_lines"] = !functions["field_lines"]
	if functions["field_lines"]:
		if !btn_field_lines.has_theme_stylebox_override("normal"):
			btn_field_lines.add_theme_stylebox_override("normal", selected_stylebox)
			await get_tree().create_timer(0.5).timeout

		field_line_instance.mesh = field_line_mesh
		
		if field_line_instance.get_parent() == null:
			vector_field.add_child(field_line_instance)
	else:
		btn_field_lines.remove_theme_stylebox_override("normal")
		
func e_field_lines_upd(h):
	var pt_charges: Array = []
	for obj in field_objects:
		if obj.object_type == ObjectType.POINT_CHARGE:
			pt_charges.append(obj)

	if pt_charges.is_empty():
		field_line_mesh.clear_surfaces()
		return

	var all_lines: Array = []
	
	var net_pos_seeds := PackedVector3Array()
	var net_neg_seeds := PackedVector3Array()
	
	var seeds_per_charge = int(N / pt_charges.size())
	for charge in pt_charges:
		var seeds = charge.generate_field_line_seeds(seeds_per_charge, 0.3, vector_field)
		if charge.q > 0:
			net_pos_seeds.append_array(seeds)
		else:
			net_neg_seeds.append_array(seeds)

	
	all_lines.append_array(build_field_lines(net_pos_seeds, h))
	all_lines.append_array(build_field_lines(net_neg_seeds, -h))
	
	rebuild_field_mesh(all_lines)
	
func build_field_lines(seeds: PackedVector3Array, h: float) -> Array:
	rk4.SetFieldPositions(seeds, FieldType.ELECTRIC_FIELD)
	var lines: Array = []
	for seed in seeds:
		var line := PackedVector3Array()
		line.append(seed)
		lines.append(line)
		
	var active := true
	var steps := 0
	var max_steps := 90
	
	while active and steps < max_steps:
		active = false
		var states = rk4.StepIntegrateField(h, 1, FieldType.ELECTRIC_FIELD)
		for i in range(states.size()):
			var pos = states[i][0]
			var done = states[i][1]
			if not done:
				lines[i].append(pos)
				active = true
		steps += 1
		
	return lines
	
func rebuild_field_mesh(lines):
	field_line_mesh.clear_surfaces()
	field_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for line in lines:
		for i in range(line.size() - 1):
			field_line_mesh.surface_add_vertex(line[i])
			field_line_mesh.surface_add_vertex(line[i + 1])
	
	field_line_mesh.surface_end()

# ------------------- TRAILS ----------------------------------------------
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

var trail_positions = PackedVector3Array()
func particle_flow_upd(h):
	var new_states = rk4.StepIntegrate(h, 1)
	
	trail_positions.clear()
	
	for i in range(mm_instance.multimesh.instance_count):
		mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), new_states[i][0]))
		if new_states[i][2]: # Regenerated
			trails[i].clear()
		trail_positions.append(new_states[i][0])
		
	update_trails(trail_positions)
		

# ------------------- MORE UI ---------------------------------------------
var debounce = true

func right(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if r_poke:
			var pos = vector_field.to_local(r_poke.global_position)
			if tools["pt_charge"]:
				spawn_pt_charge(pos, 1250.0)
			elif tools["bar_magnet"]:
				spawn_bar_magnet(pos, Vector3(0.0, 700.0, 0.0))
		await get_tree().create_timer(0.2).timeout
		debounce = true

func left(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if l_poke:
			var pos = vector_field.to_local(l_poke.global_position)
			if tools["pt_charge"]:
				spawn_pt_charge(pos, -1250.0)
			elif tools["bar_magnet"]:
				spawn_bar_magnet(pos, Vector3(0.0, 700.0, 0.0))
		await get_tree().create_timer(0.2).timeout
		debounce = true
		
