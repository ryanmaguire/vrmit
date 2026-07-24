class_name CurrentSource extends CircuitComponent

## Current Source component, maintains a specificed current [member current] THROUGH
## its two terminals.

var current:= 0.

func set_current(new_current: float) -> void:
	current = new_current

func get_elements() -> Array:
	return [{
		"type": ElementType.ISOURCE,
		"terminals": [snapPoints[0], snapPoints[1]],
		"value": current,
	}]
