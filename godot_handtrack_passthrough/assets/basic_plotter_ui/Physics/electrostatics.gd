extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_pt_charge_tool : Button
@export var btn_spawn_pt_charge :  Button

@export var pos_charge_mesh : PackedScene
@export var neg_charge_mesh : PackedScene

var vector_field = null
var r_hand_pose_detector = null
var l_hand_pose_detector = null
var r_poke = null
var l_poke = null
var selected_stylebox = StyleBoxFlat.new()

# --- Physics Constants ---
var EPSILON_0 = 8.85 * pow(10, -12)
var k = round(1 / (4 * PI * EPSILON_0))

# Tools:
# 1. Point Charges
# 2. Charged Rod
var tools = {"pt_charge": false, "charged_rod": false}
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
	_connect(btn_spawn_pt_charge, spawn_pt_charge.bind(2.0, 2.0, 2.0, 1.0))
	
	r_hand_pose_detector.pose_started.connect(right)
	l_hand_pose_detector.pose_started.connect(left)


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
			

var pt_charge_locations = []
var E_fields = []
var charge

func spawn_pt_charge(a_x, a_y, a_z, q):
	var Net_E_x = []
	var Net_E_y = []
	var Net_E_z = []

	if tools["pt_charge"] and [a_x, a_y, a_z] not in pt_charge_locations:
		var E_x = "((%s*%s)/((sqrt((x-%s)^2+(y-%s)^2+(z-%s)^2))^3))*(x-%s)" % [k, q, a_x, a_z, a_y, a_x]
		var E_y = "((%s*%s)/((sqrt((x-%s)^2+(y-%s)^2+(z-%s)^2))^3))*(y-%s)" % [k, q, a_x, a_z, a_y, a_z]
		var E_z = "((%s*%s)/((sqrt((x-%s)^2+(y-%s)^2+(z-%s)^2))^3))*(z-%s)" % [k, q, a_x, a_z, a_y, a_y]
		
		pt_charge_locations.append([a_x, a_y, a_z])
		E_fields.append([E_x, E_y, E_z])

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
		
		GlobalSignals.expressions_entered.emit(" + ".join(Net_E_x), " + ".join(Net_E_y), " + ".join(Net_E_z))

var debounce = true
func right(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if r_poke:
			var pos = vector_field.to_local(r_poke.global_position)
			spawn_pt_charge(pos.x, pos.y, pos.z, 1.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true

func left(p_name : String):
	if p_name == "index_pinch" and debounce:
		debounce = false
		if l_poke:
			var pos = vector_field.to_local(l_poke.global_position)
			spawn_pt_charge(pos.x, pos.y, pos.z, -1.0)
		await get_tree().create_timer(0.2).timeout
		debounce = true
