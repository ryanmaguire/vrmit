extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool: Button
@export var btn_bar_magnet_tool: Button
@export var btn_particle_flow: Button
@export var btn_e_field_lines: Button
@export var btn_b_field_lines: Button
@export var btn_solar_system: Button

@export var pos_charge_scene: PackedScene
@export var neg_charge_scene: PackedScene
@export var bar_magnet_scene: PackedScene

var holding_sfx: AudioStreamPlayer3D
var pickup_sfx: AudioStreamPlayer3D
var release_sfx: AudioStreamPlayer3D
var whoosh_sfx: AudioStreamPlayer3D

# --- Classes ---
const HandState = preload("res://assets/basic_plotter_ui/Physics/HandState.gd")
const PhysicsTypes = preload("res://scripts/physics/PhysicsTypes.gd")
const BAR_MAGNET_PREVIEW_SHADER = preload(
	"res://assets/physics/bar magnet/bar_magnet_preview.gdshader"
)

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
	"b_field_lines": false,
	"soloar_system": false
}

var selected_tool = "N/A"

const FIELD_MOVE_THRESHOLD := 0.0015
const FIELD_MOVE_THRESHOLD_SQUARED := (FIELD_MOVE_THRESHOLD * FIELD_MOVE_THRESHOLD)

var mat := StandardMaterial3D.new()

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

enum FieldGestureState {
	IDLE,
	PENDING,
	ROTATING
}

enum FieldMoveHand {
	NONE,
	RIGHT,
	LEFT
}

const FIELD_ROTATION_ANGLE_THRESHOLD := deg_to_rad(7.0)

var r_field_gesture_state := FieldGestureState.IDLE
var l_field_gesture_state := FieldGestureState.IDLE
var r_field_gesture_start := Vector3.ZERO
var l_field_gesture_start := Vector3.ZERO
var r_placement_preview: Node3D = null
var l_placement_preview: Node3D = null
var field_move_hand := FieldMoveHand.NONE
var control_panel_active := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("physics_tool_controller")
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
	_connect(btn_particle_flow, on_btn_particle_flow_pressed)
	_connect(btn_e_field_lines, on_btn_e_fields_pressed)
	_connect(btn_b_field_lines, on_btn_b_fields_pressed)
	_connect(btn_solar_system, on_btn_solar_system_pressed)

	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)
	r_hand_pose_detector.pose_ended.connect(_on_right_pose_ended)
	l_hand_pose_detector.pose_ended.connect(_on_left_pose_ended)
	GlobalSignals.control_panel_visibility_changed.connect(
		_on_control_panel_visibility_changed
	)

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
		physics.particles.particle_flow_upd(delta * 0.06)

	# Field gestures must keep tracking even when the field has no sources.
	r_hand_state.update(vector_field)
	l_hand_state.update(vector_field)

	if physics.sources.field_objects:
		if (
			r_field_gesture_state == FieldGestureState.IDLE
			and field_move_hand == FieldMoveHand.NONE
		):
			r_obj_index = select_obj(r_hand_state, r_previous_obj_index)
		else:
			r_obj_index = null

		if (
			l_field_gesture_state == FieldGestureState.IDLE
			and field_move_hand == FieldMoveHand.NONE
		):
			l_obj_index = select_obj(l_hand_state, l_previous_obj_index)
		else:
			l_obj_index = null

		r_moving_obj = is_moving_obj(r_obj_index, r_previous_obj_index)
		l_moving_obj = is_moving_obj(l_obj_index, l_previous_obj_index)
	else:
		r_obj_index = null
		l_obj_index = null
		r_moving_obj = false
		l_moving_obj = false

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

	_update_field_gesture(true, delta)
	_update_field_gesture(false, delta)
	_update_field_translation()

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

