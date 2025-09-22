@tool

extends Control

@export_category("Debug")

#@export var cardozo_cube_scene: PackedScene
#@export var bloom_cube_scene: PackedScene
#@export var hagood_cube_scene: PackedScene
#@export var chen_cube_scene: PackedScene
@export var surface: PackedScene
  
@onready var btn_x = $"ColorRect/TabContainer/XZ Plot/x"
@onready var btn_y = $"ColorRect/TabContainer/XZ Plot/y"
@onready var btn_z = $"ColorRect/TabContainer/XZ Plot/z"
@onready var btn_a = $"ColorRect/TabContainer/XZ Plot/a"
@onready var btn_7 = $"ColorRect/TabContainer/XZ Plot/7"
@onready var btn_8 = $"ColorRect/TabContainer/XZ Plot/8"
@onready var btn_9 = $"ColorRect/TabContainer/XZ Plot/9"
@onready var btn_divide = $"ColorRect/TabContainer/XZ Plot/divide"
@onready var btn_back = $"ColorRect/TabContainer/XZ Plot/back"

@onready var btn_par_l = $"ColorRect/TabContainer/XZ Plot/("
@onready var btn_par_r = $"ColorRect/TabContainer/XZ Plot/)"
@onready var btn_power = $"ColorRect/TabContainer/XZ Plot/power"
@onready var btn_sqrt = $"ColorRect/TabContainer/XZ Plot/sqrt"
@onready var btn_4 = $"ColorRect/TabContainer/XZ Plot/4"
@onready var btn_5 = $"ColorRect/TabContainer/XZ Plot/5"
@onready var btn_6 = $"ColorRect/TabContainer/XZ Plot/6"
@onready var btn_times = $"ColorRect/TabContainer/XZ Plot/times"
@onready var btn_left = $"ColorRect/TabContainer/XZ Plot/left"

@onready var btn_sin = $"ColorRect/TabContainer/XZ Plot/sin"
@onready var btn_cos = $"ColorRect/TabContainer/XZ Plot/cos"
@onready var btn_tan = $"ColorRect/TabContainer/XZ Plot/tan"
@onready var btn_abs = $"ColorRect/TabContainer/XZ Plot/abs"
@onready var btn_1 = $"ColorRect/TabContainer/XZ Plot/1"
@onready var btn_2 = $"ColorRect/TabContainer/XZ Plot/2"
@onready var btn_3 = $"ColorRect/TabContainer/XZ Plot/3"
@onready var btn_minus = $"ColorRect/TabContainer/XZ Plot/minus"
@onready var btn_right = $"ColorRect/TabContainer/XZ Plot/right"

@onready var btn_ln = $"ColorRect/TabContainer/XZ Plot/ln"
@onready var btn_pi = $"ColorRect/TabContainer/XZ Plot/pi"
@onready var btn_e = $"ColorRect/TabContainer/XZ Plot/e"
@onready var btn_clear = $"ColorRect/TabContainer/XZ Plot/clear"
@onready var btn_0 = $"ColorRect/TabContainer/XZ Plot/0"
@onready var btn_dot = $"ColorRect/TabContainer/XZ Plot/dot"
@onready var btn_equals = $"ColorRect/TabContainer/XZ Plot/equals"
@onready var btn_plus = $"ColorRect/TabContainer/XZ Plot/plus"
@onready var btn_enter = $"ColorRect/TabContainer/XZ Plot/enter"


@onready var cardozo_button = $ColorRect/TabContainer/Cube/Cardozo
@onready var bloom_button = $ColorRect/TabContainer/Cube/Bloom
@onready var hagood_button = $ColorRect/TabContainer/Cube/Hagood
@onready var chen_button = $ColorRect/TabContainer/Cube/Chen
@onready var maguire_button = $ColorRect/TabContainer/Cube/Maguire

@onready var debug_label = $DebugLabel

@onready var set_origin_btn = $"ColorRect/TabContainer/Settings/Set Origin"
@onready var scan_surroundings_btn = $"ColorRect/TabContainer/Settings/Scan Surroundings"
@onready var toggle_mesh_visibility_btn = $"ColorRect/TabContainer/Settings/Toggle Mesh Visibility"

@onready var expr = ""
@onready var cursor_index : int = 0


