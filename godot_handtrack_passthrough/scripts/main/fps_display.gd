extends Label3D
## Head-following performance display, also available in exported APKs.

@export var enabled := true:
	set(value):
		enabled = value
		visible = value
		set_process(value)
		_elapsed = 0.0

const UPDATE_INTERVAL := 0.5
var _elapsed := 0.0


func _ready() -> void:
	visible = enabled
	set_process(enabled)
	_update_text()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= UPDATE_INTERVAL:
		_elapsed = fmod(_elapsed, UPDATE_INTERVAL)
		_update_text()


func _update_text() -> void:
	var fps := Engine.get_frames_per_second()
	if fps <= 0.0:
		text = "FPS: --\nFrame interval: -- ms"
		return
	# Reciprocal FPS describes frame spacing, not CPU or GPU execution time.
	text = "FPS: %.0f\nFrame interval: %.1f ms" % [fps, 1000.0 / fps]
