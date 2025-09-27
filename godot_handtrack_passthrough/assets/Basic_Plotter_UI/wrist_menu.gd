@tool
extends MarginContainer

@onready var btn_x = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/x"
@onready var btn_y = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/y"
@onready var btn_z = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/z"
@onready var btn_a = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/a"
@onready var btn_7 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/7"
@onready var btn_8 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/8"
@onready var btn_9 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/9"
@onready var btn_divide = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/divide"
@onready var btn_back = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/back"

@onready var btn_par_l = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/("
@onready var btn_par_r = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/)"
@onready var btn_power = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/power"
@onready var btn_sqrt = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/sqrt"
@onready var btn_4 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/4"
@onready var btn_5 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/5"
@onready var btn_6 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/6"
@onready var btn_times = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/times"
@onready var btn_left = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/left"

@onready var btn_sin = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/sin"
@onready var btn_cos = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/cos"
@onready var btn_tan = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/tan"
@onready var btn_abs = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/abs"
@onready var btn_1 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/1"
@onready var btn_2 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/2"
@onready var btn_3 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/3"
@onready var btn_minus = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/minus"
@onready var btn_right = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/right"

@onready var btn_ln = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/ln"
@onready var btn_pi = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/pi"
@onready var btn_e = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/e"
@onready var btn_clear = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/clear"
@onready var btn_0 = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/0"
@onready var btn_dot = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/dot"
@onready var btn_equals = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/equals"
@onready var btn_plus = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/plus"
@onready var btn_enter = $"ColorRect/TabContainer/Equation Input/MarginContainer/XZ Plot/enter"

@onready var debug_label = $"ColorRect/TabContainer/Equation Input/HBoxContainer/equation_input"


#buttons
@onready var preset_func_1 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer/Button"
@onready var preset_func_2 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer2/Button"
@onready var preset_func_3 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer3/Button"
@onready var preset_func_4 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer4/Button"
@onready var preset_func_5 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer5/Button"
@onready var preset_func_6 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer6/Button"
@onready var preset_func_7 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer8/Button"
@onready var preset_func_8 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer7/Button"
@onready var preset_func_9 = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Function Buttons/GridContainer/MarginContainer9/Button"

@onready var plot_scale = $"ColorRect/TabContainer/Plot Options/VBoxContainer/VBoxContainer/Plot Scale/Plot Scale" # h slider
@onready var function_scale = $"ColorRect/TabContainer/Plot Options/VBoxContainer2/Function Scale/Function Scale" #v slider

@onready var rotate_toggle = $"ColorRect/TabContainer/Plot Options/VBoxContainer/Rotate Toggle/Rotate/MarginContainer/Rotation Toggle" #check button

@onready var expr = ""
@onready var cursor_index : int = 0

var preset_exprs := [
	"x+y",
	"x*y",
	"1/(x*y)",
	"x^2+y^2",
	"x^2-y^2",
	"sin(x)*sin(y)",
	"sqrt(x^2+y^2)",
	"exp(-x^2-y^2)",
	"(sin(x)+1)^(sin(y)+4)"
]

func _ready():
	GlobalSignals.connect("debug_message", _on_debug_message)
	debug_label.text = expr_display()
	
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
	
	# preset buttons
	preset_func_1.pressed.connect(_on_preset_pressed.bind(preset_exprs[0]))
	preset_func_2.pressed.connect(_on_preset_pressed.bind(preset_exprs[1]))
	preset_func_3.pressed.connect(_on_preset_pressed.bind(preset_exprs[2]))
	preset_func_4.pressed.connect(_on_preset_pressed.bind(preset_exprs[3]))
	preset_func_5.pressed.connect(_on_preset_pressed.bind(preset_exprs[4]))
	preset_func_6.pressed.connect(_on_preset_pressed.bind(preset_exprs[5]))
	preset_func_7.pressed.connect(_on_preset_pressed.bind(preset_exprs[6]))
	preset_func_8.pressed.connect(_on_preset_pressed.bind(preset_exprs[7]))
	preset_func_9.pressed.connect(_on_preset_pressed.bind(preset_exprs[8]))
	
	if plot_scale:
		plot_scale.value_changed.connect(_on_plot_scale_changed)
	if function_scale:
		function_scale.value_changed.connect(_on_function_scale_changed)
	if rotate_toggle:
		# CheckBox/CheckButton typically emit "toggled(bool)"
		rotate_toggle.toggled.connect(_on_rotate_toggled)



#func _process(delta: float) -> void:
	#pass
	
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
	debug_label.text = ""
	
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

func _on_debug_message(message):
	debug_label.text = message





func _on_preset_pressed(s: String) -> void:
	# set expression and trigger plotting
	_on_function_pressed(s)

func _on_plot_scale_changed(value: float) -> void:
	# emit a global signal other systems can connect to
	# signal name: "plot_scale_changed"
	GlobalSignals.update_plot_scale.emit(value)

func _on_function_scale_changed(value: float) -> void:
	# vertical scaling of function values
	GlobalSignals.update_function_scale.emit(value)

func _on_rotate_toggled(pressed: bool) -> void:
	# toggle rotation on surfaces and related nodes
	# surface expects signal "set_rotating" as used elsewhere
	GlobalSignals.set_rotating.emit(pressed)
