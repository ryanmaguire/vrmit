extends HBoxContainer

# --- Preset buttons (assign in Inspector) ---
@export var btn_preset_1: Button        
@export var btn_preset_2: Button         
@export var btn_preset_3: Button        
@export var btn_preset_4: Button        
@export var btn_preset_5: Button        
@export var btn_preset_6: Button      

# --- Sliders (assign in Inspector) ---
@export var slider_alpha: Slider             # field alpha
@export var slider_resolution: Slider        # field resolution

# --- Render-mode buttons (assign in Inspector) ---
@export var btn_render_arrows: Button        # type 0
@export var btn_render_streamlines: Button   # type 1
@export var btn_render_slices: Button        # type 2

const RENDER_ARROWS      := 0
const RENDER_STREAMLINES := 1
const RENDER_SLICES      := 2

func _ready() -> void:
	# Preset vector fields
	btn_preset_1.pressed.connect(
		_on_preset_pressed.bind("x", "y", "z")
	)
	btn_preset_2.pressed.connect(
		_on_preset_pressed.bind("-y", "-x", "0")
	)
	btn_preset_3.pressed.connect(
		_on_preset_pressed.bind("x-y", "y+x", "0")
	)
	btn_preset_4.pressed.connect(
		_on_preset_pressed.bind("cos(x)", "sin(y)", "cos(z)")
	)
	btn_preset_5.pressed.connect(
		_on_preset_pressed.bind("-x/(sqrt(x^2+y^2+z^2)^3)", "-y/(sqrt(x^2+y^2+z^2)^3)", "-z/(sqrt(x^2+y^2+z^2)^3)")
	)
	btn_preset_6.pressed.connect(
		_on_preset_pressed.bind("z", "x", "y")
	)

	# Sliders
	slider_alpha.value_changed.connect(_on_alpha_changed)
	slider_resolution.value_changed.connect(_on_resolution_changed)

	# Render modes
	btn_render_arrows.pressed.connect(
		_on_render_pressed.bind(RENDER_ARROWS)
	)
	btn_render_streamlines.pressed.connect(
		_on_render_pressed.bind(RENDER_STREAMLINES)
	)
	btn_render_slices.pressed.connect(
		_on_render_pressed.bind(RENDER_SLICES)
	)


func _on_preset_pressed(expr_x: String, expr_y: String, expr_z: String) -> void:
	GlobalSignals.expressions_entered.emit(expr_x, expr_y, expr_z)


func _on_alpha_changed(value: float) -> void:
	GlobalSignals.set_field_alpha.emit(value)


func _on_resolution_changed(value: float) -> void:
	GlobalSignals.set_field_resolution.emit(value)


func _on_render_pressed(render_type: int) -> void:
	GlobalSignals.set_field_render.emit(render_type)
