extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool: Button
@export var btn_bar_magnet_tool: Button
@export var btn_particle_flow: Button
@export var btn_e_field_lines: Button
@export var btn_b_field_lines: Button

@export var pos_charge_scene: PackedScene
@export var neg_charge_scene: PackedScene
@export var bar_magnet_scene: PackedScene

@export var particle_multimesh: PackedScene
@export var arrow_multimesh: PackedScene

var holding_sfx: AudioStreamPlayer3D
var pickup_sfx: AudioStreamPlayer3D
var release_sfx: AudioStreamPlayer3D
var whoosh_sfx: AudioStreamPlayer3D

# --- Classes ---
const HandState = preload("res://assets/basic_plotter_ui/Physics/HandState.gd")

const PhysicsTypes = preload("res://scripts/physics/PhysicsTypes.gd")

@onready var physics: Physics = (get_tree().get_first_node_in_group("physics"))

var r_hand_state = null
var l_hand_state = null

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var r_palm = null
var l_palm = null

var selected_stylebox = StyleBoxFlat.new()

var red = Color(0.67, 0.0, 0.0, 1.0)
var blue = Color(0.0, 0.54, 0.79, 1.0)

# --- Physics Tools ---
var tools = {
	"pt_charge": false,
	"bar_magnet": false
}

var functions = {
	"particle_flow": false,
	"e_field_lines": false,
	"b_field_lines": false
}

var selected_tool = "N/A"

const TRAIL_LENGTH := 16
const FIELD_MOVE_THRESHOLD := 0.0015
const FIELD_MOVE_THRESHOLD_SQUARED := (FIELD_MOVE_THRESHOLD * FIELD_MOVE_THRESHOLD)

var trails: Array = []
var trail_mesh := ImmediateMesh.new()
var mat := StandardMaterial3D.new()
var trail_instance := MeshInstance3D.new()

var field_line_instance := MeshInstance3D.new()
var field_line_mesh := ImmediateMesh.new()

var dragging_electric_object = false
var e_field_changed = false
var b_field_changed = false
var dragging_magnetic_object = false

var r_obj_index = null
var r_previous_obj_index = null
var l_obj_index = null
var l_previous_obj_index = null

var r_moving_obj = false
var l_moving_obj = false

var last_field_update_positions: Dictionary = {}

const MAGNET_ROTATION_SMOOTHING_SPEED := 20.0
const MAGNET_ROTATION_UPDATE_ANGLE := deg_to_rad(1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = false
	trail_instance.material_override = mat
	trail_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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

	holding_sfx = tree.get_first_node_in_group("holding")
	pickup_sfx = tree.get_first_node_in_group("pickup")
	release_sfx = tree.get_first_node_in_group("release")
	whoosh_sfx = tree.get_first_node_in_group("whoosh")

	selected_stylebox.set_bg_color(Color("#ce2e2b"))
	selected_stylebox.set_corner_radius_all(4)
	selected_stylebox.set_border_width_all(2)

	_connect(btn_pt_charge_tool, _on_tool_switch.bind("pt_charge"))

	_connect(btn_bar_magnet_tool, _on_tool_switch.bind("bar_magnet"))

	_connect(btn_particle_flow, enable_particle_flow)

	_connect(btn_e_field_lines, on_btn_e_fields_pressed)

	_connect(btn_b_field_lines, on_btn_b_fields_pressed)

	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)

func finish_moving_object(obj_i: int) -> void:
	if obj_i < 0 or obj_i >= physics.sources.field_objects.size():
		return

	var obj = physics.sources.field_objects[obj_i]
	if obj == null:
		return

	physics.rk4.UpdateObject(obj, obj_i)
	last_field_update_positions[obj] = obj.pos

	holding_sfx.stop()
	release_sfx.position = obj.pos
	release_sfx.play()

	if obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE:
		dragging_electric_object = false
		e_field_changed = true

		if obj.q > 0:
			obj.mesh.material_override.albedo_color = red
		else:
			obj.mesh.material_override.albedo_color = blue

	elif obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET:
		dragging_magnetic_object = false
		b_field_changed = true

		obj.mesh.set_instance_shader_parameter("blue", Vector3(0.0, 0.0, 1.0))
		obj.mesh.set_instance_shader_parameter("red", Vector3(1.0, 0.0, 0.0))