# Cancel placement without deleting sources or hiding their fields.
func clear_inventory_tool() -> void:
	for tool in tools:
		tools[tool] = false
	selected_tool = "N/A"
	set_button_selected(btn_pt_charge_tool, false)
	set_button_selected(btn_bar_magnet_tool, false)
	_clear_placement_preview(true)
	_clear_placement_preview(false)
	if (r_field_gesture_state == FieldGestureState.ROTATING
		or l_field_gesture_state == FieldGestureState.ROTATING):
		vector_field.end_rotation()
	r_field_gesture_state = FieldGestureState.IDLE
	l_field_gesture_state = FieldGestureState.IDLE


# The wheel enables the selected tool's field without toggling it back off.
func select_inventory_tool(tool: String) -> void:
	if not tools.has(tool):
		return
	select_tool(tool)
	if tool == "pt_charge" and not functions["e_field_lines"]:
		physics.fields.enable_e_field_lines()
		functions["e_field_lines"] = true
		e_field_changed = true
		set_button_selected(btn_e_field_lines, true)
	elif tool == "bar_magnet" and not functions["b_field_lines"]:
		physics.fields.enable_b_field_lines()
		functions["b_field_lines"] = true
		b_field_changed = true
		set_button_selected(btn_b_field_lines, true)


func select_obj(hand_state: HandState, previous_obj_index):
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
func on_btn_particle_flow_pressed():
	functions["particle_flow"] = !functions["particle_flow"]

	if functions["particle_flow"]:
		set_button_selected(btn_particle_flow, true)
		physics.particles.enable_particle_flow()

	else:
		set_button_selected(btn_particle_flow, false)
		physics.particles.disable_particle_flow()

	physics.particles.clear_trails()

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

func on_btn_solar_system_pressed():
	functions["solar_system"] = !functions["solar_system"]

	if functions["solar_system"]:
		set_button_selected(btn_solar_system, true)

		await get_tree().create_timer(0.5).timeout

		# CODE GOES HERE

		b_field_changed = false

	else:
		set_button_selected(btn_solar_system, false)
		

# ------------------- MORE UI -------------------
var spawn_debounce = true

func _is_inside_vector_field(hand_state: HandState) -> bool:
	return _is_global_position_inside_vector_field(
		hand_state.global_pinch_center
	)

func _is_global_position_inside_vector_field(global_position: Vector3) -> bool:
	var p: Vector3 = vector_field.to_local(global_position)
	return (
		p.x >= vector_field.x_min and p.x <= vector_field.x_max
		and p.y >= vector_field.y_min and p.y <= vector_field.y_max
		and p.z >= vector_field.z_min and p.z <= vector_field.z_max
	)

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
	if p_name == "Fist":
		_begin_field_translation(true)
		return
	if p_name != "index_pinch":
		return

	r_hand_state.update(vector_field)

	if (
		hand_is_touching_field_object(r_hand_state)
		or not _is_inside_vector_field(r_hand_state)
		or l_field_gesture_state == FieldGestureState.ROTATING
		or field_move_hand != FieldMoveHand.NONE
	):
		return

	r_field_gesture_start = r_hand_state.global_pinch_center
	r_field_gesture_state = FieldGestureState.PENDING
	vector_field.stop_rotation_inertia()
	_create_placement_preview(true, r_hand_state.global_pinch_center)

func left(p_name: String) -> void:
	if p_name == "Fist":
		_begin_field_translation(false)
		return
	if p_name != "index_pinch":
		return

	l_hand_state.update(vector_field)

	if (
		hand_is_touching_field_object(l_hand_state)
		or not _is_inside_vector_field(l_hand_state)
		or r_field_gesture_state == FieldGestureState.ROTATING
		or field_move_hand != FieldMoveHand.NONE
	):
		return

	l_field_gesture_start = l_hand_state.global_pinch_center
	l_field_gesture_state = FieldGestureState.PENDING
	vector_field.stop_rotation_inertia()
	_create_placement_preview(false, l_hand_state.global_pinch_center)

