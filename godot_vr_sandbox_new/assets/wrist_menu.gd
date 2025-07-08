@tool

extends Node2D

@export var update_x = false
@export var update_y = false
@export var update_z = false
@export var update_7 = false
@export var update_8 = false
@export var update_9 = false
@export var update_divide = false
@export var update_back = false

@export var update_par_l = false
@export var update_par_r = false
@export var update_power = false
@export var update_4 = false
@export var update_5 = false
@export var update_6 = false
@export var update_times = false
@export var update_left = false

@export var update_sin = false
@export var update_cos = false
@export var update_tan = false
@export var update_1 = false
@export var update_2 = false
@export var update_3 = false
@export var update_minus = false
@export var update_right = false

@export var update_ln = false
@export var update_pi = false
@export var update_e = false
@export var update_0 = false
@export var update_dot = false
@export var update_equals = false
@export var update_plus = false
@export var update_enter = false

var control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	control = $Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update_x:
		control._on_text_pressed("x")
		update_x = false
	if update_y:
		control._on_text_pressed("y")
		update_y = false
	if update_z:
		control._on_text_pressed("z")
		update_z = false
	if update_7:
		control._on_text_pressed("7")
		update_7 = false
	if update_8:
		control._on_text_pressed("8")
		update_8 = false
	if update_9:
		control._on_text_pressed("9")
		update_9 = false
	if update_divide:
		control._on_text_pressed("/")
		update_divide = false
	if update_back:
		control._on_back_pressed()
		update_back = false
		
	if update_par_l:
		control._on_text_pressed("(")
		update_par_l = false
	if update_par_r:
		control._on_text_pressed(")")
		update_par_r = false
	if update_power:
		control._on_text_pressed("^")
		update_power = false
	if update_4:
		control._on_text_pressed("4")
		update_4 = false
	if update_5:
		control._on_text_pressed("5")
		update_5 = false
	if update_6:
		control._on_text_pressed("6")
		update_6 = false
	if update_times:
		control._on_text_pressed("*")
		update_times = false
	if update_left:
		control._on_left_pressed()
		update_left = false
		
	if update_sin:
		control._on_text_pressed("sin(")
		update_sin = false
	if update_cos:
		control._on_text_pressed("cos(")
		update_cos = false
	if update_tan:
		control._on_text_pressed("tan(")
		update_tan = false
	if update_1:
		control._on_text_pressed("1")
		update_1 = false
	if update_2:
		control._on_text_pressed("2")
		update_2 = false
	if update_3:
		control._on_text_pressed("3")
		update_3 = false
	if update_minus:
		control._on_text_pressed("-")
		update_minus = false
	if update_right:
		control._on_right_pressed()
		update_right = false
		
	if update_ln:
		control._on_text_pressed("ln(")
		update_ln = false
	if update_pi:
		control._on_text_pressed("pi")
		update_pi = false
	if update_e:
		control._on_text_pressed("e")
		update_e = false
	if update_0:
		control._on_text_pressed("0")
		update_0 = false
	if update_dot:
		control._on_text_pressed(".")
		update_dot = false
	if update_equals:
		control._on_text_pressed("=")
		update_equals = false
	if update_plus:
		control._on_text_pressed("+")
		update_plus = false
	if update_enter:
		control._on_enter_pressed()
		update_enter = false