func _process(delta) -> void:
	if functions["particle_flow"]:
		particle_flow_upd(delta * 0.06)

	if physics.sources.field_objects:
		r_hand_state.update(vector_field)
		l_hand_state.update(vector_field)

		r_obj_index = select_obj(r_hand_state, r_previous_obj_index)

		l_obj_index = select_obj(l_hand_state, l_previous_obj_index)

		r_moving_obj = is_moving_obj(r_obj_index, r_previous_obj_index)

		l_moving_obj = is_moving_obj(l_obj_index, l_previous_obj_index)

	if r_moving_obj and r_obj_index != null:
		move_selected_obj(r_hand_state, r_obj_index, delta)

		if r_hand_state.released():
			finish_moving_object(r_obj_index)
			r_hand_state.clear_magnet_rotation()
			r_moving_obj = false
		else:
			r_moving_obj = true

	if l_moving_obj and l_obj_index != null:
		move_selected_obj(l_hand_state, l_obj_index, delta)

		if l_hand_state.released():
			finish_moving_object(l_obj_index)
			l_hand_state.clear_magnet_rotation()
			l_moving_obj = false
		else:
			l_moving_obj = true

	if functions["e_field_lines"]:
		if e_field_changed:
			physics.fields.update_e_field_lines(0.05)

			e_field_changed = false

		physics.fields.set_field_object_moving(PhysicsTypes.FieldType.ELECTRIC_FIELD, dragging_electric_object)

		physics.fields.animate_field_arrows(delta)

	if functions["b_field_lines"]:
		if b_field_changed:
			physics.fields.update_b_field_lines(0.02)

			b_field_changed = false

		physics.fields.set_field_object_moving(PhysicsTypes.FieldType.MAGNETIC_FIELD, dragging_magnetic_object)

		physics.fields.animate_b_field_arrows(delta)

	r_previous_obj_index = r_obj_index
	l_previous_obj_index = l_obj_index

# ---------- Connection helpers ----------
func _connect(btn: BaseButton, fn: Callable) -> void:
	if btn == null:
		return

	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	if !btn.pressed.is_connected(fn):
		btn.pressed.connect(fn)

func _on_tool_switch(tool: String) -> void:
	select_tool(tool)

func set_button_selected(btn: BaseButton, is_selected: bool) -> void:
	if btn == null:
		return

	for state in ["normal", "hover", "pressed", "focus"]:
		if is_selected:
			btn.add_theme_stylebox_override(state, selected_stylebox)
		else:
			btn.remove_theme_stylebox_override(state)

func select_tool(tool: String):
	if !tools.has(tool):
		return

	for key in tools.keys():
		tools[key] = false

	tools[tool] = true
	selected_tool = tool

	set_button_selected(btn_pt_charge_tool, false)
	set_button_selected(btn_bar_magnet_tool, false)

	if tool == "pt_charge" and btn_pt_charge_tool:
		set_button_selected(btn_pt_charge_tool, true)

	elif tool == "bar_magnet" and btn_bar_magnet_tool:
		set_button_selected(btn_bar_magnet_tool, true)

func select_obj(hand_state: HandState, previous_obj_index):
	# Once an object is acquired, keep the grab latched until the pinch
	# release threshold is crossed. Fingertip collision overlaps can flicker
	# at a magnet's edges and should only be required to begin a grab.
	if (previous_obj_index != null and previous_obj_index >= 0 and previous_obj_index < physics.sources.field_objects.size() and not hand_state.released()):
		return previous_obj_index

	for i in range(physics.sources.field_objects.size()):
		var obj = physics.sources.field_objects[i]

		if obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE:
			if (hand_state.is_pinching() and obj.pos.distance_to(hand_state.pinch_center) < 0.085):
				pickup_sfx.position = hand_state.pinch_center

				if previous_obj_index != i:
					pickup_sfx.play()

				return i

		elif obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET:
			if (hand_state.is_pinching() and obj.area.has_overlapping_areas()):
				var areas = obj.area.get_overlapping_areas()

				if (hand_state.index_area in areas and hand_state.thumb_area in areas):
					pickup_sfx.position = (hand_state.pinch_center)

					if previous_obj_index != i:
						pickup_sfx.play()
						hand_state.begin_magnet_rotation(obj)

					return i

	return null

