class_name VoltageSource extends CircuitComponent

## Voltage Source component, maintains a specificed voltage [member voltage] ACROSS
## its two terminals.

var voltage:= 0.

func set_voltage(new_voltage: float) -> void:
	voltage = new_voltage

func get_elements() -> Array:
	return [{
		"type": ElementType.VSOURCE,
		"terminals": [snapPoints[0], snapPoints[1]],
		"value": voltage,
	}]