func _update_field_gesture(is_right_hand: bool, delta: float) -> void:
	var state: FieldGestureState = (
		r_field_gesture_state if is_right_hand else l_field_gesture_state
	)
	if state == FieldGestureState.IDLE:
		return

	var hand_state: HandState = r_hand_state if is_right_hand else l_hand_state
	var start_position: Vector3 = (
		r_field_gesture_start if is_right_hand else l_field_gesture_start
	)
	if hand_state.released():
		_finish_field_gesture(is_right_hand)
		return

	if state == FieldGestureState.PENDING:
		_update_placement_preview(
			is_right_hand,
			hand_state.global_pinch_center
		)

		# Do not rotate the world while either hand is manipulating a source.
		if r_moving_obj or l_moving_obj:
			return

		var initial_direction: Vector3 = start_position - vector_field.global_position
		var current_direction: Vector3 = (
			hand_state.global_pinch_center - vector_field.global_position
		)
		if initial_direction.is_zero_approx() or current_direction.is_zero_approx():
			return

		var drag_angle: float = initial_direction.angle_to(current_direction)
		if drag_angle < FIELD_ROTATION_ANGLE_THRESHOLD:
			return

		var other_state: FieldGestureState = (
			l_field_gesture_state if is_right_hand else r_field_gesture_state
		)
		if other_state == FieldGestureState.ROTATING:
			return

		if not vector_field.begin_rotation(start_position):
			return

		_clear_placement_preview(is_right_hand)
		state = FieldGestureState.ROTATING
		if is_right_hand:
			r_field_gesture_state = state
		else:
			l_field_gesture_state = state

	if state == FieldGestureState.ROTATING:
		vector_field.update_rotation(hand_state.global_pinch_center, delta)

func _on_right_pose_ended(p_name: String) -> void:
	if p_name == "index_pinch":
		_finish_field_gesture(true)
	elif p_name == "Fist" and field_move_hand == FieldMoveHand.RIGHT:
		_end_field_translation()

func _on_left_pose_ended(p_name: String) -> void:
	if p_name == "index_pinch":
		_finish_field_gesture(false)
	elif p_name == "Fist" and field_move_hand == FieldMoveHand.LEFT:
		_end_field_translation()

func _begin_field_translation(is_right_hand: bool) -> void:
	if (
		control_panel_active
		or field_move_hand != FieldMoveHand.NONE
		or r_field_gesture_state != FieldGestureState.IDLE
		or l_field_gesture_state != FieldGestureState.IDLE
		or r_moving_obj
		or l_moving_obj
	):
		return

	var palm: Node3D = r_palm if is_right_hand else l_palm
	if (
		palm == null
		or not _is_global_position_inside_vector_field(palm.global_position)
	):
		return

	if not vector_field.begin_translation(palm.global_position):
		return

	field_move_hand = (
		FieldMoveHand.RIGHT if is_right_hand else FieldMoveHand.LEFT
	)

func _update_field_translation() -> void:
	if field_move_hand == FieldMoveHand.NONE:
		return

	var palm: Node3D = (
		r_palm if field_move_hand == FieldMoveHand.RIGHT else l_palm
	)
	if palm != null:
		vector_field.update_translation(palm.global_position)

func _end_field_translation() -> void:
	vector_field.end_translation()
	field_move_hand = FieldMoveHand.NONE

func _on_control_panel_visibility_changed(is_visible: bool) -> void:
	control_panel_active = is_visible
	if is_visible and field_move_hand != FieldMoveHand.NONE:
		_end_field_translation()

func _finish_field_gesture(is_right_hand: bool) -> void:
	var state: FieldGestureState = (
		r_field_gesture_state if is_right_hand else l_field_gesture_state
	)
	if state == FieldGestureState.IDLE:
		return

	var hand_state: HandState = r_hand_state if is_right_hand else l_hand_state
	if state == FieldGestureState.PENDING:
		_clear_placement_preview(is_right_hand)
		_spawn_selected_object(hand_state.global_pinch_center, is_right_hand)
	elif state == FieldGestureState.ROTATING:
		vector_field.end_rotation()

	if is_right_hand:
		r_field_gesture_state = FieldGestureState.IDLE
	else:
		l_field_gesture_state = FieldGestureState.IDLE

