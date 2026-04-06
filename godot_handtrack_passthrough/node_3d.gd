extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var expression = Expression.new()
	expression.parse("sqrt(4)")
	var result = expression.execute()
	print(result)  # 37.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
