@tool
extends MarginContainer

# --- Keypad buttons (assign in Inspector) ---
@export var btn_x: Button
@export var btn_y: Button
@export var btn_z: Button
@export var btn_a: Button
@export var btn_7: Button
@export var btn_8: Button
@export var btn_9: Button
@export var btn_divide: Button
@export var btn_back: Button

@export var btn_par_l: Button
@export var btn_par_r: Button
@export var btn_power: Button
@export var btn_sqrt: Button
@export var btn_4: Button
@export var btn_5: Button
@export var btn_6: Button
@export var btn_times: Button
@export var btn_left: Button

@export var btn_sin: Button
@export var btn_cos: Button
@export var btn_tan: Button
@export var btn_abs: Button
@export var btn_1: Button
@export var btn_2: Button
@export var btn_3: Button
@export var btn_minus: Button
@export var btn_right: Button

@export var btn_ln: Button
@export var btn_pi: Button
@export var btn_e: Button
@export var btn_clear: Button
@export var btn_0: Button
@export var btn_dot: Button
@export var btn_equals: Button
@export var btn_plus: Button
@export var btn_enter: Button

# --- Display / controls ---
@export var debug_label: Label
@export var plot_scale: HSlider          # "Plot Scale" slider
@export var function_scale: VSlider      # "Function Scale" slider
@export var rotate_toggle: CheckButton   # rotation toggle
@export var axis_toggle: CheckButton   # rotation toggle

# --- Preset function buttons ---
@export var preset_func_1: Button
@export var preset_func_2: Button
@export var preset_func_3: Button
@export var preset_func_4: Button
@export var preset_func_5: Button
@export var preset_func_6: Button
@export var preset_func_7: Button
@export var preset_func_8: Button
@export var preset_func_9: Button

# --- Cal Functions ---
@export var gradient_toggle: CheckButton 
@export var level_curves_toggle: CheckButton 
@export var tangent_plane_toggle: CheckButton 

@export var tangent_plane_x_slider: HSlider 
@export var tangent_plane_y_slider: HSlider

@export var plot_alpha_slider: HSlider

# --- State ---
var expr: String = ""
var cursor_index: int = 0

var preset_exprs := [
	"x+y",
	"x*y/10",
	"1/(x*y)",
	"(x^2+y^2)/20",
	"(x^2-y^2)/10",
	"Sx)*Sy)",
	"Rx^2+y^2)",
	"5*E^(-(x^2+y^2)/10)",
	"(Sx)+1)^(Sy)+4)"
]

func _ready() -> void:
	_connect_global()
	_update_display()

	# Keypad text buttons
	_connect_text(btn_x, "x")
	_connect_text(btn_y, "y")
	_connect_text(btn_z, "z")
	_connect_text(btn_a, "a")
	_connect_text(btn_7, "7")
	_connect_text(btn_8, "8")
	_connect_text(btn_9, "9")
	_connect_text(btn_divide, "/")

	_connect(btn_back, _on_back_pressed)

	_connect_text(btn_par_l, "(")
	_connect_text(btn_par_r, ")")
	_connect_text(btn_power, "^")
	_connect_text(btn_sqrt, "R)")
	_connect_text(btn_4, "4")
	_connect_text(btn_5, "5")
	_connect_text(btn_6, "6")
	_connect_text(btn_times, "*")
	_connect(btn_left, _on_left_pressed)

	_connect_text(btn_sin, "S)")
	_connect_text(btn_cos, "C)")
	_connect_text(btn_tan, "T)")
	_connect_text(btn_abs, "A)")
	_connect_text(btn_1, "1")
	_connect_text(btn_2, "2")
	_connect_text(btn_3, "3")
	_connect_text(btn_minus, "-")
	_connect(btn_right, _on_right_pressed)

	_connect_text(btn_ln, "L)")
	_connect_text(btn_pi, "P")
	_connect_text(btn_e, "E")
	_connect(btn_clear, _on_clear_pressed)
	_connect_text(btn_0, "0")
	_connect_text(btn_dot, ".")
	_connect_text(btn_equals, "=")
	_connect_text(btn_plus, "+")
	_connect(btn_enter, _on_enter_pressed)

	# Presets
	_connect_preset(preset_func_1, 0)
	_connect_preset(preset_func_2, 1)
	_connect_preset(preset_func_3, 2)
	_connect_preset(preset_func_4, 3)
	_connect_preset(preset_func_5, 4)
	_connect_preset(preset_func_6, 5)
	_connect_preset(preset_func_7, 6)
	_connect_preset(preset_func_8, 7)
	_connect_preset(preset_func_9, 8)

	# Sliders and toggle
	if plot_scale:
		plot_scale.value_changed.connect(_on_plot_scale_changed)
	if function_scale:
		function_scale.value_changed.connect(_on_function_scale_changed)
	if rotate_toggle:
		rotate_toggle.toggled.connect(_on_rotate_toggled)
	if axis_toggle:
		axis_toggle.toggled.connect(_on_show_axis_toggled)
		
	
	# Calculus UI → GlobalSignals
	if gradient_toggle:
		gradient_toggle.toggled.connect(_on_gradient_toggled)
	if level_curves_toggle:
		level_curves_toggle.toggled.connect(_on_level_curves_toggled)
	if tangent_plane_toggle:
		tangent_plane_toggle.toggled.connect(_on_tangent_plane_toggled)

	if tangent_plane_x_slider:
		tangent_plane_x_slider.value_changed.connect(_on_tp_x_changed)
	if tangent_plane_y_slider:
		tangent_plane_y_slider.value_changed.connect(_on_tp_y_changed)

	if plot_alpha_slider:
		plot_alpha_slider.value_changed.connect(_on_plot_alpha_changed)

	# initialize downstream state once
	_emit_plane_grad_location()
	if gradient_toggle:
		_on_gradient_toggled(gradient_toggle.button_pressed)
	if level_curves_toggle:
		_on_level_curves_toggled(level_curves_toggle.button_pressed)
	if tangent_plane_toggle:
		_on_tangent_plane_toggled(tangent_plane_toggle.button_pressed)
	if plot_alpha_slider:
		_on_plot_alpha_changed(plot_alpha_slider.value)