func _ready():
	GlobalSignals.connect("debug_message", _on_debug_message)
	debug_label.text = expr_display()
	
	#surface = get_parent().get_parent().get_node("Surface")
	print(surface != null)
	
	btn_x.pressed.connect(_on_text_pressed.bind("x"))
	btn_y.pressed.connect(_on_text_pressed.bind("y"))
	btn_z.pressed.connect(_on_text_pressed.bind("z"))
	btn_a.pressed.connect(_on_text_pressed.bind("a"))
	btn_7.pressed.connect(_on_text_pressed.bind("7"))
	btn_8.pressed.connect(_on_text_pressed.bind("8"))
	btn_9.pressed.connect(_on_text_pressed.bind("9"))
	btn_divide.pressed.connect(_on_text_pressed.bind("/"))
	btn_back.pressed.connect(_on_back_pressed)
	
	btn_par_l.pressed.connect(_on_text_pressed.bind("("))
	btn_par_r.pressed.connect(_on_text_pressed.bind(")"))
	btn_power.pressed.connect(_on_text_pressed.bind("^"))
	btn_sqrt.pressed.connect(_on_text_pressed.bind("sqrt()"))
	btn_4.pressed.connect(_on_text_pressed.bind("4"))
	btn_5.pressed.connect(_on_text_pressed.bind("5"))
	btn_6.pressed.connect(_on_text_pressed.bind("6"))
	btn_times.pressed.connect(_on_text_pressed.bind("*"))
	btn_left.pressed.connect(_on_left_pressed)
	
	btn_sin.pressed.connect(_on_text_pressed.bind("sin()"))
	btn_cos.pressed.connect(_on_text_pressed.bind("cos()"))
	btn_tan.pressed.connect(_on_text_pressed.bind("tan()"))
	btn_abs.pressed.connect(_on_text_pressed.bind("abs()"))
	btn_1.pressed.connect(_on_text_pressed.bind("1"))
	btn_2.pressed.connect(_on_text_pressed.bind("2"))
	btn_3.pressed.connect(_on_text_pressed.bind("3"))
	btn_minus.pressed.connect(_on_text_pressed.bind("-"))
	btn_right.pressed.connect(_on_right_pressed)
	
	btn_ln.pressed.connect(_on_text_pressed.bind("log("))
	btn_pi.pressed.connect(_on_text_pressed.bind("PI"))
	btn_e.pressed.connect(_on_text_pressed.bind("exp(1)"))
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_0.pressed.connect(_on_text_pressed.bind("0"))
	btn_dot.pressed.connect(_on_text_pressed.bind("."))
	btn_equals.pressed.connect(_on_text_pressed.bind("="))
	btn_plus	.pressed.connect(_on_text_pressed.bind("+"))
	btn_enter.pressed.connect(_on_enter_pressed)
	

	cardozo_button.pressed.connect(_on_cardozo_pressed)
	bloom_button.pressed.connect(_on_bloom_pressed)
	hagood_button.pressed.connect(_on_hagood_pressed)
	chen_button.pressed.connect(_on_chen_pressed)
	maguire_button.pressed.connect(_on_maguire_pressed)
	
	set_origin_btn.pressed.connect(_on_set_origin_btn_pressed)
	scan_surroundings_btn.pressed.connect(_on_scan_surroundings_btn_pressed)
	toggle_mesh_visibility_btn.pressed.connect(_on_toggle_mesh_visibility_btn_pressed)


func _process(delta: float) -> void:
	pass
	
func _on_function_pressed(s: String):
	'''
	Here are some functions for Tuesday
	(x^2+y^2)/20
	a*(x^2-y^2)/10
	sin(x)+sin(y)
	5*e^(-a*(x^2+y^2))
	z^2=x^2+y^2+a^2
	'''
	expr = s
	cursor_index = len(s)
	_on_enter_pressed()

func _on_text_pressed(s: String):
	if cursor_index == 0:
		expr = s + expr
	elif cursor_index == len(expr):
		expr = expr + s
	else:
		expr = expr.left(cursor_index) + s + expr.right(-cursor_index)
	cursor_index += len(s)
	if s[len(s) - 1] == ")" && len(s) > 1:
		cursor_index -= 1
	debug_label.text = expr_display()

func _on_back_pressed():
	if cursor_index > 0:
		expr = expr.left(cursor_index - 1) + expr.right(-cursor_index)
		cursor_index -= 1
	debug_label.text = expr_display()

func _on_left_pressed():
	cursor_index -= 1
	if cursor_index < 0:
		cursor_index = 0
	debug_label.text = expr_display()
	
func _on_right_pressed():
	cursor_index += 1
	if cursor_index > len(expr):
		cursor_index = len(expr)
	debug_label.text = expr_display()
	
func _on_enter_pressed():
	GlobalSignals.expression_entered.emit(expr)
	debug_label.text = "Entered: " + expr
	
func _on_clear_pressed():
	expr = ""
	cursor_index = 0
	debug_label.text = expr_display()
	
func expr_display() -> String:
	if cursor_index == 0:
		return "|" + expr
	elif cursor_index == len(expr):
		return expr + "|"
	else:
		return expr.left(cursor_index) + "|" + expr.right(-cursor_index)
	
func _on_cardozo_pressed():
	debug_label.text = "Cardozo selected"
	GlobalSignals.block_button_pressed.emit("cardozo")

func _on_bloom_pressed():
	debug_label.text = "Bloom selected"
	GlobalSignals.block_button_pressed.emit("bloom")

func _on_hagood_pressed():
	debug_label.text = "Hagood selected"
	GlobalSignals.block_button_pressed.emit("hagood")
	
func _on_chen_pressed():
	debug_label.text = "Chen selected"
	GlobalSignals.block_bSSutton_pressed.emit("chen")
	
func _on_maguire_pressed():
	debug_label.text = "Maguire selected"
	GlobalSignals.block_button_pressed.emit("maguire")
	
func _on_debug_message(message):
	debug_label.text = message

func _on_set_origin_btn_pressed():
	GlobalSignals.set_origin.emit()
	
func _on_scan_surroundings_btn_pressed():
	GlobalSignals.scan_surroundings.emit()
	
func _on_toggle_mesh_visibility_btn_pressed():
	GlobalSignals.toggle_mesh_visibility.emit()