func is_moving_obj(obj_i, previous_obj_i):
	if previous_obj_i != null and obj_i != previous_obj_i:
		var previous_obj = (physics.sources.field_objects[previous_obj_i])

		if (previous_obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE):
			if previous_obj.q > 0:
				previous_obj.mesh.material_override.albedo_color = red
			else:
				previous_obj.mesh.material_override.albedo_color = blue

		elif (previous_obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET):
			previous_obj.mesh.set_instance_shader_parameter("blue", Vector3(0.0, 0.0, 1.0))

			previous_obj.mesh.set_instance_shader_parameter("red", Vector3(1.0, 0.0, 0.0))

		holding_sfx.stop()
		release_sfx.position = previous_obj.pos
		release_sfx.play()

		dragging_electric_object = false
		dragging_magnetic_object = false

	if obj_i != null:
		var obj = physics.sources.field_objects[obj_i]

		if (obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE):
			obj.mesh.material_override.albedo_color = Color.WHITE

			dragging_electric_object = true

		elif (obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET):
			obj.mesh.set_instance_shader_parameter("blue", Vector3(1.0, 1.0, 1.0))

			obj.mesh.set_instance_shader_parameter("red", Vector3(1.0, 1.0, 1.0))

			dragging_magnetic_object = true

		return true

	return false

func move_selected_obj(hand_state: HandState, obj_i, delta: float):
	if (obj_i == null or obj_i < 0 or obj_i >= physics.sources.field_objects.size()):
		return

	var obj = physics.sources.field_objects[obj_i]
	if obj == null:
		return

	var new_position: Vector3 = hand_state.pinch_center

	if not last_field_update_positions.has(obj):
		last_field_update_positions[obj] = obj.pos

	var rotation_changed := false
	if obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET:
		if hand_state.rotation_object != obj:
			hand_state.begin_magnet_rotation(obj)

		if (hand_state.rotation_object == obj and hand_state.direction_is_valid):
			var smoothing_weight := 1.0 - exp(-MAGNET_ROTATION_SMOOTHING_SPEED * delta)
			hand_state.rotation_smoothed_direction = (hand_state.rotation_smoothed_direction.slerp(hand_state.direction, smoothing_weight).normalized())
			var delta_rotation := Quaternion(hand_state.rotation_initial_direction, hand_state.rotation_smoothed_direction)
			var delta_basis := Basis(delta_rotation)
			obj.area.transform.basis = (delta_basis * hand_state.rotation_initial_basis).orthonormalized()
			obj.m = (delta_basis * hand_state.rotation_initial_moment)

			var moment_direction: Vector3 = obj.m.normalized()
			rotation_changed = (hand_state.rotation_last_submitted_direction.angle_to(moment_direction) >= MAGNET_ROTATION_UPDATE_ANGLE)

	obj.area.position = new_position
	obj.pos = new_position

	holding_sfx.position = new_position

	if !holding_sfx.playing:
		holding_sfx.play()

	var last_position: Vector3 = last_field_update_positions[obj]
	var position_changed := (last_position.distance_squared_to(new_position) >= FIELD_MOVE_THRESHOLD_SQUARED)
	if position_changed or rotation_changed:
		physics.rk4.UpdateObject(obj, obj_i)
		last_field_update_positions[obj] = new_position

		if obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE:
			e_field_changed = true
		elif obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET:
			hand_state.rotation_last_submitted_direction = (obj.m.normalized())
			b_field_changed = true

func _on_area_entered(area: Area3D) -> void:
	for i in range(physics.sources.field_objects.size()):
		var obj = physics.sources.field_objects[i]

		if area != obj.area:
			continue

		whoosh_sfx.position = obj.pos
		whoosh_sfx.play()

		if (obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE):
			e_field_changed = true

		elif (obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET):
			b_field_changed = true

		_remove_field_object_deferred.call_deferred(i)
		return

func _remove_field_object_deferred(index: int) -> void:
	if (index < 0 or index >= physics.sources.field_objects.size()):
		return

	if (r_obj_index == index or r_previous_obj_index == index):
		r_obj_index = null
		r_previous_obj_index = null
		r_moving_obj = false

	if (l_obj_index == index or l_previous_obj_index == index):
		l_obj_index = null
		l_previous_obj_index = null
		l_moving_obj = false

	holding_sfx.stop()

	dragging_electric_object = false
	dragging_magnetic_object = false

	var removed_obj = physics.sources.field_objects[index]
	last_field_update_positions.erase(removed_obj)
	physics.sources.remove_object(index)

# ------------------- PARTICLE FLOW -------------------
var mm_instance: MultiMeshInstance3D
var particle_count = 700

