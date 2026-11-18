class_name Ground extends CircuitComponent

## Ground object. Only contains one SnapPoint. Meant to be attached to a wire
## or component junction.

func get_elements() -> Array:
	return [{
		"type": ElementType.GROUND,
		"terminals": [snapPoints[0]],
		"value": 0.0,
	}]
