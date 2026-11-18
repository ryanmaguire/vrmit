extends Button

# Keep the corners of the button's rectangular bounds non-interactive.
func _has_point(point: Vector2) -> bool:
	return point.distance_squared_to(size * 0.5) <= pow(minf(size.x, size.y) * 0.5, 2)