# ---------- Connection helpers ----------
func _connect_global() -> void:
	if GlobalSignals.has_signal("debug_message"):
		GlobalSignals.connect("debug_message", _on_debug_message)

func _connect(btn: BaseButton, fn: Callable) -> void:
	if btn:
		btn.pressed.connect(fn)

func _connect_text(btn: BaseButton, s: String) -> void:
	if btn:
		btn.pressed.connect(_on_text_pressed.bind(s))

func _connect_preset(btn: BaseButton, idx: int) -> void:
	if btn and idx >= 0 and idx < preset_exprs.size():
		btn.pressed.connect(_on_preset_pressed.bind(preset_exprs[idx]))

# ---------- UI actions ----------
func _on_function_pressed(s: String) -> void:
	expr = s
	cursor_index = s.length()
	_on_enter_pressed()

func _on_text_pressed(s: String) -> void:
	if cursor_index == 0:
		expr = s + expr
	elif cursor_index == expr.length():
		expr += s
	else:
		expr = expr.left(cursor_index) + s + expr.right(-cursor_index)
	cursor_index += s.length()
	if s.length() > 1 and s[s.length() - 1] == ")":
		cursor_index -= 1
	_update_display()

func _on_back_pressed() -> void:
	if cursor_index > 0:
		expr = expr.left(cursor_index - 1) + expr.right(-cursor_index)
		cursor_index -= 1
	_update_display()

func _on_left_pressed() -> void:
	cursor_index = max(cursor_index - 1, 0)
	_update_display()

func _on_right_pressed() -> void:
	cursor_index = min(cursor_index + 1, expr.length())
	_update_display()

func _on_enter_pressed() -> void:
	GlobalSignals.expression_entered.emit(expr)
	GlobalSignals.update_plot_scale.emit(plot_scale.value)
	GlobalSignals.set_plot_alpha.emit(clamp(plot_alpha_slider.value, 0.0, 1.0))
	_update_display()
	#if debug_label:
	#	debug_label.text = ""

func _on_clear_pressed() -> void:
	expr = ""
	cursor_index = 0
	_update_display()

func expr_display(original: String = "") -> String:
	var display
	if original != "":
		display = original
	if cursor_index == 0:
		display = "|" + expr
	elif cursor_index == len(expr):
		display = expr + "|"
	else:
		display = expr.left(cursor_index) + "|" + expr.right(-cursor_index)
	display = display.replace("R", "sqrt(")
	display = display.replace("S", "sin(")
	display = display.replace("C", "cos(")
	display = display.replace("T", "tan(")
	display = display.replace("A", "abs(")
	display = display.replace("L", "ln(")
	display = display.replace("P", "PI")
	display = display.replace("E", "exp(1)")
	return display

func _on_debug_message(message: String) -> void:
	if debug_label:
		debug_label.text = message

# ---------- Presets and options ----------
func _on_preset_pressed(s: String) -> void:
	_on_function_pressed(s)

func _on_plot_scale_changed(value: float) -> void:
	GlobalSignals.update_plot_scale.emit(value)

func _on_function_scale_changed(value: float) -> void:
	GlobalSignals.update_function_scale.emit(value)

func _on_rotate_toggled(pressed: bool) -> void:
	GlobalSignals.set_rotating.emit(pressed)