func _create_placement_preview(
	is_positive: bool,
	global_position: Vector3
) -> void:
	_clear_placement_preview(is_positive)

	var preview_scene: PackedScene = null
	if tools["pt_charge"]:
		preview_scene = pos_charge_scene if is_positive else neg_charge_scene
	elif tools["bar_magnet"]:
		preview_scene = bar_magnet_scene
	else:
		return

	if preview_scene == null:
		return

	var preview := preview_scene.instantiate() as Node3D
	if preview == null:
		return

	preview.name = "RightPlacementPreview" if is_positive else "LeftPlacementPreview"
	_configure_placement_preview(preview)
	vector_field.add_child(preview)
	preview.global_position = global_position

	var charge_label := preview.get_node_or_null("ChargeLabel") as Label3D
	if charge_label:
		charge_label.text = "+1C" if is_positive else "-1C"

	if is_positive:
		r_placement_preview = preview
	else:
		l_placement_preview = preview

func _configure_placement_preview(node: Node) -> void:
	if node is Area3D:
		var area := node as Area3D
		area.monitoring = false
		area.monitorable = false
		area.collision_layer = 0
		area.collision_mask = 0
	elif node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	elif node is GPUParticles3D:
		(node as GPUParticles3D).emitting = false
	elif node is Label3D:
		var label := node as Label3D
		var label_color := label.modulate
		label_color.a = 0.5
		label.modulate = label_color
		var label_outline_color := label.outline_modulate
		label_outline_color.a = 0.5
		label.outline_modulate = label_outline_color
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif node is MeshInstance3D:
		_configure_preview_mesh(node as MeshInstance3D)

	for child in node.get_children():
		_configure_placement_preview(child)

func _configure_preview_mesh(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if mesh_instance.material_override:
		mesh_instance.material_override = _make_preview_material(
			mesh_instance.material_override
		)
		return

	if mesh_instance.mesh == null:
		return

	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material := mesh_instance.get_active_material(surface_index)
		if material:
			mesh_instance.set_surface_override_material(
				surface_index,
				_make_preview_material(material)
			)

func _make_preview_material(source: Material) -> Material:
	var preview_material := source.duplicate() as Material
	if preview_material is BaseMaterial3D:
		var standard_material := preview_material as BaseMaterial3D
		standard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var albedo := standard_material.albedo_color
		albedo.a = 0.5
		standard_material.albedo_color = albedo
	elif preview_material is ShaderMaterial:
		var shader_material := preview_material as ShaderMaterial
		shader_material.shader = BAR_MAGNET_PREVIEW_SHADER
		shader_material.set_shader_parameter(
			"preview_alpha",
			0.5
		)
	return preview_material

func _update_placement_preview(
	is_right_hand: bool,
	global_position: Vector3
) -> void:
	var preview: Node3D = (
		r_placement_preview if is_right_hand else l_placement_preview
	)
	if is_instance_valid(preview):
		preview.global_position = global_position

func _clear_placement_preview(is_right_hand: bool) -> void:
	var preview: Node3D = (
		r_placement_preview if is_right_hand else l_placement_preview
	)
	if is_instance_valid(preview):
		preview.visible = false
		preview.queue_free()

	if is_right_hand:
		r_placement_preview = null
	else:
		l_placement_preview = null

func _spawn_selected_object(global_position: Vector3, is_positive: bool) -> void:
	if not spawn_debounce:
		return

	var pos: Vector3 = vector_field.to_local(global_position)
	if tools["pt_charge"]:
		physics.sources.spawn_pt_charge(pos, 1250.0 if is_positive else -1250.0)
		e_field_changed = true
	elif tools["bar_magnet"]:
		var moment := Vector3(0.0, 700.0 if is_positive else 550.0, 0.0)
		physics.sources.spawn_bar_magnet(pos, moment)
		b_field_changed = true
	else:
		return

	release_sfx.position = pos
	release_sfx.play()

	spawn_debounce = false
	_release_spawn_debounce()

func _release_spawn_debounce() -> void:
	await get_tree().create_timer(0.2).timeout
	spawn_debounce = true