func enable_particle_flow():
	functions["particle_flow"] = !functions["particle_flow"]

	if functions["particle_flow"]:
		set_button_selected(btn_particle_flow, true)

		await get_tree().create_timer(0.5).timeout

		if mm_instance == null:
			mm_instance = particle_multimesh.instantiate()
			mm_instance.multimesh.instance_count = particle_count
			vector_field.add_child(mm_instance)
		mm_instance.visible = true

		var initial_positions = physics.rk4.SetParticles(particle_count)

		for i in range(mm_instance.multimesh.instance_count):
			mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), initial_positions[i]))

		trail_instance.mesh = trail_mesh
		if trail_instance.get_parent() == null:
			vector_field.add_child(trail_instance)
		trail_instance.visible = true

	else:
		set_button_selected(btn_particle_flow, false)
		if mm_instance:
			mm_instance.visible = false
		trail_instance.visible = false

	trails.clear()

	for i in range(particle_count):
		trails.append(PackedVector3Array())

func on_btn_e_fields_pressed():
	functions["e_field_lines"] = !functions["e_field_lines"]

	if functions["e_field_lines"]:
		set_button_selected(btn_e_field_lines, true)

		await get_tree().create_timer(0.5).timeout

		physics.fields.enable_e_field_lines()
		physics.fields.update_e_field_lines(0.05)

		e_field_changed = false

	else:
		set_button_selected(btn_e_field_lines, false)
		physics.fields.disable_e_field_lines()

func on_btn_b_fields_pressed():
	functions["b_field_lines"] = !functions["b_field_lines"]

	if functions["b_field_lines"]:
		set_button_selected(btn_b_field_lines, true)

		await get_tree().create_timer(0.5).timeout

		physics.fields.enable_b_field_lines()
		physics.fields.update_b_field_lines(0.02)

		b_field_changed = false

	else:
		set_button_selected(btn_b_field_lines, false)
		physics.fields.disable_b_field_lines()

# ------------------- TRAILS -------------------
func update_trails(positions: PackedVector3Array):
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
	var new_states = physics.rk4.StepIntegrate(h, 1)

	trail_positions.clear()

	for i in range(mm_instance.multimesh.instance_count):
		mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), new_states[i][0]))

		if new_states[i][2]:
			trails[i].clear()

		trail_positions.append(new_states[i][0])

	update_trails(trail_positions)

# ------------------- MORE UI -------------------
var spawn_debounce = true

func hand_is_touching_field_object(hand_state: HandState) -> bool:
	for obj in physics.sources.field_objects:
		if (obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE):
			if (obj.pos.distance_to(hand_state.pinch_center) < 0.085):
				return true

		elif (obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET):
			if obj.area == null:
				continue

			var overlapping_areas: Array[Area3D] = (obj.area.get_overlapping_areas())

			if (hand_state.index_area in overlapping_areas and hand_state.thumb_area in overlapping_areas):
				return true

	return false

func right(p_name: String) -> void:
	if p_name != "index_pinch" or !spawn_debounce:
		return

	if r_poke == null:
		return

	r_hand_state.update(vector_field)

	if hand_is_touching_field_object(r_hand_state):
		return

	spawn_debounce = false

	var pos: Vector3 = vector_field.to_local(r_poke.global_position)

	if tools["pt_charge"]:
		physics.sources.spawn_pt_charge(pos, 1250.0)

		e_field_changed = true

	elif tools["bar_magnet"]:
		physics.sources.spawn_bar_magnet(pos, Vector3(0.0, 700.0, 0.0))

		b_field_changed = true

	await get_tree().create_timer(0.2).timeout
	spawn_debounce = true

func left(p_name: String) -> void:
	if p_name != "index_pinch" or !spawn_debounce:
		return

	if l_poke == null:
		return

	l_hand_state.update(vector_field)

	if hand_is_touching_field_object(l_hand_state):
		return

	spawn_debounce = false

	var pos: Vector3 = vector_field.to_local(l_poke.global_position)

	if tools["pt_charge"]:
		physics.sources.spawn_pt_charge(pos, -1250.0)

		e_field_changed = true

	elif tools["bar_magnet"]:
		physics.sources.spawn_bar_magnet(pos, Vector3(0.0, 550.0, 0.0))

		b_field_changed = true

	await get_tree().create_timer(0.2).timeout
	spawn_debounce = true
