class_name VoltageSource extends CircuitComponent

## Voltage Source component, maintains a specificed voltage [member voltage] ACROSS
## its two terminals.

## As of this version, this is a double A battery
## Later on, will be broken into a proper power source and 
## battery will be its own thing
var voltage:= 1.5 

func set_voltage(new_voltage: float) -> void:
	voltage = new_voltage

func get_elements() -> Array:
	return [{
		"type": ElementType.VSOURCE,
		"terminals": [snapPoints[0], snapPoints[1]],
		"value": voltage,
	}]
