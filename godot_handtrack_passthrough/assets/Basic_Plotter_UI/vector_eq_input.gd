@tool
extends VBoxContainer

# Optional display label for showing the expression + cursor.
@export var debug_label: Label

# --- Keypad buttons (assign in Inspector) ---
@export var btn_x: Button
@export var btn_y: Button
@export var btn_z: Button
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
@export var btn_comma: Button
@export var btn_enter: Button

# --- State ---
var expr: String = ""
var cursor_index: int = 0


func _ready() -> void:
	GlobalSignals.set_field_render.emit(1);
	_update_display()

	# Text buttons
	_connect_text(btn_x, "x")
	_connect_text(btn_y, "y")
	_connect_text(btn_z, "z")
	_connect_text(btn_7, "7")
	_connect_text(btn_8, "8")
	_connect_text(btn_9, "9")
	_connect_text(btn_divide, "/")

	_connect_text(btn_par_l, "(")
	_connect_text(btn_par_r, ")")
	_connect_text(btn_power, "^")
	_connect_text(btn_sqrt, "R)")  # sqrt placeholder
	_connect_text(btn_4, "4")
	_connect_text(btn_5, "5")
	_connect_text(btn_6, "6")
	_connect_text(btn_times, "*")

	_connect_text(btn_sin, "S)")   # sin placeholder
	_connect_text(btn_cos, "C)")   # cos placeholder
	_connect_text(btn_tan, "T)")   # tan placeholder
	_connect_text(btn_abs, "A)")   # abs placeholder
	_connect_text(btn_1, "1")
	_connect_text(btn_2, "2")
	_connect_text(btn_3, "3")
	_connect_text(btn_minus, "-")

	_connect_text(btn_ln, "L)")    # ln placeholder
	_connect_text(btn_pi, "P")     # PI placeholder
	_connect_text(btn_e, "E")      # exp(1) placeholder
	_connect_text(btn_0, "0")
	_connect_text(btn_dot, ".")
	_connect_text(btn_equals, "=")
	_connect_text(btn_plus, "+")
	_connect_text(btn_comma, ",")

	# Non-text actions
	_connect(btn_back, _on_back_pressed)
	_connect(btn_left, _on_left_pressed)
	_connect(btn_right, _on_right_pressed)
	_connect(btn_clear, _on_clear_pressed)
	_connect(btn_enter, _on_enter_pressed)


# ---------- Connection helpers ----------
func _connect(btn: BaseButton, fn: Callable) -> void:
	if btn:
		btn.pressed.connect(fn)

func _connect_text(btn: BaseButton, s: String) -> void:
	if btn:
		btn.pressed.connect(_on_text_pressed.bind(s))


# ---------- Editing actions ----------
func _on_text_pressed(s: String) -> void:
	if cursor_index <= 0:
		expr = s + expr
	elif cursor_index >= expr.length():
		expr += s
	else:
		expr = expr.substr(0, cursor_index) + s + expr.substr(cursor_index)
	cursor_index += s.length()
	# If we just inserted a function pattern like "S)" keep cursor before the ")"
	if s.length() > 1 and s[s.length() - 1] == ")":
		cursor_index -= 1
	_update_display()


func _on_back_pressed() -> void:
	if cursor_index > 0:
		expr = expr.substr(0, cursor_index - 1) + expr.substr(cursor_index)
		cursor_index -= 1
	_update_display()


func _on_left_pressed() -> void:
	cursor_index = max(cursor_index - 1, 0)
	_update_display()


func _on_right_pressed() -> void:
	cursor_index = min(cursor_index + 1, expr.length())
	_update_display()


func _on_clear_pressed() -> void:
	expr = ""
	cursor_index = 0
	_update_display()


# ---------- Enter: parse and emit (x, y, z) ----------
func _on_enter_pressed() -> void:
	var parts := _parse_vector_expr(expr)
	var message_x: String = parts[0]
	var message_y: String = parts[1]
	var message_z: String = parts[2]

	# New vector-expression signal
	GlobalSignals.expressions_entered.emit(message_x, message_y, message_z)

	# Optional: keep old scalar signal if you still use it elsewhere
	# GlobalSignals.expression_entered.emit(expr)

	_update_display()


# ---------- Parsing / display helpers ----------
func _expand_placeholders(s: String) -> String:
	var d := s
	d = d.replace("R", "sqrt(")
	d = d.replace("S", "sin(")
	d = d.replace("C", "cos(")
	d = d.replace("T", "tan(")
	d = d.replace("A", "abs(")
	d = d.replace("L", "ln(")
	d = d.replace("P", "PI")
	d = d.replace("E", "exp(1)")
	return d


func _parse_vector_expr(expr_str: String) -> Array:
	var s := expr_str.strip_edges()

	# Strip one level of outer parentheses: "(x, y, z)" -> "x, y, z"
	if s.begins_with("(") and s.ends_with(")"):
		s = s.substr(1, s.length() - 2).strip_edges()

	var parts: Array = s.split(",", false)

	while parts.size() < 3:
		parts.append("")

	var msg_x: String = _expand_placeholders(str(parts[0]).strip_edges())
	var msg_y: String = _expand_placeholders(str(parts[1]).strip_edges())
	var msg_z: String = _expand_placeholders(str(parts[2]).strip_edges())

	return [msg_x, msg_y, msg_z]


func _expr_display() -> String:
	var display: String
	if cursor_index == 0:
		display = "|" + expr
	elif cursor_index >= expr.length():
		display = expr + "|"
	else:
		display = expr.substr(0, cursor_index) + "|" + expr.substr(cursor_index)
	return _expand_placeholders(display)


func _update_display() -> void:
	if debug_label:
		debug_label.text = _expr_display()