func _on_show_axis_toggled(pressed: bool) -> void:
	GlobalSignals.set_axis_visibility.emit(pressed)
	
 

# --------------  CAL FUNCTIONS ----------------------
func _on_gradient_toggled(on: bool) -> void:
	GlobalSignals.set_grad_vector.emit(on)

func _on_level_curves_toggled(on: bool) -> void:
	GlobalSignals.set_level_curves.emit(on)

func _on_tangent_plane_toggled(on: bool) -> void:
	GlobalSignals.set_tangent_plane.emit(on)

func _on_tp_x_changed(_v: float) -> void:
	_emit_plane_grad_location()

func _on_tp_y_changed(_v: float) -> void:
	_emit_plane_grad_location()

func _emit_plane_grad_location() -> void:
	var x = 0.0
	var y = 0.0
	if tangent_plane_x_slider:
		x = float(tangent_plane_x_slider.value)
	if tangent_plane_y_slider:
		y = float(tangent_plane_y_slider.value)
	GlobalSignals.set_plane_grad_location.emit(x, y)

func _on_plot_alpha_changed(alpha: float) -> void:
	GlobalSignals.set_plot_alpha.emit(clamp(alpha, 0.0, 1.0))

# ---------- Internal ----------
func _update_display() -> void:
	if debug_label:
		debug_label.text = expr_display()

func _process(delta: float) -> void:
	if !btn_x.visible:
		_on_text_pressed("x")
		btn_x.visible = true
	if !btn_y.visible:
		_on_text_pressed("y")
		btn_y.visible = true
	if !btn_z.visible:
		_on_text_pressed("z")
		btn_z.visible = true
	if !btn_a.visible:
		_on_text_pressed("a")
		btn_a.visible = true
	if !btn_7.visible:
		_on_text_pressed("7")
		btn_7.visible = true
	if !btn_8.visible:
		_on_text_pressed("8")
		btn_8.visible = true
	if !btn_9.visible:
		_on_text_pressed("9")
		btn_9.visible = true
	if !btn_divide.visible:
		_on_text_pressed("/")
		btn_divide.visible = true
	if !btn_back.visible:
		_on_back_pressed()
		btn_back.visible = true
	
	if !btn_par_l.visible:
		_on_text_pressed("(")
		btn_par_l.visible = true
	if !btn_par_r.visible:
		_on_text_pressed(")")
		btn_par_r.visible = true
	if !btn_power.visible:
		_on_text_pressed("^")
		btn_power.visible = true
	if !btn_sqrt.visible:
		_on_text_pressed("R)")
		btn_sqrt.visible = true
	if !btn_4.visible:
		_on_text_pressed("4")
		btn_4.visible = true
	if !btn_5.visible:
		_on_text_pressed("5")
		btn_5.visible = true
	if !btn_6.visible:
		_on_text_pressed("6")
		btn_6.visible = true
	if !btn_times.visible:
		_on_text_pressed("*")
		btn_times.visible = true
	if !btn_left.visible:
		_on_left_pressed()
		btn_left.visible = true
		
	if !btn_sin.visible:
		_on_text_pressed("S)")
		btn_sin.visible = true
	if !btn_cos.visible:
		_on_text_pressed("C)")
		btn_cos.visible = true
	if !btn_tan.visible:
		_on_text_pressed("T)")
		btn_tan.visible = true
	if !btn_abs.visible:
		_on_text_pressed("A)")
		btn_abs.visible = true
	if !btn_1.visible:
		_on_text_pressed("1")
		btn_1.visible = true
	if !btn_2.visible:
		_on_text_pressed("2")
		btn_2.visible = true
	if !btn_3.visible:
		_on_text_pressed("3")
		btn_3.visible = true
	if !btn_minus.visible:
		_on_text_pressed("-")
		btn_minus.visible = true
	if !btn_right.visible:
		_on_right_pressed()
		btn_right.visible = true
		
	if !btn_ln.visible:
		_on_text_pressed("L)")
		btn_ln.visible = true
	if !btn_pi.visible:
		_on_text_pressed("P")
		btn_pi.visible = true
	if !btn_e.visible:
		_on_text_pressed("E")
		btn_e.visible = true
	if !btn_clear.visible:
		_on_clear_pressed()
		btn_clear.visible = true
	if !btn_0.visible:
		_on_text_pressed("0")
		btn_0.visible = true
	if !btn_dot.visible:
		_on_text_pressed(".")
		btn_dot.visible = true
	if !btn_equals.visible:
		_on_text_pressed("=")
		btn_equals.visible = true
	if !btn_plus.visible:
		_on_text_pressed("+")
		btn_plus.visible = true
	if !btn_enter.visible:
		_on_enter_pressed()
		btn_enter.visible = true
