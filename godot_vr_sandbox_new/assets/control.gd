@tool

extends Control

@export_category("Debug")

@export var cardozo_cube_scene: PackedScene
@export var bloom_cube_scene: PackedScene
@export var hagood_cube_scene: PackedScene

var surface

@onready var btn_x = $"ColorRect/TabContainer/XZ Plot/x"
@onready var btn_y = $"ColorRect/TabContainer/XZ Plot/y"
@onready var btn_z = $"ColorRect/TabContainer/XZ Plot/z"
@onready var btn_7 = $"ColorRect/TabContainer/XZ Plot/7"
@onready var btn_8 = $"ColorRect/TabContainer/XZ Plot/8"
@onready var btn_9 = $"ColorRect/TabContainer/XZ Plot/9"
@onready var btn_divide = $"ColorRect/TabContainer/XZ Plot/divide"
@onready var btn_back = $"ColorRect/TabContainer/XZ Plot/back"

@onready var btn_par_l = $"ColorRect/TabContainer/XZ Plot/("
@onready var btn_par_r = $"ColorRect/TabContainer/XZ Plot/)"
@onready var btn_power = $"ColorRect/TabContainer/XZ Plot/power"
@onready var btn_4 = $"ColorRect/TabContainer/XZ Plot/4"
@onready var btn_5 = $"ColorRect/TabContainer/XZ Plot/5"
@onready var btn_6 = $"ColorRect/TabContainer/XZ Plot/6"
@onready var btn_times = $"ColorRect/TabContainer/XZ Plot/times"
@onready var btn_left = $"ColorRect/TabContainer/XZ Plot/left"

@onready var btn_sin = $"ColorRect/TabContainer/XZ Plot/sin"
@onready var btn_cos = $"ColorRect/TabContainer/XZ Plot/cos"
@onready var btn_tan = $"ColorRect/TabContainer/XZ Plot/tan"
@onready var btn_1 = $"ColorRect/TabContainer/XZ Plot/1"
@onready var btn_2 = $"ColorRect/TabContainer/XZ Plot/2"
@onready var btn_3 = $"ColorRect/TabContainer/XZ Plot/3"
@onready var btn_minus = $"ColorRect/TabContainer/XZ Plot/minus"
@onready var btn_right = $"ColorRect/TabContainer/XZ Plot/right"

@onready var btn_ln = $"ColorRect/TabContainer/XZ Plot/ln"
@onready var btn_pi = $"ColorRect/TabContainer/XZ Plot/pi"
@onready var btn_e = $"ColorRect/TabContainer/XZ Plot/e"
@onready var btn_0 = $"ColorRect/TabContainer/XZ Plot/0"
@onready var btn_dot = $"ColorRect/TabContainer/XZ Plot/dot"
@onready var btn_equals = $"ColorRect/TabContainer/XZ Plot/equals"
@onready var btn_plus = $"ColorRect/TabContainer/XZ Plot/plus"
@onready var btn_enter = $"ColorRect/TabContainer/XZ Plot/enter"


@onready var cardozo_button = $ColorRect/TabContainer/Cube/Cardozo
@onready var bloom_button = $ColorRect/TabContainer/Cube/Bloom
@onready var hagood_button = $ColorRect/TabContainer/Cube/Hagood
@onready var debug_label = $DebugLabel

func _ready():
	print("reaty")
	debug_label.text = "debug label :)"
	
	surface = get_node("sandbox/Surface")
	
	btn_x.pressed.connect(_on_text_pressed.bind("x"))
	btn_y.pressed.connect(_on_text_pressed.bind("y"))
	btn_z.pressed.connect(_on_text_pressed.bind("z"))
	btn_7.pressed.connect(_on_text_pressed.bind("7"))
	btn_8.pressed.connect(_on_text_pressed.bind("8"))
	btn_9.pressed.connect(_on_text_pressed.bind("9"))
	btn_divide.pressed.connect(_on_text_pressed.bind("/"))
	btn_back.pressed.connect(_on_back_pressed)
	
	btn_par_l.pressed.connect(_on_text_pressed.bind("("))
	btn_par_r.pressed.connect(_on_text_pressed.bind(")"))
	btn_power.pressed.connect(_on_text_pressed.bind("z"))
	btn_4.pressed.connect(_on_text_pressed.bind("4"))
	btn_5.pressed.connect(_on_text_pressed.bind("5"))
	btn_6.pressed.connect(_on_text_pressed.bind("6"))
	btn_times.pressed.connect(_on_text_pressed.bind("*"))
	btn_left.pressed.connect(_on_left_pressed)
	
	btn_sin.pressed.connect(_on_text_pressed.bind("sin("))
	btn_cos.pressed.connect(_on_text_pressed.bind("cos("))
	btn_tan.pressed.connect(_on_text_pressed.bind("tan("))
	btn_1.pressed.connect(_on_text_pressed.bind("1"))
	btn_2.pressed.connect(_on_text_pressed.bind("2"))
	btn_3.pressed.connect(_on_text_pressed.bind("3"))
	btn_minus.pressed.connect(_on_text_pressed.bind("-"))
	btn_right.pressed.connect(_on_right_pressed)
	
	btn_ln.pressed.connect(_on_text_pressed.bind("log("))
	btn_pi.pressed.connect(_on_text_pressed.bind("PI"))
	btn_e.pressed.connect(_on_text_pressed.bind("exp(1)"))
	btn_0.pressed.connect(_on_text_pressed.bind("0"))
	btn_dot.pressed.connect(_on_text_pressed.bind("."))
	btn_equals.pressed.connect(_on_text_pressed.bind("="))
	btn_enter.pressed.connect(_on_enter_pressed)
	

	cardozo_button.pressed.connect(_on_cardozo_pressed)
	bloom_button.pressed.connect(_on_bloom_pressed)
	hagood_button.pressed.connect(_on_hagood_pressed)

func _process(delta: float) -> void:
	pass

func _on_text_pressed(s: String):
	surface.function.add_string(s)
	debug_label.text = surface.function.exp_string

func _on_back_pressed():
	surface.function.delete_char()
	debug_label.text = surface.function.exp_string

func _on_left_pressed():
	print("goon")
	
func _on_right_pressed():
	print("goon")
	
func _on_enter_pressed():
	surface.hide()
	surface.update()
	debug_label.text = surface.function.exp_string
	
func _on_cardozo_pressed():
	print("cgoon")
	debug_label.text = "Cardozo selected"
	GlobalSignals.spawn_mode_selected.emit(cardozo_cube_scene)

func _on_bloom_pressed():
	debug_label.text = "Bloom selected"
	GlobalSignals.spawn_mode_selected.emit(bloom_cube_scene)

func _on_hagood_pressed():
	debug_label.text = "Hagood selected"
	GlobalSignals.spawn_mode_selected.emit(hagood_cube_scene)
	
