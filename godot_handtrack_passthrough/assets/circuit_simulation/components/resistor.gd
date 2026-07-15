class_name Resistor extends CircuitComponent

## Resistor class for circuit component. Base [CircuitComponent] plus a resistance value.

## Resistance of the resistor (in ohms). Defaults to 100.
var resistance := 100.0

func set_resistance(new_resistance: float):
	resistance = new_resistance
